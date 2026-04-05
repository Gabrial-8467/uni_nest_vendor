import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/vendor_config.dart';
import '../models/vendor_notification.dart';
import 'auth_service.dart';

/// Clean API service for vendor notifications
class VendorNotificationService {
  static final String _baseUrl = VendorConfig.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all notifications for the vendor
  static Future<List<VendorNotification>> getNotifications() async {
    try {
      final response = await _makeRequest('GET', '/api/vendor/notifications');

      if (response['success'] == true && response['data'] != null) {
        final notificationsData = response['data'] as List? ?? [];

        debugPrint(
          'Fetched ${notificationsData.length} notifications from backend',
        );

        return notificationsData.map((json) {
          return VendorNotification.fromJson(json as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error in getNotifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllRead() async {
    try {
      await _makeRequest('POST', '/api/vendor/notifications/read-all');

      debugPrint('Marked all notifications as read');
    } catch (e) {
      debugPrint('Error in markAllRead: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Mark a specific notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _makeRequest(
        'POST',
        '/api/vendor/notifications/$notificationId/read',
      );

      debugPrint('Marked notification $notificationId as read');
    } catch (e) {
      debugPrint('Error in markAsRead: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Delete a specific notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _makeRequest('DELETE', '/api/vendor/notifications/$notificationId');

      debugPrint('Deleted notification $notificationId');
    } catch (e) {
      debugPrint('Error in deleteNotification: $e');
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
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      debugPrint('API Response: ${response.statusCode} - $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw Exception(
          responseBody['message'] ??
              'Request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('HTTP Request Error: $e');
      throw Exception('Network error: $e');
    }
  }
}
