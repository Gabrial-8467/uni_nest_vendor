import 'dart:convert';
import 'package:flutter/foundation.dart';

class SecurityValidator {
  static final SecurityValidator _instance = SecurityValidator._internal();
  factory SecurityValidator() => _instance;
  SecurityValidator._internal();

  // Input Validation
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return email.contains('@') &&
        email.contains('.') &&
        email.indexOf('@') < email.lastIndexOf('.');
  }

  bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length == 10 && cleanPhone.startsWith('6');
  }

  bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 8) return false;

    bool hasUpper = false;
    bool hasLower = false;
    bool hasDigit = false;
    bool hasSpecial = false;

    for (int i = 0; i < password.length; i++) {
      final char = password[i];
      if (char.toUpperCase() != char.toLowerCase()) {
        if (char == char.toUpperCase()) hasUpper = true;
        if (char == char.toLowerCase()) hasLower = true;
      }
      if ('0123456789'.contains(char)) hasDigit = true;
      if (r'@!#$%^&*'.split('').contains(char)) hasSpecial = true;
    }

    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  bool isValidName(String name) {
    if (name.isEmpty) return false;
    if (name.length < 2 || name.length > 50) return false;

    final sanitized = name.replaceAll(RegExp(r"[^a-zA-Z\s\-\.\'\,]"), '');
    return sanitized.length == name.length;
  }

  bool isValidBusinessName(String businessName) {
    if (businessName.isEmpty) return false;
    if (businessName.length < 2 || businessName.length > 100) return false;

    final sanitized = businessName.replaceAll(
      RegExp(r'[^a-zA-Z0-9\s\-\&\.\,\"]'),
      '',
    );
    return sanitized.length == businessName.length;
  }

  bool isValidPrice(String price) {
    if (price.isEmpty) return false;
    final priceValue = double.tryParse(price);
    return priceValue != null && priceValue >= 0 && priceValue <= 99999.99;
  }

  bool isValidQuantity(String quantity) {
    if (quantity.isEmpty) return false;
    final qtyValue = int.tryParse(quantity);
    return qtyValue != null && qtyValue >= 0 && qtyValue <= 99999;
  }

  // Input Sanitization
  String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    String sanitized = input;
    sanitized = sanitized.replaceAll('<', '');
    sanitized = sanitized.replaceAll('>', '');
    sanitized = sanitized.replaceAll('"', '');
    sanitized = sanitized.replaceAll("'", '');
    sanitized = sanitized.trim();

    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }

    return sanitized;
  }

  String sanitizeHtml(String input) {
    if (input.isEmpty) return input;

    String sanitized = input;
    sanitized = sanitized.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<object[^>]*>.*?</object>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<embed[^>]*>.*?</embed>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<form[^>]*>.*?</form>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'on\w+\s*=', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'javascript:', caseSensitive: false),
      '',
    );

    return sanitized;
  }

  // Data Validation
  Map<String, String> validateRegistrationData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    if (data['name'] == null || data['name'].toString().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (!isValidName(data['name'].toString())) {
      errors['name'] = 'Please enter a valid name (2-50 characters)';
    }

    if (data['email'] == null || data['email'].toString().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!isValidEmail(data['email'].toString())) {
      errors['email'] = 'Please enter a valid email address';
    }

    if (data['phone'] == null || data['phone'].toString().isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!isValidPhone(data['phone'].toString())) {
      errors['phone'] = 'Please enter a valid 10-digit phone number';
    }

    if (data['password'] == null || data['password'].toString().isEmpty) {
      errors['password'] = 'Password is required';
    } else if (!isValidPassword(data['password'].toString())) {
      errors['password'] =
          'Password must be at least 8 characters with 1 uppercase, 1 lowercase, 1 digit, and 1 special character';
    }

    if (data['businessName'] == null ||
        data['businessName'].toString().isEmpty) {
      errors['businessName'] = 'Business name is required';
    } else if (!isValidBusinessName(data['businessName'].toString())) {
      errors['businessName'] =
          'Please enter a valid business name (2-100 characters)';
    }

    if (data['businessType'] == null ||
        data['businessType'].toString().isEmpty) {
      errors['businessType'] = 'Business type is required';
    } else {
      final validTypes = [
        'canteen',
        'restaurant',
        'cafe',
        'food truck',
        'food_truck',
        'other',
      ];
      if (!validTypes.contains(data['businessType'].toString())) {
        errors['businessType'] = 'Please select a valid business type';
      }
    }

    return errors;
  }

  Map<String, String> validateProductData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    if (data['name'] == null || data['name'].toString().isEmpty) {
      errors['name'] = 'Product name is required';
    } else if (data['name'].toString().length < 2 ||
        data['name'].toString().length > 100) {
      errors['name'] = 'Product name must be between 2 and 100 characters';
    }

    if (data['description'] == null || data['description'].toString().isEmpty) {
      errors['description'] = 'Product description is required';
    } else if (data['description'].toString().length < 10 ||
        data['description'].toString().length > 1000) {
      errors['description'] =
          'Description must be between 10 and 1000 characters';
    }

    if (data['category'] == null || data['category'].toString().isEmpty) {
      errors['category'] = 'Category is required';
    } else {
      final validCategories = [
        'snacks',
        'beverages',
        'south indian',
        'north indian',
        'chinese',
        'desserts',
      ];
      if (!validCategories.contains(
        data['category'].toString().toLowerCase(),
      )) {
        errors['category'] = 'Please select a valid category';
      }
    }

    if (data['price'] == null || data['price'].toString().isEmpty) {
      errors['price'] = 'Price is required';
    } else if (!isValidPrice(data['price'].toString())) {
      errors['price'] = 'Please enter a valid price (0-99999.99)';
    }

    if (data['inStock'] == null || data['inStock'].toString().isEmpty) {
      errors['inStock'] = 'Stock quantity is required';
    } else if (!isValidQuantity(data['inStock'].toString())) {
      errors['inStock'] = 'Please enter a valid quantity (0-99999)';
    }

    if (data['images'] == null) {
      errors['images'] = 'At least one product image is required';
    } else {
      final images = data['images'] as List?;
      if (images == null || images.isEmpty) {
        errors['images'] = 'At least one product image is required';
      } else if (images.length > 5) {
        errors['images'] = 'Maximum 5 images allowed';
      }
    }

    return errors;
  }

  // Security Headers Validation
  bool isValidHttpResponse(Map<String, String> headers) {
    if (kReleaseMode) {
      final requiredHeaders = [
        'x-content-type-options',
        'x-frame-options',
        'x-xss-protection',
      ];

      for (final header in requiredHeaders) {
        if (!headers.containsKey(header.toLowerCase())) {
          return false;
        }
      }
    }

    return true;
  }

  // Rate Limiting Validation
  bool isRateLimitExceeded(
    String identifier,
    int maxRequests,
    Duration window,
  ) {
    return false;
  }

  // Content Security Policy
  String generateCSP() {
    if (kReleaseMode) {
      return "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://api.uninest.com";
    }
    return "default-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'";
  }

  // Token Validation
  bool isValidJwtToken(String token) {
    if (token.isEmpty) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );

      if (header['typ'] != 'JWT') return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];
      if (exp != null) {
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expirationTime)) {
          return false;
        }
      }

      final iat = payload['iat'];
      if (iat != null) {
        final issuedAt = DateTime.fromMillisecondsSinceEpoch(iat * 1000);
        if (DateTime.now().difference(issuedAt).inHours > 24) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('JWT validation error: $e');
      return false;
    }
  }

  // File Validation
  bool isValidImageFile(String fileName, int fileSize) {
    if (fileName.isEmpty) return false;

    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final maxSize = 5 * 1024 * 1024; // 5MB

    final extension = fileName.split('.').last.toLowerCase();

    return validExtensions.contains(extension) && fileSize <= maxSize;
  }

  bool isValidDocumentFile(String fileName, int fileSize) {
    if (fileName.isEmpty) return false;

    final validExtensions = ['pdf', 'doc', 'docx'];
    final maxSize = 10 * 1024 * 1024; // 10MB

    final extension = fileName.split('.').last.toLowerCase();

    return validExtensions.contains(extension) && fileSize <= maxSize;
  }
}
