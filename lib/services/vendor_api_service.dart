import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_endpoints.dart';
import '../config/vendor_config.dart';
import '../models/vendor_models.dart';
import '../utils/secure_logger.dart';
import 'image_upload_service.dart';

class AuthTokenStorage {
  static Future<void> saveTokens({
    required String authToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(VendorConfig.tokenKey, authToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(VendorConfig.refreshTokenKey, refreshToken);
    }
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(VendorConfig.tokenKey);
  }

  static Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(VendorConfig.tokenKey);
    await prefs.remove(VendorConfig.refreshTokenKey);
    await prefs.remove(VendorConfig.vendorKey);
    await prefs.remove(VendorConfig.settingsKey);
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  final http.Client _httpClient = http.Client();

  String get _baseUrl => ApiEndpoints.baseUrl;

  Duration get _timeout => VendorConfig.connectionTimeout;

  int get _maxRetries => VendorConfig.maxRetries;

  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    String? authTokenOverride,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      ApiHeaders.contentType: ApiHeaders.applicationJson,
      ApiHeaders.accept: ApiHeaders.applicationJson,
      ApiHeaders.userAgent: 'VendorApp/1.0',
      ...?extraHeaders,
    };

    if (!requiresAuth) {
      return headers;
    }

    final token = authTokenOverride ?? await AuthTokenStorage.getAuthToken();
    if (token == null || token.isEmpty) {
      SecureLogger.error(
        'Blocked authenticated API call because auth token is missing',
        tag: 'API_AUTH',
      );
      throw VendorApiException(
        message: 'Authentication token is missing. Please login again.',
        statusCode: ApiStatusCodes.unauthorized,
        errorData: {'reason': 'token_missing'},
      );
    }

    headers[ApiHeaders.authorization] = 'Bearer $token';
    return headers;
  }

  Future<Map<String, dynamic>> request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    String? authTokenOverride,
    Duration? timeout,
    int? maxRetries,
  }) async {
    final url = '$_baseUrl$endpoint';
    final requestTimeout = timeout ?? _timeout;
    final retries = maxRetries ?? _maxRetries;

    int attempts = 0;
    while (attempts < retries) {
      attempts++;
      try {
        final headers = await _buildHeaders(
          requiresAuth: requiresAuth,
          authTokenOverride: authTokenOverride,
        );

        SecureLogger.logRequest(method, url, body: body);

        final response = await _send(
          method: method,
          url: url,
          headers: headers,
          body: body,
          timeout: requestTimeout,
        );

        SecureLogger.logResponse(response.statusCode, url, body: response.body);
        return await _handleResponse(response);
      } on VendorApiException {
        rethrow;
      } on TimeoutException catch (e) {
        SecureLogger.error(
          'Timeout on attempt $attempts for $method $url',
          error: e,
          tag: 'API',
        );

        if (attempts >= retries) {
          throw VendorApiException(
            message: 'Request timed out. Please try again.',
            statusCode: -1,
            errorData: {'reason': 'timeout'},
          );
        }
      } catch (e) {
        SecureLogger.error(
          'Request attempt $attempts failed for $method $url',
          error: e,
          tag: 'API',
        );

        if (attempts >= retries) {
          throw VendorApiException(
            message: 'Network error: $e',
            statusCode: -1,
            errorData: {'reason': 'network_error', 'details': e.toString()},
          );
        }

        await Future.delayed(Duration(milliseconds: 250 * attempts * attempts));
      }
    }

    throw VendorApiException(
      message: 'Max retry attempts exceeded',
      statusCode: -1,
      errorData: {'reason': 'max_retries_exceeded'},
    );
  }

  Future<http.Response> _send({
    required String method,
    required String url,
    required Map<String, String> headers,
    required Duration timeout,
    Map<String, dynamic>? body,
  }) {
    final uri = Uri.parse(url);
    final normalizedMethod = method.toUpperCase();

    switch (normalizedMethod) {
      case ApiMethods.get:
        return _httpClient.get(uri, headers: headers).timeout(timeout);
      case ApiMethods.post:
        return _httpClient
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout);
      case ApiMethods.put:
        return _httpClient
            .put(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout);
      case ApiMethods.delete:
        return _httpClient.delete(uri, headers: headers).timeout(timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final data = _decodeResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == ApiStatusCodes.unauthorized) {
      await AuthTokenStorage.clearSessionData();
      SecureLogger.warning(
        'Received 401 Unauthorized. Cleared local auth/session data.',
        tag: 'API_AUTH',
      );
    }

    throw VendorApiException(
      message: data['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
      errorData: data,
    );
  }

  Map<String, dynamic> _decodeResponseBody(String rawBody) {
    if (rawBody.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{'message': rawBody};
    }
  }
}

class VendorApiService {
  static final ApiClient _apiClient = ApiClient();

  static Future<void> saveAuthTokens({
    required String authToken,
    String? refreshToken,
  }) async {
    await AuthTokenStorage.saveTokens(
      authToken: authToken,
      refreshToken: refreshToken,
    );
  }

  static Future<String?> getAuthToken() async {
    return AuthTokenStorage.getAuthToken();
  }

  static Future<void> clearAuthSession() async {
    await AuthTokenStorage.clearSessionData();
  }

  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    String? authTokenOverride,
    Duration? timeout,
    int? maxRetries,
  }) {
    return _apiClient.request(
      method: method,
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
      authTokenOverride: authTokenOverride,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  static Future<Map<String, dynamic>> loginVendor(
    String email,
    String password,
  ) {
    return _makeRequest(
      ApiMethods.post,
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> registerVendor(
    Map<String, dynamic> vendorData,
  ) {
    final data = Map<String, dynamic>.from(vendorData);
    data['role'] = 'vendor';

    return _makeRequest(
      ApiMethods.post,
      ApiEndpoints.register,
      body: data,
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) {
    return Future.value(<String, dynamic>{
      'success': false,
      'message': 'Refresh token endpoint is not available on the current backend.',
    });
  }

  static Future<Map<String, dynamic>> logoutVendor([String? authToken]) {
    return Future.value(<String, dynamic>{'success': true});
  }

  static Future<Map<String, dynamic>> changePassword(
    String authToken,
    String currentPassword,
    String newPassword,
  ) {
    return _makeRequest(
      ApiMethods.post,
      ApiEndpoints.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      authTokenOverride: authToken,
    );
  }

  static Future<Vendor> getVendorProfile(String authToken) async {
    final response = await _makeRequest(
      ApiMethods.get,
      ApiEndpoints.profile,
      authTokenOverride: authToken,
    );
    return Vendor.fromJson(response['data']);
  }

  static Future<Vendor> updateVendorProfile(
    Map<String, dynamic> profileData,
    String authToken,
  ) async {
    final response = await _makeRequest(
      ApiMethods.put,
      ApiEndpoints.profile,
      body: profileData,
      authTokenOverride: authToken,
    );

    return Vendor.fromJson(response['data']);
  }

  static Future<Map<String, dynamic>> uploadVendorImage(
    File imageFile,
    String authToken,
  ) async {
    try {
      final result = await ImageUploadService.uploadSingleImage(
        imageFile,
        authToken: authToken,
        baseUrl: _apiClient._baseUrl,
        endpoint: ApiEndpoints.uploadAvatar,
      );

      if (result.success) {
        return {
          'success': true,
          'data': {'url': result.imageUrl},
          'message': 'Image uploaded successfully',
        };
      } else {
        return {'success': false, 'message': result.error ?? 'Upload failed'};
      }
    } catch (e) {
      SecureLogger.error('Vendor image upload failed', error: e);
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  static Future<List<Product>> getVendorProducts(String authToken) async {
    final response = await _makeRequest(
      ApiMethods.get,
      ApiEndpoints.products,
      authTokenOverride: authToken,
    );
    final rawData = response['data'];

    List<dynamic> rawProducts;
    if (rawData is List) {
      rawProducts = rawData;
    } else if (rawData is Map<String, dynamic>) {
      final nestedProducts =
          rawData['products'] ?? rawData['items'] ?? rawData['results'];
      rawProducts = nestedProducts is List ? nestedProducts : <dynamic>[];
    } else {
      rawProducts = <dynamic>[];
    }

    return rawProducts
        .whereType<Map>()
        .map((product) => Product.fromJson(Map<String, dynamic>.from(product)))
        .toList();
  }

  static Future<Product> createProduct(
    Map<String, dynamic> productData,
    String authToken,
  ) async {
    final response = await _makeRequest(
      ApiMethods.post,
      ApiEndpoints.products,
      body: productData,
      authTokenOverride: authToken,
    );

    return Product.fromJson(response['data']);
  }

  static Future<Product> createProductWithImages(
    Map<String, dynamic> productData,
    List<File> imageFiles,
    String authToken,
  ) async {
    final uri = Uri.parse('${_apiClient._baseUrl}${ApiEndpoints.products}');
    final request = http.MultipartRequest('POST', uri);
    request.headers[ApiHeaders.authorization] = 'Bearer $authToken';
    request.headers[ApiHeaders.accept] = ApiHeaders.applicationJson;

    productData.forEach((key, value) {
      if (value == null) return;
      if (value is List || value is Map<String, dynamic>) {
        request.fields[key] = jsonEncode(value);
      } else {
        request.fields[key] = value.toString();
      }
    });

    for (final file in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }

    SecureLogger.info(
      'Creating product with multipart upload: ${request.files.length} image(s)',
      tag: 'PRODUCTS',
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _apiClient._decodeResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return Product.fromJson(payload);
      }
      return Product.fromJson(Map<String, dynamic>.from(data));
    }

    throw VendorApiException(
      message: data['message']?.toString() ?? 'Product creation failed',
      statusCode: response.statusCode,
      errorData: data,
    );
  }

  static Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> productData,
    String authToken, {
    List<File>? imageFiles,
  }) async {
    final uri = Uri.parse(
      '${_apiClient._baseUrl}${ApiEndpoints.productById(productId)}',
    );

    // DEBUG: Print request details
    SecureLogger.info('=== UPDATE PRODUCT DEBUG ===', tag: 'PRODUCTS');
    SecureLogger.info('URL: $uri', tag: 'PRODUCTS');
    SecureLogger.info('Method: PUT', tag: 'PRODUCTS');
    SecureLogger.info(
      'Image files count: ${imageFiles?.length ?? 0}',
      tag: 'PRODUCTS',
    );

    // Check if we have files to upload - use multipart
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final request = http.MultipartRequest('PUT', uri);

      // Set headers correctly - NO Content-Type override for multipart
      request.headers['Authorization'] = 'Bearer $authToken';
      request.headers['Accept'] = 'application/json';

      // Add all non-null fields as strings (per backend contract)
      productData.forEach((key, value) {
        if (value != null) {
          if (value is List || value is Map) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
          SecureLogger.info(
            'Field: $key = ${value.toString()}',
            tag: 'PRODUCTS',
          );
        }
      });

      // Attach files with EXACT field name 'images'
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileSize = await file.length();
        final fileNumber = i + 1;
        SecureLogger.info(
          'Attaching file $fileNumber: ${file.path} ($fileSize bytes)',
          tag: 'PRODUCTS',
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // EXACT field name required by backend
            file.path,
          ),
        );
      }

      // DEBUG: Print final request details
      SecureLogger.info('Request headers: ${request.headers}', tag: 'PRODUCTS');
      SecureLogger.info(
        'Request fields count: ${request.fields.length}',
        tag: 'PRODUCTS',
      );
      SecureLogger.info(
        'Request files count: ${request.files.length}',
        tag: 'PRODUCTS',
      );
      SecureLogger.info(
        'Request file field names: ${request.files.map((f) => f.field).toList()}',
        tag: 'PRODUCTS',
      );

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        // DEBUG: Print response details
        SecureLogger.info(
          'Response status: ${response.statusCode}',
          tag: 'PRODUCTS',
        );
        SecureLogger.info('Response body: ${response.body}', tag: 'PRODUCTS');

        final data = _apiClient._decodeResponseBody(response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final payload = data['data'];
          final productJson = payload is Map<String, dynamic>
              ? payload
              : Map<String, dynamic>.from(data);
          final updatedProduct = Product.fromJson(productJson);

          SecureLogger.info(
            'Product updated successfully with ${imageFiles.length} images',
            tag: 'PRODUCTS',
          );
          SecureLogger.info(
            'Updated product images: ${updatedProduct.images}',
            tag: 'PRODUCTS',
          );

          return updatedProduct;
        }

        throw VendorApiException(
          message: data['message']?.toString() ?? 'Product update failed',
          statusCode: response.statusCode,
          errorData: data,
        );
      } catch (e) {
        SecureLogger.error(
          'Multipart product update failed',
          error: e,
          tag: 'PRODUCTS',
        );
        rethrow;
      }
    } else {
      // Fallback to regular JSON update if no files
      SecureLogger.info(
        'No files provided, using JSON update',
        tag: 'PRODUCTS',
      );

      final response = await _makeRequest(
        ApiMethods.put,
        ApiEndpoints.productById(productId),
        body: productData,
        authTokenOverride: authToken,
      );

      final payload = response['data'];
      final productJson = payload is Map<String, dynamic>
          ? payload
          : Map<String, dynamic>.from(response);
      final updatedProduct = Product.fromJson(productJson);

      SecureLogger.info(
        'Product updated successfully (JSON only)',
        tag: 'PRODUCTS',
      );

      return updatedProduct;
    }
  }

  static Future<bool> deleteProduct(String productId, String authToken) async {
    await _makeRequest(
      ApiMethods.delete,
      ApiEndpoints.productById(productId),
      authTokenOverride: authToken,
    );
    return true;
  }

  static Future<Map<String, dynamic>> uploadProductImages(
    String vendorId,
    String productId,
    List<File> imageFiles,
    String authToken,
  ) async {
    try {
      final results = await ImageUploadService.uploadImages(
        imageFiles,
        authToken: authToken,
        baseUrl: _apiClient._baseUrl,
        endpoint: '/$vendorId/products/$productId/upload-images',
      );

      final successfulUploads = results.where((r) => r.success).toList();
      final failedUploads = results.where((r) => !r.success).toList();

      if (successfulUploads.isEmpty) {
        return {
          'success': false,
          'message': 'All uploads failed',
          'errors': failedUploads.map((r) => r.error).toList(),
        };
      }

      return {
        'success': true,
        'data': {
          'uploadedImages': successfulUploads.map((r) => r.imageUrl).toList(),
          'failedCount': failedUploads.length,
        },
        'message': '${successfulUploads.length} images uploaded successfully',
      };
    } catch (e) {
      SecureLogger.error('Product images upload failed', error: e);
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  static Future<List<Order>> getVendorOrders(
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

    if (status != null) {
      queryParams['status'] = status;
    }
    if (startDate != null) {
      queryParams['dateFrom'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['dateTo'] = endDate.toIso8601String();
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '${ApiEndpoints.orders}?$queryString';

    final response = await _makeRequest(
      ApiMethods.get,
      endpoint,
      authTokenOverride: authToken,
    );
    final rawData = response['data'];

    List<dynamic> rawOrders;
    if (rawData is List) {
      rawOrders = rawData;
    } else if (rawData is Map<String, dynamic>) {
      final nestedOrders =
          rawData['orders'] ?? rawData['items'] ?? rawData['results'];
      rawOrders = nestedOrders is List ? nestedOrders : <dynamic>[];
    } else {
      rawOrders = <dynamic>[];
    }

    return rawOrders
        .whereType<Map>()
        .map((order) => Order.fromJson(Map<String, dynamic>.from(order)))
        .toList();
  }

  static Future<Order> getOrderDetails(String orderId, String authToken) async {
    final response = await _makeRequest(
      ApiMethods.get,
      ApiEndpoints.orderById(orderId),
      authTokenOverride: authToken,
    );

    return Order.fromJson(Map<String, dynamic>.from(response['data'] ?? {}));
  }

  static Future<Order> updateOrderStatus(
    String orderId,
    String status,
    String authToken, {
    String? notes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null) {
      body['note'] = notes;
    }

    final response = await _makeRequest(
      ApiMethods.put,
      ApiEndpoints.updateOrderStatus(orderId),
      body: body,
      authTokenOverride: authToken,
    );

    final payload = response['data'];
    final orderJson = payload is Map<String, dynamic>
        ? (payload['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['order'])
              : payload)
        : <String, dynamic>{};
    return Order.fromJson(orderJson);
  }

  static Future<VendorAnalytics> getVendorAnalytics(
    String authToken, {
    DateTime? startDate,
    DateTime? endDate,
    String? period,
  }) async {
    final queryParams = <String, String>{};
    if (period != null) {
      queryParams['period'] = period;
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.analytics
        : '${ApiEndpoints.analytics}?$queryString';

    final response = await _makeRequest(
      ApiMethods.get,
      endpoint,
      authTokenOverride: authToken,
    );
    final rawData = response['data'];
    if (rawData is! Map<String, dynamic>) {
      return VendorAnalytics.fromJson(<String, dynamic>{});
    }

    final overview = rawData['overview'];
    final normalized = <String, dynamic>{
      ...rawData,
      ...(overview is Map ? Map<String, dynamic>.from(overview) : {}),
    };

    return VendorAnalytics.fromJson(normalized);
  }

  static Future<Map<String, dynamic>> getVendorEarnings(
    String authToken, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _makeRequest(
        ApiMethods.get,
        ApiEndpoints.dashboard,
        authTokenOverride: authToken,
      );
      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final overview = rawData['overview'];
        if (overview is Map<String, dynamic>) {
          final totalRevenue = overview['totalRevenue'] ?? 0;
          return {
            ...overview,
            'total': totalRevenue,
            'totalRevenue': totalRevenue,
          };
        }
      }
      return <String, dynamic>{};
    } on VendorApiException catch (e) {
      if (e.statusCode == ApiStatusCodes.notFound) {
        SecureLogger.warning('Earnings endpoint unavailable, using defaults');
        return <String, dynamic>{};
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getVendorDashboard(String authToken) {
    return _makeRequest(
      ApiMethods.get,
      ApiEndpoints.dashboard,
      authTokenOverride: authToken,
    );
  }

  static Future<VendorLedger> getVendorLedger(String authToken) async {
    final response = await _makeRequest(
      ApiMethods.get,
      ApiEndpoints.ledger,
      authTokenOverride: authToken,
    );
    return VendorLedger.fromJson(
      Map<String, dynamic>.from(response['data'] ?? {}),
    );
  }

  static Future<List<VendorPayout>> getVendorPayouts(String authToken) async {
    final response = await _makeRequest(
      ApiMethods.get,
      ApiEndpoints.payouts,
      authTokenOverride: authToken,
    );
    final rawData = response['data'];
    final rawList = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
        ? (rawData['payouts'] is List ? rawData['payouts'] : <dynamic>[])
        : <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((item) => VendorPayout.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<Map<String, dynamic>> exportVendorData(
    String vendorId,
    String exportType,
    String authToken, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final body = <String, dynamic>{
      'exportType': exportType,
      'vendorId': vendorId,
    };

    if (startDate != null) {
      body['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      body['endDate'] = endDate.toIso8601String();
    }

    return _makeRequest(ApiMethods.post, '/$vendorId/export', body: body);
  }

  static Future<Map<String, dynamic>> getVendorCustomers(
    String vendorId,
    String authToken, {
    int page = 1,
    int limit = 20,
  }) {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    final endpoint = '/$vendorId/customers?$queryString';

    return _makeRequest(ApiMethods.get, endpoint);
  }

  static Future<Map<String, dynamic>> getNotifications(
    String authToken, {
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) {
      queryParams['read'] = (status == NotificationStatus.read).toString();
    }
    if (type != null) {
      queryParams['type'] = type;
    }

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    final endpoint = '${ApiEndpoints.notifications}?$queryString';

    return _makeRequest(
      ApiMethods.get,
      endpoint,
      authTokenOverride: authToken,
    );
  }

  static Future<Map<String, dynamic>> getNotificationById(
    String notificationId,
    String authToken,
  ) {
    return _makeRequest(
      ApiMethods.get,
      ApiEndpoints.notificationById(notificationId),
      authTokenOverride: authToken,
    );
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
    String notificationId,
    String authToken,
  ) {
    return _makeRequest(
      ApiMethods.put,
      ApiEndpoints.markNotificationRead(notificationId),
      authTokenOverride: authToken,
    );
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead(
    String authToken,
  ) {
    return _makeRequest(
      ApiMethods.put,
      ApiEndpoints.markAllNotificationsRead,
      authTokenOverride: authToken,
    );
  }

  static Future<Map<String, dynamic>> getNotificationSettings(
    String authToken,
  ) {
    return Future.value(<String, dynamic>{});
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, dynamic> settings,
    String authToken,
  ) {
    return Future.value(<String, dynamic>{'success': true, 'data': settings});
  }

  static Future<Map<String, dynamic>> sendNotification(
    Map<String, dynamic> notificationData,
    String authToken,
  ) {
    return Future.value(<String, dynamic>{
      'success': false,
      'message': 'Vendor notification send endpoint is not available.',
    });
  }

  static Future<Map<String, dynamic>> deleteNotification(
    String notificationId,
    String authToken,
  ) {
    return Future.value(<String, dynamic>{
      'success': false,
      'message': 'Delete notification endpoint is not available.',
    });
  }

  static Future<Map<String, dynamic>> clearAllNotifications(String authToken) {
    return _makeRequest(
      ApiMethods.delete,
      ApiEndpoints.clearAllNotifications,
      authTokenOverride: authToken,
    );
  }

  static Future<Map<String, dynamic>> sendNotificationLegacy(
    String vendorId,
    Map<String, dynamic> notificationData,
    String authToken,
  ) {
    return _makeRequest(
      ApiMethods.post,
      '/$vendorId/notifications',
      body: notificationData,
    );
  }

  static Future<Map<String, dynamic>> getVendorSettings(String authToken) {
    return Future.value(<String, dynamic>{});
  }

  static Future<Map<String, dynamic>> updateVendorSettings(
    Map<String, dynamic> settings,
    String authToken,
  ) {
    return Future.value(<String, dynamic>{'success': true, 'data': settings});
  }
}

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
