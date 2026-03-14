import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/vendor_models.dart';
import '../utils/secure_logger.dart';

class VendorApiService {
  static const String _baseUrl = 'https://api.uninest.com';
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  // Authentication headers
  static Map<String, String> _getHeaders({String? authToken}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'VendorApp/1.0',
    };

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  // Generic HTTP request method with retry logic
  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    String? authToken,
    Duration? timeout,
    int? maxRetries,
  }) async {
    final url = '$_baseUrl$endpoint';
    final headers = _getHeaders(authToken: authToken);
    final requestTimeout = timeout ?? _timeout;
    final retries = maxRetries ?? _maxRetries;

    SecureLogger.logRequest(method, url, body: body);

    int attempts = 0;
    while (attempts < retries) {
      try {
        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(Uri.parse(url), headers: headers)
                .timeout(requestTimeout);
            break;
          case 'POST':
            response = await http
                .post(
                  Uri.parse(url),
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(requestTimeout);
            break;
          case 'PUT':
            response = await http
                .put(
                  Uri.parse(url),
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(requestTimeout);
            break;
          case 'DELETE':
            response = await http
                .delete(Uri.parse(url), headers: headers)
                .timeout(requestTimeout);
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }

        SecureLogger.logResponse(response.statusCode, url, body: response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body);
        } else {
          final errorData = jsonDecode(response.body);
          throw VendorApiException(
            message: errorData['message'] ?? 'Request failed',
            statusCode: response.statusCode,
            errorData: errorData,
          );
        }
      } catch (e) {
        attempts++;
        SecureLogger.error(
          'Request attempt $attempts failed for $method $url',
          error: e,
        );

        if (attempts >= retries) {
          if (e is VendorApiException) rethrow;
          throw VendorApiException(
            message: 'Network error: ${e.toString()}',
            statusCode: -1,
            errorData: {'originalError': e.toString()},
          );
        }

        // Exponential backoff
        await Future.delayed(Duration(seconds: attempts * attempts));
      }
    }

    throw VendorApiException(
      message: 'Max retry attempts exceeded',
      statusCode: -1,
      errorData: {'attempts': attempts},
    );
  }

  // Vendor Authentication
  static Future<Map<String, dynamic>> loginVendor(
    String email,
    String password,
  ) async {
    return await _makeRequest(
      'POST',
      '/api/vendor/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> registerVendor(
    Map<String, dynamic> vendorData,
  ) async {
    return await _makeRequest(
      'POST',
      '/api/vendor/auth/register',
      body: vendorData,
    );
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _makeRequest(
      'POST',
      '/api/vendor/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
  }

  static Future<Map<String, dynamic>> logoutVendor(String authToken) async {
    return await _makeRequest(
      'POST',
      '/api/vendor/auth/logout',
      authToken: authToken,
    );
  }

  // Vendor Profile Management
  static Future<Vendor> getVendorProfile(
    String vendorId,
    String authToken,
  ) async {
    final response = await _makeRequest(
      'GET',
      '/api/vendor/profile/$vendorId',
      authToken: authToken,
    );
    return Vendor.fromJson(response['vendor']);
  }

  static Future<Vendor> updateVendorProfile(
    String vendorId,
    Map<String, dynamic> profileData,
    String authToken,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/api/vendor/profile/$vendorId',
      body: profileData,
      authToken: authToken,
    );
    return Vendor.fromJson(response['vendor']);
  }

  static Future<Map<String, dynamic>> uploadVendorImage(
    String vendorId,
    String imagePath,
    String authToken,
  ) async {
    // This would typically use multipart form data
    // For now, we'll simulate the upload
    return await _makeRequest(
      'POST',
      '/api/vendor/profile/$vendorId/upload-image',
      body: {'imagePath': imagePath},
      authToken: authToken,
    );
  }

  // Product Management
  static Future<List<Product>> getVendorProducts(
    String vendorId,
    String authToken,
  ) async {
    final response = await _makeRequest(
      'GET',
      '/api/vendor/$vendorId/products',
      authToken: authToken,
    );
    return (response['products'] as List)
        .map((product) => Product.fromJson(product))
        .toList();
  }

  static Future<Product> createProduct(
    String vendorId,
    Map<String, dynamic> productData,
    String authToken,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/api/vendor/$vendorId/products',
      body: productData,
      authToken: authToken,
    );
    return Product.fromJson(response['product']);
  }

  static Future<Product> updateProduct(
    String vendorId,
    String productId,
    Map<String, dynamic> productData,
    String authToken,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/api/vendor/$vendorId/products/$productId',
      body: productData,
      authToken: authToken,
    );
    return Product.fromJson(response['product']);
  }

  static Future<bool> deleteProduct(
    String vendorId,
    String productId,
    String authToken,
  ) async {
    await _makeRequest(
      'DELETE',
      '/api/vendor/$vendorId/products/$productId',
      authToken: authToken,
    );
    return true;
  }

  static Future<Map<String, dynamic>> uploadProductImages(
    String vendorId,
    String productId,
    List<String> imagePaths,
    String authToken,
  ) async {
    return await _makeRequest(
      'POST',
      '/api/vendor/$vendorId/products/$productId/upload-images',
      body: {'imagePaths': imagePaths},
      authToken: authToken,
    );
  }

  // Order Management
  static Future<List<Order>> getVendorOrders(
    String vendorId,
    String authToken, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final endpoint = '/api/vendor/$vendorId/orders?$queryString';

    final response = await _makeRequest('GET', endpoint, authToken: authToken);
    return (response['orders'] as List)
        .map((order) => Order.fromJson(order))
        .toList();
  }

  static Future<Order> getOrderDetails(
    String vendorId,
    String orderId,
    String authToken,
  ) async {
    final response = await _makeRequest(
      'GET',
      '/api/vendor/$vendorId/orders/$orderId',
      authToken: authToken,
    );
    return Order.fromJson(response['order']);
  }

  static Future<Order> updateOrderStatus(
    String vendorId,
    String orderId,
    String status,
    String authToken, {
    String? notes,
  }) async {
    final body = {'status': status};
    if (notes != null) body['notes'] = notes;

    final response = await _makeRequest(
      'PUT',
      '/api/vendor/$vendorId/orders/$orderId/status',
      body: body,
      authToken: authToken,
    );
    return Order.fromJson(response['order']);
  }

  // Analytics and Reporting
  static Future<VendorAnalytics> getVendorAnalytics(
    String vendorId,
    String authToken, {
    DateTime? startDate,
    DateTime? endDate,
    String? period,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (period != null) queryParams['period'] = period;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final endpoint = '/api/vendor/$vendorId/analytics?$queryString';

    final response = await _makeRequest('GET', endpoint, authToken: authToken);
    return VendorAnalytics.fromJson(response['analytics']);
  }

  static Future<Map<String, dynamic>> getVendorEarnings(
    String vendorId,
    String authToken, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final endpoint = '/api/vendor/$vendorId/earnings?$queryString';

    return await _makeRequest('GET', endpoint, authToken: authToken);
  }

  static Future<Map<String, dynamic>> exportVendorData(
    String vendorId,
    String exportType,
    String authToken, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final body = {'exportType': exportType, 'vendorId': vendorId};
    if (startDate != null) body['startDate'] = startDate.toIso8601String();
    if (endDate != null) body['endDate'] = endDate.toIso8601String();

    return await _makeRequest(
      'POST',
      '/api/vendor/$vendorId/export',
      body: body,
      authToken: authToken,
    );
  }

  // Customer Management
  static Future<Map<String, dynamic>> getVendorCustomers(
    String vendorId,
    String authToken, {
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {'page': page.toString(), 'limit': limit.toString()};

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final endpoint = '/api/vendor/$vendorId/customers?$queryString';

    return await _makeRequest('GET', endpoint, authToken: authToken);
  }

  // Notifications
  static Future<Map<String, dynamic>> sendNotification(
    String vendorId,
    Map<String, dynamic> notificationData,
    String authToken,
  ) async {
    return await _makeRequest(
      'POST',
      '/api/vendor/$vendorId/notifications',
      body: notificationData,
      authToken: authToken,
    );
  }

  // Settings and Configuration
  static Future<Map<String, dynamic>> getVendorSettings(
    String vendorId,
    String authToken,
  ) async {
    return await _makeRequest(
      'GET',
      '/api/vendor/$vendorId/settings',
      authToken: authToken,
    );
  }

  static Future<Map<String, dynamic>> updateVendorSettings(
    String vendorId,
    Map<String, dynamic> settings,
    String authToken,
  ) async {
    return await _makeRequest(
      'PUT',
      '/api/vendor/$vendorId/settings',
      body: settings,
      authToken: authToken,
    );
  }
}

// Custom exception for vendor API errors
class VendorApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> errorData;

  VendorApiException({
    required this.message,
    required this.statusCode,
    required this.errorData,
  });

  @override
  String toString() {
    return 'VendorApiException: $message (Status: $statusCode)';
  }
}
