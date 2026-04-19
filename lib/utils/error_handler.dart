import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import '../config/vendor_config.dart';

enum ErrorType { network, authentication, validation, server, unknown }

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final int? statusCode;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.statusCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'AppError{type: $type, message: $message, statusCode: $statusCode}';
  }
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  AppError handleError(dynamic error, {String? context}) {
    if (error is AppError) return error;

    final timestamp = DateTime.now();

    // Network connectivity errors
    if (!_connectivityService.isConnected) {
      return AppError(
        type: ErrorType.network,
        message: 'No internet connection. Please check your network settings.',
        details: 'Device is not connected to the internet',
        timestamp: timestamp,
      );
    }

    // HTTP errors
    if (error is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: 'Network connection failed. Please try again.',
        details: error.toString(),
        timestamp: timestamp,
      );
    }

    if (error is HttpException) {
      return AppError(
        type: ErrorType.server,
        message: 'Server error occurred. Please try again later.',
        details: error.message,
        statusCode: _extractStatusCode(error.message),
        timestamp: timestamp,
      );
    }

    // Timeout errors
    if (error is TimeoutException) {
      return AppError(
        type: ErrorType.network,
        message:
            'Request timed out. Please check your connection and try again.',
        details: error.toString(),
        timestamp: timestamp,
      );
    }

    // Format errors
    if (error is FormatException) {
      return AppError(
        type: ErrorType.server,
        message: 'Invalid server response. Please try again.',
        details: error.toString(),
        timestamp: timestamp,
      );
    }

    // Validation errors
    if (error is ArgumentError) {
      return AppError(
        type: ErrorType.validation,
        message: 'Invalid input: ${error.message}',
        details: error.toString(),
        timestamp: timestamp,
      );
    }

    // API specific errors
    if (error.toString().contains('401')) {
      return AppError(
        type: ErrorType.authentication,
        message: 'Authentication failed. Please login again.',
        statusCode: 401,
        timestamp: timestamp,
      );
    }

    if (error.toString().contains('403')) {
      return AppError(
        type: ErrorType.authentication,
        message:
            'Access denied. You don\'t have permission to perform this action.',
        statusCode: 403,
        timestamp: timestamp,
      );
    }

    if (error.toString().contains('404')) {
      return AppError(
        type: ErrorType.server,
        message: 'Requested resource not found.',
        statusCode: 404,
        timestamp: timestamp,
      );
    }

    if (error.toString().contains('500')) {
      return AppError(
        type: ErrorType.server,
        message: 'Server error occurred. Please try again later.',
        statusCode: 500,
        timestamp: timestamp,
      );
    }

    // Default unknown error
    return AppError(
      type: ErrorType.unknown,
      message: kDebugMode ? error.toString() : 'An unexpected error occurred.',
      details: kDebugMode ? error.toString() : null,
      timestamp: timestamp,
    );
  }

  int? _extractStatusCode(String message) {
    final regex = RegExp(r'Status code: (\d+)');
    final match = regex.firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Network error: ${error.message}';
      case ErrorType.authentication:
        return 'Authentication error: ${error.message}';
      case ErrorType.validation:
        return 'Validation error: ${error.message}';
      case ErrorType.server:
        return 'Server error: ${error.message}';
      case ErrorType.unknown:
        return 'Error: ${error.message}';
    }
  }

  void logError(AppError error, {String? context}) {
    if (VendorConfig.isDebugMode) {
      debugPrint('=== ERROR LOG ===');
      debugPrint('Timestamp: ${error.timestamp}');
      debugPrint('Type: ${error.type}');
      debugPrint('Message: ${error.message}');
      if (context != null) {
        debugPrint('Context: $context');
      }
      if (error.details != null) {
        debugPrint('Details: ${error.details}');
      }
      if (error.statusCode != null) {
        debugPrint('Status Code: ${error.statusCode}');
      }
      debugPrint('================');
    }
  }

  Future<void> reportError(AppError error, {String? context}) async {
    // In production, send errors to crash reporting service
    if (!VendorConfig.isDebugMode) {
      try {
        await _sendToCrashReportingService(error, context);
      } catch (e) {
        debugPrint('Failed to report error: $e');
      }
    }

    logError(error, context: context);
  }

  Future<void> _sendToCrashReportingService(
    AppError error,
    String? context,
  ) async {
    // Create error report data
    final errorReport = {
      'timestamp': error.timestamp.toIso8601String(),
      'type': error.type.name,
      'message': error.message,
      'details': error.details,
      'statusCode': error.statusCode,
      'context': context,
      'platform': 'Flutter',
      'version': await _getAppVersion(),
      'deviceId': await _getDeviceId(),
      'userId': await _getUserId(),
    };

    // Send to crash reporting API endpoint
    try {
      final response = await _makeHttpRequest(
        'POST',
        '${VendorConfig.apiBaseUrl}/errors/report',
        body: errorReport,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'VendorApp/${await _getAppVersion()}',
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception('Failed to report error: ${response['statusCode']}');
      }
    } catch (e) {
      // Fallback to local logging if API fails
      await _logErrorLocally(errorReport, e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _makeHttpRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final request = await HttpClient().postUrl(Uri.parse(url));

    if (headers != null) {
      headers.forEach((key, value) => request.headers.add(key, value));
    }

    if (body != null) {
      request.add(utf8.encode(jsonEncode(body)));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    return {
      'statusCode': response.statusCode,
      'body': responseBody.isNotEmpty ? jsonDecode(responseBody) : null,
    };
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');

      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_id', deviceId);
      }

      return deviceId;
    } catch (e) {
      return 'unknown_device';
    }
  }

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      return null;
    }
  }

  Future<void> _logErrorLocally(
    Map<String, dynamic> errorReport,
    String error,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList('error_logs') ?? [];

      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'error': error,
        'report': errorReport,
      };

      errorLogs.add(jsonEncode(logEntry));

      // Keep only last 100 error logs
      if (errorLogs.length > 100) {
        errorLogs.removeRange(0, errorLogs.length - 100);
      }

      await prefs.setStringList('error_logs', errorLogs);
    } catch (e) {
      debugPrint('Failed to log error locally: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLocalErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList('error_logs') ?? [];

      return errorLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to get local error logs: $e');
      return [];
    }
  }

  Future<void> clearLocalErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('error_logs');
    } catch (e) {
      debugPrint('Failed to clear local error logs: $e');
    }
  }

  void showUserFriendlyError(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getUserFriendlyMessage(error)),
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 5),
        action: error.type == ErrorType.network && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }
}
