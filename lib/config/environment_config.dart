class EnvironmentConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30000,
  );
  
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const bool debug = bool.fromEnvironment(
    'DEBUG',
    defaultValue: true,
  );
  
  // Security
  static const String jwtSecret = String.fromEnvironment(
    'JWT_SECRET',
    defaultValue: 'your_jwt_secret_key_here',
  );
  
  static const int sessionTimeout = int.fromEnvironment(
    'SESSION_TIMEOUT',
    defaultValue: 3600000, // 1 hour in milliseconds
  );
  
  // File Upload
  static const int maxFileSize = int.fromEnvironment(
    'MAX_FILE_SIZE',
    defaultValue: 5242880, // 5MB in bytes
  );
  
  static const String allowedFileTypes = String.fromEnvironment(
    'ALLOWED_FILE_TYPES',
    defaultValue: 'jpeg,jpg,png,gif,webp,pdf,doc,docx',
  );
  
  // Helper Methods
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  static Duration get timeoutDuration => Duration(milliseconds: apiTimeout);
  static Duration get sessionTimeoutDuration => Duration(milliseconds: sessionTimeout);
  
  static List<String> get allowedFileTypesList => allowedFileTypes.split(',');
  
  // Validation
  static bool isValidEnvironment() {
    return ['development', 'staging', 'production'].contains(environment);
  }
  
  static bool isValidTimeout() {
    return apiTimeout > 0 && apiTimeout <= 120000; // Max 2 minutes
  }
  
  static bool isValidFileSize() {
    return maxFileSize > 0 && maxFileSize <= 10485760; // Max 10MB
  }
}
