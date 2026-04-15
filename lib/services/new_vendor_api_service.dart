import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/vendor_config.dart';
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
    return AuthSession.fromLoginResponse(response.data!);
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
    return AuthSession.fromLoginResponse(response.data!);
  }

  /// Forgot password
  Future<void> forgotPassword({required String email}) async {
    throw const ApiException(
      'Forgot password is not available in the current vendor API.',
      statusCode: 404,
    );
  }

  /// Logout
  Future<void> logout() async {
    // The current vendor backend does not expose a logout endpoint.
    // Session cleanup is handled locally by the auth layer.
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
    final payload = Map<String, dynamic>.from(profileData);
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

    final response = await _apiClient.put<VendorProfile>(
      '/profile',
      data: payload,
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
    String? otp,
  }) async {
    final response = await _apiClient.put<VendorOrder>(
      '/orders/$orderId/status',
      data: {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (estimatedDeliveryTime != null &&
            estimatedDeliveryTime.trim().isNotEmpty)
          'estimatedDeliveryTime': estimatedDeliveryTime.trim(),
        if (otp != null && otp.trim().isNotEmpty) 'otp': otp.trim(),
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
    return updateOrderStatus(
      orderId: orderId,
      status: 'cancelled',
      note: reason,
    );
  }

  /// Verify delivery OTP
  Future<VendorOrder> verifyDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    return updateOrderStatus(
      orderId: orderId,
      status: 'delivered',
      note: 'Delivery OTP verified by vendor',
      otp: otp,
    );
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
    final response = await _apiClient.publicDio.get<Map<String, dynamic>>(
      '${VendorConfig.apiRootUrl}/version/check',
    );
    return response.data!;
  }
}

/// Provider for VendorApiService
final vendorApiServiceProvider = Provider<VendorApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VendorApiService(apiClient);
});
