import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/auth_models.dart';
import '../utils/logger.dart';

/// Authentication state
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  final bool isAuthenticated;
  final VendorProfile? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    VendorProfile? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.isAuthenticated == isAuthenticated &&
        other.user == user &&
        other.token == token &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(isAuthenticated, user, token, isLoading, error);
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, user: $user, token: $token, isLoading: $isLoading, error: $error)';
  }
}

/// Authentication controller
class AuthController extends StateNotifier<AsyncValue<AuthState>> {
  AuthController(this._apiClient) : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  final ApiClient _apiClient;

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    try {
      state = const AsyncValue.loading();

      // Check if user is authenticated
      final isAuthenticated = await TokenStorage.isAuthenticated();

      if (isAuthenticated) {
        final token = await TokenStorage.getAccessToken();
        final user = await TokenStorage.getUser();

        if (token != null && user != null) {
          state = AsyncValue.data(
            AuthState(isAuthenticated: true, user: user, token: token),
          );
          return;
        }
      }

      // Not authenticated
      state = const AsyncValue.data(AuthState());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with email and password
  Future<void> login({required String email, required String password}) async {
    try {
      state = const AsyncValue.loading();

      final response = await _apiClient.publicDio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token =
            data['token'] as String? ?? data['accessToken'] as String?;

        if (token == null || token.isEmpty) {
          throw const ApiException('No access token received from server');
        }

        // Parse user data
        final userData = data['user'] ?? data['vendor'] ?? data['data'];
        final user = VendorProfile.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
        );

        // Save tokens and user data
        await TokenStorage.saveTokens(
          accessToken: token,
          refreshToken: data['refreshToken'] as String?,
        );
        await TokenStorage.saveUser(user);

        // Update state
        state = AsyncValue.data(
          AuthState(isAuthenticated: true, user: user, token: token),
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Register new vendor
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();

      final response = await _apiClient.publicDio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'businessName': businessName,
          'businessType': businessType,
          'password': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        final token =
            data['token'] as String? ?? data['accessToken'] as String?;

        if (token == null || token.isEmpty) {
          throw const ApiException('No access token received from server');
        }

        // Parse user data
        final userData = data['user'] ?? data['vendor'] ?? data['data'];
        final user = VendorProfile.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
        );

        // Save tokens and user data
        await TokenStorage.saveTokens(
          accessToken: token,
          refreshToken: data['refreshToken'] as String?,
        );
        await TokenStorage.saveUser(user);

        // Update state
        state = AsyncValue.data(
          AuthState(isAuthenticated: true, user: user, token: token),
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint if available
      try {
        await _apiClient.dio.post('/auth/logout');
      } catch (e) {
        // Ignore logout API errors - we'll clear local data anyway
        Logger().warning('Logout API call failed: $e', tag: 'AUTH');
      }

      // Clear local storage
      await TokenStorage.clearAuth();

      // Update state
      state = const AsyncValue.data(AuthState());
    } catch (e) {
      // Even if logout fails, clear local data
      await TokenStorage.clearAuth();
      state = const AsyncValue.data(AuthState());
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final currentState = state.value;
      if (currentState == null || !currentState.isAuthenticated) {
        throw const ApiException('User not authenticated');
      }

      final response = await _apiClient.dio.put('/profile', data: profileData);

      if (response.statusCode == 200) {
        final userData = response.data['data'] ?? response.data;
        final updatedUser = VendorProfile.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
        );

        // Save updated user data
        await TokenStorage.saveUser(updatedUser);

        // Update state
        state = AsyncValue.data(currentState.copyWith(user: updatedUser));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Refresh authentication state
  Future<void> refreshAuthState() async {
    await _initializeAuth();
  }

  /// Handle authentication errors (like 401s)
  void handleAuthError() {
    // Clear auth state on authentication errors
    state = const AsyncValue.data(AuthState());
    TokenStorage.clearAuth();
  }
}

/// Provider for auth controller
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthState>>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return AuthController(apiClient);
    });

/// Provider for current auth state
final authStateProvider = Provider<AsyncValue<AuthState>>((ref) {
  return ref.watch(authControllerProvider);
});

/// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.isAuthenticated,
    orElse: () => false,
  );
});

/// Provider for current user
final currentUserProvider = Provider<VendorProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (state) => state.user, orElse: () => null);
});

/// Provider for current token
final currentTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (state) => state.token, orElse: () => null);
});

/// Provider for loading state
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

/// Provider for auth errors
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (state) => state.error, orElse: () => null);
});
