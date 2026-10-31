import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/token_storage.dart';
import 'api_config.dart';
import 'api_exceptions.dart';
import 'api_response.dart';

/// Reusable HTTP client supporting JSON serialization, Bearer token injection,
/// timeouts, and consistent error normalization.
class ApiClient {
  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  final String? _customBaseUrl;

  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _customBaseUrl = baseUrl;

  String get baseUrl => _customBaseUrl ?? ApiConfig.baseUrl;
  TokenStorage get tokenStorage => _tokenStorage;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    if (kReleaseMode && baseUrl.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        code: 'CONFIG_ERROR',
        message:
            'Production configuration error: API_BASE_URL is not configured. '
            'Please build with --dart-define=API_BASE_URL=https://...',
      );
    }
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sanitizedParams = queryParameters
          .map((key, value) => MapEntry(key, value?.toString() ?? ''));
      return Uri.parse(fullUrl).replace(queryParameters: sanitizedParams);
    }
    return Uri.parse(fullUrl);
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw const ApiException(
          statusCode: 401,
          code: 'AUTH_REQUIRED',
          message: 'Authentication required. No session token found.',
        );
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(() async {
      final uri = _buildUri(path, queryParameters);
      final reqHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );
      return await _httpClient.get(uri, headers: reqHeaders);
    });
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    return _sendRequest(() async {
      final uri = _buildUri(path);
      final reqHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );
      final encodedBody = body != null ? jsonEncode(body) : null;
      return await _httpClient.post(uri,
          headers: reqHeaders, body: encodedBody);
    });
  }

  Future<ApiResponse<dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(() async {
      final uri = _buildUri(path);
      final reqHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );
      final encodedBody = body != null ? jsonEncode(body) : null;
      return await _httpClient.patch(uri,
          headers: reqHeaders, body: encodedBody);
    });
  }

  Future<ApiResponse<dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(() async {
      final uri = _buildUri(path);
      final reqHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );
      return await _httpClient.delete(uri, headers: reqHeaders);
    });
  }

  Future<ApiResponse<dynamic>> _sendRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(ApiConfig.timeout);
      return ApiResponse.fromHttpResponse(response);
    } on TimeoutException {
      throw const ApiTimeoutException();
    } on http.ClientException catch (e) {
      throw NetworkException(originalError: e);
    } on ApiException {
      rethrow;
    } catch (e) {
      final errString = e.toString().toLowerCase();
      if (errString.contains('socket') ||
          errString.contains('connection refused') ||
          errString.contains('failed host lookup') ||
          errString.contains('network') ||
          errString.contains('xmlhttprequest error') ||
          errString.contains('clientexception')) {
        throw NetworkException(originalError: e);
      }
      rethrow;
    }
  }

  void close() {
    _httpClient.close();
  }
}
