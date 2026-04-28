import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Security utilities for sensitive payout operations
class PayoutSecurity {
  /// Prevents screenshots and screen recording on sensitive screens
  static void enableScreenProtection() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      // Note: Full screenshot prevention requires native plugin integration
      // like `secure_application` or `flutter_windowmanager` for Android
      // and `UIApplication.shared.isIdleTimerDisabled` for iOS
    }
  }

  /// Disables screen protection when leaving sensitive screen
  static void disableScreenProtection() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Sanitize account number input - remove spaces and special chars
  static String sanitizeAccountNumber(String input) {
    return input.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Sanitize IFSC code - uppercase and remove spaces
  static String sanitizeIfscCode(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'\s'), '');
  }

  /// Sanitize UPI ID - lowercase and trim
  static String sanitizeUpiId(String input) {
    return input.toLowerCase().trim();
  }

  /// Validate account number (9-18 digits)
  static bool isValidAccountNumber(String accountNumber) {
    final sanitized = sanitizeAccountNumber(accountNumber);
    return sanitized.length >= 9 && sanitized.length <= 18;
  }

  /// Validate IFSC code (4 letters + 7 alphanumeric)
  static bool isValidIfscCode(String ifscCode) {
    final sanitized = sanitizeIfscCode(ifscCode);
    final regex = RegExp(r'^[A-Z]{4}[0-9A-Z]{7}$');
    return regex.hasMatch(sanitized);
  }

  /// Validate UPI ID (format: username@provider)
  static bool isValidUpiId(String upiId) {
    final sanitized = sanitizeUpiId(upiId);
    final regex = RegExp(r'^[a-z0-9._-]+@[a-z]{3,}$');
    return regex.hasMatch(sanitized);
  }

  /// Mask account number for display (show only last 4 digits)
  static String maskAccountNumber(String accountNumber) {
    final sanitized = sanitizeAccountNumber(accountNumber);
    if (sanitized.length < 4) return sanitized;
    final last4 = sanitized.substring(sanitized.length - 4);
    return '*' * (sanitized.length - 4) + last4;
  }

  /// Mask UPI ID for display (show only first 3 and domain)
  static String maskUpiId(String upiId) {
    final sanitized = sanitizeUpiId(upiId);
    final atIndex = sanitized.indexOf('@');
    if (atIndex == -1 || atIndex < 3) return sanitized;
    return '${sanitized.substring(0, 3)}***${sanitized.substring(atIndex)}';
  }

  /// Check if text contains any sensitive bank patterns
  static bool containsSensitiveData(String text) {
    final patterns = [
      RegExp(r'\b\d{9,18}\b'), // Account numbers
      RegExp(r'\b[A-Z]{4}[0-9A-Z]{7}\b'), // IFSC
      RegExp(r'\b[a-z0-9._-]+@[a-z]{3,}\b'), // UPI
    ];
    return patterns.any((pattern) => pattern.hasMatch(text));
  }
}

/// Widget that wraps sensitive screens with security measures
class SecureScreen extends StatefulWidget {
  const SecureScreen({
    super.key,
    required this.child,
    this.preventScreenshots = true,
  });

  final Widget child;
  final bool preventScreenshots;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preventScreenshots) {
      PayoutSecurity.enableScreenProtection();
    }
  }

  @override
  void dispose() {
    PayoutSecurity.disableScreenProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Rate limiter for sensitive operations (like payout requests)
class RateLimiter {
  final Map<String, DateTime> _lastAttempt = {};
  final Duration minInterval;

  RateLimiter({this.minInterval = const Duration(seconds: 5)});

  bool canProceed(String operationId) {
    final lastAttempt = _lastAttempt[operationId];
    if (lastAttempt == null) return true;
    return DateTime.now().difference(lastAttempt) >= minInterval;
  }

  void recordAttempt(String operationId) {
    _lastAttempt[operationId] = DateTime.now();
  }

  Duration? timeUntilNextAttempt(String operationId) {
    final lastAttempt = _lastAttempt[operationId];
    if (lastAttempt == null) return null;
    final elapsed = DateTime.now().difference(lastAttempt);
    if (elapsed >= minInterval) return null;
    return minInterval - elapsed;
  }
}
