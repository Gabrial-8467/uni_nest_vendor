import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../models/vendor_notification.dart';
import '../utils/logger.dart';

/// Background notification handler that works without Firebase
class BackgroundNotificationHandler {
  static final BackgroundNotificationHandler _instance =
      BackgroundNotificationHandler._internal();
  factory BackgroundNotificationHandler() => _instance;
  BackgroundNotificationHandler._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _notificationTask = 'backgroundNotificationCheck';

  /// Initialize the background notification system
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeNotifications();

      // Initialize background work
      await _initializeBackgroundWork();

      Logger().info('Background notification handler initialized');
    } catch (e) {
      Logger().error('Failed to initialize background notifications: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize periodic background work
  Future<void> _initializeBackgroundWork() async {
    // Register periodic task to check notifications every 15 minutes
    await Workmanager().registerPeriodicTask(
      _notificationTask,
      _notificationTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
    );
  }

  /// Show notification when app is in background/closed
  Future<void> showNotification(VendorNotification notification) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'vendor_notifications',
            'Vendor Notifications',
            channelDescription: 'Notifications for vendor updates',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(
              notification.body,
              htmlFormatBigText: true,
              contentTitle: notification.title,
            ),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: notification.id,
      );

      Logger().info('Background notification shown: ${notification.title}');
    } catch (e) {
      Logger().error('Failed to show background notification: $e');
    }
  }

  /// Handle notification tap when app is in background
  void _onNotificationTapped(NotificationResponse response) {
    Logger().info('Background notification tapped: ${response.payload}');
    // Navigate to notification screen when app opens
    // This will be handled by the main app
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(String notificationId) async {
    await _notifications.cancel(notificationId.hashCode);
  }
}

/// Background task callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'backgroundNotificationCheck') {
        Logger().info('Background notification check started');

        // Check for new notifications from backend
        final notifications = await _fetchNotificationsInBackground();

        // Show notifications for unread ones
        for (final notification in notifications) {
          if (!notification.isRead) {
            await _showBackgroundNotification(notification);
          }
        }

        Logger().info('Background notification check completed');
      }
      return Future.value(true);
    } catch (e) {
      Logger().error('Background task failed: $e');
      return Future.value(false);
    }
  });
}

/// Fetch notifications in background isolate
Future<List<VendorNotification>> _fetchNotificationsInBackground() async {
  try {
    // This would need to be adapted to work in isolate
    // For now, return empty list as placeholder
    return [];
  } catch (e) {
    Logger().error('Failed to fetch notifications in background: $e');
    return [];
  }
}

/// Show notification in background isolate
Future<void> _showBackgroundNotification(
  VendorNotification notification,
) async {
  try {
    // This would need to be adapted to work in isolate
    // For now, just log the notification
    Logger().info('Would show background notification: ${notification.title}');
  } catch (e) {
    Logger().error('Failed to show background notification: $e');
  }
}
