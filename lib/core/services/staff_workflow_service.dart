import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../../models/journey_request.dart';

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
}
