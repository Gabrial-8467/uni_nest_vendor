import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/vendor_notification.dart';
import '../providers/vendor_notification_provider.dart';
import 'background_notification_service.dart';

/// Real-time notification service using WebSocket
class RealtimeNotificationService {
  static WebSocketChannel? _channel;
  static StreamController<VendorNotification>? _notificationController;
  static Stream<VendorNotification>? _notificationStream;
  static bool _isConnected = false;
  static Timer? _reconnectTimer;
  static const Duration _reconnectInterval = Duration(seconds: 30);
  static WidgetRef? _ref;

  /// Set the WidgetRef for provider access
  static void setRef(WidgetRef ref) {
    _ref = ref;
  }

  /// Initialize WebSocket connection
  static Future<void> initialize() async {
    try {
      final wsUrl =
          'ws://your-backend-url.com/notifications'; // Replace with actual WebSocket URL

      debugPrint('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _notificationController =
          StreamController<VendorNotification>.broadcast();
      _notificationStream = _notificationController!.stream;

      // Listen for WebSocket messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  static void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      if (data['type'] == 'notification') {
        final notification = VendorNotification.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        _notificationController?.add(notification);

        // Show background notification
        BackgroundNotificationService.showBackgroundNotification(notification);

        // Add to provider if ref is available
        if (_ref != null) {
          _ref!
              .read(vendorNotificationProvider.notifier)
              .addNotification(notification);
        }

        debugPrint('Received real-time notification: ${notification.title}');
      } else if (data['type'] == 'notification_read') {
        // Handle notification read event
        final notificationId = data['notificationId'] as String?;
        debugPrint('Marking notification as read: $notificationId');
        // Update notification as read in provider
        _ref
            ?.read(vendorNotificationProvider.notifier)
            .markAsRead(notificationId!);
      } else if (data['type'] == 'notification_deleted') {
        // Handle notification deleted event
        final notificationId = data['notificationId'] as String?;
        debugPrint('Deleting notification: $notificationId');
        // Remove notification from provider
        _ref
            ?.read(vendorNotificationProvider.notifier)
            .deleteNotification(notificationId!);
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  /// Schedule reconnection attempt
  static void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isConnected) {
        debugPrint('Attempting to reconnect WebSocket...');
        initialize();
      }
    });
  }

  /// Get notification stream
  static Stream<VendorNotification>? get notificationStream =>
      _notificationStream;

  /// Send message through WebSocket
  static void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
        debugPrint('Sent WebSocket message: $message');
      } catch (e) {
        debugPrint('Error sending WebSocket message: $e');
      }
    }
  }

  /// Disconnect WebSocket
  static void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _notificationController?.close();
    _isConnected = false;
    debugPrint('WebSocket disconnected');
  }

  /// Check connection status
  static bool get isConnected => _isConnected;
}

/// Fallback polling service for when WebSocket is unavailable
class FallbackPollingService {
  static Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 15);
  static bool _isPolling = false;

  /// Start fallback polling
  static void start() {
    if (_isPolling) return;

    debugPrint('Starting fallback polling');
    _isPolling = true;

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      try {
        // Simulate receiving new notifications
        // In real implementation, this would call the API
        debugPrint('Fallback polling check...');
      } catch (e) {
        debugPrint('Error in fallback polling: $e');
      }
    });
  }

  /// Stop fallback polling
  static void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('Stopped fallback polling');
  }

  /// Check polling status
  static bool get isPolling => _isPolling;
}

/// Enhanced notification service with real-time capabilities
class EnhancedNotificationService {
  static bool _useRealtime = true;
  static bool _realtimeAvailable = false;

  /// Initialize with automatic fallback
  static Future<void> initialize() async {
    // Try WebSocket first
    if (_useRealtime) {
      await RealtimeNotificationService.initialize();

      // Wait a moment to see if WebSocket connects
      await Future.delayed(const Duration(seconds: 3));

      if (RealtimeNotificationService.isConnected) {
        _realtimeAvailable = true;
        debugPrint('Using real-time notifications');
        return;
      }
    }

    // Fallback to polling if WebSocket fails
    _realtimeAvailable = false;
    FallbackPollingService.start();
    debugPrint('Using fallback polling');
  }

  /// Get unified notification stream
  static Stream<VendorNotification> get notificationStream {
    if (_realtimeAvailable &&
        RealtimeNotificationService.notificationStream != null) {
      return RealtimeNotificationService.notificationStream!;
    } else {
      // Create a mock stream for polling
      // In real implementation, this would be from polling results
      return Stream.empty(); // Replace with actual polling stream
    }
  }

  /// Send real-time acknowledgment
  static void sendAcknowledgment(String notificationId, String type) {
    if (_realtimeAvailable) {
      RealtimeNotificationService.sendMessage({
        'type': 'notification_ack',
        'data': {
          'notificationId': notificationId,
          'ackType': type,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    }
  }

  /// Switch between real-time and polling
  static void toggleRealtime(bool useRealtime) {
    _useRealtime = useRealtime;

    if (useRealtime && !_realtimeAvailable) {
      initialize(); // Try to enable real-time
    } else if (!useRealtime && _realtimeAvailable) {
      RealtimeNotificationService.disconnect();
      FallbackPollingService.start(); // Switch to polling
    }
  }

  /// Get current service status
  static Map<String, dynamic> getStatus() {
    return {
      'realtimeAvailable': _realtimeAvailable,
      'connected': _realtimeAvailable
          ? RealtimeNotificationService.isConnected
          : FallbackPollingService.isPolling,
      'service': _realtimeAvailable ? 'websocket' : 'polling',
    };
  }
}
