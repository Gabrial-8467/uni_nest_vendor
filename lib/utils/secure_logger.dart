import 'dart:convert';
import 'package:flutter/foundation.dart';

class SecureLogger {
  static const int _maxPayloadLogChars = 800;
  static const List<String> _sensitiveKeywords = [
    'token',
    'password',
    'key',
    'secret',
    'auth',
    'authorization',
    'bearer',
    'jwt',
    'session',
    'cookie',
    'credit_card',
    'ssn',
    'pin',
    'cvv',
    // Bank/Payout related
    'accountnumber',
    'account_number',
    'ifsc',
    'ifscode',
    'ifsc_code',
    'upi',
    'upiid',
    'upi_id',
    'bankaccount',
    'bank_account',
    'payoutmethod',
    'payout_method',
    'accountholder',
    'account_holder',
  ];

  static const List<String> _sensitivePatterns = [
    r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b', // Credit card numbers
    r'\b\d{3}-\d{2}-\d{4}\b', // SSN pattern
    r'\b[A-Za-z0-9+/]{20,}={0,2}\b', // Base64 encoded data (potential tokens)
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', // Bearer tokens
    // Bank account patterns (9-18 digits)
    r'\b\d{9,18}\b',
    // IFSC code pattern (4 letters + 7 alphanumeric)
    r'\b[A-Z]{4}[0-9A-Z]{7}\b',
    // UPI ID pattern
    r'\b[A-Za-z0-9._-]+@[A-Za-z]{3,}\b',
  ];

  static bool get enableDebugLogging => kDebugMode;

  // Main logging method
  static void log(String level, String message, {String? tag, Object? error}) {
    if (!enableDebugLogging) return;

    final sanitizedMessage = _sanitizeMessage(message);
    final timestamp = DateTime.now().toIso8601String();
    final logMessage =
        '[$timestamp] [$level] ${tag != null ? '[$tag] ' : ''}$sanitizedMessage';

    if (error != null) {
      debugPrint('$logMessage\nError: ${_sanitizeError(error)}');
    } else {
      debugPrint(logMessage);
    }
  }

  // Convenience methods
  static void debug(String message, {String? tag, Object? error}) {
    log('DEBUG', message, tag: tag, error: error);
  }

  static void info(String message, {String? tag, Object? error}) {
    log('INFO', message, tag: tag, error: error);
  }

  static void warning(String message, {String? tag, Object? error}) {
    log('WARNING', message, tag: tag, error: error);
  }

  static void error(String message, {String? tag, Object? error}) {
    log('ERROR', message, tag: tag, error: error);
  }

  // Network request logging
  static void logRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    if (!enableDebugLogging) return;

    final sanitizedUrl = _sanitizeUrl(url);
    debug('$method $sanitizedUrl', tag: 'HTTP');

    if (body != null && kDebugMode) {
      final sanitizedBody = _sanitizeMap(body);
      debugPrint('Body: ${_truncateForLog(sanitizedBody.toString())}');
    }
  }

  // Network response logging
  static void logResponse(int statusCode, String url, {dynamic body}) {
    if (!enableDebugLogging) return;

    final sanitizedUrl = _sanitizeUrl(url);
    debug('Response $statusCode from $sanitizedUrl', tag: 'HTTP');

    if (body != null && kDebugMode) {
      final sanitizedBody = _sanitizeResponse(body);
      debugPrint('Response: ${_truncateForLog(sanitizedBody)}');
    }
  }

  static String _truncateForLog(String value) {
    if (value.length <= _maxPayloadLogChars) return value;
    return '${value.substring(0, _maxPayloadLogChars)}... [truncated ${value.length - _maxPayloadLogChars} chars]';
  }

  static String _sanitizeError(Object error) {
    return _truncateForLog(_sanitizeMessage(error.toString()));
  }

  // Sanitize URL to remove sensitive query parameters
  static String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final sanitizedQuery = <String, String>{};

      uri.queryParameters.forEach((key, value) {
        if (_sensitiveKeywords.any(
          (keyword) => key.toLowerCase().contains(keyword),
        )) {
          sanitizedQuery[key] = '[REDACTED]';
        } else {
          sanitizedQuery[key] = value;
        }
      });

      final sanitizedUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        queryParameters: sanitizedQuery.isEmpty ? null : sanitizedQuery,
        fragment: uri.fragment,
      );

      return sanitizedUri.toString();
    } catch (e) {
      return '[URL_PARSE_ERROR]';
    }
  }

  // Sanitize message to remove sensitive information
  static String _sanitizeMessage(String message) {
    String sanitized = message;

    // Remove sensitive patterns
    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAll(RegExp(pattern), '[REDACTED]');
    }

    // Remove sensitive keywords and their values
    for (final keyword in _sensitiveKeywords) {
      final pattern = RegExp(
        '$keyword\\s*[:=]\\s*[\\w\\-._~+/=]+',
        caseSensitive: false,
      );
      sanitized = sanitized.replaceAll(pattern, '$keyword: [REDACTED]');
    }

    // Remove email addresses
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL_REDACTED]',
    );

    // Remove phone numbers
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b'),
      '[PHONE_REDACTED]',
    );

    return sanitized;
  }

  // Sanitize Map data
  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (_sensitiveKeywords.any(
        (keyword) => key.toLowerCase().contains(keyword),
      )) {
        sanitized[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeMap(item);
          } else if (item is String) {
            return _sanitizeMessage(item);
          }
          return item;
        }).toList();
      } else if (value is String) {
        sanitized[key] = _sanitizeMessage(value);
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  // Sanitize response body
  static String _sanitizeResponse(dynamic body) {
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        return jsonEncode(_sanitizeJsonValue(decoded));
      } catch (e) {
        return _sanitizeMessage(body);
      }
    } else if (body is Map<String, dynamic>) {
      return jsonEncode(_sanitizeMap(body));
    } else {
      return _sanitizeMessage(body.toString());
    }
  }

  static dynamic _sanitizeJsonValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _sanitizeMap(value);
    }
    if (value is Map) {
      return _sanitizeMap(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_sanitizeJsonValue).toList();
    }
    if (value is String) {
      return _sanitizeMessage(value);
    }
    return value;
  }

  // Performance logging
  static void logPerformance(
    String operation,
    Duration duration, {
    String? tag,
  }) {
    if (!enableDebugLogging) return;

    final message =
        'Operation "$operation" completed in ${duration.inMilliseconds}ms';
    info(message, tag: tag ?? 'PERFORMANCE');
  }

  // User action logging
  static void logUserAction(
    String action, {
    Map<String, dynamic>? metadata,
    String? tag,
  }) {
    if (!enableDebugLogging) return;

    final message = 'User action: $action';
    if (metadata != null) {
      final sanitizedMetadata = _sanitizeMap(metadata);
      info(message, tag: tag ?? 'USER_ACTION', error: sanitizedMetadata);
    } else {
      info(message, tag: tag ?? 'USER_ACTION');
    }
  }

  // Security event logging
  static void logSecurityEvent(
    String event, {
    Map<String, dynamic>? context,
    String? tag,
  }) {
    // Security events should always be logged regardless of debug mode
    final message = 'SECURITY: $event';
    if (context != null) {
      final sanitizedContext = _sanitizeMap(context);
      error(message, tag: tag ?? 'SECURITY', error: sanitizedContext);
    } else {
      error(message, tag: tag ?? 'SECURITY');
    }
  }

  // Error logging with stack trace
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!enableDebugLogging) return;

    final logMessage = _sanitizeMessage(message);
    if (error != null) {
      if (stackTrace != null) {
        debugPrint(
          '[$tag] ERROR: $logMessage\nError: ${_sanitizeError(error)}\nStack Trace:\n$stackTrace',
        );
      } else {
        debugPrint(
          '[$tag] ERROR: $logMessage\nError: ${_sanitizeError(error)}',
        );
      }
    } else {
      debugPrint('[$tag] ERROR: $logMessage');
    }
  }
}
