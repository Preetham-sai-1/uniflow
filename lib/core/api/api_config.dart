import 'package:flutter/foundation.dart';

/// Centralized configuration for UniFlow backend API connections.
class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String? _overrideBaseUrl;

  /// Default development base URL based on platform:
  /// - Web: http://localhost:3001/api
  /// - Android Emulator: http://10.0.2.2:3001/api
  /// - Windows Desktop / iOS / other: http://localhost:3001/api
  ///
  /// In release mode, returns empty string if API_BASE_URL was not supplied,
  /// preventing production builds from silently defaulting to local development addresses.
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    // Production builds must never default to localhost, 127.0.0.1, 10.0.2.2, or LAN addresses
    if (kReleaseMode) {
      return '';
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

  /// Validates whether the active base URL satisfies production security standards.
  /// When in release mode, enforces that the URL uses HTTPS and does not point
  /// to loopback (localhost, 127.0.0.1, 10.0.2.2) or local LAN addresses.
  static bool get isSecureProductionUrl {
    if (!kReleaseMode) return true;
    final url = baseUrl.toLowerCase().trim();
    if (url.isEmpty || !url.startsWith('https://')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.16.')) {
      return false;
    }
    return true;
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
