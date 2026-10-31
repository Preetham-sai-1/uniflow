import 'package:flutter/foundation.dart';

/// Centralized configuration for UniFlow backend API connections.
class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String? _overrideBaseUrl;

  /// Default development base URL based on platform:
  /// - Web: http://localhost:3001/api
  /// - Android Emulator: http://10.0.2.2:3001/api
  /// - Windows Desktop / iOS / other: http://localhost:3001/api
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3001/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3001/api';
      default:
        return 'http://localhost:3001/api';
    }
  }

  /// Active API base URL. Can be dynamically overridden at runtime.
  static String get baseUrl => _overrideBaseUrl ?? defaultBaseUrl;

  /// Override the API base URL at runtime (e.g. for testing).
  static void setBaseUrl(String url) {
    _overrideBaseUrl =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Reset the runtime override back to default.
  static void reset() {
    _overrideBaseUrl = null;
  }

  /// Standard HTTP request timeout.
  static const Duration timeout = Duration(seconds: 15);
}
