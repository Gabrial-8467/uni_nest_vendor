import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/vendor_config.dart';
import '../firebase_options.dart';
import '../utils/secure_logger.dart';
import 'permission_service.dart';
import 'secure_auth_service.dart';

@pragma('vm:entry-point')
Future<void> vendorFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await VendorPushNotificationService.ensureFirebaseInitialized();
  SecureLogger.info(
    'Background push received: ${message.messageId ?? message.data['type'] ?? 'unknown'}',
    tag: 'PUSH',
  );
}

class VendorPushNotificationService {
  VendorPushNotificationService._();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final http.Client _httpClient = http.Client();

  static bool _firebaseAvailable = false;
  static bool _initialized = false;
  static bool _localNotificationsInitialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
        'order',
        'Orders',
        description: 'New orders and order updates',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _vendorStatusChannel =
      AndroidNotificationChannel(
        'vendor_status',
        'Vendor Status',
        description: 'Vendor account status changes',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _paymentChannel =
      AndroidNotificationChannel(
        'payment',
        'Payments',
        description: 'Payment and payout notifications',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _systemChannel =
      AndroidNotificationChannel(
        'system',
        'System',
        description: 'System alerts and updates',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _testChannel =
      AndroidNotificationChannel(
        'test',
        'Test',
        description: 'Test notifications',
        importance: Importance.high,
      );

  static const List<AndroidNotificationChannel> _androidChannels = [
    _orderChannel,
    _vendorStatusChannel,
    _paymentChannel,
    _systemChannel,
    _testChannel,
  ];

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await ensureFirebaseInitialized();
    await _initializeLocalNotifications();

    if (!_firebaseAvailable || kIsWeb || !_supportsFirebaseMessaging) {
      _initialized = true;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(
      vendorFirebaseMessagingBackgroundHandler,
    );

    await _requestNotificationPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await registerToken(fcmToken: token);
    });

    _initialized = true;
  }

  static Future<void> ensureFirebaseInitialized() async {
    if (_firebaseAvailable || kIsWeb || !_supportsFirebaseMessaging) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseAvailable = true;
    } catch (error) {
      _firebaseAvailable = false;
      SecureLogger.error(
        'Firebase initialization failed. Add Firebase platform config before using push notifications.',
        error: error,
        tag: 'PUSH',
      );
    }
  }

  static Future<void> registerCurrentToken() async {
    await initialize();
    if (!_firebaseAvailable || kIsWeb || !_supportsFirebaseMessaging) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        SecureLogger.info('FCM token is not available yet', tag: 'PUSH');
        return;
      }

      await registerToken(fcmToken: token);
    } catch (error) {
      SecureLogger.error(
        'Failed to get FCM token',
        error: error,
        tag: 'PUSH',
      );
    }
  }

  static Future<void> registerToken({required String fcmToken}) async {
    if (fcmToken.isEmpty) {
      return;
    }

    final token = await SecureAuthService.getAuthToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _postNotificationEndpoint(
        path: '/notifications/register-token',
        authToken: token,
        body: {
          'fcmToken': fcmToken,
          'deviceType': _deviceType,
          'deviceName': await _deviceName(),
        },
      );
      SecureLogger.info('FCM token registered', tag: 'PUSH');
    } catch (error) {
      SecureLogger.error(
        'Failed to register FCM token',
        error: error,
        tag: 'PUSH',
      );
    }
  }

  static Future<void> unregisterCurrentToken() async {
    if (!_firebaseAvailable || kIsWeb || !_supportsFirebaseMessaging) {
      await ensureFirebaseInitialized();
    }
    if (!_firebaseAvailable || kIsWeb || !_supportsFirebaseMessaging) {
      return;
    }

    final authToken = await SecureAuthService.getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      await _postNotificationEndpoint(
        path: '/notifications/unregister-token',
        authToken: authToken,
        body: {'fcmToken': fcmToken},
      );
      SecureLogger.info('FCM token unregistered', tag: 'PUSH');
    } catch (error) {
      SecureLogger.error(
        'Failed to unregister FCM token',
        error: error,
        tag: 'PUSH',
      );
    }
  }

  static Future<void> sendTestNotification() async {
    final token = await SecureAuthService.getAuthToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _postNotificationEndpoint(
      path: '/notifications/test',
      authToken: token,
    );
  }

  static Future<List<Map<String, dynamic>>> getRegisteredTokens() async {
    final token = await SecureAuthService.getAuthToken();
    if (token == null || token.isEmpty) {
      return const [];
    }

    final uri = Uri.parse('${VendorConfig.apiRootUrl}/notifications/tokens');
    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(VendorConfig.connectionTimeout);

    final decoded = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to fetch FCM tokens');
    }

    final data = decoded['data'];
    final tokens = data is Map<String, dynamic> ? data['tokens'] : null;
    if (tokens is! List) {
      return const [];
    }

    return tokens
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _initialized = false;
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized ||
        kIsWeb ||
        !_supportsLocalNotifications) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        SecureLogger.info(
          'Local notification tapped: ${response.payload ?? ''}',
          tag: 'PUSH',
        );
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    for (final channel in _androidChannels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    _localNotificationsInitialized = true;
  }

  static Future<void> _requestNotificationPermission() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      if (defaultTargetPlatform == TargetPlatform.android) {
        await PermissionService.requestNotificationPermission();
      }
    } catch (error) {
      SecureLogger.error(
        'Failed to request notification permission',
        error: error,
        tag: 'PUSH',
      );
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || kIsWeb) {
      return;
    }

    final channelId = _channelIdFromMessage(message);
    final channel = _androidChannels.firstWhere(
      (item) => item.id == channelId,
      orElse: () => _systemChannel,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'UniNest',
      body: notification.body ?? '',
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    SecureLogger.info(
      'Push notification tapped: ${message.data}',
      tag: 'PUSH',
    );
  }

  static String _channelIdFromMessage(RemoteMessage message) {
    final androidChannel = message.notification?.android?.channelId;
    if (androidChannel != null && androidChannel.isNotEmpty) {
      return androidChannel;
    }

    final type = message.data['type']?.toString();
    switch (type) {
      case 'order':
        return 'order';
      case 'vendor_status':
      case 'vendor_approval':
      case 'account_alert':
        return 'vendor_status';
      case 'payment':
        return 'payment';
      case 'test':
        return 'test';
      default:
        return 'system';
    }
  }

  static Future<void> _postNotificationEndpoint({
    required String path,
    required String authToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${VendorConfig.apiRootUrl}$path');
    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(VendorConfig.connectionTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final decoded = _decodeResponse(response.body);
    throw Exception(
      decoded['message'] ?? 'Push notification request failed',
    );
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {'data': decoded};
    } catch (_) {
      return {'message': body};
    }
  }

  static String get _deviceType {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  static bool get _supportsLocalNotifications {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  static bool get _supportsFirebaseMessaging {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  static Future<String> _deviceName() async {
    try {
      final info = DeviceInfoPlugin();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await info.androidInfo;
          return [android.manufacturer, android.model]
              .where((item) => item.trim().isNotEmpty)
              .join(' ');
        case TargetPlatform.iOS:
          final ios = await info.iosInfo;
          return ios.name.isNotEmpty ? ios.name : ios.model;
        default:
          return 'Vendor Device';
      }
    } catch (_) {
      return 'Vendor Device';
    }
  }
}
