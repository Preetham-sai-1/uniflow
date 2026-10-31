import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/admin_stats.dart';
import '../../models/journey_request.dart';
import '../../models/pending_user.dart';

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
}
