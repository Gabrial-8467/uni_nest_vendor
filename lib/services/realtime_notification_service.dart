import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/vendor_config.dart';
import '../models/vendor_notification.dart';
import '../providers/vendor_notification_provider.dart';
import '../utils/secure_logger.dart';

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
      final wsUrl = VendorConfig.realtimeNotificationsUrl;
      if (wsUrl == null) {
        SecureLogger.info(
          'Realtime notifications disabled: no secure websocket URL configured',
          tag: 'REALTIME',
        );
        return;
      }

      SecureLogger.info('Connecting to notification WebSocket', tag: 'REALTIME');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _notificationController =
          StreamController<VendorNotification>.broadcast();
      _notificationStream = _notificationController!.stream;

      // Listen for WebSocket messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          SecureLogger.error('WebSocket error', error: error, tag: 'REALTIME');
          _scheduleReconnect();
        },
        onDone: () {
          SecureLogger.info('WebSocket connection closed', tag: 'REALTIME');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      SecureLogger.info('WebSocket connected successfully', tag: 'REALTIME');
    } catch (e) {
      SecureLogger.error('Failed to connect WebSocket', error: e, tag: 'REALTIME');
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  static void _handleWebSocketMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);

      if (data['type'] == 'notification') {
        final rawNotification = data['data'];
        if (rawNotification is! Map) return;
        final notification = VendorNotification.fromJson(
          Map<String, dynamic>.from(rawNotification),
        );
        _notificationController?.add(notification);

        // Add to provider if ref is available
        if (_ref != null) {
          _ref!
              .read(vendorNotificationProvider.notifier)
              .addNotification(notification);
        }

        SecureLogger.info('Received real-time notification', tag: 'REALTIME');
      } else if (data['type'] == 'notification_read') {
        // Handle notification read event
        final notificationId = data['notificationId'] as String?;
        if (notificationId == null || notificationId.isEmpty) return;
        SecureLogger.info('Realtime notification marked read', tag: 'REALTIME');
        // Update notification as read in provider
        _ref
            ?.read(vendorNotificationProvider.notifier)
            .markAsRead(notificationId);
      } else if (data['type'] == 'notification_deleted') {
        // Handle notification deleted event
        final notificationId = data['notificationId'] as String?;
        if (notificationId == null || notificationId.isEmpty) return;
        SecureLogger.info('Realtime notification deleted', tag: 'REALTIME');
        // Remove notification from provider
        _ref
            ?.read(vendorNotificationProvider.notifier)
            .deleteNotification(notificationId);
      }
    } catch (e) {
      SecureLogger.error(
        'Error parsing WebSocket message',
        error: e,
        tag: 'REALTIME',
      );
    }
  }

  /// Schedule reconnection attempt
  static void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isConnected) {
        SecureLogger.info('Attempting to reconnect WebSocket', tag: 'REALTIME');
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
        SecureLogger.info('Sent WebSocket message', tag: 'REALTIME');
      } catch (e) {
        SecureLogger.error('Error sending WebSocket message', error: e, tag: 'REALTIME');
      }
    }
  }

  /// Disconnect WebSocket
  static void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _notificationController?.close();
    _isConnected = false;
    SecureLogger.info('WebSocket disconnected', tag: 'REALTIME');
  }

  /// Check connection status
  static bool get isConnected => _isConnected;
}

/// Fallback polling service for when WebSocket is unavailable
class FallbackPollingService {
  static Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 60);
  static bool _isPolling = false;

  /// Start fallback polling
  static void start() {
    if (_isPolling) return;

    SecureLogger.info('Starting fallback polling', tag: 'REALTIME');
    _isPolling = true;

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      try {
        // Simulate receiving new notifications
        // In real implementation, this would call the API
        SecureLogger.info('Fallback polling check', tag: 'REALTIME');
      } catch (e) {
        SecureLogger.error('Error in fallback polling', error: e, tag: 'REALTIME');
      }
    });
  }

  /// Stop fallback polling
  static void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    SecureLogger.info('Stopped fallback polling', tag: 'REALTIME');
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
        SecureLogger.info('Using real-time notifications', tag: 'REALTIME');
        return;
      }
    }

    // Fallback to polling if WebSocket fails
    _realtimeAvailable = false;
    FallbackPollingService.start();
    SecureLogger.info('Using fallback polling', tag: 'REALTIME');
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
