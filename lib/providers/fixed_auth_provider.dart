import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/vendor_api_client.dart';
import '../models/auth_models.dart';

/// Authentication state
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.session,
    this.isLoading = false,
    this.error,
  });

  final bool isAuthenticated;
  final VendorProfile? user;
  final AuthSession? session;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    VendorProfile? user,
    AuthSession? session,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      session: session ?? this.session,
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
        other.session == session &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(isAuthenticated, user, session, isLoading, error);
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, user: $user, session: $session, isLoading: $isLoading, error: $error)';
  }
}

/// Authentication controller using existing VendorApiClient
class AuthController extends StateNotifier<AsyncValue<AuthState>> {
  AuthController(this._apiClient) : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  final VendorApiClient _apiClient;

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    try {
      state = const AsyncValue.loading();

      // Restore session from existing storage
      final session = await _apiClient.restoreSession();

      if (session != null) {
        state = AsyncValue.data(
          AuthState(
            isAuthenticated: true,
            user: session.profile,
            session: session,
          ),
        );
        return;
      }

      // Not authenticated
      state = const AsyncValue.data(AuthState());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    try {
      state = const AsyncValue.loading();

      final session = await _apiClient.login(email: email, password: password);

      // Update state
      state = AsyncValue.data(
        AuthState(
          isAuthenticated: true,
          user: session.profile,
          session: session,
        ),
      );

      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Register new vendor
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();

      final session = await _apiClient.register(
        name: name,
        email: email,
        phone: phone,
        businessName: businessName,
        businessType: businessType,
        password: password,
      );

      // Update state
      state = AsyncValue.data(
        AuthState(
          isAuthenticated: true,
          user: session.profile,
          session: session,
        ),
      );

      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiClient.clearSession();

      // Update state
      state = const AsyncValue.data(AuthState());
    } catch (e) {
      // Even if logout fails, clear state
      state = const AsyncValue.data(AuthState());
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final currentState = state.value;
      if (currentState == null || !currentState.isAuthenticated) {
        return false;
      }

      final updatedProfile = await _apiClient.updateProfile(profileData);

      // Update session with new profile
      final updatedSession = AuthSession(
        accessToken: currentState.session!.accessToken,
        refreshToken: currentState.session!.refreshToken,
        profile: updatedProfile,
      );

      await _apiClient.persistSession(updatedSession);

      // Update state
      state = AsyncValue.data(
        currentState.copyWith(user: updatedProfile, session: updatedSession),
      );

      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
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
    _apiClient.clearSession();
  }

  /// Clear error state
  void clearError() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(error: null));
    }
  }
}

/// Provider for secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Provider for VendorApiClient
final vendorApiClientProvider = Provider<VendorApiClient>(
  (ref) => VendorApiClient(ref.watch(secureStorageProvider)),
);

/// Provider for auth controller
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthState>>((ref) {
      final apiClient = ref.watch(vendorApiClientProvider);
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

/// Provider for current session
final currentSessionProvider = Provider<AuthSession?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session,
    orElse: () => null,
  );
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
