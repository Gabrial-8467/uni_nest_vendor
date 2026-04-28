# Vendor Push Notification API Documentation

## Overview

Vendors can receive Firebase Cloud Messaging (FCM) push notifications for order updates, system alerts, and account notifications. All push notification endpoints require vendor authentication.

## Base URL

```
https://uninest-backend.onrender.com/api
```

## Authentication

All endpoints require a valid JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

---

## FCM Token Management

### Register FCM Token

Register your device's FCM token to receive push notifications.

```
POST /api/notifications/register-token
```

**Request Headers:**
```
Authorization: Bearer <vendor-jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "fcmToken": "string (required)",
  "deviceType": "string (optional) - e.g., 'android', 'ios'",
  "deviceName": "string (optional) - e.g., 'Samsung Galaxy S21'"
}
```

**Response:**
```json
{
  "success": true,
  "message": "FCM token registered successfully",
  "data": {
    "tokenCount": 1
  }
}
```

**Notes:**
- Maximum 5 tokens per vendor (oldest removed if exceeded)
- Updates `lastUsedAt` timestamp if token already exists
- Required to receive push notifications

---

### Unregister FCM Token

Remove an FCM token when logging out or switching devices.

```
POST /api/notifications/unregister-token
```

**Request Headers:**
```
Authorization: Bearer <vendor-jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "fcmToken": "string (required)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "FCM token unregistered successfully",
  "data": {
    "removed": true
  }
}
```

---

### Get Registered Tokens

View all FCM tokens registered for your vendor account.

```
GET /api/notifications/tokens
```

**Request Headers:**
```
Authorization: Bearer <vendor-jwt-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tokens": [
      {
        "deviceType": "android",
        "deviceName": "Pixel 6",
        "createdAt": "2024-01-01T00:00:00.000Z",
        "lastUsedAt": "2024-01-01T00:00:00.000Z",
        "tokenPreview": "dHh0dGh0dH..."
      }
    ],
    "count": 1
  }
}
```

---

## Test Notification

### Send Test Notification

Send a test push notification to verify FCM setup is working correctly.

```
POST /api/notifications/test
```

**Request Headers:**
```
Authorization: Bearer <vendor-jwt-token>
```

**Response:**
```json
{
  "success": true,
  "message": "Test notification sent",
  "data": {
    "successCount": 1,
    "failureCount": 0,
    "invalidTokensRemoved": 0
  }
}
```

**Notification Content:**
- **Title:** "Test Notification"
- **Body:** "This is a test push notification from UniNest!"
- **Channel:** `test`

---

## Automatic Push Notifications

Vendors automatically receive push notifications for the following events (no API call required):

### Order Status Updates

When a customer places an order, vendors receive:

```json
{
  "notification": {
    "title": "New Order Received",
    "body": "You have received a new order #ORD12345 for Rs.250"
  },
  "data": {
    "type": "order",
    "orderId": "...",
    "orderNumber": "ORD12345",
    "finalAmount": 250,
    "paymentMethod": "online"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channelId": "order"
    }
  }
}
```

### System Notifications

Vendors receive system notifications for:
- Account status changes
- Product approval/rejection
- Payment settlements
- Payout updates

---

## FCM Payload Structure

All push notifications follow this standard structure:

```json
{
  "notification": {
    "title": "string - Notification title",
    "body": "string - Notification body text"
  },
  "data": {
    "type": "string - Notification type (order, system, payment, etc.)",
    "notificationId": "string - Notification database ID",
    "orderId": "string - Order ID (if applicable)",
    "actionUrl": "string - Deep link URL (optional)",
    "clickAction": "FLUTTER_NOTIFICATION_CLICK"
  },
  "android": {
    "priority": "high|normal",
    "notification": {
      "channelId": "string - Notification channel ID",
      "sound": "default"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

---

## Notification Channels (Android)

| Channel ID | Description | Priority |
|------------|-------------|----------|
| `order` | New orders and order updates | High |
| `vendor_status` | Vendor account status changes | High |
| `payment` | Payment and payout notifications | Normal |
| `system` | System alerts and updates | Normal |
| `test` | Test notifications | High |

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "FCM token is required"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "No token provided"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "User not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Server error"
}
```

---

## Flutter Integration Example

### 1. Register FCM Token

```dart
Future<void> registerFcmToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  final response = await http.post(
    Uri.parse('https://uninest-backend.onrender.com/api/notifications/register-token'),
    headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fcmToken': fcmToken,
      'deviceType': Platform.isAndroid ? 'android' : 'ios',
      'deviceName': 'Vendor Device',
    }),
  );
  
  print('Token registered: ${response.statusCode}');
}
```

### 2. Handle Incoming Notifications

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Foreground notification received');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  
  // Show local notification
  if (message.notification != null) {
    showNotification(
      title: message.notification!.title ?? 'UniNest',
      body: message.notification!.body ?? '',
    );
  }
});

FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Handle notification tap
  print('Notification tapped: ${message.data}');
});
```

### 3. Unregister Token on Logout

```dart
Future<void> unregisterFcmToken(String fcmToken) async {
  await http.post(
    Uri.parse('https://uninest-backend.onrender.com/api/notifications/unregister-token'),
    headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fcmToken': fcmToken,
    }),
  );
}
```

---

## Best Practices

1. **Register token on app startup** - Call register-token when the vendor logs in
2. **Unregister on logout** - Remove the token when the vendor logs out
3. **Handle token refresh** - FCM tokens can expire, listen for token refresh events
4. **Test before production** - Use the test notification endpoint to verify setup
5. **Handle background notifications** - Configure proper background message handling

---

## Support

For issues or questions regarding push notifications:
- Check the Render logs for FCM send errors
- Verify notification channels are configured in your Flutter app
- Ensure app permissions allow notifications
- Contact backend support if API errors persist
