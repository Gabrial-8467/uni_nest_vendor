import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/vendor_config.dart';
import '../models/auth_models.dart';
import '../models/ledger_models.dart';
import '../models/order_models.dart';
import '../services/secure_auth_service.dart';

class VendorApiException implements Exception {
  VendorApiException(this.message, {this.statusCode, this.payload});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? payload;

  @override
  String toString() => message;
}

class VendorApiClient {
  VendorApiClient([
    dynamic legacyStorage,
  ]); // Parameter kept for backward compatibility

  final http.Client _httpClient = http.Client();
  final Map<String, _CachedResponse> _getCache = {};

  String get _baseUrl => VendorConfig.apiBaseUrl;
  static const Duration _cacheTtl = Duration(seconds: 15);

  Future<AuthSession?> restoreSession() async {
    // Use SecureAuthService for consistent token storage
    final token = await SecureAuthService.getAuthToken();
    final refreshToken = await SecureAuthService.getRefreshToken();
    final vendorData = await SecureAuthService.getVendorData();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      VendorProfile profile;
      if (vendorData != null) {
        final data = Map<String, dynamic>.from(jsonDecode(vendorData) as Map);
        profile = VendorProfile.fromJson(data);
      } else {
        // Fetch profile from API if not stored
        profile = await getProfile();
        // Save it for next time
        await SecureAuthService.saveVendorData(jsonEncode(profile.toJson()));
      }
      return AuthSession(
        accessToken: token,
        refreshToken: refreshToken,
        profile: profile,
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> persistSession(AuthSession session) async {
    await SecureAuthService.saveAuthSession(
      authToken: session.accessToken,
      refreshToken: session.refreshToken,
      vendorData: jsonEncode(session.profile.toJson()),
    );
  }

  Future<void> clearSession() async {
    await SecureAuthService.clearAuthSession();
  }

  Future<String?> getAccessToken() => SecureAuthService.getAuthToken();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/auth/login',
      requiresAuth: false,
      body: {'email': email, 'password': password},
    );
    final session = AuthSession.fromLoginResponse(response);
    await persistSession(session);
    return session;
  }

  Future<void> forgotPassword({required String email}) async {
    await _request(
      method: 'POST',
      path: '/auth/forgot-password',
      requiresAuth: false,
      body: {'email': email},
    );
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/auth/register',
      requiresAuth: false,
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'businessName': businessName,
        'businessType': businessType,
        'password': password,
      },
    );
    final session = AuthSession.fromLoginResponse(response);
    await persistSession(session);
    return session;
  }

  Future<VendorProfile> getProfile() async {
    final response = await _request(method: 'GET', path: '/profile');
    return VendorProfile.fromJson(_asMap(response['data']));
  }

  Future<VendorProfile> updateProfile(Map<String, dynamic> body) async {
    final payload = Map<String, dynamic>.from(body);
    final contactInfo = payload['contactInfo'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(payload['contactInfo'] as Map)
        : <String, dynamic>{};

    if (payload['phone'] != null && contactInfo['phone'] == null) {
      contactInfo['phone'] = payload['phone'];
    }
    if (payload['email'] != null && contactInfo['email'] == null) {
      contactInfo['email'] = payload['email'];
    }
    if (contactInfo.isNotEmpty) {
      payload['contactInfo'] = contactInfo;
    }

    final response = await _request(
      method: 'PUT',
      path: '/profile',
      body: payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic> && data.isNotEmpty) {
      return VendorProfile.fromJson(data);
    }
    return getProfile();
  }

  Future<List<VendorOrder>> getVendorOrders() async {
    final response = await _request(
      method: 'GET',
      path: '/orders',
      queryParameters: const {
        'page': '1',
        'limit': '50',
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      },
    );
    final data = response['data'];
    final rawOrders = data is List
        ? data
        : data is Map<String, dynamic>
        ? (data['orders'] ?? data['items'] ?? data['results'] ?? const [])
        : const [];

    return (rawOrders as List)
        .whereType<Map>()
        .map((order) => VendorOrder.fromJson(Map<String, dynamic>.from(order)))
        .toList();
  }

  Future<VendorOrder> getOrderById(String orderId) async {
    final response = await _request(method: 'GET', path: '/orders/$orderId');
    final payload = response['data'];
    final orderJson = payload is Map<String, dynamic>
        ? payload['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['order'] as Map)
              : payload
        : <String, dynamic>{};
    return VendorOrder.fromJson(orderJson);
  }

  Future<VendorOrder> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
    String? estimatedDeliveryTime,
    String? otp,
  }) async {
    final response = await _request(
      method: 'PUT',
      path: '/orders/$orderId/status',
      body: {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (estimatedDeliveryTime != null &&
            estimatedDeliveryTime.trim().isNotEmpty)
          'estimatedDeliveryTime': estimatedDeliveryTime.trim(),
        if (otp != null && otp.trim().isNotEmpty) 'otp': otp.trim(),
      },
    );

    final payload = response['data'];
    final orderJson = payload is Map<String, dynamic>
        ? payload['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['order'] as Map)
              : payload
        : <String, dynamic>{};
    return VendorOrder.fromJson(orderJson);
  }

  Future<VendorOrder> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    final order = await getOrderById(orderId);
    final status = order.status.toLowerCase();
    if (status != 'pending' && status != 'confirmed') {
      throw VendorApiException(
        'Cannot reject order in "$status" status. Only pending or confirmed orders can be rejected.',
      );
    }
    return updateOrderStatus(
      orderId: orderId,
      status: 'cancelled',
      note: reason,
    );
  }

  Future<VendorOrder> verifyDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/orders/$orderId/verify-otp',
      body: {'otp': otp},
    );
    final payload = response['data'];
    final orderJson = payload is Map<String, dynamic>
        ? payload['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['order'] as Map)
              : payload
        : <String, dynamic>{};
    return VendorOrder.fromJson(orderJson);
  }

  Future<VendorLedgerSummary> getLedger() async {
    try {
      final response = await _request(method: 'GET', path: '/ledger');
      return VendorLedgerSummary.fromJson(
        Map<String, dynamic>.from(response['data'] ?? const {}),
      );
    } on VendorApiException catch (error) {
      if (error.statusCode == 404) {
        return VendorLedgerSummary.fromJson(const {});
      }
      rethrow;
    }
  }

  Future<List<VendorPayout>> getPayouts() async {
    try {
      final response = await _request(method: 'GET', path: '/payouts');
      final data = response['data'];
      final rawPayouts = data is List
          ? data
          : data is Map<String, dynamic>
          ? (data['payouts'] ?? data['items'] ?? const [])
          : const [];

      return (rawPayouts as List)
          .whereType<Map>()
          .map((item) => VendorPayout.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on VendorApiException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<VendorPayout> requestPayout({required double amount}) async {
    final response = await _request(
      method: 'POST',
      path: '/payouts/request',
      body: {'amount': amount},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return VendorPayout.fromJson(Map<String, dynamic>.from(data));
    }
    throw VendorApiException('Invalid response format from payout request');
  }

  /// Get vendor's payout method (bank/UPI details)
  Future<PayoutMethod?> getPayoutMethod() async {
    try {
      final response = await _request(method: 'GET', path: '/payouts/method');
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return PayoutMethod.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on VendorApiException catch (error) {
      if (error.statusCode == 404) {
        return null; // No payout method set yet
      }
      rethrow;
    }
  }

  /// Update vendor's payout method
  Future<PayoutMethod> updatePayoutMethod(PayoutMethod method) async {
    final response = await _request(
      method: 'PUT',
      path: '/payouts/method',
      body: method.toJson(),
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return PayoutMethod.fromJson(Map<String, dynamic>.from(data));
    }
    throw VendorApiException(
      'Invalid response format from update payout method',
    );
  }

  Future<Map<String, dynamic>> getAnalytics({
    String period = 'lifetime',
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/analytics',
      queryParameters: {'period': period},
    );
    return _asMap(response['data']);
  }

  Future<Map<String, dynamic>> getProductAnalytics({
    String period = '7d',
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/analytics/products',
      queryParameters: {'period': period},
    );
    return _asMap(response['data']);
  }

  Future<Map<String, dynamic>> getRevenueAnalytics({
    String period = '7d',
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/analytics/revenue',
      queryParameters: {'period': period},
    );
    return _asMap(response['data']);
  }

  Future<Map<String, dynamic>> getOrderAnalytics({String period = '7d'}) async {
    final response = await _request(
      method: 'GET',
      path: '/analytics/orders',
      queryParameters: {'period': period},
    );
    return _asMap(response['data']);
  }

  Future<List<VendorNotification>> getNotifications() async {
    final response = await _request(
      method: 'GET',
      path: '/notifications',
      queryParameters: const {'page': '1', 'limit': '20'},
    );
    final data = response['data'];
    final rawNotifications = data is List
        ? data
        : data is Map<String, dynamic>
        ? (data['notifications'] ?? data['items'] ?? const [])
        : const [];

    return (rawNotifications as List)
        .whereType<Map>()
        .map(
          (item) =>
              VendorNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Get vendor dashboard data
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _request(method: 'GET', path: '/dashboard');
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  // ==================== PRODUCT CRUD ====================

  Future<List<Map<String, dynamic>>> getProducts({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    String? status,
    String? availability,
    bool? isFeatured,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (availability != null && availability.isNotEmpty) {
      queryParams['availability'] = availability;
    }
    if (isFeatured != null) queryParams['isFeatured'] = isFeatured.toString();
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) {
      queryParams['sortOrder'] = sortOrder;
    }

    final response = await _request(
      method: 'GET',
      path: '/products',
      queryParameters: queryParams,
    );
    final data = response['data'];
    final rawProducts = data is List
        ? data
        : data is Map<String, dynamic>
        ? (data['products'] ?? data['items'] ?? data['results'] ?? const [])
        : const [];

    return (rawProducts as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getProductById(String productId) async {
    final response = await _request(
      method: 'GET',
      path: '/products/$productId',
    );
    final payload = response['data'];
    if (payload is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload);
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    String? availability,
    bool? isFeatured,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'category': category,
    };
    if (availability != null) body['availability'] = availability;
    if (isFeatured != null) body['isFeatured'] = isFeatured;
    if (images != null && images.isNotEmpty) body['images'] = images;

    final response = await _request(
      method: 'POST',
      path: '/products',
      body: body,
    );
    final payload = response['data'];
    if (payload is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload);
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? availability,
    bool? isFeatured,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (category != null) body['category'] = category;
    if (availability != null) body['availability'] = availability;
    if (isFeatured != null) body['isFeatured'] = isFeatured;
    if (images != null) body['images'] = images;

    final response = await _request(
      method: 'PUT',
      path: '/products/$productId',
      body: body.isEmpty ? null : body,
    );
    final payload = response['data'];
    if (payload is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload);
    }
    return <String, dynamic>{};
  }

  Future<void> deleteProduct(String productId) async {
    await _request(method: 'DELETE', path: '/products/$productId');
  }

  // ==================== UPLOAD ====================

  Future<List<String>> uploadProductImages(
    List<List<int>> imageBytesList,
    List<String> filenames,
  ) async {
    final uri = _buildUri('/upload/product-images');
    final token = await getAccessToken();
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    for (var i = 0; i < imageBytesList.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytesList[i],
          filename: filenames[i],
        ),
      );
    }
    final streamedResponse = await request.send().timeout(
      VendorConfig.connectionTimeout,
    );
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final urls = data['imageUrls'] ?? data['urls'] ?? data['images'];
        if (urls is List) {
          return urls.whereType<String>().toList();
        }
      }
      return [];
    }
    throw VendorApiException(
      decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Upload failed',
      statusCode: response.statusCode,
    );
  }

  // ==================== REVIEWS ====================

  Future<List<Map<String, dynamic>>> getReviews({
    int page = 1,
    int limit = 20,
    int? rating,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (rating != null) queryParams['rating'] = rating.toString();

    final response = await _request(
      method: 'GET',
      path: '/reviews',
      queryParameters: queryParams,
    );
    final data = response['data'];
    final rawReviews = data is List
        ? data
        : data is Map<String, dynamic>
        ? (data['reviews'] ?? data['items'] ?? data['results'] ?? const [])
        : const [];

    return (rawReviews as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 20,
    int? rating,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (rating != null) queryParams['rating'] = rating.toString();

    final response = await _request(
      method: 'GET',
      path: '/reviews/products/$productId',
      queryParameters: queryParams,
    );
    final data = response['data'];
    final rawReviews = data is List
        ? data
        : data is Map<String, dynamic>
        ? (data['reviews'] ?? data['items'] ?? data['results'] ?? const [])
        : const [];

    return (rawReviews as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ==================== PAYOUT BY ID ====================

  Future<Map<String, dynamic>> getPayoutById(String payoutId) async {
    final response = await _request(method: 'GET', path: '/payouts/$payoutId');
    final payload = response['data'];
    if (payload is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload);
    }
    return <String, dynamic>{};
  }

  Future<void> markAllNotificationsRead() async {
    await _request(method: 'PUT', path: '/notifications/mark-all-read');
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _request(method: 'PUT', path: '/notifications/$notificationId/read');
  }

  Future<void> clearAllNotifications() async {
    await _request(method: 'DELETE', path: '/notifications/clear-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _request(method: 'DELETE', path: '/notifications/$notificationId');
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    bool requiresAuth = true,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: queryParameters?.isEmpty == true
          ? null
          : queryParameters,
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final normalizedMethod = method.toUpperCase();
    final cacheKey = '$normalizedMethod:$uri';

    if (normalizedMethod == 'GET') {
      final cached = _getCache[cacheKey];
      if (cached != null && !cached.isExpired) {
        return cached.data;
      }
    }

    if (requiresAuth) {
      final token = await getAccessToken();
      if (token == null || token.isEmpty) {
        throw VendorApiException('Session expired. Please login again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    try {
      switch (normalizedMethod) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(VendorConfig.connectionTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(VendorConfig.connectionTimeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(VendorConfig.connectionTimeout);
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(VendorConfig.connectionTimeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers)
              .timeout(VendorConfig.connectionTimeout);
          break;
        default:
          throw VendorApiException('Unsupported request method: $method');
      }
    } catch (error) {
      throw VendorApiException('Network error: $error');
    }

    final decoded = _decodeResponse(response.body);
    debugPrint('API Response: ${response.statusCode} - $decoded');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (normalizedMethod == 'GET') {
        _getCache[cacheKey] = _CachedResponse(decoded);
      } else {
        _invalidateMutableCaches();
      }
      return decoded;
    }

    if (response.statusCode == 401) {
      await clearSession();
    }

    final errorMsg =
        decoded['message']?.toString() ??
        decoded['error']?.toString() ??
        'Request failed';
    debugPrint('API Error: $errorMsg (status: ${response.statusCode})');
    throw VendorApiException(
      errorMsg,
      statusCode: response.statusCode,
      payload: decoded,
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return {'message': body};
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  Uri _buildUri(String path) {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  void _invalidateMutableCaches() {
    _getCache.removeWhere(
      (key, _) =>
          key.contains('/orders') ||
          key.contains('/notifications') ||
          key.contains('/ledger') ||
          key.contains('/payouts') ||
          key.contains('/dashboard') ||
          key.contains('/profile'),
    );
  }
}

class _CachedResponse {
  _CachedResponse(this.data) : createdAt = DateTime.now();

  final Map<String, dynamic> data;
  final DateTime createdAt;

  bool get isExpired =>
      DateTime.now().difference(createdAt) > VendorApiClient._cacheTtl;
}
