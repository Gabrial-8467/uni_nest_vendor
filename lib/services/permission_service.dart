import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Required permissions for the app
  static final List<Permission> _requiredPermissions = [
    Permission.camera,
    Permission.storage,
    Permission.notification,
  ];

  // Optional permissions
  static final List<Permission> _optionalPermissions = [
    Permission.location,
    Permission.phone,
  ];

  // Check if all required permissions are granted
  static Future<bool> get areRequiredPermissionsGranted async {
    for (final permission in _requiredPermissions) {
      final status = await permission.status;
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  // Request required permissions
  static Future<bool> requestRequiredPermissions() async {
    try {
      final Map<Permission, PermissionStatus> statuses =
          await _requiredPermissions.request();

      return statuses.values.every(
        (status) => status == PermissionStatus.granted,
      );
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Request optional permissions
  static Future<void> requestOptionalPermissions() async {
    try {
      await _optionalPermissions.request();
    } catch (e) {
      debugPrint('Error requesting optional permissions: $e');
    }
  }

  // Request a specific permission
  static Future<bool> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting permission ${permission.toString()}: $e');
      return false;
    }
  }

  // Check permission status
  static Future<bool> isPermissionGranted(Permission permission) async {
    try {
      final status = await permission.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return false;
    }
  }

  // Show permission dialog
  static Future<bool> showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    List<Permission> permissions,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  Text(
                    'Required permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...permissions.map(
                    (permission) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('• ${_getPermissionDisplayName(permission)}'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Get user-friendly permission name
  static String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera Access - Take photos for products';
      case Permission.storage:
        return 'Storage Access - Save and load images';
      case Permission.notification:
        return 'Notifications - Receive order updates';
      case Permission.location:
        return 'Location - Delivery tracking (optional)';
      case Permission.phone:
        return 'Phone - Contact customers (optional)';
      default:
        return permission.toString();
    }
  }

  // Initialize permissions on app start
  static Future<void> initializePermissions() async {
    try {
      // Check and request required permissions
      if (!await _checkPermissionsStatus()) {
        debugPrint('Some required permissions are not granted');
      }
    } catch (e) {
      debugPrint('Error initializing permissions: $e');
    }
  }

  // Check current permission status
  static Future<bool> _checkPermissionsStatus() async {
    try {
      for (final permission in _requiredPermissions) {
        final status = await permission.status;
        if (status != PermissionStatus.granted) {
          debugPrint('Permission not granted: ${permission.toString()}');
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  // Show permission rationale dialog
  static Future<void> showPermissionRationale(
    BuildContext context,
    String permission,
    String rationale,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app needs ${_getPermissionDisplayName(_getPermissionFromString(permission))} to function properly.',
              ),
              const SizedBox(height: 12),
              Text(rationale),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestSpecificPermission(
                  _getPermissionFromString(permission),
                );
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  // Convert string to Permission enum
  static Permission _getPermissionFromString(String permissionString) {
    switch (permissionString) {
      case 'camera':
        return Permission.camera;
      case 'storage':
        return Permission.storage;
      case 'notification':
        return Permission.notification;
      case 'location':
        return Permission.location;
      case 'phone':
        return Permission.phone;
      default:
        return Permission.camera;
    }
  }

  // Request specific permission
  static Future<void> _requestSpecificPermission(Permission permission) async {
    try {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Permission denied: ${permission.toString()}');
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
  }
}
