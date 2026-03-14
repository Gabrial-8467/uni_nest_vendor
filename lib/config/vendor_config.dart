import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VendorConfig {
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

    // Fallback for development
    if (isDebugMode) {
      return 'http://127.0.0.1:5000';
    }

    // Production fallback
    return 'https://api.uninest.com';
  }

  // API Endpoints
  static const String authEndpoint = '/api/vendor/auth';
  static const String profileEndpoint = '/api/vendor/profile';
  static const String productsEndpoint = '/api/vendor/products';
  static const String ordersEndpoint = '/api/vendor/orders';
  static const String analyticsEndpoint = '/api/vendor/analytics';
  static const String earningsEndpoint = '/api/vendor/earnings';
  static const String customersEndpoint = '/api/vendor/customers';
  static const String notificationsEndpoint = '/api/vendor/notifications';
  static const String settingsEndpoint = '/api/vendor/settings';

  // Network Configuration
  static Duration get connectionTimeout {
    final timeoutSeconds = dotenv.env['API_TIMEOUT_SECONDS'];
    if (timeoutSeconds != null && timeoutSeconds.isNotEmpty) {
      return Duration(seconds: int.tryParse(timeoutSeconds) ?? 30);
    }
    return const Duration(seconds: 30);
  }

  static Duration get receiveTimeout {
    final timeoutSeconds = dotenv.env['RECEIVE_TIMEOUT_SECONDS'];
    if (timeoutSeconds != null && timeoutSeconds.isNotEmpty) {
      return Duration(seconds: int.tryParse(timeoutSeconds) ?? 30);
    }
    return const Duration(seconds: 30);
  }

  static int get maxRetries {
    final retries = dotenv.env['MAX_RETRIES'];
    if (retries != null && retries.isNotEmpty) {
      return int.tryParse(retries) ?? 3;
    }
    return 3;
  }

  // Security Configuration
  static bool get enforceHttps {
    final enforce = dotenv.env['ENFORCE_HTTPS'];
    if (enforce != null && enforce.isNotEmpty) {
      return enforce.toLowerCase() == 'true';
    }
    return isReleaseMode;
  }

  static String get encryptionKey {
    return dotenv.env['ENCRYPTION_KEY'] ?? 'default_encryption_key_32_chars';
  }

  static String get jwtSecret {
    return dotenv.env['JWT_SECRET'] ?? 'default_jwt_secret_key';
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

  // Product Categories
  static const List<String> productCategories = [
    'Snacks',
    'Beverages',
    'South Indian',
    'North Indian',
    'Chinese',
    'Continental',
    'Desserts',
    'Bakery',
    'Healthy Food',
    'Fast Food',
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
    'food_truck',
    'mess',
    'kiosk',
  ];

  // Image Upload Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
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

    if (isDebugMode && (url.contains('localhost') || url.contains('127.0.0.1'))) {
      debugPrint(
        '⚠️ WARNING: Using localhost/127.0.0.1. This won\'t work on physical devices!',
      );
      debugPrint(
        'Please change to your computer\'s local IP address (e.g., 192.168.1.x)',
      );
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
      throw Exception('Insecure URL detected. HTTPS is required in production mode.');
    }
    return url;
  }
}
