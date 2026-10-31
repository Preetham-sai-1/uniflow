import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'service_item.dart';

enum JourneyStatus {
  submitted,
  departmentReview,
  securityReview,
  paymentRequired,
  adminApproval,
  approved,
  rejected;

  String get label {
    switch (this) {
      case JourneyStatus.submitted:
        return 'Submitted';
      case JourneyStatus.departmentReview:
        return 'Dept. Verification';
      case JourneyStatus.securityReview:
        return 'Security Review';
      case JourneyStatus.paymentRequired:
        return 'Payment Required';
      case JourneyStatus.adminApproval:
        return 'Admin Approval';
      case JourneyStatus.approved:
        return 'Completed';
      case JourneyStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case JourneyStatus.submitted:
        return AppColors.lightBlue;
      case JourneyStatus.departmentReview:
      case JourneyStatus.securityReview:
        return AppColors.statusPending;
      case JourneyStatus.paymentRequired:
        return AppColors.statusPayment;
      case JourneyStatus.adminApproval:
        return AppColors.statusPending;
      case JourneyStatus.approved:
        return AppColors.statusApproved;
      case JourneyStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case JourneyStatus.submitted:
        return const Color(0xFFEFF6FF);
      case JourneyStatus.departmentReview:
      case JourneyStatus.securityReview:
        return AppColors.statusPendingBg;
      case JourneyStatus.paymentRequired:
        return AppColors.statusPaymentBg;
      case JourneyStatus.adminApproval:
        return AppColors.statusPendingBg;
      case JourneyStatus.approved:
        return AppColors.statusApprovedBg;
      case JourneyStatus.rejected:
        return AppColors.statusRejectedBg;
    }
  }

  IconData get icon {
    switch (this) {
      case JourneyStatus.submitted:
        return Icons.send_rounded;
      case JourneyStatus.departmentReview:
        return Icons.pending_actions_rounded;
      case JourneyStatus.securityReview:
        return Icons.security_rounded;
      case JourneyStatus.paymentRequired:
        return Icons.payment_rounded;
      case JourneyStatus.adminApproval:
        return Icons.admin_panel_settings_rounded;
      case JourneyStatus.approved:
        return Icons.check_circle_rounded;
      case JourneyStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  bool get isTerminal =>
      this == JourneyStatus.approved || this == JourneyStatus.rejected;

  static JourneyStatus fromBackendString(String? status) {
    if (status == null) return JourneyStatus.submitted;
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return JourneyStatus.submitted;
      case 'DEPARTMENT_VERIFICATION_PENDING':
      case 'DEPT_REVIEW':
        return JourneyStatus.departmentReview;
      case 'SECURITY_REVIEW_PENDING':
      case 'STAFF_REVIEW_PENDING':
        return JourneyStatus.securityReview;
      case 'FEE_PAYMENT_PENDING':
      case 'PAYMENT_REQUIRED':
        return JourneyStatus.paymentRequired;
      case 'ADMIN_APPROVAL_PENDING':
      case 'ADMIN_REVIEW':
        return JourneyStatus.adminApproval;
      case 'COMPLETED':
      case 'BOOKING_CONFIRMED':
      case 'APPROVED':
        return JourneyStatus.approved;
      case 'REJECTED':
        return JourneyStatus.rejected;
      default:
        return JourneyStatus.submitted;
    }
  }
}

class TimelineStep {
  final String title;
  final String description;
  final String actorRole;
  final String? actorName;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isRejected;
  final String? comment;
  final int stepIndex;
  final bool isPaymentStep;
  final String status;

  const TimelineStep({
    required this.title,
    required this.description,
    required this.actorRole,
    this.actorName,
    required this.timestamp,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isRejected = false,
    this.comment,
    this.stepIndex = 0,
    this.isPaymentStep = false,
    this.status = 'PENDING',
  });

  TimelineStep copyWith({
    String? title,
    String? description,
    String? actorRole,
    String? actorName,
    DateTime? timestamp,
    bool? isCompleted,
    bool? isCurrent,
    bool? isRejected,
    String? comment,
    int? stepIndex,
    bool? isPaymentStep,
    String? status,
  }) {
    return TimelineStep(
      title: title ?? this.title,
      description: description ?? this.description,
      actorRole: actorRole ?? this.actorRole,
      actorName: actorName ?? this.actorName,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
      isCurrent: isCurrent ?? this.isCurrent,
      isRejected: isRejected ?? this.isRejected,
      comment: comment ?? this.comment,
      stepIndex: stepIndex ?? this.stepIndex,
      isPaymentStep: isPaymentStep ?? this.isPaymentStep,
      status: status ?? this.status,
    );
  }
}

class JourneyRequest {
  final String id;
  final String? backendId;
  final String requestNumber;
  final ServiceType serviceType;
  final String serviceName;
  final String studentId;
  final String studentName;
  final String studentRoll;
  final String department;
  final JourneyStatus status;
  final String backendStatus;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final Map<String, String> formData;
  final List<TimelineStep> timeline;
  final double feeAmount;
  final bool isFeePaid;
  final String? staffComment;
  final String? adminComment;
  final String? rejectionReason;
  final int currentStepIndex;
  final int? waitingHours;
  final String? stepName;

  const JourneyRequest({
    required this.id,
    this.backendId,
    String? requestNumber,
    required this.serviceType,
    String? serviceName,
    required this.studentId,
    required this.studentName,
    required this.studentRoll,
    required this.department,
    required this.status,
    String? backendStatus,
    required this.submittedAt,
    required this.updatedAt,
    required this.formData,
    required this.timeline,
    this.feeAmount = 0.0,
    this.isFeePaid = false,
    this.staffComment,
    this.adminComment,
    this.rejectionReason,
    this.currentStepIndex = 0,
    this.waitingHours,
    this.stepName,
  })  : requestNumber = requestNumber ?? id,
        serviceName = serviceName ?? '',
        backendStatus = backendStatus ?? '';

  String get effectiveServiceName =>
      serviceName.isNotEmpty ? serviceName : serviceType.title;

  String get effectiveId => backendId ?? id;

  JourneyRequest copyWith({
    String? id,
    String? backendId,
    String? requestNumber,
    ServiceType? serviceType,
    String? serviceName,
    String? studentId,
    String? studentName,
    String? studentRoll,
    String? department,
    JourneyStatus? status,
    String? backendStatus,
    DateTime? submittedAt,
    DateTime? updatedAt,
    Map<String, String>? formData,
    List<TimelineStep>? timeline,
    double? feeAmount,
    bool? isFeePaid,
    String? staffComment,
    String? adminComment,
    String? rejectionReason,
    int? currentStepIndex,
    int? waitingHours,
    String? stepName,
  }) {
    return JourneyRequest(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      requestNumber: requestNumber ?? this.requestNumber,
      serviceType: serviceType ?? this.serviceType,
      serviceName: serviceName ?? this.serviceName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRoll: studentRoll ?? this.studentRoll,
      department: department ?? this.department,
      status: status ?? this.status,
      backendStatus: backendStatus ?? this.backendStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formData: formData ?? this.formData,
      timeline: timeline ?? this.timeline,
      feeAmount: feeAmount ?? this.feeAmount,
      isFeePaid: isFeePaid ?? this.isFeePaid,
      staffComment: staffComment ?? this.staffComment,
      adminComment: adminComment ?? this.adminComment,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      waitingHours: waitingHours ?? this.waitingHours,
      stepName: stepName ?? this.stepName,
    );
  }

  factory JourneyRequest.fromJson(Map<String, dynamic> json) {
    final serviceData = (json['service'] is Map<String, dynamic>)
        ? json['service'] as Map<String, dynamic>
        : (json['serviceId'] is Map<String, dynamic>
            ? json['serviceId'] as Map<String, dynamic>
            : null);
    final slug = serviceData?['slug'] as String? ??
        json['serviceSlug'] as String? ??
        json['serviceCategory'] as String? ??
        '';
    final serviceType = ServiceType.fromSlug(slug);
    final serviceName = serviceData?['name'] as String? ??
        json['serviceName'] as String? ??
        serviceType.title;

    final studentData = (json['student'] is Map<String, dynamic>)
        ? json['student'] as Map<String, dynamic>
        : (json['studentId'] is Map<String, dynamic>
            ? json['studentId'] as Map<String, dynamic>
            : null);
    final studentId = studentData?['_id'] as String? ??
        studentData?['id'] as String? ??
        (json['studentId'] is String ? json['studentId'] as String : '');
    final studentName = studentData?['name'] as String? ?? 'Student';
    final studentRoll = studentData?['studentId'] as String? ??
        studentData?['rollNumber'] as String? ??
        '';

    String dept = 'General';
    if (serviceData?['responsibleDepartment'] is Map<String, dynamic>) {
      dept =
          serviceData!['responsibleDepartment']['name'] as String? ?? 'General';
    } else if (studentData?['department'] is String) {
      dept = studentData!['department'] as String;
    }

    final statusStr = json['status'] as String? ?? 'SUBMITTED';
    final status = JourneyStatus.fromBackendString(statusStr);
    final currentStepIdx = json['currentStepIndex'] as int? ?? 0;

    final rawFormData = json['formData'] as Map<String, dynamic>? ?? {};
    final formData =
        rawFormData.map((k, v) => MapEntry(k, v?.toString() ?? ''));

    final rawSteps = (json['runtimeSteps'] as List<dynamic>?) ?? [];
    final isReqCompleted = status == JourneyStatus.approved;
    final isReqRejected = status == JourneyStatus.rejected;

    final timeline = rawSteps.asMap().entries.map<TimelineStep>((entry) {
      final idx = entry.key;
      final s = entry.value as Map<String, dynamic>;
      final stepName = s['name'] as String? ?? 'Workflow Step';
      final stepRole = (s['assignedRole'] as String? ?? 'Staff').toUpperCase();
      final stepStatus = (s['status'] as String? ?? 'PENDING').toUpperCase();
      final isPaymentStep = s['isPaymentStep'] == true;
      final actorData = s['actor'] as Map<String, dynamic>?;
      final actorName = actorData?['name'] as String?;
      final comment = s['comment'] as String?;
      final actionedAtStr = s['actionedAt'] as String?;
      final timestamp = actionedAtStr != null
          ? DateTime.tryParse(actionedAtStr) ?? DateTime.now()
          : DateTime.now();

      final isCompleted = stepStatus == 'APPROVED' ||
          stepStatus == 'PAYMENT_COMPLETED' ||
          stepStatus == 'PAID' ||
          (idx < currentStepIdx && !isReqRejected);
      final isRejected = stepStatus == 'REJECTED';
      final isCurrent =
          idx == currentStepIdx && !isReqCompleted && !isReqRejected;

      String description;
      if (isRejected) {
        description = comment != null && comment.isNotEmpty
            ? 'Rejected: $comment'
            : 'Rejected by $stepRole';
      } else if (isCompleted) {
        if (isPaymentStep) {
          description = 'Simulated fee payment verified and confirmed.';
        } else {
          description = actorName != null
              ? 'Approved by $actorName ($stepRole)'
              : 'Approved by $stepRole authority';
        }
      } else if (isCurrent) {
        if (isPaymentStep) {
          description =
              'Action Required: Simulated fee payment needed to proceed.';
        } else {
          description = 'Active review checkpoint — awaiting $stepRole action';
        }
      } else {
        description = 'Upcoming verification step';
      }

      return TimelineStep(
        title: stepName,
        description: description,
        actorRole: stepRole,
        actorName: actorName,
        timestamp: timestamp,
        isCompleted: isCompleted,
        isCurrent: isCurrent,
        isRejected: isRejected,
        comment: comment,
        stepIndex: idx,
        isPaymentStep: isPaymentStep,
        status: stepStatus,
      );
    }).toList();

    // Check if rejection reason is present in rejected step or auditLog
    String? rejectionReason;
    if (isReqRejected) {
      final rejectedStep = timeline.cast<TimelineStep?>().firstWhere(
            (st) => st?.isRejected == true,
            orElse: () => null,
          );
      rejectionReason = rejectedStep?.comment;

      if (rejectionReason == null) {
        final auditLog = json['auditLog'] as List<dynamic>?;
        if (auditLog != null && auditLog.isNotEmpty) {
          final lastRejection = auditLog.reversed.firstWhere(
            (log) => (log as Map<String, dynamic>)['action'] == 'REJECTED',
            orElse: () => null,
          );
          if (lastRejection != null) {
            rejectionReason = lastRejection['comment'] as String?;
          }
        }
      }
    }

    final backendId = json['_id']?.toString() ?? json['id']?.toString();
    final requestNumber = json['requestNumber']?.toString() ?? backendId ?? '';

    // Fee calculation: check formData or fallback for ID Card
    double fee = 0.0;
    if (slug == 'id-card-replacement') {
      fee = 200.0;
      final rawFeeStr = formData['Estimated Fee'] ?? formData['estimatedFee'];
      if (rawFeeStr != null) {
        final numeric = rawFeeStr.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(numeric);
        if (parsed != null && parsed > 0) fee = parsed;
      }
    }

    final isFeePaid = timeline.any((st) =>
        st.isPaymentStep &&
        (st.isCompleted || st.status == 'PAYMENT_COMPLETED'));

    return JourneyRequest(
      id: requestNumber.isNotEmpty ? requestNumber : (backendId ?? ''),
      backendId: backendId,
      requestNumber: requestNumber,
      serviceType: serviceType,
      serviceName: serviceName,
      studentId: studentId,
      studentName: studentName,
      studentRoll: studentRoll,
      department: dept,
      status: status,
      backendStatus: statusStr,
      submittedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      formData: formData,
      timeline: timeline,
      feeAmount: fee,
      isFeePaid: isFeePaid,
      rejectionReason: rejectionReason,
      currentStepIndex: currentStepIdx,
    );
  }

  factory JourneyRequest.fromStaffQueueJson(Map<String, dynamic> json) {
    final requestId = json['requestId'] as String? ??
        json['_id'] as String? ??
        json['id'] as String? ??
        '';
    final requestNumber = json['requestNumber'] as String? ?? requestId;
    final serviceName = json['serviceName'] as String? ?? 'Campus Service';
    final serviceCategory = json['serviceCategory'] as String?;
    final serviceType =
        ServiceType.fromSlug(serviceName) != ServiceType.bonafide
            ? ServiceType.fromSlug(serviceName)
            : ServiceType.fromSlug(serviceCategory ?? serviceName);

    final studentName = json['studentName'] as String? ?? 'Student';
    final studentEmail = json['studentEmail'] as String? ?? '';
    final studentRoll = json['studentIdNumber'] as String? ?? '';

    final stepIndex = json['stepIndex'] as int? ?? 0;
    final stepName = json['stepName'] as String? ?? 'Review';
    final assignedRole = json['assignedRole'] as String? ?? 'staff';
    final statusStr = json['status'] as String? ?? 'SUBMITTED';
    final status = JourneyStatus.fromBackendString(statusStr);

    final submittedAt = json['submittedAt'] != null
        ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final waitingHours = json['waitingHours'] as int? ?? 0;

    return JourneyRequest(
      id: requestNumber.isNotEmpty ? requestNumber : requestId,
      backendId: requestId,
      requestNumber: requestNumber,
      serviceType: serviceType,
      serviceName: serviceName,
      studentId: studentEmail,
      studentName: studentName,
      studentRoll: studentRoll,
      department: 'Assigned Department',
      status: status,
      backendStatus: statusStr,
      submittedAt: submittedAt,
      updatedAt: submittedAt,
      formData: {},
      timeline: [
        TimelineStep(
          title: stepName,
          description: 'Awaiting ${assignedRole.toUpperCase()} action',
          actorRole: assignedRole,
          timestamp: submittedAt,
          isCurrent: true,
          stepIndex: stepIndex,
          status: statusStr,
        ),
      ],
      currentStepIndex: stepIndex,
      waitingHours: waitingHours,
      stepName: stepName,
    );
  }
}
