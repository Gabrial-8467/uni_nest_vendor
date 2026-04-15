import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/vendor_config.dart';
import '../models/vendor_notification.dart';
import '../utils/secure_logger.dart';
import 'auth_service.dart';

/// Clean API service for vendor notifications
class VendorNotificationService {
  static final String _baseUrl = VendorConfig.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all notifications for the vendor
  static Future<List<VendorNotification>> getNotifications() async {
    try {
      final response = await _makeRequest('GET', '/notifications');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final notificationsData = data is List
            ? data
            : data is Map<String, dynamic>
            ? ((data['notifications'] ??
                      data['items'] ??
                      data['results']) as List? ??
                  const [])
            : const [];

        SecureLogger.info(
          'Fetched ${notificationsData.length} notifications from backend',
          tag: 'NOTIFICATIONS',
        );

        return notificationsData.whereType<Map>().map((json) {
          return VendorNotification.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      SecureLogger.error(
        'Error in getNotifications',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllRead() async {
    try {
      await _makeRequest('PUT', '/notifications/mark-all-read');

      SecureLogger.info('Marked all notifications as read', tag: 'NOTIFICATIONS');
    } catch (e) {
      SecureLogger.error('Error in markAllRead', error: e, tag: 'NOTIFICATIONS');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Mark a specific notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      try {
        await _makeRequest('PUT', '/notifications/$notificationId/read');
      } catch (_) {
        await markAllRead();
      }

      SecureLogger.info('Marked notification as read', tag: 'NOTIFICATIONS');
    } catch (e) {
      SecureLogger.error('Error in markAsRead', error: e, tag: 'NOTIFICATIONS');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    try {
      await _makeRequest('DELETE', '/notifications/clear-all');
      SecureLogger.info('Cleared all notifications', tag: 'NOTIFICATIONS');
    } catch (e) {
      SecureLogger.error('Error in clearAll', error: e, tag: 'NOTIFICATIONS');
      throw Exception('Failed to clear notifications: $e');
    }
  }

  /// Delete a specific notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _makeRequest('DELETE', '/notifications/$notificationId');

      SecureLogger.info('Deleted notification', tag: 'NOTIFICATIONS');
    } catch (e) {
      SecureLogger.error(
        'Error in deleteNotification',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Make HTTP request to notification API
  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if available
    final authService = AuthService();
    final token = await authService.getValidAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final decodedBody = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};
      final responseBody = decodedBody is Map<String, dynamic>
          ? decodedBody
          : decodedBody is Map
          ? Map<String, dynamic>.from(decodedBody)
          : <String, dynamic>{'data': decodedBody};

      SecureLogger.info(
        'Notification API response: ${response.statusCode}',
        tag: 'NOTIFICATIONS',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw Exception(
          responseBody['message'] ??
              'Request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      SecureLogger.error(
        'Notification HTTP request error',
        error: e,
        tag: 'NOTIFICATIONS',
      );
      throw Exception('Network error: $e');
    }
  }
}
