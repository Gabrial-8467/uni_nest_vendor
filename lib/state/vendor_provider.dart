import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/vendor_models.dart';
import '../services/vendor_api_service.dart';
import '../config/vendor_config.dart';
import '../utils/secure_logger.dart';

class VendorProvider extends ChangeNotifier {
  // Vendor Data
  Vendor? _currentVendor;
  List<Product> _products = [];
  List<Order> _orders = [];
  VendorAnalytics? _analytics;
  Map<String, dynamic> _earnings = {};
  Map<String, dynamic> _settings = {};

  // Loading States
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  bool _isLoadingOrders = false;
  bool _isLoadingAnalytics = false;
  bool _isLoadingEarnings = false;

  // Error States
  String? _error;
  String? _productsError;
  String? _ordersError;
  String? _analyticsError;
  String? _earningsError;

  // Authentication
  bool _isAuthenticated = false;
  String? _authToken;
  String? _refreshToken;

  // Getters
  Vendor? get currentVendor => _currentVendor;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  VendorAnalytics? get analytics => _analytics;
  Map<String, dynamic> get earnings => _earnings;
  Map<String, dynamic> get settings => _settings;

  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoadingEarnings => _isLoadingEarnings;

  String? get error => _error;
  String? get productsError => _productsError;
  String? get ordersError => _ordersError;
  String? get analyticsError => _analyticsError;
  String? get earningsError => _earningsError;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;

  // Initialize provider
  Future<void> initialize() async {
    await VendorConfig.initialize();
    await _loadAuthState();
    if (_isAuthenticated && _authToken != null) {
      await loadVendorData();
    }
  }

  // Load authentication state from storage
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(VendorConfig.tokenKey);
      _refreshToken = prefs.getString(VendorConfig.refreshTokenKey);
      _isAuthenticated = _authToken != null && _authToken!.isNotEmpty;

      if (_isAuthenticated) {
        final vendorData = prefs.getString(VendorConfig.vendorKey);
        if (vendorData != null) {
          _currentVendor = Vendor.fromJson(
            Map<String, dynamic>.from(await _decodeJson(vendorData)),
          );
        }
      }
    } catch (e) {
      SecureLogger.error('Failed to load auth state', error: e);
      await logout();
    }
  }

  String? _readToken(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<bool> _ensureAuthenticatedSession() async {
    if (!_isAuthenticated || _currentVendor == null) {
      return false;
    }

    final storedToken = await VendorApiService.getAuthToken();
    if (storedToken == null || storedToken.isEmpty) {
      SecureLogger.error(
        'Authenticated state exists but stored token is missing. Clearing session.',
        tag: 'AUTH',
      );
      await _clearAuthState();
      return false;
    }

    _authToken = storedToken;
    return true;
  }

  Future<void> _handleUnauthorizedIfNeeded(Object error) async {
    if (error is VendorApiException &&
        error.statusCode == ApiStatusCodes.unauthorized) {
      _error = 'Session expired. Please login again.';
      await _clearAuthState();
    }
  }

  // Login vendor
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await VendorApiService.loginVendor(email, password);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final tokens = data?['tokens'] as Map<String, dynamic>?;
        final user = data?['user'] as Map<String, dynamic>?;

        _authToken =
            _readToken(tokens, const ['token', 'accessToken']) ??
            _readToken(data, const ['token', 'accessToken', 'access_token']) ??
            _readToken(response, const ['token', 'accessToken']);
        _refreshToken =
            _readToken(tokens, const ['refreshToken', 'refresh_token']) ??
            _readToken(data, const ['refreshToken', 'refresh_token']) ??
            _readToken(response, const ['refreshToken', 'refresh_token']);
        _currentVendor = Vendor.fromJson(
          user ?? (response['vendor'] as Map<String, dynamic>? ?? {}),
        );

        if (_authToken == null || _authToken!.isEmpty) {
          _error = 'Login failed: token not found in response';
          SecureLogger.error(_error!, tag: 'AUTH');
          return false;
        }

        // Persist token first to avoid race conditions with immediate GET calls.
        await VendorApiService.saveAuthTokens(
          authToken: _authToken!,
          refreshToken: _refreshToken,
        );

        _isAuthenticated = true;

        await _saveAuthState();
        await loadVendorData();

        SecureLogger.info('Vendor login successful', tag: 'AUTH');
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        SecureLogger.error('Vendor login failed: $_error');
        return false;
      }
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _error = 'Login failed: ${e.toString()}';
      SecureLogger.error('Vendor login error', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register vendor
  Future<bool> register(Map<String, dynamic> vendorData) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await VendorApiService.registerVendor(vendorData);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final tokens = data?['tokens'] as Map<String, dynamic>?;
        final user = data?['user'] as Map<String, dynamic>?;

        _authToken =
            _readToken(tokens, const ['token', 'accessToken']) ??
            _readToken(data, const ['token', 'accessToken', 'access_token']) ??
            _readToken(response, const ['token', 'accessToken']);
        _refreshToken =
            _readToken(tokens, const ['refreshToken', 'refresh_token']) ??
            _readToken(data, const ['refreshToken', 'refresh_token']) ??
            _readToken(response, const ['refreshToken', 'refresh_token']);
        _currentVendor = Vendor.fromJson(
          user ?? (response['vendor'] as Map<String, dynamic>? ?? {}),
        );

        if (_authToken == null || _authToken!.isEmpty) {
          _error = 'Registration failed: token not found in response';
          SecureLogger.error(_error!, tag: 'AUTH');
          return false;
        }

        await VendorApiService.saveAuthTokens(
          authToken: _authToken!,
          refreshToken: _refreshToken,
        );

        _isAuthenticated = true;

        await _saveAuthState();
        await loadVendorData();

        SecureLogger.info('Vendor registration successful', tag: 'AUTH');
        return true;
      } else {
        _error = response['message'] ?? 'Registration failed';
        SecureLogger.error('Vendor registration failed: $_error');
        return false;
      }
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _error = 'Registration failed: ${e.toString()}';
      SecureLogger.error('Vendor registration error', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout vendor
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await VendorApiService.logoutVendor(_authToken!);
      }
    } catch (e) {
      SecureLogger.error('Logout API call failed', error: e);
    }

    await _clearAuthState();
    SecureLogger.info('Vendor logged out', tag: 'AUTH');
  }

  // Save authentication state
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null && _authToken!.isNotEmpty) {
        await VendorApiService.saveAuthTokens(
          authToken: _authToken!,
          refreshToken: _refreshToken,
        );
      }

      if (_currentVendor != null) {
        await prefs.setString(
          VendorConfig.vendorKey,
          await _encodeJson(_currentVendor!.toJson()),
        );
      }
    } catch (e) {
      SecureLogger.error('Failed to save auth state', error: e);
    }
  }

  // Clear authentication state
  Future<void> _clearAuthState() async {
    try {
      await VendorApiService.clearAuthSession();

      _authToken = null;
      _refreshToken = null;
      _currentVendor = null;
      _isAuthenticated = false;
      _products = [];
      _orders = [];
      _analytics = null;
      _earnings = {};
      _settings = {};

      notifyListeners();
    } catch (e) {
      SecureLogger.error('Failed to clear auth state', error: e);
    }
  }

  // Load vendor data
  Future<void> loadVendorData() async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    await Future.wait([
      loadVendorProfile(),
      loadProducts(),
      loadOrders(),
      loadAnalytics(),
      loadEarnings(),
      loadSettings(),
    ]);
  }

  // Load products
  Future<void> loadProducts() async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingProducts(true);
    _productsError = null;

    try {
      _products = await VendorApiService.getVendorProducts(_authToken!);
      SecureLogger.info('Loaded ${_products.length} products', tag: 'PRODUCTS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _productsError = 'Failed to load products: ${e.toString()}';
      SecureLogger.error('Failed to load products', error: e);
    } finally {
      _setLoadingProducts(false);
    }
  }

  // Load orders
  Future<void> loadOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingOrders(true);
    _ordersError = null;

    try {
      _orders = await VendorApiService.getVendorOrders(
        _authToken!,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      SecureLogger.info('Loaded ${_orders.length} orders', tag: 'ORDERS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _ordersError = 'Failed to load orders: ${e.toString()}';
      SecureLogger.error('Failed to load orders', error: e);
    } finally {
      _setLoadingOrders(false);
    }
  }

  // Load analytics
  Future<void> loadAnalytics({DateTime? startDate, DateTime? endDate}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingAnalytics(true);
    _analyticsError = null;

    try {
      _analytics = await VendorApiService.getVendorAnalytics(
        _authToken!,
        startDate: startDate,
        endDate: endDate,
      );
      SecureLogger.info('Loaded vendor analytics', tag: 'ANALYTICS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _analyticsError = 'Failed to load analytics: ${e.toString()}';
      SecureLogger.error('Failed to load analytics', error: e);
    } finally {
      _setLoadingAnalytics(false);
    }
  }

  // Load earnings
  Future<void> loadEarnings({DateTime? startDate, DateTime? endDate}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingEarnings(true);
    _earningsError = null;

    try {
      final earningsData = await VendorApiService.getVendorEarnings(
        _authToken!,
        startDate: startDate,
        endDate: endDate,
      );
      _earnings = Map<String, dynamic>.from(earningsData);
      if (!_earnings.containsKey('total') &&
          _earnings.containsKey('totalRevenue')) {
        _earnings['total'] = _earnings['totalRevenue'];
      }
      if (!_earnings.containsKey('totalRevenue') &&
          _earnings.containsKey('total')) {
        _earnings['totalRevenue'] = _earnings['total'];
      }
      SecureLogger.info('Loaded vendor earnings', tag: 'EARNINGS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _earningsError = 'Failed to load earnings: ${e.toString()}';
      SecureLogger.error('Failed to load earnings', error: e);
    } finally {
      _setLoadingEarnings(false);
    }
  }

  // Load settings
  Future<void> loadSettings() async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    try {
      final response = await VendorApiService.getVendorSettings(_authToken!);
      _settings = Map<String, dynamic>.from(response);

      // Also load from local storage
      final prefs = await SharedPreferences.getInstance();
      final localSettings = prefs.getString(VendorConfig.settingsKey);
      if (localSettings != null) {
        _settings.addAll(
          Map<String, dynamic>.from(await _decodeJson(localSettings)),
        );
      }

      SecureLogger.info('Loaded vendor settings', tag: 'SETTINGS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      SecureLogger.error('Failed to load settings', error: e);
    }
  }

  // Update vendor profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final updatedVendor = await VendorApiService.updateVendorProfile(
        profileData,
        _authToken!,
      );

      _currentVendor = updatedVendor;
      await _saveAuthState();

      SecureLogger.info('Vendor profile updated', tag: 'PROFILE');
      return true;
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      SecureLogger.error('Failed to update profile', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load vendor profile
  Future<void> loadVendorProfile() async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    try {
      final vendor = await VendorApiService.getVendorProfile(_authToken!);
      _currentVendor = vendor;
      await _saveAuthState();
      SecureLogger.info('Vendor profile loaded', tag: 'PROFILE');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      SecureLogger.error('Failed to load vendor profile', error: e);
    }
  }

  // Update notification settings
  Future<bool> updateNotificationSettings(
    NotificationSettings notificationSettings,
  ) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      // Update the vendor's notification settings
      final updatedVendor = _currentVendor!.copyWith(
        notificationSettings: notificationSettings,
      );

      _currentVendor = updatedVendor;
      await _saveAuthState();

      SecureLogger.info('Notification settings updated', tag: 'NOTIFICATIONS');
      return true;
    } catch (e) {
      _error = 'Failed to update notification settings: ${e.toString()}';
      SecureLogger.error('Failed to update notification settings', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create product
  Future<bool> createProduct(
    Map<String, dynamic> productData, {
    List<File>? imageFiles,
  }) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final newProduct =
          (imageFiles != null && imageFiles.isNotEmpty)
          ? await VendorApiService.createProductWithImages(
              productData,
              imageFiles,
              _authToken!,
            )
          : await VendorApiService.createProduct(productData, _authToken!);

      _products.insert(0, newProduct);

      SecureLogger.info('Product created: ${newProduct.name}', tag: 'PRODUCTS');
      return true;
    } catch (e) {
      _error = 'Failed to create product: ${e.toString()}';
      SecureLogger.error('Failed to create product', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update product
  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final updatedProduct = await VendorApiService.updateProduct(
        productId,
        productData,
        _authToken!,
      );

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
      }

      SecureLogger.info(
        'Product updated: ${updatedProduct.name}',
        tag: 'PRODUCTS',
      );

      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update product: ${e.toString()}';
      SecureLogger.error('Failed to update product', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await VendorApiService.deleteProduct(productId, _authToken!);
      _products.removeWhere((p) => p.id == productId);

      SecureLogger.info('Product deleted: $productId', tag: 'PRODUCTS');
      return true;
    } catch (e) {
      _error = 'Failed to delete product: ${e.toString()}';
      SecureLogger.error('Failed to delete product', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? notes,
  }) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    try {
      final updatedOrder = await VendorApiService.updateOrderStatus(
        orderId,
        status,
        _authToken!,
        notes: notes,
      );

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      SecureLogger.info(
        'Order status updated: $orderId -> $status',
        tag: 'ORDERS',
      );
      return true;
    } catch (e) {
      SecureLogger.error('Failed to update order status', error: e);
      return false;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    if (_isAuthenticated) {
      await loadVendorData();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingProducts(bool loading) {
    _isLoadingProducts = loading;
    notifyListeners();
  }

  void _setLoadingOrders(bool loading) {
    _isLoadingOrders = loading;
    notifyListeners();
  }

  void _setLoadingAnalytics(bool loading) {
    _isLoadingAnalytics = loading;
    notifyListeners();
  }

  void _setLoadingEarnings(bool loading) {
    _isLoadingEarnings = loading;
    notifyListeners();
  }

  // JSON encoding/decoding helpers
  Future<String> _encodeJson(Map<String, dynamic> data) async {
    // In a real implementation, this would use encryption
    return jsonEncode(data);
  }

  Future<Map<String, dynamic>> _decodeJson(String data) async {
    // In a real implementation, this would use decryption
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((o) => o.status == status).toList();
  }

  // Get today's orders
  List<Order> getTodayOrders() {
    final today = DateTime.now();
    return _orders.where((o) {
      final orderDate = o.createdAt;
      return orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).toList();
  }

  // Get pending orders count
  int get pendingOrdersCount {
    return _orders
        .where((o) => o.status == 'pending' || o.status == 'confirmed')
        .length;
  }

  // Get total revenue
  double get totalRevenue {
    return _earnings['totalRevenue']?.toDouble() ?? 0.0;
  }

  // Get today's revenue
  double get todayRevenue {
    final todayOrders = getTodayOrders();
    return todayOrders.fold(0.0, (sum, order) => sum + order.finalAmount);
  }

  // Get weekly revenue
  double get weeklyRevenue {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final weekOrders = _orders.where((order) {
      return order.createdAt.isAfter(weekStart);
    }).toList();

    return weekOrders.fold(0.0, (sum, order) => sum + order.finalAmount);
  }

  // Get daily revenue for the last 7 days
  List<double> get dailyRevenueLast7Days {
    final now = DateTime.now();
    final List<double> dailyRevenue = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayOrders = _orders.where((order) {
        return order.createdAt.isAfter(dayStart) &&
            order.createdAt.isBefore(dayEnd);
      }).toList();

      final dayRevenue = dayOrders.fold(
        0.0,
        (sum, order) => sum + order.finalAmount,
      );
      dailyRevenue.add(dayRevenue);
    }

    return dailyRevenue;
  }

  // Get revenue growth percentage (last 7 days vs previous 7 days)
  double get revenueGrowthPercentage {
    final now = DateTime.now();
    final currentPeriodStart = now.subtract(const Duration(days: 7));
    final previousPeriodStart = now.subtract(const Duration(days: 14));

    final currentRevenue = _orders
        .where((order) => order.createdAt.isAfter(currentPeriodStart))
        .fold(0.0, (sum, order) => sum + order.finalAmount);

    final previousRevenue = _orders
        .where(
          (order) =>
              order.createdAt.isAfter(previousPeriodStart) &&
              order.createdAt.isBefore(currentPeriodStart),
        )
        .fold(0.0, (sum, order) => sum + order.finalAmount);

    if (previousRevenue == 0) return currentRevenue > 0 ? 100.0 : 0.0;
    return ((currentRevenue - previousRevenue) / previousRevenue) * 100;
  }

  // Get average order value growth percentage
  double get averageOrderValueGrowth {
    final now = DateTime.now();
    final currentPeriodStart = now.subtract(const Duration(days: 7));
    final previousPeriodStart = now.subtract(const Duration(days: 14));

    final currentOrders = _orders
        .where((order) => order.createdAt.isAfter(currentPeriodStart))
        .toList();
    final previousOrders = _orders
        .where(
          (order) =>
              order.createdAt.isAfter(previousPeriodStart) &&
              order.createdAt.isBefore(currentPeriodStart),
        )
        .toList();

    if (currentOrders.isEmpty && previousOrders.isEmpty) return 0.0;

    final currentAvg = currentOrders.isEmpty
        ? 0.0
        : currentOrders.fold(0.0, (sum, order) => sum + order.finalAmount) /
              currentOrders.length;
    final previousAvg = previousOrders.isEmpty
        ? 0.0
        : previousOrders.fold(0.0, (sum, order) => sum + order.finalAmount) /
              previousOrders.length;

    if (previousAvg == 0) return currentAvg > 0 ? 100.0 : 0.0;
    return ((currentAvg - previousAvg) / previousAvg) * 100;
  }

  // Get orders growth percentage
  double get ordersGrowthPercentage {
    final now = DateTime.now();
    final currentPeriodStart = now.subtract(const Duration(days: 7));
    final previousPeriodStart = now.subtract(const Duration(days: 14));

    final currentOrders = _orders
        .where((order) => order.createdAt.isAfter(currentPeriodStart))
        .length;
    final previousOrders = _orders
        .where(
          (order) =>
              order.createdAt.isAfter(previousPeriodStart) &&
              order.createdAt.isBefore(currentPeriodStart),
        )
        .length;

    if (previousOrders == 0) return currentOrders > 0 ? 100.0 : 0.0;
    return ((currentOrders - previousOrders) / previousOrders) * 100;
  }

  // Get peak revenue day in the last 7 days
  String get peakRevenueDay {
    final dailyRevenue = dailyRevenueLast7Days;

    if (dailyRevenue.isEmpty) return 'None';

    final maxRevenue = dailyRevenue.reduce((a, b) => a > b ? a : b);
    final maxIndex = dailyRevenue.indexOf(maxRevenue);

    // Calculate the actual day of week for the peak day
    final now = DateTime.now();
    final peakDay = now.subtract(Duration(days: 6 - maxIndex));

    switch (peakDay.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // Get new products count (last 30 days)
  int get newProductsCount {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _products
        .where((product) => product.createdAt.isAfter(thirtyDaysAgo))
        .length;
  }

  // Clear errors
  void clearErrors() {
    _error = null;
    _productsError = null;
    _ordersError = null;
    _analyticsError = null;
    _earningsError = null;
    notifyListeners();
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await VendorApiService.changePassword(
        _authToken!,
        currentPassword,
        newPassword,
      );

      if (response['success'] == true) {
        SecureLogger.info('Password changed successfully', tag: 'AUTH');
        return true;
      } else {
        _error = response['message'] ?? 'Failed to change password';
        SecureLogger.error('Password change failed: $_error', tag: 'AUTH');
        return false;
      }
    } catch (e) {
      _error = 'Failed to change password: $e';
      SecureLogger.error('Password change error', error: e, tag: 'AUTH');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
