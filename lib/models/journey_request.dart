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
    );
  }
}

class JourneyRequest {
  final String id;
  final ServiceType serviceType;
  final String studentId;
  final String studentName;
  final String studentRoll;
  final String department;
  final JourneyStatus status;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final Map<String, String> formData;
  final List<TimelineStep> timeline;
  final double feeAmount;
  final bool isFeePaid;
  final String? staffComment;
  final String? adminComment;
  final String? rejectionReason;

  const JourneyRequest({
    required this.id,
    required this.serviceType,
    required this.studentId,
    required this.studentName,
    required this.studentRoll,
    required this.department,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
    required this.formData,
    required this.timeline,
    this.feeAmount = 0.0,
    this.isFeePaid = false,
    this.staffComment,
    this.adminComment,
    this.rejectionReason,
  });

  JourneyRequest copyWith({
    String? id,
    ServiceType? serviceType,
    String? studentId,
    String? studentName,
    String? studentRoll,
    String? department,
    JourneyStatus? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
    Map<String, String>? formData,
    List<TimelineStep>? timeline,
    double? feeAmount,
    bool? isFeePaid,
    String? staffComment,
    String? adminComment,
    String? rejectionReason,
  }) {
    return JourneyRequest(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRoll: studentRoll ?? this.studentRoll,
      department: department ?? this.department,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formData: formData ?? this.formData,
      timeline: timeline ?? this.timeline,
      feeAmount: feeAmount ?? this.feeAmount,
      isFeePaid: isFeePaid ?? this.isFeePaid,
      staffComment: staffComment ?? this.staffComment,
      adminComment: adminComment ?? this.adminComment,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
