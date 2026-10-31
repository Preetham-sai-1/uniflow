import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';

/// Standard response envelope parser matching backend: { success, data, error }.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final Map<String, dynamic>? pagination;

  const ApiResponse({
    required this.success,
    this.data,
    this.pagination,
  });

  /// Parse an HTTP response into an [ApiResponse] or throw an [ApiException].
  factory ApiResponse.fromHttpResponse(http.Response response) {
    Map<String, dynamic> jsonBody;
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 400) {
        throw ApiException(
          statusCode: response.statusCode,
          code: 'SERVER_ERROR',
          message:
              'Server error (${response.statusCode}): ${response.reasonPhrase ?? 'Unknown error'}',
        );
      }
      throw ApiException(
        statusCode: response.statusCode,
        code: 'PARSE_ERROR',
        message: 'Invalid response format received from server.',
      );
    }

    final success = jsonBody['success'] == true;
    if (!success) {
      final errorMap = jsonBody['error'] as Map<String, dynamic>?;
      final code = errorMap?['code']?.toString() ?? 'UNKNOWN_ERROR';
      final message =
          errorMap?['message']?.toString() ?? 'An unexpected error occurred.';
      final details = errorMap?['details'] as List<dynamic>?;

      throw ApiException(
        statusCode: response.statusCode,
        code: code,
        message: message,
        details: details,
      );
    }

    return ApiResponse(
      success: true,
      data: jsonBody['data'] as T?,
      pagination: jsonBody['pagination'] as Map<String, dynamic>?,
    );
  }
}
