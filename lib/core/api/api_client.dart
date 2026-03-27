import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

/// HTTP client for communicating with the Dailathon CRM backend.
/// 
/// Handles authentication, request building, error handling, and response parsing.
/// Automatically refreshes authentication tokens when needed.
class ApiClient {

  ApiClient({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initializeDio();
  }
  static const String _baseUrl = 'https://api.dailathon.com/v1';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const Duration _requestTimeout = Duration(seconds: 30);

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  /// Current authentication token
  String? _authToken;

  /// Current refresh token
  String? _refreshToken;

  /// Initialize Dio with interceptors and configuration
  void _initializeDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = _requestTimeout;
    _dio.options.receiveTimeout = _requestTimeout;
    _dio.options.sendTimeout = _requestTimeout;

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
        onResponse: _onResponse,
      ),
    );
  }

  /// Pre-request interceptor
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authorization header if token exists
    if (_authToken != null) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }

    // Add common headers
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    developer.log('API Request: ${options.method} ${options.path}');
    handler.next(options);
  }

  /// Post-response interceptor
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    developer.log('API Response: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  /// Error interceptor with token refresh logic
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    developer.log('API Error: ${err.response?.statusCode} - ${err.message}', level: 1000);

    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == 401) {
      try {
        await _refreshAuthToken();
        // Retry original request
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $_authToken';
        final response = await _dio.request(
          options.path,
          options: Options(
            method: options.method,
            headers: options.headers,
          ),
          data: options.data,
          queryParameters: options.queryParameters,
        );
        handler.resolve(response);
        return;
      } catch (e) {
        developer.log('Token refresh failed: $e', level: 1000);
        handler.reject(err);
      }
    }

    handler.reject(err);
  }

  /// Load stored authentication tokens
  Future<void> loadStoredTokens() async {
    try {
      _authToken = await _secureStorage.read(key: _tokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      developer.log('Loaded stored tokens');
    } catch (e) {
      developer.log('Error loading tokens: $e', level: 1000);
    }
  }

  /// Store authentication tokens securely
  Future<void> _storeTokens(String accessToken, String? refreshToken) async {
    try {
      _authToken = accessToken;
      if (refreshToken != null) {
        _refreshToken = refreshToken;
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      await _secureStorage.write(key: _tokenKey, value: accessToken);
      developer.log('Tokens stored securely');
    } catch (e) {
      developer.log('Error storing tokens: $e', level: 1000);
    }
  }

  /// Clear stored authentication tokens
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      _authToken = null;
      _refreshToken = null;
      developer.log('Tokens cleared');
    } catch (e) {
      developer.log('Error clearing tokens: $e', level: 1000);
    }
  }

  /// Authenticate with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _storeTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      developer.log('Login successful for $email');
      return authResponse;
    } on DioException catch (e) {
      developer.log('Login failed: ${e.message}', level: 1000);
      rethrow;
    }
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await clearTokens();
      developer.log('Logout successful');
    } catch (e) {
      developer.log('Logout error (clearing tokens anyway): $e', level: 1000);
      await clearTokens();
    }
  }

  /// Refresh authentication token using refresh token
  Future<void> _refreshAuthToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _storeTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      developer.log('Token refreshed successfully');
    } on DioException catch (e) {
      developer.log('Token refresh failed: ${e.message}', level: 1000);
      await clearTokens();
      rethrow;
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<void> delete(String endpoint) async {
    try {
      await _dio.delete(endpoint);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Parse response and handle errors
  Map<String, dynamic> _parseResponse(Response response) {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      throw ApiException(
        statusCode: response.statusCode ?? 0,
        message: response.data?['message'] ?? 'Unknown error',
      );
    }

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data != null) {
      return {'data': response.data};
    } else {
      return {};
    }
  }

  /// Convert DioException to ApiException
  ApiException _handleError(DioException e) {
    var message = 'Network error';
    var statusCode = 0;

    if (e.response != null) {
      statusCode = e.response!.statusCode ?? 0;
      message = e.response!.data?['message'] ?? e.message ?? 'Server error';
    } else {
      message = e.message ?? 'Network error';
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      originalError: e,
    );
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null;

  /// Get current auth token
  String? get token => _authToken;
}

/// Authentication response model
class AuthResponse {

  AuthResponse({
    required this.accessToken,
    required this.expiresAt, this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: json['user'] as Map<String, dynamic>?,
    );
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final Map<String, dynamic>? user;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'user': user,
      };
}

/// Custom exception for API errors
class ApiException implements Exception {

  ApiException({
    required this.statusCode,
    required this.message,
    this.originalError,
  });
  final int statusCode;
  final String message;
  final DioException? originalError;

  @override
  String toString() => 'ApiException ($statusCode): $message';
}
