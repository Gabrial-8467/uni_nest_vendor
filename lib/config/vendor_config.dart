import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment_config.dart';

class VendorConfig {
  static String _trimTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Environment configuration
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;

  // Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      if (isDebugMode) {
        debugPrint('Warning: Could not load .env file: $e');
      }
      // Fallback to default values
    }
  }

  // API Configuration
  static String get apiBaseUrl {
    final envUrl = dotenv.env['VENDOR_API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallback to environment variable or production URL
    final envVarUrl = String.fromEnvironment('API_BASE_URL');
    if (envVarUrl.isNotEmpty) {
      return envVarUrl;
    }

    // Production fallback
    return 'https://uninest-backend.onrender.com/api/vendor';
  }

  static String get apiRootUrl {
    final normalized = _trimTrailingSlash(apiBaseUrl);
    if (normalized.endsWith('/vendor')) {
      return normalized.substring(0, normalized.length - '/vendor'.length);
    }
    return normalized;
  }

  // Debug method to check current API URL
  static void debugApiUrl() {
    if (isDebugMode) {
      debugPrint('🔗 API URL being used: $apiBaseUrl');
      debugPrint(
        '📁 .env VENDOR_API_BASE_URL: ${dotenv.env['VENDOR_API_BASE_URL']}',
      );
      debugPrint(
        '🏗️ Environment API_BASE_URL: ${String.fromEnvironment('API_BASE_URL')}',
      );
    }
  }

  // Network Configuration
  static Duration get connectionTimeout {
    final timeoutSeconds = dotenv.env['API_TIMEOUT_SECONDS'];
    if (timeoutSeconds != null && timeoutSeconds.isNotEmpty) {
      return Duration(seconds: int.tryParse(timeoutSeconds) ?? 30);
    }
    return EnvironmentConfig.timeoutDuration;
  }

  static Duration get receiveTimeout {
    final timeoutSeconds = dotenv.env['RECEIVE_TIMEOUT_SECONDS'];
    if (timeoutSeconds != null && timeoutSeconds.isNotEmpty) {
      return Duration(seconds: int.tryParse(timeoutSeconds) ?? 30);
    }
    return EnvironmentConfig.timeoutDuration;
  }

  // Security Configuration
  static bool get enforceHttps {
    final enforce = dotenv.env['ENFORCE_HTTPS'];
    if (enforce != null && enforce.isNotEmpty) {
      return enforce.toLowerCase() == 'true';
    }
    return EnvironmentConfig.isProduction;
  }

  static String get jwtSecret {
    final secret = dotenv.env['JWT_SECRET'];
    if (secret != null && secret.isNotEmpty) {
      return secret;
    }
    return EnvironmentConfig.jwtSecret;
  }

  // Session Management
  static Duration get sessionTimeout =>
      EnvironmentConfig.sessionTimeoutDuration;

  // API Rate Limiting
  static int get maxRetries {
    final retries = dotenv.env['MAX_RETRIES'];
    if (retries != null && retries.isNotEmpty) {
      return int.tryParse(retries) ?? 3;
    }
    return 3;
  }

  // Production Environment Check
  static bool get isProductionReady {
    if (isReleaseMode) {
      return EnvironmentConfig.isProduction &&
          jwtSecret != 'your_jwt_secret_key_here' &&
          enforceHttps;
    }
    return true;
  }

  // Data Retention
  static Duration get dataRetentionPeriod {
    final days = dotenv.env['DATA_RETENTION_DAYS'];
    return Duration(days: int.tryParse(days ?? '') ?? 90);
  }

  // Feature Flags
  static bool get enableDebugLogging {
    final enable = dotenv.env['ENABLE_DEBUG_LOGGING'];
    if (enable != null && enable.isNotEmpty) {
      return enable.toLowerCase() == 'true';
    }
    return isDebugMode;
  }

  static bool get enableAnalytics {
    final enable = dotenv.env['ENABLE_ANALYTICS'];
    if (enable != null && enable.isNotEmpty) {
      return enable.toLowerCase() == 'true';
    }
    return true;
  }

  static bool get enableNotifications {
    final enable = dotenv.env['ENABLE_NOTIFICATIONS'];
    if (enable != null && enable.isNotEmpty) {
      return enable.toLowerCase() == 'true';
    }
    return true;
  }

  static String? get realtimeNotificationsUrl {
    final envUrl = dotenv.env['VENDOR_WS_URL'];
    final buildUrl = String.fromEnvironment('VENDOR_WS_URL');
    final url = (envUrl != null && envUrl.trim().isNotEmpty)
        ? envUrl.trim()
        : buildUrl.trim();

    if (url.isEmpty) {
      return null;
    }

    if (enforceHttps && url.toLowerCase().startsWith('ws://')) {
      return null;
    }

    return url;
  }

  // App Configuration
  static String get appName => 'UNI NEST Vendor';
  static String get appVersion => '1.0.0';
  static String get buildNumber => '1';

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // Colors
  static const int primaryColorValue = 0xFFFF6B6B;
  static const int secondaryColorValue = 0xFF2D3436;
  static const int backgroundColorValue = 0xFFF8F9FA;
  static const int errorColorValue = 0xFFE74C3C;
  static const int successColorValue = 0xFF27AE60;
  static const int warningColorValue = 0xFFF39C12;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Storage Keys
  static const String tokenKey = 'vendor_auth_token';
  static const String refreshTokenKey = 'vendor_refresh_token';
  static const String vendorKey = 'vendor_data';
  static const String themeKey = 'vendor_theme_mode';
  static const String languageKey = 'vendor_language';
  static const String settingsKey = 'vendor_settings';

  // Product Categories — must match backend enum exactly
  static const List<String> productCategories = [
    'snacks',
    'beverages',
    'south indian',
    'north indian',
    'chinese',
    'desserts',
  ];

  // Order Status Options
  static const List<String> orderStatusOptions = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled',
    'refunded',
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'card',
    'upi',
    'wallet',
    'net_banking',
  ];

  // Business Types
  static const List<String> businessTypes = [
    'canteen',
    'cafe',
    'restaurant',
    'food truck',
    'other',
  ];

  // Image Upload Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const int maxImagesPerProduct = 5;

  // Pagination Configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static Duration get cacheExpiration {
    final hours = dotenv.env['CACHE_EXPIRATION_HOURS'];
    if (hours != null && hours.isNotEmpty) {
      return Duration(hours: int.tryParse(hours) ?? 1);
    }
    return const Duration(hours: 1);
  }

  // Notification Configuration
  static Duration get notificationCheckInterval {
    final minutes = dotenv.env['NOTIFICATION_CHECK_INTERVAL_MINUTES'];
    if (minutes != null && minutes.isNotEmpty) {
      return Duration(minutes: int.tryParse(minutes) ?? 5);
    }
    return const Duration(minutes: 5);
  }

  // Analytics Configuration
  static Duration get analyticsRefreshInterval {
    final minutes = dotenv.env['ANALYTICS_REFRESH_INTERVAL_MINUTES'];
    if (minutes != null && minutes.isNotEmpty) {
      return Duration(minutes: int.tryParse(minutes) ?? 15);
    }
    return const Duration(minutes: 15);
  }

  // Helper method to validate and secure URL
  static String validateAndGetBaseUrl() {
    String url = apiBaseUrl;

    // Enforce HTTPS in production if enabled
    if (enforceHttps && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    return url;
  }

  // Validate if URL is secure
  static bool isSecureUrl(String url) {
    return url.startsWith('https://');
  }

  // Get secure base URL
  static String getSecureBaseUrl() {
    final url = validateAndGetBaseUrl();
    if (enforceHttps && !isSecureUrl(url)) {
      throw Exception(
        'Insecure URL detected. HTTPS is required in production mode.',
      );
    }
    return url;
  }
}
