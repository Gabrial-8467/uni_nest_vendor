# 🚀 Production-Level Authentication System

## 📋 Overview

This is a complete, production-ready authentication system for Flutter apps using Riverpod and Dio. It handles JWT authentication, token management, automatic token refresh, and global error handling.

## 🏗️ Architecture

### Core Components

1. **ApiClient** - Centralized HTTP client using Dio
2. **TokenStorage** - Secure token management
3. **AuthController** - Riverpod state management
4. **AppInitializer** - App startup logic
5. **Interceptors** - Automatic auth headers & error handling

## 🔧 Setup Instructions

### 1. Add Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  dio: ^5.4.3
  flutter_secure_storage: ^9.0.0
```

### 2. Update pubspec.yaml

```yaml
flutter:
  uses-material-design: true
```

### 3. Initialize App

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_initializer.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Vendor App',
      home: AppInitializationWidget(
        child: const AuthWrapper(),
      ),
    );
  }
}
```

## 📱 Usage Examples

### 🔐 Authentication

```dart
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: authState.when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
        data: (state) {
          if (state.isAuthenticated) {
            return const DashboardScreen();
          }

          return Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    await authController.login(
                      email: 'vendor@example.com',
                      password: 'password123',
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $e')),
                    );
                  }
                },
                child: const Text('Login'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

### 🌐 API Calls

```dart
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiService = ref.read(vendorApiServiceProvider);

    return Scaffold(
      body: FutureBuilder<List<VendorOrder>>(
        future: apiService.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final orders = snapshot.data ?? [];
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text('Order #${order.id}'),
                subtitle: Text(order.status),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 🔄 Protected Routes

```dart
class ProtectedRoute extends ConsumerWidget {
  const ProtectedRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return const LoginScreen();
    }

    return const DashboardScreen();
  }
}
```

### 📊 User Profile

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          if (user != null) ...[
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            Text('Business: ${user.businessName}'),
          ],
          ElevatedButton(
            onPressed: () async {
              await authController.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
```

## 🔒 Public vs Private APIs

### Public APIs (No Auth Required)
- `/auth/login`
- `/auth/register`
- `/auth/forgot-password`
- `/version`
- `/health`

### Private APIs (Auth Required)
- `/profile`
- `/orders`
- `/notifications`
- `/ledger`
- `/payouts`

## 🛡️ Security Features

### Automatic Token Management
```dart
// Tokens are automatically attached to requests
// No manual header management needed!

final response = await apiService.getOrders();
// Authorization: Bearer <token> is added automatically
```

### Token Refresh
```dart
// Expired tokens are automatically refreshed
// Failed requests are retried with new token
// All handled transparently by interceptors
```

### 401 Error Handling
```dart
// 401 errors automatically trigger logout
// User is redirected to login screen
// Local storage is cleared
```

## 🔧 Error Handling

### Global Error Handling
```dart
// Errors are handled globally by interceptors
// 401 → Auto logout
// Network errors → User-friendly messages
// Timeouts → Retry logic
```

### Custom Error Handling
```dart
try {
  await apiService.updateOrderStatus(orderId: '123', status: 'confirmed');
} on ApiException catch (e) {
  // Handle specific API errors
  if (e.statusCode == 400) {
    // Bad request
  } else if (e.statusCode == 403) {
    // Forbidden
  }
} catch (e) {
  // Handle other errors
}
```

## 📱 Best Practices

### ✅ DO's
- Always use the centralized ApiClient
- Let Riverpod manage auth state
- Handle loading states properly
- Use proper error boundaries
- Implement proper logout flow

### ❌ DON'Ts
- Don't manually attach headers
- Don't store tokens in SharedPreferences
- Don't ignore 401 errors
- Don't bypass the auth system
- Don't hardcode API URLs

## 🔄 Token Flow

```
1. App Start → Load token from secure storage
2. API Request → Attach auth header automatically  
3. 401 Response → Try token refresh
4. Refresh Success → Retry original request
5. Refresh Failed → Logout user
6. Logout → Clear all tokens & redirect
```

## 🚀 Advanced Features

### Refresh Token System
```dart
// Automatic token refresh is built-in
// No manual implementation needed
// Handles concurrent requests gracefully
```

### Request Caching
```dart
// GET requests are cached for 15 seconds
// Cache is invalidated on mutations
// Reduces unnecessary API calls
```

### Request Logging
```dart
// All requests are logged in debug mode
// Request/response bodies are visible
// Helps with debugging API issues
```

## 📱 Testing

### Mock ApiClient
```dart
class MockApiClient extends ApiClient {
  @override
  Future<T> get<T>(String path, {T Function(dynamic)? fromJson}) async {
    // Return mock data
  }
}
```

### Test Auth State
```dart
test('login success', (ref) async {
  final authController = ref.read(authControllerProvider.notifier);
  await authController.login(email: 'test@test.com', password: 'password');
  
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  expect(isAuthenticated, true);
});
```

## 🔧 Configuration

### Base URL
```dart
// lib/config/api_endpoints.dart
class ApiEndpoints {
  static String get baseUrl => 'https://your-api.com/api/v1';
}
```

### Environment Variables
```dart
// .env file
API_BASE_URL=https://api.yourapp.com/v1
DEBUG_MODE=true
```

## 🚨 Troubleshooting

### Common Issues

1. **401 Errors**
   - Check token storage
   - Verify token format
   - Check backend token validation

2. **Network Errors**
   - Check internet connection
   - Verify API base URL
   - Check timeout settings

3. **Login Not Persisting**
   - Check secure storage permissions
   - Verify token saving
   - Check app initialization

## 📚 Additional Resources

- [Dio Documentation](https://pub.dev/packages/dio)
- [Riverpod Documentation](https://pub.dev/packages/flutter_riverpod)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)

---

## 🎉 Summary

This authentication system provides:

✅ **Secure token management**  
✅ **Automatic auth headers**  
✅ **Token refresh handling**  
✅ **Global error handling**  
✅ **Public/private API separation**  
✅ **Production-ready architecture**  
✅ **Easy testing and debugging**  

Use this system as the foundation for your Flutter app's authentication needs! 🚀
