import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../../models/journey_request.dart';
import '../../models/managed_user.dart';
import '../../models/pending_user.dart';
import 'admin_workflow_service.dart';

/// Service handling staff queue retrieval and request actioning (approval/rejection)
/// communicating with Node.js/Express backend API contracts.
class StaffWorkflowService {
  final ApiClient apiClient;

  StaffWorkflowService({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  /// Fetches pending requests in the review queue from GET /api/staff/queue.
  /// Requires authenticated session with staff or admin role.
  Future<List<JourneyRequest>> fetchStaffQueue({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.staffQueue,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      requiresAuth: true,
    );

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((item) =>
              JourneyRequest.fromStaffQueueJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Approves a pending workflow step at [stepIndex] for request [requestId].
  /// Calls PATCH /api/staff/requests/:id/steps/:stepIndex/approve.
  /// Returns the authoritative updated request with populated fields.
  Future<JourneyRequest> approveStep({
    required String requestId,
    required int stepIndex,
    String comment = '',
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.approveStep(requestId, stepIndex),
      body: {'comment': comment.trim()},
      requiresAuth: true,
    );

    if (response.data != null && response.data is Map<String, dynamic>) {
      return JourneyRequest.fromJson(response.data as Map<String, dynamic>);
    }
    throw const ApiException(
      statusCode: 500,
      code: 'SERVER_ERROR',
      message: 'Unexpected response from step approval endpoint.',
    );
  }

  /// Rejects a pending workflow step at [stepIndex] for request [requestId].
  /// Calls PATCH /api/staff/requests/:id/steps/:stepIndex/reject.
  /// Enforces a non-empty rejection comment before dispatching to the server.
  /// Returns the authoritative updated request in REJECTED status.
  Future<JourneyRequest> rejectStep({
    required String requestId,
    required int stepIndex,
    required String comment,
  }) async {
    final cleanComment = comment.trim();
    if (cleanComment.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'A comment explaining the reason for rejection is required.',
      );
    }

    final response = await apiClient.patch(
      ApiEndpoints.rejectStep(requestId, stepIndex),
      body: {'comment': cleanComment},
      requiresAuth: true,
    );

    if (response.data != null && response.data is Map<String, dynamic>) {
      return JourneyRequest.fromJson(response.data as Map<String, dynamic>);
    }
    throw const ApiException(
      statusCode: 500,
      code: 'SERVER_ERROR',
      message: 'Unexpected response from step rejection endpoint.',
    );
  }

  /// Lists student accounts for staff review from GET /api/staff/students.
  /// Requires authenticated session with staff role.
  Future<AdminUsersResult> fetchStudents({
    String? search,
    String? approvalStatus,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (approvalStatus != null &&
        approvalStatus.isNotEmpty &&
        approvalStatus != 'All' &&
        approvalStatus.toLowerCase() != 'all') {
      query['approvalStatus'] = approvalStatus.toUpperCase();
    }

    final response = await apiClient.get(
      ApiEndpoints.staffStudents,
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

  /// Lists all pending student registrations awaiting staff review.
  /// Calls GET /api/staff/pending-students.
  Future<List<PendingUser>> fetchPendingStudents() async {
    final response = await apiClient.get(
      ApiEndpoints.staffPendingStudents,
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

  /// Creates a student account on behalf of a student.
  /// Calls POST /api/staff/students.
  Future<ManagedUser> createStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    String? departmentId,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'studentId': studentId.trim(),
    };
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      body['department'] = departmentId.trim();
    }

    final response = await apiClient.post(
      ApiEndpoints.staffStudents,
      body: body,
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return ManagedUser.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Invalid user response payload from server.');
  }

  /// Approves a pending student registration.
  /// Calls PATCH /api/staff/students/:id/approve.
  Future<void> approveStudent(String studentId) async {
    await apiClient.patch(
      ApiEndpoints.staffApproveStudent(studentId),
      requiresAuth: true,
    );
  }

  /// Rejects a pending student registration with an optional reason.
  /// Calls PATCH /api/staff/students/:id/reject.
  Future<void> rejectStudent(String studentId, {String? reason}) async {
    await apiClient.patch(
      ApiEndpoints.staffRejectStudent(studentId),
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      requiresAuth: true,
    );
  }

  /// Permanently deletes a student account.
  /// Calls DELETE /api/staff/students/:id.
  Future<void> deleteStudent(String studentId) async {
    await apiClient.delete(
      ApiEndpoints.staffDeleteStudent(studentId),
      requiresAuth: true,
    );
  }
}
