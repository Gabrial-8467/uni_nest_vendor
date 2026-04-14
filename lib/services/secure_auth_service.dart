import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/vendor_config.dart';
import '../utils/secure_logger.dart';

/// Secure authentication service using FlutterSecureStorage
/// Provides token persistence with encryption
class SecureAuthService {
  // Use VendorConfig keys for consistency across the app
  static String get _authTokenKey => VendorConfig.tokenKey;
  static String get _refreshTokenKey => VendorConfig.refreshTokenKey;
  static String get _vendorDataKey => VendorConfig.vendorKey;
  static String get _tokenExpiryKey => '${VendorConfig.tokenKey}_expiry';

  // Secure storage with iOS/Android specific options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accountName: 'secure_auth_tokens',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
    ),
  );

  /// Save authentication tokens securely
  static Future<void> saveAuthSession({
    required String authToken,
    String? refreshToken,
    String? vendorData,
    DateTime? tokenExpiry,
  }) async {
    try {
      // Write to secure storage first
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

      // Also persist a fallback copy in SharedPreferences for platforms where
      // FlutterSecureStorage may not be available (e.g., desktop/web). This ensures
      // the token can be retrieved via the SharedPreferences fallback path.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(VendorConfig.tokenKey, authToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await prefs.setString(VendorConfig.refreshTokenKey, refreshToken);
        }
        if (vendorData != null && vendorData.isNotEmpty) {
          await prefs.setString(VendorConfig.vendorKey, vendorData);
        }
        if (tokenExpiry != null) {
          await prefs.setString(
            '${VendorConfig.tokenKey}_expiry',
            tokenExpiry.toIso8601String(),
          );
        }
      } catch (ePrefs) {
        // Do not fail the whole operation if SharedPreferences write fails.
        SecureLogger.error(
          'Failed to write token fallback to SharedPreferences',
          error: ePrefs,
          tag: 'AUTH_STORAGE',
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

  /// Get auth token from secure storage (with SharedPreferences fallback)
  static Future<String?> getAuthToken() async {
    try {
      // Try secure storage first
      final token = await _storage.read(key: _authTokenKey);
      if (token != null && token.isNotEmpty) {
        SecureLogger.info('Token found in secure storage', tag: 'AUTH_STORAGE');
        return token;
      }

      // Fallback: check SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(VendorConfig.tokenKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        SecureLogger.info(
          'Token found in SharedPreferences, migrating to secure storage',
          tag: 'AUTH_STORAGE',
        );
        // Migrate to secure storage
        await _storage.write(key: _authTokenKey, value: legacyToken);
        return legacyToken;
      }

      SecureLogger.info('Token NOT FOUND in any storage', tag: 'AUTH_STORAGE');
      return null;
    } catch (e) {
      SecureLogger.error(
        'Failed to read auth token',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      return null;
    }
  }

  /// Get refresh token from secure storage (with SharedPreferences fallback)
  static Future<String?> getRefreshToken() async {
    try {
      // Try secure storage first
      final token = await _storage.read(key: _refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        return token;
      }

      // Fallback: check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(VendorConfig.refreshTokenKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: legacyToken);
        return legacyToken;
      }
      return null;
    } catch (e) {
      SecureLogger.error(
        'Failed to read refresh token',
        error: e,
        tag: 'AUTH_STORAGE',
      );
      return null;
    }
  }

  /// Get vendor data from secure storage (with SharedPreferences fallback)
  static Future<String?> getVendorData() async {
    try {
      // Try secure storage first
      final data = await _storage.read(key: _vendorDataKey);
      if (data != null && data.isNotEmpty) {
        SecureLogger.info(
          'Vendor data found in secure storage',
          tag: 'AUTH_STORAGE',
        );
        return data;
      }

      // Fallback: check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final legacyData = prefs.getString(VendorConfig.vendorKey);
      if (legacyData != null && legacyData.isNotEmpty) {
        SecureLogger.info(
          'Vendor data found in SharedPreferences, migrating',
          tag: 'AUTH_STORAGE',
        );
        await _storage.write(key: _vendorDataKey, value: legacyData);
        return legacyData;
      }

      SecureLogger.info(
        'Vendor data NOT FOUND in any storage',
        tag: 'AUTH_STORAGE',
      );
      return null;
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

  /// Clear all auth data from both secure storage and SharedPreferences
  static Future<void> clearAuthSession() async {
    try {
      // Clear secure storage
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _vendorDataKey);
      await _storage.delete(key: _tokenExpiryKey);

      // Also clear SharedPreferences fallback to ensure complete logout
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(VendorConfig.tokenKey);
        await prefs.remove(VendorConfig.refreshTokenKey);
        await prefs.remove(VendorConfig.vendorKey);
        await prefs.remove(_tokenExpiryKey);
      } catch (ePrefs) {
        SecureLogger.error(
          'Failed to clear SharedPreferences during logout',
          error: ePrefs,
          tag: 'AUTH_STORAGE',
        );
      }

      SecureLogger.info(
        'Auth session cleared from all storage',
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
