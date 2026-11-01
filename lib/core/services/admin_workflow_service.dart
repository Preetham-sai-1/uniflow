import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/admin_stats.dart';
import '../../models/journey_request.dart';
import '../../models/managed_user.dart';
import '../../models/pending_user.dart';

class AdminUsersResult {
  final List<ManagedUser> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  const AdminUsersResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });
}

class AdminRequestsResult {
  final List<JourneyRequest> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  const AdminRequestsResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });
}

/// Service handling administrator statistics and institutional request oversight
/// communicating with Node.js/Express backend API contracts.
class AdminWorkflowService {
  final ApiClient apiClient;

  AdminWorkflowService({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  /// Fetches campus-wide administrative summary statistics from GET /api/admin/stats.
  /// Requires authenticated session with admin role.
  Future<AdminStats> fetchAdminStats() async {
    final response = await apiClient.get(
      ApiEndpoints.adminStats,
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return AdminStats.fromJson(response.data as Map<String, dynamic>);
    }
    return const AdminStats();
  }

  /// Lists all institutional requests with filters from GET /api/admin/requests.
  /// Requires authenticated session with admin role.
  Future<AdminRequestsResult> fetchAdminRequests({
    String? status,
    String? serviceId,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty && status != 'All') {
      query['status'] = status;
    }
    if (serviceId != null && serviceId.isNotEmpty && serviceId != 'All') {
      query['serviceId'] = serviceId;
    }

    final response = await apiClient.get(
      ApiEndpoints.adminRequests,
      queryParameters: query,
      requiresAuth: true,
    );

    List<JourneyRequest> requests = [];
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      requests = list
          .map((item) => JourneyRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    int total = requests.length;
    int pages = 1;
    int currentPage = page;
    if (response.pagination != null) {
      total = response.pagination!['total'] as int? ?? total;
      pages = response.pagination!['pages'] as int? ?? pages;
      currentPage = response.pagination!['page'] as int? ?? currentPage;
    }

    return AdminRequestsResult(
      items: requests,
      total: total,
      page: currentPage,
      limit: limit,
      pages: pages,
    );
  }

  /// Lists all pending student registrations awaiting administrator review.
  /// Calls GET /api/admin/pending-users.
  Future<List<PendingUser>> fetchPendingUsers() async {
    final response = await apiClient.get(
      ApiEndpoints.adminPendingUsers,
      requiresAuth: true,
    );

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((item) => PendingUser.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Approves a pending student registration.
  /// Calls PATCH /api/admin/users/:id/approve.
  Future<void> approveUser(String userId) async {
    await apiClient.patch(
      ApiEndpoints.approveUser(userId),
      requiresAuth: true,
    );
  }

  /// Rejects a pending student registration with an optional reason.
  /// Calls PATCH /api/admin/users/:id/reject.
  Future<void> rejectUser(String userId, {String? reason}) async {
    await apiClient.patch(
      ApiEndpoints.rejectUser(userId),
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      requiresAuth: true,
    );
  }

  /// Lists all users with optional role, approval status, and search filters.
  /// Calls GET /api/admin/users.
  Future<AdminUsersResult> fetchUsers({
    String? role,
    String? approvalStatus,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (role != null && role.isNotEmpty && role != 'All') {
      query['role'] = role.toLowerCase();
    }
    if (approvalStatus != null && approvalStatus.isNotEmpty && approvalStatus != 'All') {
      query['approvalStatus'] = approvalStatus.toUpperCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await apiClient.get(
      ApiEndpoints.adminUsers,
      queryParameters: query,
      requiresAuth: true,
    );

    List<ManagedUser> users = [];
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      users = list
          .map((item) => ManagedUser.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    int total = users.length;
    int pages = 1;
    int currentPage = page;
    if (response.pagination != null) {
      total = response.pagination!['total'] as int? ?? total;
      pages = response.pagination!['pages'] as int? ?? pages;
      currentPage = response.pagination!['page'] as int? ?? currentPage;
    }

    return AdminUsersResult(
      items: users,
      total: total,
      page: currentPage,
      limit: limit,
      pages: pages,
    );
  }

  /// Administratively creates a student or staff account.
  /// Calls POST /api/admin/users.
  Future<ManagedUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    String? studentId,
    String? staffId,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'role': role.toLowerCase().trim(),
    };
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      body['department'] = departmentId.trim();
    }
    if (studentId != null && studentId.trim().isNotEmpty) {
      body['studentId'] = studentId.trim();
    }
    if (staffId != null && staffId.trim().isNotEmpty) {
      body['staffId'] = staffId.trim();
    }

    final response = await apiClient.post(
      ApiEndpoints.adminUsers,
      body: body,
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return ManagedUser.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Invalid user response payload from server.');
  }

  /// Changes a user's role between student and staff.
  /// Calls PATCH /api/admin/users/:id/role.
  Future<ManagedUser> changeUserRole({
    required String userId,
    required String newRole,
    String? studentId,
    String? staffId,
    String? departmentId,
  }) async {
    final body = <String, dynamic>{
      'role': newRole.toLowerCase().trim(),
    };
    if (studentId != null) body['studentId'] = studentId.trim();
    if (staffId != null) body['staffId'] = staffId.trim();
    if (departmentId != null) body['department'] = departmentId.trim();

    final response = await apiClient.patch(
      ApiEndpoints.adminUserRole(userId),
      body: body,
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return ManagedUser.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Invalid user response payload from server.');
  }

  /// Permanently deletes an account.
  /// Calls DELETE /api/admin/users/:id.
  Future<void> deleteUser(String userId) async {
    await apiClient.delete(
      ApiEndpoints.adminDeleteUser(userId),
      requiresAuth: true,
    );
  }
}
