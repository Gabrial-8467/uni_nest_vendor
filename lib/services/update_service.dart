import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';
import '../config/vendor_config.dart';
import '../utils/logger.dart';

class AppVersion {
  final String currentVersion;
  final String latestVersion;
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final String? updateUrl;
  final String? releaseNotes;
  final DateTime? checkedAt;

  AppVersion({
    required this.currentVersion,
    required this.latestVersion,
    required this.isUpdateAvailable,
    this.isForceUpdate = false,
    this.updateUrl,
    this.releaseNotes,
    this.checkedAt,
  });

  factory AppVersion.fromJson(
    Map<String, dynamic> json,
    String currentVersion,
  ) {
    final latest = json['latest_version'] as String? ?? currentVersion;
    final current = Version.parse(currentVersion);
    final latestVersion = Version.parse(latest);

    return AppVersion(
      currentVersion: currentVersion,
      latestVersion: latest,
      isUpdateAvailable: latestVersion > current,
      isForceUpdate: json['force_update'] as bool? ?? false,
      updateUrl: json['update_url'] as String?,
      releaseNotes: json['release_notes'] as String?,
      checkedAt: DateTime.tryParse(json['checked_at'] as String? ?? ''),
    );
  }
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Logger _logger = Logger();
  PackageInfo? _packageInfo;
  AppVersion? _lastVersionCheck;
  Timer? _updateCheckTimer;

  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _logger.info(
        'Update service initialized',
        tag: 'UPDATE',
        context: {'version': _packageInfo!.version},
      );

      // Start periodic update checks (every 24 hours)
      _startPeriodicChecks();

      // Check for updates on startup
      await checkForUpdates();
    } catch (e) {
      _logger.error(
        'Failed to initialize update service',
        tag: 'UPDATE',
        context: {'error': e.toString()},
      );
    }
  }

  void _startPeriodicChecks() {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => checkForUpdates(),
    );
  }

  Future<AppVersion> checkForUpdates({bool forceCheck = false}) async {
    if (_packageInfo == null) {
      throw Exception('Update service not initialized');
    }

    try {
      // Check if we should skip (not forced and checked recently)
      if (!forceCheck && _shouldSkipCheck()) {
        return _lastVersionCheck!;
      }

      _logger.info('Checking for app updates', tag: 'UPDATE');

      // Call version check API
      final response = await _callVersionCheckApi();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final appVersion = AppVersion.fromJson(data, _packageInfo!.version);

        _lastVersionCheck = appVersion;
        await _saveLastCheck();

        _logger.info(
          'Version check completed',
          tag: 'UPDATE',
          context: {
            'current': appVersion.currentVersion,
            'latest': appVersion.latestVersion,
            'updateAvailable': appVersion.isUpdateAvailable,
            'forceUpdate': appVersion.isForceUpdate,
          },
        );

        return appVersion;
      } else {
        throw Exception('Failed to check version: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error(
        'Version check failed',
        tag: 'UPDATE',
        context: {'error': e.toString()},
      );

      // Return last known version if available
      if (_lastVersionCheck != null) {
        return _lastVersionCheck!;
      }

      // Return current version as fallback
      return AppVersion(
        currentVersion: _packageInfo!.version,
        latestVersion: _packageInfo!.version,
        isUpdateAvailable: false,
      );
    }
  }

  bool _shouldSkipCheck() {
    if (_lastVersionCheck == null || _lastVersionCheck!.checkedAt == null) {
      return false;
    }

    final timeSinceLastCheck = DateTime.now().difference(
      _lastVersionCheck!.checkedAt!,
    );
    return timeSinceLastCheck.inHours <
        1; // Don't check more than once per hour
  }

  Future<http.Response> _callVersionCheckApi() async {
    final baseUrl = VendorConfig.apiBaseUrl;
    final url = '$baseUrl/version/check';

    return await http
        .get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'VendorApp/${_packageInfo!.version}',
            'Platform': _getPlatform(),
          },
        )
        .timeout(const Duration(seconds: 10));
  }

  String _getPlatform() {
    // This would be expanded based on actual platform detection
    return 'android';
  }

  Future<void> _saveLastCheck() async {
    if (_lastVersionCheck == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_version_check',
        jsonEncode({
          'current_version': _lastVersionCheck!.currentVersion,
          'latest_version': _lastVersionCheck!.latestVersion,
          'is_update_available': _lastVersionCheck!.isUpdateAvailable,
          'is_force_update': _lastVersionCheck!.isForceUpdate,
          'update_url': _lastVersionCheck!.updateUrl,
          'release_notes': _lastVersionCheck!.releaseNotes,
          'checked_at': _lastVersionCheck!.checkedAt?.toIso8601String(),
        }),
      );
    } catch (e) {
      _logger.error(
        'Failed to save version check',
        tag: 'UPDATE',
        context: {'error': e.toString()},
      );
    }
  }

  Future<void> markUpdateShown() async {
    if (_lastVersionCheck == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'update_shown_for_${_lastVersionCheck!.latestVersion}',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _logger.error(
        'Failed to mark update as shown',
        tag: 'UPDATE',
        context: {'error': e.toString()},
      );
    }
  }

  Future<bool> shouldShowUpdateDialog() async {
    if (_lastVersionCheck == null || !_lastVersionCheck!.isUpdateAvailable) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final shownKey = 'update_shown_for_${_lastVersionCheck!.latestVersion}';
      final shownAt = prefs.getString(shownKey);

      if (shownAt == null) {
        return true; // Never shown before
      }

      // Show again if it's been more than 7 days
      final shownDate = DateTime.parse(shownAt);
      final daysSinceShown = DateTime.now().difference(shownDate).inDays;

      return daysSinceShown > 7;
    } catch (e) {
      _logger.error(
        'Failed to check if update should be shown',
        tag: 'UPDATE',
        context: {'error': e.toString()},
      );
      return true; // Show on error
    }
  }

  AppVersion? get lastVersionCheck => _lastVersionCheck;

  String get currentVersion => _packageInfo?.version ?? 'Unknown';

  String get buildNumber => _packageInfo?.buildNumber ?? 'Unknown';

  void dispose() {
    _updateCheckTimer?.cancel();
  }
}
