import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/vendor_api_client.dart';
import '../models/auth_models.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final vendorApiClientProvider = Provider<VendorApiClient>(
  (ref) => VendorApiClient(ref.watch(secureStorageProvider)),
);

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.session,
    this.errorMessage,
    this.didBootstrap = false,
  });

  final bool isLoading;
  final AuthSession? session;
  final String? errorMessage;
  final bool didBootstrap;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    bool? isLoading,
    AuthSession? session,
    String? errorMessage,
    bool clearError = false,
    bool? didBootstrap,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      didBootstrap: didBootstrap ?? this.didBootstrap,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._read) : super(const AuthState());

  final Ref _read;

  VendorApiClient get _apiClient => _read.read(vendorApiClientProvider);

  Future<void> bootstrap() async {
    if (state.didBootstrap) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _apiClient.restoreSession();
      if (session == null) {
        state = state.copyWith(
          isLoading: false,
          didBootstrap: true,
          session: null,
          clearError: true,
        );
        return;
      }

      AuthSession hydrated = session;
      try {
        final profile = await _apiClient.getProfile();
        hydrated = AuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          profile: profile,
        );
        await _apiClient.persistSession(hydrated);
      } catch (_) {
        await _apiClient.persistSession(session);
      }
      state = state.copyWith(
        isLoading: false,
        session: hydrated,
        didBootstrap: true,
        clearError: true,
      );
    } catch (error) {
      await _apiClient.clearSession();
      state = state.copyWith(
        isLoading: false,
        didBootstrap: true,
        session: null,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _apiClient.login(email: email, password: password);
      AuthSession hydrated = session;
      try {
        final profile = await _apiClient.getProfile();
        hydrated = AuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          profile: profile,
        );
      } catch (_) {
        hydrated = session;
      }
      await _apiClient.persistSession(hydrated);
      state = state.copyWith(
        isLoading: false,
        session: hydrated,
        didBootstrap: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        didBootstrap: true,
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _apiClient.register(
        name: name,
        email: email,
        phone: phone,
        businessName: businessName,
        businessType: businessType,
        password: password,
      );
      AuthSession hydrated = session;
      try {
        final profile = await _apiClient.getProfile();
        hydrated = AuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          profile: profile,
        );
      } catch (_) {
        hydrated = session;
      }
      await _apiClient.persistSession(hydrated);
      state = state.copyWith(
        isLoading: false,
        session: hydrated,
        didBootstrap: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        didBootstrap: true,
      );
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiClient.forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearSession();
    state = const AuthState(didBootstrap: true);
  }

  Future<void> refreshProfile() async {
    final session = state.session;
    if (session == null) {
      return;
    }

    try {
      final profile = await _apiClient.getProfile();
      final hydrated = AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        profile: profile,
      );
      await _apiClient.persistSession(hydrated);
      state = state.copyWith(session: hydrated, clearError: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
