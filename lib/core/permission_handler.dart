import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class AppPermissions {
  /// Request storage permissions based on Android version
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33) {
        // Android 13+ (API 33+) - Use granular media permissions
        final imageStatus = await ph.Permission.photos.request();
        final videoStatus = await ph.Permission.videos.request();
        final audioStatus = await ph.Permission.audio.request();

        return imageStatus.isGranted &&
            videoStatus.isGranted &&
            audioStatus.isGranted;
      } else {
        // Android 12 and below - Use legacy storage permission
        final status = await ph.Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await ph.Permission.photos.request();
      return status.isGranted;
    }

    return false;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await ph.Permission.location.request();
    return status.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStorageGranted() async {
    if (Platform.isAndroid) {
      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33) {
        final imageStatus = await ph.Permission.photos.status;
        return imageStatus.isGranted;
      } else {
        final status = await ph.Permission.storage.status;
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await ph.Permission.photos.status;
      return status.isGranted;
    }

    return false;
  }

  /// Get Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      // Default to API 33 for safety
      return 33;
    }
  }

  /// Open app settings if permission permanently denied
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}
