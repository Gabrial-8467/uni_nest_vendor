import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/vendor_config.dart';
import '../models/auth_models.dart';

/// API Exception class
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Token storage utility class
class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'vendor_access_token';
  static const _refreshTokenKey = 'vendor_refresh_token';
  static const _userKey = 'vendor_user';

  /// Save access and refresh tokens
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save user data
  static Future<void> saveUser(VendorProfile user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Get user data
  static Future<VendorProfile?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return VendorProfile.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all authentication data
  static Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}

/// API Client class with Dio HTTP clients
class ApiClient {
  final FlutterSecureStorage _storage;
  late final Dio _dio;
  late final Dio _publicDio;

  /// Constructor initializes Dio clients
  ApiClient(this._storage) {
    _dio = _createDioInstance();
    _publicDio = _createDioInstance();

    // Add auth interceptor to authenticated client
    _dio.interceptors.add(AuthInterceptor(_storage));
  }

  /// Authenticated Dio client
  Dio get dio => _dio;

  /// Public Dio client (no authentication)
  Dio get publicDio => _publicDio;

  Dio _createDioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: VendorConfig.apiBaseUrl,
        connectTimeout: VendorConfig.connectionTimeout,
        receiveTimeout: VendorConfig.connectionTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor in debug mode
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );

    return dio;
  }

  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    bool usePublicClient = false,
  }) async {
    try {
      final dio = usePublicClient ? _publicDio : _dio;
      final response = await dio.get<T>(path, queryParameters: queryParameters);

      if (fromJson != null && response.data != null) {
        return Response<T>(
          data: fromJson(response.data),
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          extra: response.extra,
        );
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    bool usePublicClient = false,
  }) async {
    try {
      final dio = usePublicClient ? _publicDio : _dio;
      final response = await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null && response.data != null) {
        return Response<T>(
          data: fromJson(response.data),
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          extra: response.extra,
        );
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    bool usePublicClient = false,
  }) async {
    try {
      final dio = usePublicClient ? _publicDio : _dio;
      final response = await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null && response.data != null) {
        return Response<T>(
          data: fromJson(response.data),
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          extra: response.extra,
        );
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    bool usePublicClient = false,
  }) async {
    try {
      final dio = usePublicClient ? _publicDio : _dio;
      final response = await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null && response.data != null) {
        return Response<T>(
          data: fromJson(response.data),
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          extra: response.extra,
        );
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio exceptions and convert to ApiException
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Request timeout', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?['message'] ??
            error.response?.data?['error'] ??
            error.response?.statusMessage ??
            'Request failed';
        return ApiException(message.toString(), statusCode: statusCode);
      case DioExceptionType.cancel:
        return const ApiException('Request cancelled', statusCode: 499);
      case DioExceptionType.connectionError:
        return const ApiException('Connection error', statusCode: 503);
      case DioExceptionType.unknown:
      default:
        return ApiException('Network error: ${error.message}', statusCode: 500);
    }
  }
}

/// Auth interceptor for adding tokens to requests
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/forgot-password')) {
      handler.next(options);
      return;
    }

    final token = await _storage.read(key: 'vendor_access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Clear auth data on 401 error
      await TokenStorage.clearAuth();
    }
    handler.next(err);
  }
}

/// Provider for API client
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = FlutterSecureStorage();
  return ApiClient(storage);
});
