/// Structured exception representing API error responses from the backend.
/// Strictly conforms to docs/API_CONTRACT.md section 5 error envelope format.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final List<dynamic>? details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => code == 'VALIDATION_ERROR';

  @override
  String toString() => 'ApiException [$statusCode $code]: $message';
}

/// Thrown when device has no network connectivity or the UniFlow server cannot be reached.
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;

  const NetworkException({
    this.message =
        'Unable to reach the UniFlow server. Please check your connection and ensure the backend is running.',
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when an HTTP request exceeds the maximum configured timeout duration.
class ApiTimeoutException implements Exception {
  final String message;

  const ApiTimeoutException({
    this.message =
        'Connection timed out. The UniFlow server took too long to respond.',
  });

  @override
  String toString() => 'ApiTimeoutException: $message';
}
