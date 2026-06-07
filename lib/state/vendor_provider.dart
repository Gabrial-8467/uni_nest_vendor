import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/vendor_models.dart';
import '../models/ledger_models.dart' as ledger_models;
import '../services/vendor_api_service.dart';
import '../services/secure_auth_service.dart';
import '../config/vendor_config.dart';
import '../utils/secure_logger.dart';

class VendorProvider extends ChangeNotifier {
  // Vendor Data
  Vendor? _currentVendor;
  List<Product> _products = [];
  List<Order> _orders = [];
  List<ledger_models.VendorPayout> _payouts = [];
  VendorAnalytics? _analytics;
  ledger_models.VendorLedgerSummary? _ledger;
  Map<String, dynamic> _earnings = {};
  Map<String, dynamic> _settings = {};
  DateTime? _productsLastLoadedAt;
  Future<void>? _productsLoadFuture;
  static const Duration _productsCacheTtl = Duration(minutes: 2);

  // Loading States
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  bool _isLoadingOrders = false;
  bool _isLoadingAnalytics = false;
  bool _isLoadingEarnings = false;
  bool _isLoadingLedger = false;
  bool _isLoadingPayouts = false;
  bool _isUpdatingCanteenStatus = false;

  // Error States
  String? _error;
  String? _productsError;
  String? _ordersError;
  String? _analyticsError;
  String? _earningsError;
  String? _ledgerError;
  String? _payoutsError;

  // Analytics Cache
  List<double>? _cachedDailyRevenueLast7Days;
  double? _cachedRevenueGrowthPercentage;
  double? _cachedAverageOrderValueGrowth;
  double? _cachedOrdersGrowthPercentage;
  String? _cachedPeakRevenueDay;

  // Authentication
  bool _isAuthenticated = false;
  String? _authToken;
  String? _refreshToken;

  // Getters
  Vendor? get currentVendor => _currentVendor;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<ledger_models.VendorPayout> get payouts => _payouts;
  VendorAnalytics? get analytics => _analytics;
  ledger_models.VendorLedgerSummary? get ledger => _ledger;
  Map<String, dynamic> get earnings => _earnings;
  Map<String, dynamic> get settings => _settings;

  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoadingEarnings => _isLoadingEarnings;
  bool get isLoadingLedger => _isLoadingLedger;
  bool get isLoadingPayouts => _isLoadingPayouts;
  bool get isUpdatingCanteenStatus => _isUpdatingCanteenStatus;

  String? get error => _error;
  String? get productsError => _productsError;
  String? get ordersError => _ordersError;
  String? get analyticsError => _analyticsError;
  String? get earningsError => _earningsError;
  String? get ledgerError => _ledgerError;
  String? get payoutsError => _payoutsError;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;

  // Invalidate analytics cache
  void _invalidateAnalyticsCache() {
    _cachedDailyRevenueLast7Days = null;
    _cachedRevenueGrowthPercentage = null;
    _cachedAverageOrderValueGrowth = null;
    _cachedOrdersGrowthPercentage = null;
    _cachedPeakRevenueDay = null;
  }

  void _computeAnalytics() {
    final now = DateTime.now();

    // 1. Daily Revenue Last 7 Days
    final List<double> dailyRevenue = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayRevenue = _orders
          .where((order) =>
              order.createdAt.isAfter(dayStart) &&
              order.createdAt.isBefore(dayEnd))
          .fold(0.0, (sum, order) => sum + order.finalAmount);
      dailyRevenue.add(dayRevenue);
    }
    _cachedDailyRevenueLast7Days = dailyRevenue;

    // 2. Growth Percentages
    final currentPeriodStart = now.subtract(const Duration(days: 7));
    final previousPeriodStart = now.subtract(const Duration(days: 14));

    // Revenue Growth
    final currentRevenue = _orders
        .where((order) => order.createdAt.isAfter(currentPeriodStart))
        .fold(0.0, (sum, order) => sum + order.finalAmount);

    final previousRevenue = _orders
        .where((order) =>
            order.createdAt.isAfter(previousPeriodStart) &&
            order.createdAt.isBefore(currentPeriodStart))
        .fold(0.0, (sum, order) => sum + order.finalAmount);

    if (previousRevenue == 0) {
      _cachedRevenueGrowthPercentage = currentRevenue > 0 ? 100.0 : 0.0;
    } else {
      _cachedRevenueGrowthPercentage =
          ((currentRevenue - previousRevenue) / previousRevenue) * 100;
    }

    // Average Order Value Growth
    final currentOrders = _orders
        .where((order) => order.createdAt.isAfter(currentPeriodStart))
        .toList();
    final previousOrders = _orders
        .where((order) =>
            order.createdAt.isAfter(previousPeriodStart) &&
            order.createdAt.isBefore(currentPeriodStart))
        .toList();

    if (currentOrders.isEmpty && previousOrders.isEmpty) {
      _cachedAverageOrderValueGrowth = 0.0;
    } else {
      final currentAvg = currentOrders.isEmpty
          ? 0.0
          : currentOrders.fold(0.0, (sum, order) => sum + order.finalAmount) /
              currentOrders.length;
      final previousAvg = previousOrders.isEmpty
          ? 0.0
          : previousOrders.fold(0.0, (sum, order) => sum + order.finalAmount) /
              previousOrders.length;

      if (previousAvg == 0) {
        _cachedAverageOrderValueGrowth = currentAvg > 0 ? 100.0 : 0.0;
      } else {
        _cachedAverageOrderValueGrowth =
            ((currentAvg - previousAvg) / previousAvg) * 100;
      }
    }

    // Orders Growth
    final currentOrdersCount = currentOrders.length;
    final previousOrdersCount = previousOrders.length;

    if (previousOrdersCount == 0) {
      _cachedOrdersGrowthPercentage = currentOrdersCount > 0 ? 100.0 : 0.0;
    } else {
      _cachedOrdersGrowthPercentage =
          ((currentOrdersCount - previousOrdersCount) / previousOrdersCount) *
              100;
    }

    // Peak Revenue Day
    if (dailyRevenue.isEmpty) {
      _cachedPeakRevenueDay = 'None';
    } else {
      final maxRev = dailyRevenue.reduce((a, b) => a > b ? a : b);
      final maxIdx = dailyRevenue.indexOf(maxRev);
      final pDay = now.subtract(Duration(days: 6 - maxIdx));

      switch (pDay.weekday) {
        case 1: _cachedPeakRevenueDay = 'Monday'; break;
        case 2: _cachedPeakRevenueDay = 'Tuesday'; break;
        case 3: _cachedPeakRevenueDay = 'Wednesday'; break;
        case 4: _cachedPeakRevenueDay = 'Thursday'; break;
        case 5: _cachedPeakRevenueDay = 'Friday'; break;
        case 6: _cachedPeakRevenueDay = 'Saturday'; break;
        case 7: _cachedPeakRevenueDay = 'Sunday'; break;
        default: _cachedPeakRevenueDay = 'None';
      }
    }
  }

  // Initialize provider
  Future<void> initialize() async {
    SecureLogger.info(
      '=== PROVIDER INITIALIZATION START ===',
      tag: 'AUTH_INIT',
    );
    await VendorConfig.initialize();
    await _loadAuthState();

    if (_isAuthenticated && _authToken != null) {
      if (_currentVendor == null) {
        SecureLogger.info(
          'Vendor null after auth load, fetching from API...',
          tag: 'AUTH_INIT',
        );
        await loadVendorData();
      }
    }

    SecureLogger.info(
      '=== PROVIDER INITIALIZATION COMPLETE ===\n'
      'isAuth: $_isAuthenticated, hasToken: ${_authToken != null}, hasVendor: ${_currentVendor != null}',
      tag: 'AUTH_INIT',
    );
    notifyListeners();
  }

  // Load authentication state from secure storage
  Future<void> _loadAuthState() async {
    try {
      SecureLogger.info(
        'Loading auth state from secure storage...',
        tag: 'AUTH',
      );

      // Load from secure storage
      _authToken = await SecureAuthService.getAuthToken();
      _refreshToken = await SecureAuthService.getRefreshToken();
      _isAuthenticated = _authToken != null && _authToken!.isNotEmpty;

      SecureLogger.info(
        'TOKEN: ${_authToken != null ? "PRESENT" : "MISSING"} | '
        'REFRESH: ${_refreshToken != null ? "PRESENT" : "MISSING"} | '
        'AUTH: $_isAuthenticated',
        tag: 'AUTH',
      );

      if (_isAuthenticated) {
        // Try to load vendor from secure storage
        final vendorData = await SecureAuthService.getVendorData();
        SecureLogger.info(
          'VENDOR DATA: ${vendorData != null ? "PRESENT" : "MISSING"}',
          tag: 'AUTH',
        );

        if (vendorData != null) {
          try {
            _currentVendor = Vendor.fromJson(
              Map<String, dynamic>.from(await _decodeJson(vendorData)),
            );
            SecureLogger.info(
              'VENDOR LOADED: ${_currentVendor?.name} (ID: ${_currentVendor?.id})',
              tag: 'AUTH',
            );
          } catch (e) {
            SecureLogger.error(
              'Failed to parse vendor from storage',
              error: e,
              tag: 'AUTH',
            );
          }
        }

        // Fallback: load from API if not in storage
        if (_currentVendor == null && _authToken != null) {
          SecureLogger.info(
            'Vendor not in storage, will fetch from API...',
            tag: 'AUTH',
          );
          await loadVendorData();
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

  Vendor _buildVendorFromAuthPayload({
    Map<String, dynamic>? user,
    Map<String, dynamic>? vendor,
    Map<String, dynamic>? fallbackVendorData,
  }) {
    final merged = <String, dynamic>{
      ...?fallbackVendorData,
      ...?vendor,
      ...?user,
    };

    if (vendor != null) {
      merged['user'] = user ?? vendor['user'];
    }

    return Vendor.fromJson(merged);
  }

  Vendor _applyVendorFallbacks(
    Vendor vendor,
    Map<String, dynamic>? fallbackVendorData,
  ) {
    if (fallbackVendorData == null) {
      return vendor;
    }

    String? readString(String key) {
      final value = fallbackVendorData[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return null;
    }

    return vendor.copyWith(
      name: vendor.name.isNotEmpty ? vendor.name : readString('name'),
      email: vendor.email.isNotEmpty ? vendor.email : readString('email'),
      phone: vendor.phone.isNotEmpty ? vendor.phone : readString('phone'),
      businessName: vendor.businessName.isNotEmpty
          ? vendor.businessName
          : readString('businessName'),
      businessType: vendor.businessType.isNotEmpty
          ? vendor.businessType
          : readString('businessType'),
    );
  }

  Future<bool> _ensureAuthenticatedSession() async {
    // Only check auth token, not vendor data (vendor may need to be fetched)
    if (!_isAuthenticated || _authToken == null) {
      return false;
    }

    // Verify token exists in storage
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
        _currentVendor = _buildVendorFromAuthPayload(
          user: user,
          vendor: response['vendor'] as Map<String, dynamic>?,
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
        _currentVendor = _applyVendorFallbacks(
          _buildVendorFromAuthPayload(
            user: user,
            vendor: response['vendor'] as Map<String, dynamic>?,
            fallbackVendorData: vendorData,
          ),
          vendorData,
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
      // Save tokens via SecureAuthService
      if (_authToken != null && _authToken!.isNotEmpty) {
        await SecureAuthService.saveAuthSession(
          authToken: _authToken!,
          refreshToken: _refreshToken,
          vendorData: _currentVendor != null
              ? await _encodeJson(_currentVendor!.toJson())
              : null,
        );
        SecureLogger.info(
          'Auth state saved: token=${_authToken != null}, vendor=${_currentVendor != null}',
          tag: 'AUTH',
        );
      }
    } catch (e) {
      SecureLogger.error('Failed to save auth state', error: e, tag: 'AUTH');
    }
  }

  // Clear authentication state
  Future<void> _clearAuthState() async {
    try {
      await SecureAuthService.clearAuthSession();

      _authToken = null;
      _refreshToken = null;
      _currentVendor = null;
      _isAuthenticated = false;
      _products = [];
      _productsLastLoadedAt = null;
      _productsLoadFuture = null;
      _orders = [];
      _payouts = [];
      _analytics = null;
      _ledger = null;
      _earnings = {};
      _settings = {};

      _invalidateAnalyticsCache();
      notifyListeners();
    } catch (e) {
      SecureLogger.error('Failed to clear auth state', error: e);
    }
  }

  // Load vendor data
  Future<void> loadVendorData({bool forceProducts = false}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    await Future.wait([
      loadVendorProfile(silent: true),
      loadProducts(force: forceProducts, silent: true),
      loadOrders(silent: true),
      loadAnalytics(silent: true),
      loadEarnings(silent: true),
      loadLedger(silent: true),
      loadPayouts(silent: true),
      loadSettings(silent: true),
    ]);
    notifyListeners();
  }

  bool get _hasFreshProductsCache {
    if (_productsLastLoadedAt == null) {
      return false;
    }

    return DateTime.now().difference(_productsLastLoadedAt!) <
        _productsCacheTtl;
  }

  // Load products
  Future<void> loadProducts({bool force = false, bool silent = false}) async {
    if (!force && _hasFreshProductsCache) {
      SecureLogger.info(
        'Using cached products (${_products.length})',
        tag: 'PRODUCTS',
      );
      return;
    }

    if (_productsLoadFuture != null) {
      SecureLogger.info('Reusing in-flight products request', tag: 'PRODUCTS');
      return _productsLoadFuture;
    }

    _productsLoadFuture = _loadProductsFromServer(silent: silent);
    try {
      await _productsLoadFuture;
    } finally {
      _productsLoadFuture = null;
    }
  }

  Future<void> _loadProductsFromServer({bool silent = false}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingProducts(true, silent: silent);
    _productsError = null;

    try {
      _products = await VendorApiService.getVendorProducts(
        _authToken!,
      );
      _productsLastLoadedAt = DateTime.now();
      SecureLogger.info('Loaded ${_products.length} products', tag: 'PRODUCTS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _productsError = 'Failed to load products: ${e.toString()}';
      SecureLogger.error('Failed to load products', error: e);
    } finally {
      _setLoadingProducts(false, silent: silent);
    }
  }

  // Load orders
  Future<void> loadOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    bool silent = false,
  }) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingOrders(true, silent: silent);
    _ordersError = null;

    try {
      _orders = await VendorApiService.getVendorOrders(
        _authToken!,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      _invalidateAnalyticsCache();
      SecureLogger.info('Loaded ${_orders.length} orders', tag: 'ORDERS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _ordersError = 'Failed to load orders: ${e.toString()}';
      SecureLogger.error('Failed to load orders', error: e);
    } finally {
      _setLoadingOrders(false, silent: silent);
    }
  }

  // Load analytics
  Future<void> loadAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    bool silent = false,
  }) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingAnalytics(true, silent: silent);
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
      _setLoadingAnalytics(false, silent: silent);
    }
  }

  // Load earnings
  Future<void> loadEarnings({
    DateTime? startDate,
    DateTime? endDate,
    bool silent = false,
  }) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingEarnings(true, silent: silent);
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
      _setLoadingEarnings(false, silent: silent);
    }
  }

  Future<void> loadLedger({bool silent = false}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingLedger(true, silent: silent);
    _ledgerError = null;

    try {
      _ledger = await VendorApiService.getVendorLedger(_authToken!);
      SecureLogger.info('Loaded vendor ledger', tag: 'LEDGER');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _ledgerError = 'Failed to load ledger: ${e.toString()}';
      SecureLogger.error('Failed to load ledger', error: e);
    } finally {
      _setLoadingLedger(false, silent: silent);
    }
  }

  Future<void> loadPayouts({bool silent = false}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    _setLoadingPayouts(true, silent: silent);
    _payoutsError = null;

    try {
      final payoutsResult = await VendorApiService.getVendorPayouts(
        _authToken!,
      );
      _payouts = payoutsResult;
      SecureLogger.info('Loaded ${_payouts.length} payouts', tag: 'PAYOUTS');
    } catch (e) {
      await _handleUnauthorizedIfNeeded(e);
      _payoutsError = 'Failed to load payouts: ${e.toString()}';
      SecureLogger.error('Failed to load payouts', error: e);
    } finally {
      _setLoadingPayouts(false, silent: silent);
    }
  }

  // Load settings
  Future<void> loadSettings({bool silent = false}) async {
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
      if (!silent) notifyListeners();
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

  Future<bool> updateCanteenOpenStatus(bool isOpen) async {
    if (!_isAuthenticated || _authToken == null || _currentVendor == null) {
      return false;
    }

    _isUpdatingCanteenStatus = true;
    _error = null;

    final previousVendor = _currentVendor!;
    final businessDetails = Map<String, dynamic>.from(
      previousVendor.businessDetails,
    );
    businessDetails['isOpen'] = isOpen;
    businessDetails['isAvailable'] = isOpen;
    businessDetails['isAcceptingOrders'] = isOpen;
    businessDetails['acceptingOrders'] = isOpen;
    businessDetails['canteenOpen'] = isOpen;

    _currentVendor = previousVendor.copyWith(
      isOpen: isOpen,
      businessDetails: businessDetails,
    );
    notifyListeners();

    try {
      final updatedVendor = await VendorApiService.updateVendorProfile(
        {
          'isOpen': isOpen,
          'isAvailable': isOpen,
          'isAcceptingOrders': isOpen,
          'acceptingOrders': isOpen,
          'canteenOpen': isOpen,
          'businessDetails': businessDetails,
        },
        _authToken!,
      );

      _currentVendor = updatedVendor.copyWith(isOpen: isOpen);
      await _saveAuthState();

      SecureLogger.info(
        'Canteen status updated: ${isOpen ? 'open' : 'closed'}',
        tag: 'PROFILE',
      );
      return true;
    } catch (e) {
      _currentVendor = previousVendor;
      _error = 'Failed to update canteen status: ${e.toString()}';
      SecureLogger.error('Failed to update canteen status', error: e);
      return false;
    } finally {
      _isUpdatingCanteenStatus = false;
      notifyListeners();
    }
  }

  // Load vendor profile
  Future<void> loadVendorProfile({bool silent = false}) async {
    if (!await _ensureAuthenticatedSession()) {
      return;
    }

    try {
      final vendor = await VendorApiService.getVendorProfile(_authToken!);
      _currentVendor = vendor;
      await _saveAuthState();
      SecureLogger.info('Vendor profile loaded', tag: 'PROFILE');
      if (!silent) notifyListeners();
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
    SecureLogger.info('=== CREATE PRODUCT START ===', tag: 'PRODUCTS');

    // Try to get token directly from secure storage if not in memory
    String? effectiveToken = _authToken;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      // Use the API service helper to retrieve the token, which handles fallback and migration
      effectiveToken = await VendorApiService.getAuthToken();
      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        _authToken = effectiveToken;
        _isAuthenticated = true;
        SecureLogger.info('Token loaded via VendorApiService', tag: 'PRODUCTS');
      }
    }

    // Validate token
    if (effectiveToken == null || effectiveToken.isEmpty) {
      _error = 'Not authenticated. Please login.';
      SecureLogger.error(
        'CREATE PRODUCT FAILED: No auth token',
        tag: 'PRODUCTS',
      );
      return false;
    }

    // If vendor is null, try to fetch it
    if (_currentVendor == null) {
      SecureLogger.info(
        'Vendor missing, attempting to fetch...',
        tag: 'PRODUCTS',
      );
      await loadVendorProfile();
      if (_currentVendor == null) {
        _error = 'Vendor profile not loaded. Please login again.';
        SecureLogger.error(
          'CREATE PRODUCT FAILED: Could not load vendor',
          tag: 'PRODUCTS',
        );
        return false;
      }
    }

    _setLoading(true);
    _error = null;

    final hasImages = imageFiles != null && imageFiles.isNotEmpty;
    SecureLogger.info(
      'Has images: $hasImages, imageCount=${imageFiles?.length ?? 0}',
      tag: 'PRODUCTS',
    );

    try {
      SecureLogger.info('Calling API service...', tag: 'PRODUCTS');
      final newProduct = hasImages
          ? await VendorApiService.createProductWithImages(
              productData,
              imageFiles,
              effectiveToken,
            )
          : await VendorApiService.createProduct(productData, effectiveToken);
      SecureLogger.info('API call completed successfully', tag: 'PRODUCTS');

      _products.insert(0, newProduct);
      _productsLastLoadedAt = DateTime.now();

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
    Map<String, dynamic> productData, {
    List<File>? imageFiles,
  }) async {
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
        imageFiles: imageFiles,
      );

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
      } else {
        _products.insert(0, updatedProduct);
      }
      _productsLastLoadedAt = DateTime.now();

      SecureLogger.info(
        'Product updated: ${updatedProduct.name}',
        tag: 'PRODUCTS',
      );

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
      _productsLastLoadedAt = DateTime.now();

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
        note: notes,
      );

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        _invalidateAnalyticsCache();
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
      await loadVendorData(forceProducts: true);
    }
  }

  // Helper methods
  void _setLoading(bool loading, {bool silent = false}) {
    _isLoading = loading;
    if (!silent) notifyListeners();
  }

  void _setLoadingProducts(bool loading, {bool silent = false}) {
    _isLoadingProducts = loading;
    if (!silent) notifyListeners();
  }

  void _setLoadingOrders(bool loading, {bool silent = false}) {
    _isLoadingOrders = loading;
    if (!silent) notifyListeners();
  }

  void _setLoadingAnalytics(bool loading, {bool silent = false}) {
    _isLoadingAnalytics = loading;
    if (!silent) notifyListeners();
  }

  void _setLoadingEarnings(bool loading, {bool silent = false}) {
    _isLoadingEarnings = loading;
    if (!silent) notifyListeners();
  }

  void _setLoadingLedger(bool loading, {bool silent = false}) {
    _isLoadingLedger = loading;
    if (!silent) notifyListeners();
  }

  void _setLoadingPayouts(bool loading, {bool silent = false}) {
    _isLoadingPayouts = loading;
    if (!silent) notifyListeners();
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
        .where(
          (o) =>
              o.status == 'pending' ||
              o.status == 'payment_pending' ||
              o.status == 'confirmed',
        )
        .length;
  }

  // Get total revenue
  double get totalRevenue {
    return _earnings['totalRevenue']?.toDouble() ??
        _analytics?.totalRevenue ??
        _ledger?.totalEarnings ??
        0.0;
  }

  double get availableSettlementBalance => _ledger?.availableBalance ?? 0.0;

  double get pendingSettlementBalance => _ledger?.pendingBalance ?? 0.0;

  double get totalCommissionOwed => _ledger?.commissionOwed ?? 0.0;

  double get platformReceivable => _ledger?.platformReceivable ?? 0.0;

  ledger_models.VendorPayout? get latestPayout =>
      _payouts.isEmpty ? null : _payouts.first;

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
    if (_cachedDailyRevenueLast7Days == null) {
      _computeAnalytics();
    }
    return _cachedDailyRevenueLast7Days!;
  }

  // Get revenue growth percentage (last 7 days vs previous 7 days)
  double get revenueGrowthPercentage {
    if (_cachedRevenueGrowthPercentage == null) {
      _computeAnalytics();
    }
    return _cachedRevenueGrowthPercentage!;
  }

  // Get average order value growth percentage
  double get averageOrderValueGrowth {
    if (_cachedAverageOrderValueGrowth == null) {
      _computeAnalytics();
    }
    return _cachedAverageOrderValueGrowth!;
  }

  // Get orders growth percentage
  double get ordersGrowthPercentage {
    if (_cachedOrdersGrowthPercentage == null) {
      _computeAnalytics();
    }
    return _cachedOrdersGrowthPercentage!;
  }

  // Get peak revenue day in the last 7 days
  String get peakRevenueDay {
    if (_cachedPeakRevenueDay == null) {
      _computeAnalytics();
    }
    return _cachedPeakRevenueDay!;
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
    _ledgerError = null;
    _payoutsError = null;
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

// Riverpod provider for VendorProvider
final vendorProviderProvider = ChangeNotifierProvider<VendorProvider>((ref) {
  return VendorProvider();
});
