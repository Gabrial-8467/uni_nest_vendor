import 'dart:convert';

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
    return VendorProfile.fromJson(
      Map<String, dynamic>.from(response['data'] ?? const {}),
    );
  }

  Future<VendorProfile> updateProfile(Map<String, dynamic> body) async {
    final response = await _request(
      method: 'PUT',
      path: '/profile',
      body: body,
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

  Future<VendorOrder> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
    String? estimatedDeliveryTime,
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
    final response = await _request(
      method: 'POST',
      path: '/orders/$orderId/reject',
      body: {'reason': reason},
    );
    final payload = response['data'];
    final orderJson = payload is Map<String, dynamic>
        ? payload['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['order'] as Map)
              : payload
        : <String, dynamic>{};
    return VendorOrder.fromJson(orderJson);
  }

  Future<VendorOrder> verifyDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/orders/$orderId/delivery-otp/verify',
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

  Future<void> markAllNotificationsRead() async {
    await _request(method: 'PUT', path: '/notifications/mark-all-read');
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

    throw VendorApiException(
      decoded['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
      payload: decoded,
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'data': decoded};
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
