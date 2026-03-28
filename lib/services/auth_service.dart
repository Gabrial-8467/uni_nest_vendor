import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/vendor_config.dart';
import '../utils/secure_logger.dart';
import 'vendor_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Timer? _sessionTimer;
  DateTime? _lastActivity;

  // Session Management
  void startSessionTimer() {
    _sessionTimer?.cancel();
    _lastActivity = DateTime.now();

    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionTimeout(),
    );
  }

  void _checkSessionTimeout() {
    if (_lastActivity == null) return;

    final elapsed = DateTime.now().difference(_lastActivity!);
    if (elapsed > VendorConfig.sessionTimeout) {
      SecureLogger.info('Session timed out', tag: 'AUTH');
      logout();
    }
  }

  void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  Future<void> logout() async {
    try {
      _sessionTimer?.cancel();

      // Clear secure storage
      await _secureStorage.deleteAll();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      SecureLogger.info('User logged out successfully', tag: 'AUTH');
    } catch (e) {
      SecureLogger.error('Error during logout', error: e);
    }
  }

  // Token Management
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsToken = prefs.getString(VendorConfig.tokenKey);
      if (sharedPrefsToken != null && sharedPrefsToken.isNotEmpty) {
        return sharedPrefsToken;
      }

      return await _secureStorage.read(key: VendorConfig.tokenKey);
    } catch (e) {
      SecureLogger.error('Failed to get auth token', error: e);
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsToken = prefs.getString(VendorConfig.refreshTokenKey);
      if (sharedPrefsToken != null && sharedPrefsToken.isNotEmpty) {
        return sharedPrefsToken;
      }

      return await _secureStorage.read(key: VendorConfig.refreshTokenKey);
    } catch (e) {
      SecureLogger.error('Failed to get refresh token', error: e);
      return null;
    }
  }

  Future<void> saveTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(VendorConfig.tokenKey, authToken);
      await prefs.setString(VendorConfig.refreshTokenKey, refreshToken);

      await _secureStorage.write(key: VendorConfig.tokenKey, value: authToken);
      await _secureStorage.write(
        key: VendorConfig.refreshTokenKey,
        value: refreshToken,
      );

      startSessionTimer();
      SecureLogger.info('Tokens saved successfully', tag: 'AUTH');
    } catch (e) {
      SecureLogger.error('Failed to save tokens', error: e);
      rethrow;
    }
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) return false;

      // Simple JWT token validation (check expiration)
      final parts = token.split('.');
      if (parts.length != 3) return false;

      try {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );

        final exp = payload['exp'];
        if (exp != null) {
          final expirationTime = DateTime.fromMillisecondsSinceEpoch(
            exp * 1000,
          );
          return DateTime.now().isBefore(expirationTime);
        }
      } catch (e) {
        SecureLogger.error('Failed to parse JWT token', error: e);
        return false;
      }

      return true;
    } catch (e) {
      SecureLogger.error('Token validation failed', error: e);
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Call actual refresh token API
      final response = await VendorApiService.refreshToken(refreshToken);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final newAuthToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        if (newAuthToken != null && newRefreshToken != null) {
          await saveTokens(
            authToken: newAuthToken,
            refreshToken: newRefreshToken,
          );

          SecureLogger.info('Token refreshed successfully', tag: 'AUTH');
          return true;
        }
      }

      SecureLogger.warning(
        'Token refresh failed: Invalid response',
        tag: 'AUTH',
      );
      return false;
    } catch (e) {
      SecureLogger.error('Token refresh failed', error: e);
      await logout();
      return false;
    }
  }

  Future<String?> getValidAuthToken() async {
    final isValid = await isTokenValid();
    if (isValid) {
      updateLastActivity();
      return await getAuthToken();
    }

    // Try to refresh the token
    final refreshSuccess = await refreshToken();
    if (refreshSuccess) {
      updateLastActivity();
      return await getAuthToken();
    }

    return null;
  }

  // User Data Management
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(VendorConfig.vendorKey);

      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      SecureLogger.error('Failed to get user data', error: e);
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(VendorConfig.vendorKey, jsonEncode(userData));
      SecureLogger.info('User data saved successfully', tag: 'AUTH');
    } catch (e) {
      SecureLogger.error('Failed to save user data', error: e);
      rethrow;
    }
  }

  // Security Methods
  Future<void> clearSensitiveData() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(VendorConfig.vendorKey);

      SecureLogger.info('Sensitive data cleared', tag: 'AUTH');
    } catch (e) {
      SecureLogger.error('Failed to clear sensitive data', error: e);
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device supports biometrics
      final canAuthenticate = await _secureStorage.read(key: 'biometric_check');
      return canAuthenticate == 'available';
    } catch (e) {
      SecureLogger.error('Biometric availability check failed', error: e);
      return false;
    }
  }

  Future<void> enableBiometricAuth() async {
    try {
      await _secureStorage.write(key: 'biometric_check', value: 'available');
      SecureLogger.info('Biometric auth enabled', tag: 'AUTH');
    } catch (e) {
      SecureLogger.error('Failed to enable biometric auth', error: e);
    }
  }

  void dispose() {
    _sessionTimer?.cancel();
  }
}
