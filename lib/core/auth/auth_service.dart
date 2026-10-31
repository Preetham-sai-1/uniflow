import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../../models/role.dart';
import '../../models/department.dart';
import 'token_storage.dart';

/// Encapsulates authentication result containing the JWT and sanitized user profile.
class AuthResult {
  final String token;
  final UserProfile user;

  const AuthResult({
    required this.token,
    required this.user,
  });
}

/// Service handling communication with the backend authentication endpoints:
/// - POST /api/auth/login
/// - GET /api/auth/me
/// - Session restoration and token lifecycle
class AuthService {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : tokenStorage =
            tokenStorage ?? apiClient?.tokenStorage ?? SecureTokenStorage(),
        apiClient = apiClient ??
            ApiClient(
                tokenStorage: tokenStorage ??
                    (apiClient != null ? apiClient.tokenStorage : SecureTokenStorage()));

  /// Authenticate with the real backend login endpoint.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      requiresAuth: false,
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    await tokenStorage.saveToken(token);

    try {
      UserProfile user;
      try {
        user = await getMe();
      } catch (meError) {
        if (meError is ApiException && meError.code == 'FORBIDDEN') {
          rethrow;
        }
        final userJson = data['user'] as Map<String, dynamic>;
        user = UserProfile.fromJson(userJson);
      }
      return AuthResult(token: token, user: user);
    } catch (e) {
      await tokenStorage.deleteToken();
      rethrow;
    }
  }

  /// Retrieve active user profile from GET /api/auth/me using stored Bearer token.
  Future<UserProfile> getMe() async {
    final response = await apiClient.get(
      ApiEndpoints.me,
      requiresAuth: true,
    );

    final data = response.data as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userJson);
  }

  /// Restores session on application startup.
  /// If token exists, verifies with /api/auth/me.
  /// If token is expired, unauthorized, or invalid role (403), removes token and returns null.
  Future<UserProfile?> restoreSession() async {
    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await getMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized ||
          e.code == 'INVALID_TOKEN' ||
          e.code == 'MISSING_TOKEN' ||
          e.code == 'FORBIDDEN') {
        await tokenStorage.deleteToken();
        return null;
      }
      rethrow;
    } catch (_) {
      await tokenStorage.deleteToken();
      return null;
    }
  }

  /// Check whether a token is stored locally without a network call.
  Future<bool> hasStoredToken() async {
    return await tokenStorage.hasToken();
  }

  /// Register a new student account.
  /// New registrations are assigned 'student' role and created with 'PENDING' status.
  /// Returns registration message on success.
  Future<String> registerStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    String? departmentId,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'studentId': studentId.trim(),
      'role': 'student',
    };
    if (departmentId != null && departmentId.isNotEmpty) {
      body['departmentId'] = departmentId;
    }

    final response = await apiClient.post(
      ApiEndpoints.register,
      body: body,
      requiresAuth: false,
    );

    final data = response.data as Map<String, dynamic>;
    return (data['message'] ??
            'Registration submitted successfully. Your account is pending administrator approval.')
        .toString();
  }

  /// Fetches campus departments from GET /api/departments (public endpoint).
  Future<List<Department>> fetchDepartments() async {
    final response = await apiClient.get(
      ApiEndpoints.departments,
      requiresAuth: false,
    );

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((item) => Department.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Clears stored JWT token on logout.
  Future<void> logout() async {
    await tokenStorage.deleteToken();
  }
}
