import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/vendor_notification.dart';
import '../providers/vendor_notification_provider.dart';

/// Background notification service for handling notifications when app is in background
class BackgroundNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static StreamController<VendorNotification>?
  _backgroundNotificationController;
  static const AndroidInitializationSettings _androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  /// Initialize the background notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize notification settings
      const InitializationSettings initializationSettings =
          InitializationSettings(android: _androidSettings);

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request notification permissions (Android 13+)
      await _requestPermissions();

      // Create background notification stream
      _backgroundNotificationController =
          StreamController<VendorNotification>.broadcast();

      _isInitialized = true;
      debugPrint('Background notification service initialized');
    } catch (e) {
      debugPrint('Failed to initialize background notifications: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      try {
        // Try to request permissions - this will only work on Android 13+
        await androidImplementation.requestNotificationsPermission();
      } catch (e) {
        // For Android 12 and below, permissions are granted at install time
        debugPrint(
          'Notification permissions handled at install time (Android < 13): $e',
        );
      }
    }
  }

  /// Show notification when app is in background
  static Future<void> showBackgroundNotification(
    VendorNotification notification,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'vendor_notifications',
            'Vendor Notifications',
            channelDescription: 'Notifications for vendor updates',
            importance: Importance.high,
            priority: Priority.high,
            color: _getNotificationColor(notification.type),
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            styleInformation: BigTextStyleInformation(
              notification.body,
              htmlFormatBigText: true,
              contentTitle: notification.title,
              htmlFormatContentTitle: true,
            ),
            category: AndroidNotificationCategory.message,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: notificationDetails,
        payload: jsonEncode({
          'id': notification.id,
          'type': notification.type,
          'data': notification.data,
        }),
      );

      debugPrint('Background notification shown: ${notification.title}');
    } catch (e) {
      debugPrint('Error showing background notification: $e');
    }
  }

  /// Handle notification tap when app is in background
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
        final notificationId = payload['id'] as String?;
        final type = payload['type'] as String?;
        final data = payload['data'] as Map<String, dynamic>?;

        debugPrint('Background notification tapped: $notificationId');

        // Add to background stream for handling
        if (notificationId != null && type != null) {
          final notification = VendorNotification(
            id: notificationId,
            title: 'Background Notification',
            body: 'Tap to view details',
            type: type,
            createdAt: DateTime.now(),
            isRead: false,
            data: data,
          );
          _backgroundNotificationController?.add(notification);
        }
      } catch (e) {
        debugPrint('Error handling background notification tap: $e');
      }
    }
  }

  /// Get background notification stream
  static Stream<VendorNotification>? get backgroundNotificationStream =>
      _backgroundNotificationController?.stream;

  /// Get notification color based on type
  static Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'system':
        return Colors.orange;
      case 'promotion':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(String notificationId) async {
    await _notificationsPlugin.cancel(id: notificationId.hashCode);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
}

/// Enhanced background notification handler
class BackgroundNotificationHandler {
  static WidgetRef? _ref;
  static StreamSubscription<VendorNotification>? _backgroundSubscription;

  /// Set the WidgetRef for provider access
  static void setRef(WidgetRef ref) {
    _ref = ref;
  }

  /// Initialize background notification handling
  static Future<void> initialize() async {
    await BackgroundNotificationService.initialize();

    // Listen to background notification taps
    _backgroundSubscription?.cancel();
    _backgroundSubscription = BackgroundNotificationService
        .backgroundNotificationStream
        ?.listen(_handleBackgroundNotification);

    debugPrint('Background notification handler initialized');
  }

  /// Handle background notification when app comes to foreground
  static void _handleBackgroundNotification(VendorNotification notification) {
    if (_ref != null) {
      // Add notification to provider
      _ref!
          .read(vendorNotificationProvider.notifier)
          .addNotification(notification);

      // Show in-app notification
      _showInAppNotification(notification);
    }
  }

  /// Show in-app notification banner
  static void _showInAppNotification(VendorNotification notification) {
    // This would be handled by the current context in the UI
    debugPrint('In-app notification: ${notification.title}');
  }

  /// Handle WebSocket message and show background notification if needed
  static Future<void> handleWebSocketMessage(dynamic message) async {
    try {
      final data = jsonDecode(message as String);

      if (data['type'] == 'notification') {
        final notification = VendorNotification.fromJson(
          data['data'] as Map<String, dynamic>,
        );

        // Always show background notification for real-time updates
        await BackgroundNotificationService.showBackgroundNotification(
          notification,
        );

        // Add to provider if app is in foreground
        if (_ref != null) {
          _ref!
              .read(vendorNotificationProvider.notifier)
              .addNotification(notification);
        }

        debugPrint('Handled WebSocket notification: ${notification.title}');
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message for background: $e');
    }
  }

  /// Cleanup resources
  static void dispose() {
    _backgroundSubscription?.cancel();
    _backgroundSubscription = null;
    _ref = null;
  }
}

/// Background WebSocket service for maintaining connection in background
class BackgroundWebSocketService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static Timer? _heartbeatTimer;
  static Timer? _reconnectTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectInterval = Duration(seconds: 10);

  /// Initialize background WebSocket connection
  static Future<void> initialize() async {
    try {
      final wsUrl = 'ws://your-backend-url.com/notifications';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          BackgroundNotificationHandler.handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('Background WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('Background WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      _startHeartbeat();
      debugPrint('Background WebSocket connected');
    } catch (e) {
      debugPrint('Failed to connect background WebSocket: $e');
      _scheduleReconnect();
    }
  }

  /// Start heartbeat to keep connection alive
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'heartbeat'}));
        } catch (e) {
          debugPrint('Heartbeat failed: $e');
        }
      }
    });
  }

  /// Schedule reconnection attempt
  static void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isConnected) {
        debugPrint('Attempting to reconnect background WebSocket...');
        initialize();
      }
    });
  }

  /// Disconnect background WebSocket
  static void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    debugPrint('Background WebSocket disconnected');
  }

  /// Check connection status
  static bool get isConnected => _isConnected;
}
