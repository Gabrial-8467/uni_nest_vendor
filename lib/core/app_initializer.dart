import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/vendor_config.dart';
import '../providers/auth_provider.dart';
import 'api_client.dart';

/// App initialization service
class AppInitializer {
  AppInitializer(this.ref);

  final Ref ref;

  /// Initialize the app on startup
  Future<void> initialize() async {
    try {
      // 1. Initialize authentication state
      await _initializeAuth();

      // 2. Set up global error handling
      _setupErrorHandling();

      // 3. Check app version (public API - no auth required)
      await _checkAppVersion();

      debugPrint('App initialization completed successfully');
    } catch (e) {
      debugPrint('App initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    // Let the auth controller handle initialization
    // It will automatically load tokens from storage and update state
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Give time for async init

    debugPrint('Authentication initialized');
  }

  /// Set up global error handling
  void _setupErrorHandling() {
    // Listen to auth state changes and handle errors globally
    ref.listen(authProvider, (previous, next) {
      // Check for authentication errors
      if (next.errorMessage != null) {
        debugPrint('Auth error: ${next.errorMessage}');

        // Handle 401 errors globally
        if (next.errorMessage!.contains('401') ||
            next.errorMessage!.contains('unauthorized')) {
          // Clear auth state and redirect to login
          final authController = ref.read(authProvider.notifier);
          authController.logout();
        }
      }
    });

    debugPrint('Global error handling configured');
  }

  /// Check app version (public endpoint)
  Future<void> _checkAppVersion() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await ref
          .read(apiClientProvider)
          .publicDio
          .get<Map<String, dynamic>>('${VendorConfig.apiRootUrl}/version/check');

      if (response.data != null) {
        debugPrint('App version check completed successfully');
        _handleVersionCheck(response.data!, currentVersion);
      } else {
        debugPrint('Version check returned null data, using fallback');
        _handleVersionCheck({
          'latestVersion': currentVersion,
          'minSupportedVersion': currentVersion,
        }, currentVersion);
      }
    } catch (e) {
      debugPrint('Version check failed (non-critical): $e');
      // Version check failure should not block app usage
      // Use fallback version info
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        _handleVersionCheck({
          'latestVersion': currentVersion,
          'minSupportedVersion': currentVersion,
        }, currentVersion);
      } catch (fallbackError) {
        debugPrint('Fallback version check also failed: $fallbackError');
      }
    }
  }

  /// Handle version check results
  void _handleVersionCheck(
    Map<String, dynamic> versionInfo,
    String currentVersion,
  ) {
    // Extract version information from API response
    final latestVersion =
        versionInfo['latestVersion'] as String? ??
        versionInfo['version'] as String? ??
        currentVersion;
    final minSupportedVersion =
        versionInfo['minSupportedVersion'] as String? ??
        versionInfo['minSupported'] as String? ??
        currentVersion;

    if (_isVersionOutdated(currentVersion, minSupportedVersion)) {
      // Force update required
      debugPrint(
        'Force update required: Current=$currentVersion, Min=$minSupportedVersion',
      );
      // Show force update dialog
    } else if (_isVersionOutdated(currentVersion, latestVersion)) {
      // Optional update available
      debugPrint(
        'Optional update available: Current=$currentVersion, Latest=$latestVersion',
      );
      // Show optional update dialog
    }
  }

  /// Simple version comparison (ignores build numbers)
  bool _isVersionOutdated(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      if (currentParts[i] < latestParts[i]) return true;
      if (currentParts[i] > latestParts[i]) return false;
    }

    return currentParts.length < latestParts.length;
  }
}

/// Provider for AppInitializer
final appInitializerProvider = Provider<AppInitializer>((ref) {
  return AppInitializer(ref);
});

/// App initialization widget
class AppInitializationWidget extends ConsumerStatefulWidget {
  const AppInitializationWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppInitializationWidget> createState() =>
      _AppInitializationWidgetState();
}

class _AppInitializationWidgetState
    extends ConsumerState<AppInitializationWidget> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final appInitializer = ref.read(appInitializerProvider);
      await appInitializer.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initializing app...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initializeApp,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
