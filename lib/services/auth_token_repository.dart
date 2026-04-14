import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/vendor_config.dart';
import '../utils/secure_logger.dart';

/// Central repository for authentication related data.
///
/// • Stores tokens in `FlutterSecureStorage` for security.
/// • Mirrors them in `SharedPreferences` as a fallback for platforms where
///   secure storage is unavailable (desktop, web, etc.).
/// • Handles automatic migration from the fallback to secure storage when the
///   secure storage becomes available.
class AuthTokenRepository {
  static const _secureStorage = FlutterSecureStorage();

  // ---------------------------------------------------------------------
  // Save ---------------------------------------------------------------
  // ---------------------------------------------------------------------
  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: VendorConfig.tokenKey, value: token);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(VendorConfig.tokenKey, token);
    } catch (e) {
      SecureLogger.error(
        'Failed to write access token to SharedPreferences',
        error: e,
        tag: 'AUTH_REPO',
      );
    }
  }

  static Future<void> saveRefreshToken(String? token) async {
    if (token == null) return;
    await _secureStorage.write(key: VendorConfig.refreshTokenKey, value: token);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(VendorConfig.refreshTokenKey, token);
    } catch (e) {
      SecureLogger.error(
        'Failed to write refresh token to SharedPreferences',
        error: e,
        tag: 'AUTH_REPO',
      );
    }
  }

  static Future<void> saveVendorData(String vendorData) async {
    await _secureStorage.write(key: VendorConfig.vendorKey, value: vendorData);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(VendorConfig.vendorKey, vendorData);
    } catch (e) {
      SecureLogger.error(
        'Failed to write vendor data to SharedPreferences',
        error: e,
        tag: 'AUTH_REPO',
      );
    }
  }

  static Future<void> saveTokenExpiry(DateTime expiry) async {
    final iso = expiry.toIso8601String();
    final key = '${VendorConfig.tokenKey}_expiry';
    await _secureStorage.write(key: key, value: iso);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, iso);
    } catch (e) {
      SecureLogger.error(
        'Failed to write token expiry to SharedPreferences',
        error: e,
        tag: 'AUTH_REPO',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Retrieve ------------------------------------------------------------
  // ---------------------------------------------------------------------
  static Future<String?> _readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _readPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAccessToken() async {
    // Prefer secure storage
    final secure = await _readSecure(VendorConfig.tokenKey);
    if (secure != null && secure.isNotEmpty) return secure;

    // Fallback to SharedPreferences and migrate back to secure storage
    final legacy = await _readPrefs(VendorConfig.tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(key: VendorConfig.tokenKey, value: legacy);
      return legacy;
    }
    return null;
  }

  static Future<String?> getRefreshToken() async {
    final secure = await _readSecure(VendorConfig.refreshTokenKey);
    if (secure != null && secure.isNotEmpty) return secure;
    final legacy = await _readPrefs(VendorConfig.refreshTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(key: VendorConfig.refreshTokenKey, value: legacy);
      return legacy;
    }
    return null;
  }

  static Future<String?> getVendorData() async {
    final secure = await _readSecure(VendorConfig.vendorKey);
    if (secure != null && secure.isNotEmpty) return secure;
    final legacy = await _readPrefs(VendorConfig.vendorKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(key: VendorConfig.vendorKey, value: legacy);
      return legacy;
    }
    return null;
  }

  static Future<String?> getTokenExpiry() async {
    final key = '${VendorConfig.tokenKey}_expiry';
    final secure = await _readSecure(key);
    if (secure != null && secure.isNotEmpty) return secure;
    final legacy = await _readPrefs(key);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(key: key, value: legacy);
      return legacy;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Clear ---------------------------------------------------------------
  // ---------------------------------------------------------------------
  static Future<void> clearAll() async {
    await Future.wait([
      _secureStorage.delete(key: VendorConfig.tokenKey),
      _secureStorage.delete(key: VendorConfig.refreshTokenKey),
      _secureStorage.delete(key: VendorConfig.vendorKey),
      _secureStorage.delete(key: '${VendorConfig.tokenKey}_expiry'),
    ]);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(VendorConfig.tokenKey);
      await prefs.remove(VendorConfig.refreshTokenKey);
      await prefs.remove(VendorConfig.vendorKey);
      await prefs.remove('${VendorConfig.tokenKey}_expiry');
    } catch (e) {
      SecureLogger.error(
        'Failed to clear SharedPreferences fallback',
        error: e,
        tag: 'AUTH_REPO',
      );
    }
  }
}
