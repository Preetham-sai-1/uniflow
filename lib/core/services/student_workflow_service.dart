import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/service_item.dart';

/// Encapsulates the verified result of a successful request creation.
class SubmissionResult {
  final String id;
  final String requestNumber;
  final String status;
  final String serviceName;
  final DateTime createdAt;
  final Map<String, dynamic> raw;

  const SubmissionResult({
    required this.id,
    required this.requestNumber,
    required this.status,
    required this.serviceName,
    required this.createdAt,
    required this.raw,
  });

  factory SubmissionResult.fromJson(Map<String, dynamic> json) {
    final serviceData = json['service'] as Map<String, dynamic>?;
    return SubmissionResult(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      requestNumber:
          json['requestNumber'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'SUBMITTED',
      serviceName: serviceData?['name'] as String? ?? 'Campus Service',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      raw: json,
    );
  }
}

/// Service handling student catalogue browsing and request submission
/// communicating with Node.js/Express backend API contracts.
class StudentWorkflowService {
  final ApiClient apiClient;

  StudentWorkflowService({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  /// Fetches all active services from GET /api/services.
  /// Authenticates using the stored JWT Bearer token.
  Future<List<CampusServiceItem>> fetchServices({String? category}) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }

    final response = await apiClient.get(
      ApiEndpoints.services,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    if (data is List) {
      return data
          .map((item) =>
              CampusServiceItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Submits a student service request via POST /api/requests.
  /// Sends the student JWT and request payload { serviceId, formData }.
  Future<SubmissionResult> submitRequest({
    required String serviceId,
    required Map<String, dynamic> formData,
  }) async {
    final payload = {
      'serviceId': serviceId,
      'formData': formData,
    };

    final response = await apiClient.post(
      ApiEndpoints.requests,
      body: payload,
      requiresAuth: true,
    );

    final data = response.data as Map<String, dynamic>;
    return SubmissionResult.fromJson(data);
  }
}
