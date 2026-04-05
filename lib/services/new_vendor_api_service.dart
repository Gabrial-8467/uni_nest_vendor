import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/auth_models.dart';
import '../models/ledger_models.dart';
import '../models/order_models.dart';

/// API Service for all vendor operations
class VendorApiService {
  VendorApiService(this._apiClient);

  final ApiClient _apiClient;

  // ==================== AUTHENTICATION ====================

  /// Login vendor
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      usePublicClient: true,
    );

    final data = response.data!;
    final token = data['token'] as String? ?? data['accessToken'] as String?;

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'No access token received from server',
        statusCode: 400,
      );
    }

    // Parse user data
    final userData = data['user'] ?? data['vendor'] ?? data['data'];
    final user = VendorProfile.fromJson(
      userData is Map<String, dynamic> ? userData : <String, dynamic>{},
    );

    return AuthSession(
      accessToken: token,
      refreshToken: data['refreshToken'] as String?,
      profile: user,
    );
  }

  /// Register new vendor
  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'businessName': businessName,
        'businessType': businessType,
        'password': password,
      },
      usePublicClient: true,
    );

    final data = response.data!;
    final token = data['token'] as String? ?? data['accessToken'] as String?;

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'No access token received from server',
        statusCode: 400,
      );
    }

    // Parse user data
    final userData = data['user'] ?? data['vendor'] ?? data['data'];
    final user = VendorProfile.fromJson(
      userData is Map<String, dynamic> ? userData : <String, dynamic>{},
    );

    return AuthSession(
      accessToken: token,
      refreshToken: data['refreshToken'] as String?,
      profile: user,
    );
  }

  /// Forgot password
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
      usePublicClient: true,
    );
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post<void>('/auth/logout');
    } catch (e) {
      // Ignore logout API errors - token will be cleared locally
    }
  }

  // ==================== PROFILE ====================

  /// Get vendor profile
  Future<VendorProfile> getProfile() async {
    final response = await _apiClient.get<VendorProfile>(
      '/profile',
      fromJson: (data) {
        final userData = data['data'] ?? data;
        return VendorProfile.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
        );
      },
    );
    return response.data!;
  }

  /// Update vendor profile
  Future<VendorProfile> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiClient.put<VendorProfile>(
      '/profile',
      data: profileData,
      fromJson: (data) {
        final userData = data['data'] ?? data;
        return VendorProfile.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
        );
      },
    );
    return response.data!;
  }

  // ==================== ORDERS ====================

  /// Get vendor orders
  Future<List<VendorOrder>> getOrders({
    String page = '1',
    String limit = '50',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final response = await _apiClient.get<List<VendorOrder>>(
      '/orders',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
      fromJson: (data) {
        final ordersData = data['data'] ?? data;
        final rawOrders = ordersData is List
            ? ordersData
            : ordersData is Map<String, dynamic>
            ? (ordersData['orders'] ??
                  ordersData['items'] ??
                  ordersData['results'] ??
                  [])
            : [];

        return (rawOrders as List)
            .whereType<Map>()
            .map(
              (order) => VendorOrder.fromJson(Map<String, dynamic>.from(order)),
            )
            .toList();
      },
    );
    return response.data!;
  }

  /// Update order status
  Future<VendorOrder> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
    String? estimatedDeliveryTime,
  }) async {
    final response = await _apiClient.put<VendorOrder>(
      '/orders/$orderId/status',
      data: {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (estimatedDeliveryTime != null &&
            estimatedDeliveryTime.trim().isNotEmpty)
          'estimatedDeliveryTime': estimatedDeliveryTime.trim(),
      },
      fromJson: (data) {
        final payload = data['data'] ?? data;
        final orderJson = payload is Map<String, dynamic>
            ? payload['order'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(payload['order'] as Map)
                  : payload
            : <String, dynamic>{};
        return VendorOrder.fromJson(orderJson);
      },
    );
    return response.data!;
  }

  /// Reject order
  Future<VendorOrder> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    final response = await _apiClient.post<VendorOrder>(
      '/orders/$orderId/reject',
      data: {'reason': reason},
      fromJson: (data) {
        final payload = data['data'] ?? data;
        final orderJson = payload is Map<String, dynamic>
            ? payload['order'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(payload['order'] as Map)
                  : payload
            : <String, dynamic>{};
        return VendorOrder.fromJson(orderJson);
      },
    );
    return response.data!;
  }

  /// Verify delivery OTP
  Future<VendorOrder> verifyDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    final response = await _apiClient.post<VendorOrder>(
      '/orders/$orderId/delivery-otp/verify',
      data: {'otp': otp},
      fromJson: (data) {
        final payload = data['data'] ?? data;
        final orderJson = payload is Map<String, dynamic>
            ? payload['order'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(payload['order'] as Map)
                  : payload
            : <String, dynamic>{};
        return VendorOrder.fromJson(orderJson);
      },
    );
    return response.data!;
  }

  // ==================== LEDGER ====================

  /// Get vendor ledger summary
  Future<VendorLedgerSummary> getLedgerSummary() async {
    try {
      final response = await _apiClient.get<VendorLedgerSummary>(
        '/ledger',
        fromJson: (data) => VendorLedgerSummary.fromJson(
          data['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['data'] as Map)
              : <String, dynamic>{},
        ),
      );
      return response.data!;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return VendorLedgerSummary.fromJson(const {});
      }
      rethrow;
    }
  }

  /// Get vendor payouts
  Future<List<VendorPayout>> getPayouts() async {
    try {
      final response = await _apiClient.get<List<VendorPayout>>(
        '/payouts',
        fromJson: (data) {
          final payoutsData = data['data'] ?? data;
          final rawPayouts = payoutsData is List
              ? payoutsData
              : payoutsData is Map<String, dynamic>
              ? (payoutsData['payouts'] ?? payoutsData['items'] ?? [])
              : [];

          return (rawPayouts as List)
              .whereType<Map>()
              .map(
                (item) =>
                    VendorPayout.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        },
      );
      return response.data!;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Get vendor notifications
  Future<List<VendorNotification>> getNotifications({
    String page = '1',
    String limit = '20',
  }) async {
    final response = await _apiClient.get<List<VendorNotification>>(
      '/notifications',
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (data) {
        final notificationsData = data['data'] ?? data;
        final rawNotifications = notificationsData is List
            ? notificationsData
            : notificationsData is Map<String, dynamic>
            ? (notificationsData['notifications'] ??
                  notificationsData['items'] ??
                  [])
            : [];

        return (rawNotifications as List)
            .whereType<Map>()
            .map(
              (item) =>
                  VendorNotification.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      },
    );
    return response.data!;
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    await _apiClient.put<void>('/notifications/mark-all-read');
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _apiClient.delete<void>('/notifications/clear-all');
  }

  /// Delete specific notification
  Future<void> deleteNotification(String notificationId) async {
    await _apiClient.delete<void>('/notifications/$notificationId');
  }

  // ==================== VERSION CHECK ====================

  /// Check app version (public endpoint)
  Future<Map<String, dynamic>> checkVersion() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/version',
      usePublicClient: true,
    );
    return response.data!;
  }
}

/// Provider for VendorApiService
final vendorApiServiceProvider = Provider<VendorApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VendorApiService(apiClient);
});
