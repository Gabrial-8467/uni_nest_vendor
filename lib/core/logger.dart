import 'package:logging/logging.dart';

/// Application logger utility
class AppLogger {
  static final Logger _auth = Logger('Auth');
  static final Logger _api = Logger('API');
  static final Logger _general = Logger('App');

  /// Authentication related logs
  static Logger get auth => _auth;
  
  /// API related logs
  static Logger get api => _api;
  
  /// General application logs
  static Logger get general => _general;

  /// Initialize logging configuration
  static void init() {
    Logger.root.level = Level.ALL;
    
    // In production, you might want to use a different handler
    // that writes to file or a logging service
    Logger.root.onRecord.listen((record) {
      // For now, using print for simplicity
      // In production, replace with proper logging service
      AppLogger.api.info('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        AppLogger.api.severe('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        AppLogger.api.severe(
          'Stack trace',
          record.error,
          record.stackTrace,
        );
      }
    });
  }
}
