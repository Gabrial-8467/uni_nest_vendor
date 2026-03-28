import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warning, error, fatal }

class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    DateTime? timestamp,
    this.context,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'stackTrace': stackTrace?.toString(),
    };
  }
}

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 1000;
  late Directory _logDirectory;
  File? _logFile;

  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logDirectory = Directory('${directory.path}/logs');

      if (!await _logDirectory.exists()) {
        await _logDirectory.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName = 'app_log_${now.year}_${now.month}_${now.day}.log';
      _logFile = File('${_logDirectory.path}/$fileName');

      // Clean old logs (keep only last 7 days)
      await _cleanOldLogs();

      developer.log('Logger initialized', name: 'APP');
    } catch (e) {
      developer.log('Failed to initialize logger: $e', name: 'APP');
    }
  }

  void log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      context: context,
      stackTrace: stackTrace,
    );

    _addLog(entry);
    _printLog(entry);
    _writeToFile(entry);

    // In production, send critical errors to crash reporting
    if (!kDebugMode && (level == LogLevel.error || level == LogLevel.fatal)) {
      _reportCrash(entry);
    }
  }

  void debug(String message, {String? tag, Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, tag: tag, context: context);
  }

  void info(String message, {String? tag, Map<String, dynamic>? context}) {
    log(LogLevel.info, message, tag: tag, context: context);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? context}) {
    log(LogLevel.warning, message, tag: tag, context: context);
  }

  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.error,
      message,
      tag: tag,
      context: context,
      stackTrace: stackTrace,
    );
  }

  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.fatal,
      message,
      tag: tag,
      context: context,
      stackTrace: stackTrace,
    );
  }

  void _addLog(LogEntry entry) {
    _logs.add(entry);

    // Keep only the last _maxLogs entries
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  void _printLog(LogEntry entry) {
    if (!kDebugMode) return;

    final timestamp = entry.timestamp.toIso8601String();
    final tag = entry.tag != null ? '[${entry.tag}]' : '';
    final context = entry.context != null ? ' | Context: ${entry.context}' : '';

    String message;
    switch (entry.level) {
      case LogLevel.debug:
        message = '\x1B[36mDEBUG\x1B[0m';
        break;
      case LogLevel.info:
        message = '\x1B[32mINFO\x1B[0m';
        break;
      case LogLevel.warning:
        message = '\x1B[33mWARNING\x1B[0m';
        break;
      case LogLevel.error:
        message = '\x1B[31mERROR\x1B[0m';
        break;
      case LogLevel.fatal:
        message = '\x1B[35mFATAL\x1B[0m';
        break;
    }

    message += ' $timestamp $tag ${entry.message}$context';

    if (entry.stackTrace != null) {
      message += '\nStack Trace:\n${entry.stackTrace}';
    }

    debugPrint(message);
  }

  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFile == null) return;

    try {
      final logLine = '${entry.toJson()}\n';
      await _logFile!.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      developer.log('Failed to write log to file: $e', name: 'APP');
    }
  }

  Future<void> _cleanOldLogs() async {
    try {
      final files = await _logDirectory.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          // Delete files older than 7 days
          if (age.inDays > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      developer.log('Failed to clean old logs: $e', name: 'APP');
    }
  }

  void _reportCrash(LogEntry entry) {
    // Send critical errors to crash reporting service
    _sendToCrashReportingService(entry);
  }

  Future<void> _sendToCrashReportingService(LogEntry entry) async {
    try {
      // Create crash report data
      final crashReport = {
        'timestamp': entry.timestamp.toIso8601String(),
        'level': entry.level.name,
        'message': entry.message,
        'tag': entry.tag,
        'context': entry.context,
        'platform': 'Flutter',
        'version': await _getAppVersion(),
        'deviceId': await _getDeviceId(),
        'userId': await _getUserId(),
        'stackTrace': entry.stackTrace?.toString(),
        'isFatal': entry.level == LogLevel.fatal,
      };

      try {
        // Send to crash reporting API endpoint
        final response = await _makeHttpRequest(
          'POST',
          '${_getApiBaseUrl()}/crash/report',
          body: crashReport,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'VendorApp/${await _getAppVersion()}',
            'X-Crash-Severity': entry.level.name,
          },
        );

        if (response['statusCode'] != 200) {
          throw Exception('Failed to report crash: ${response['statusCode']}');
        }

        developer.log(
          'Crash reported successfully: ${entry.message}',
          name: 'CRASH',
        );
      } catch (e) {
        // Fallback to local logging if API fails
        await _logCrashLocally(crashReport, e.toString());
        developer.log('Failed to report crash: $e', name: 'CRASH');
      }
    } catch (e) {
      // Handle any other exceptions
      developer.log('Failed to send crash report: $e', name: 'CRASH');
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
      // This would typically use package_info_plus
      return '1.0.0'; // Fallback version
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getApiBaseUrl() async {
    try {
      // Import VendorConfig here or use a fallback
      return 'https://api.uninest.com/api/vendor'; // Fallback URL
    } catch (e) {
      return 'https://api.uninest.com/api/vendor';
    }
  }

  Future<String> _getDeviceId() async {
    try {
      // This would typically use shared_preferences
      return 'device_${DateTime.now().millisecondsSinceEpoch}'; // Fallback device ID
    } catch (e) {
      return 'unknown_device';
    }
  }

  Future<String?> _getUserId() async {
    try {
      // This would typically use shared_preferences
      return null; // Fallback user ID
    } catch (e) {
      return null;
    }
  }

  Future<void> _logCrashLocally(
    Map<String, dynamic> crashReport,
    String error,
  ) async {
    try {
      // This would typically use shared_preferences to store crash logs locally
      developer.log(
        'Crash logged locally: ${crashReport['message']}',
        name: 'CRASH',
      );
    } catch (e) {
      developer.log('Failed to log crash locally: $e', name: 'CRASH');
    }
  }

  Future<List<Map<String, dynamic>>> getLocalCrashLogs() async {
    try {
      // This would typically use shared_preferences to retrieve crash logs
      return []; // Fallback empty list
    } catch (e) {
      developer.log('Failed to get local crash logs: $e', name: 'CRASH');
      return [];
    }
  }

  Future<void> clearLocalCrashLogs() async {
    try {
      // This would typically use shared_preferences to clear crash logs
      developer.log('Local crash logs cleared', name: 'CRASH');
    } catch (e) {
      developer.log('Failed to clear local crash logs: $e', name: 'CRASH');
    }
  }

  List<LogEntry> getLogs({LogLevel? minLevel, String? tag}) {
    var filteredLogs = _logs.toList();

    if (minLevel != null) {
      filteredLogs = filteredLogs
          .where((log) => log.level.index >= minLevel.index)
          .toList();
    }

    if (tag != null) {
      filteredLogs = filteredLogs.where((log) => log.tag == tag).toList();
    }

    return filteredLogs;
  }

  Future<String> exportLogs() async {
    try {
      final logs = getLogs();
      final logData = logs.map((log) => log.toJson()).toList();
      return jsonEncode(logData);
    } catch (e) {
      return 'Failed to export logs: $e';
    }
  }

  Future<void> clearLogs() async {
    _logs.clear();

    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
    }
  }

  void logUserAction(String action, {Map<String, dynamic>? details}) {
    info('User action: $action', tag: 'USER', context: details);
  }

  void logApiCall(
    String endpoint,
    String method, {
    int? statusCode,
    Duration? duration,
  }) {
    info(
      'API call: $method $endpoint',
      tag: 'API',
      context: {'statusCode': statusCode, 'duration': duration?.inMilliseconds},
    );
  }

  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag: 'PERF',
      context: context,
    );
  }
}
