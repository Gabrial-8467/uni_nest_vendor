import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/secure_logger.dart';

/// Secure authentication service using FlutterSecureStorage
/// Provides token persistence with encryption
class SecureAuthService {
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _vendorDataKey = 'vendor_data';
  static const String _tokenExpiryKey = 'token_expiry';

  // Secure storage with iOS/Android specific options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accountName: 'secure_auth_tokens',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(),
  );

  /// Save authentication tokens securely
  static Future<void> saveAuthSession({
    required String authToken,
    String? refreshToken,
    String? vendorData,
    DateTime? tokenExpiry,
  }) async {
    try {
      await _storage.write(key: _authTokenKey, value: authToken);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }

      if (vendorData != null && vendorData.isNotEmpty) {
        await _storage.write(key: _vendorDataKey, value: vendorData);
      }

      if (tokenExpiry != null) {
        await _storage.write(
          key: _tokenExpiryKey,
          value: tokenExpiry.toIso8601String(),
        );
      }

      SecureLogger.info(
        'Auth session saved: token=${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...',
        tag: 'AUTH_STORAGE',
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to save auth session',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      throw Exception('Failed to save authentication data: $e');
    }
  }

  /// Get auth token from secure storage
  static Future<String?> getAuthToken() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      SecureLogger.info(
        'Token ${token != null ? 'found' : 'NOT FOUND'} in secure storage',
        tag: 'AUTH_STORAGE',
      );
      return token;
    } catch (e) {
      SecureLogger.error(
        'Failed to read auth token',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      return null;
    }
  }

  /// Get refresh token from secure storage
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      SecureLogger.error(
        'Failed to read refresh token',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      return null;
    }
  }

  /// Get vendor data from secure storage
  static Future<String?> getVendorData() async {
    try {
      final data = await _storage.read(key: _vendorDataKey);
      SecureLogger.info(
        'Vendor data ${data != null ? 'found' : 'NOT FOUND'} in secure storage',
        tag: 'AUTH_STORAGE',
      );
      return data;
    } catch (e) {
      SecureLogger.error(
        'Failed to read vendor data',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      return null;
    }
  }

  /// Save vendor data to secure storage
  static Future<void> saveVendorData(String vendorData) async {
    try {
      await _storage.write(key: _vendorDataKey, value: vendorData);
      SecureLogger.info(
        'Vendor data saved to secure storage',
        tag: 'AUTH_STORAGE',
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to save vendor data',
        error: e,
        tag: 'AUTH_STORAGE',
      );
    }
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return false; // No expiry set, assume valid

      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      SecureLogger.error(
        'Failed to check token expiry',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      return false;
    }
  }

  /// Clear all auth data from secure storage
  static Future<void> clearAuthSession() async {
    try {
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _vendorDataKey);
      await _storage.delete(key: _tokenExpiryKey);

      SecureLogger.info(
        'Auth session cleared from secure storage',
        tag: 'AUTH_STORAGE',
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to clear auth session',
        error: e,
        tag: 'AUTH_STORAGE',
      );
    }
  }

  /// Check if user has valid auth session
  static Future<bool> hasValidSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Debug: Print current auth state
  static Future<void> debugPrintAuthState() async {
    final token = await getAuthToken();
    final refresh = await getRefreshToken();
    final vendor = await getVendorData();
    final isExpired = await isTokenExpired();

    SecureLogger.info('=== AUTH STATE DEBUG ===', tag: 'AUTH_DEBUG');
    SecureLogger.info(
      'Token: ${token != null ? 'PRESENT' : 'MISSING'}',
      tag: 'AUTH_DEBUG',
    );
    if (token != null) {
      SecureLogger.info(
        'Token preview: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
        tag: 'AUTH_DEBUG',
      );
    }
    SecureLogger.info(
      'Refresh Token: ${refresh != null ? 'PRESENT' : 'MISSING'}',
      tag: 'AUTH_DEBUG',
    );
    SecureLogger.info(
      'Vendor Data: ${vendor != null ? 'PRESENT' : 'MISSING'}',
      tag: 'AUTH_DEBUG',
    );
    SecureLogger.info('Token Expired: $isExpired', tag: 'AUTH_DEBUG');
    SecureLogger.info('========================', tag: 'AUTH_DEBUG');
  }
}
