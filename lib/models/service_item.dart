import 'package:flutter/material.dart';

enum ServiceType {
  bonafide,
  idCard,
  equipment;

  String get title {
    switch (this) {
      case ServiceType.bonafide:
        return 'Bonafide Certificate';
      case ServiceType.idCard:
        return 'ID Card Replacement';
      case ServiceType.equipment:
        return 'Equipment Booking';
    }
  }

  String get shortCode {
    switch (this) {
      case ServiceType.bonafide:
        return 'BON';
      case ServiceType.idCard:
        return 'IDC';
      case ServiceType.equipment:
        return 'EQP';
    }
  }

  String get category {
    switch (this) {
      case ServiceType.bonafide:
        return 'Academic & Records';
      case ServiceType.idCard:
        return 'Identity & Badges';
      case ServiceType.equipment:
        return 'Campus Facilities & Tech';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.bonafide:
        return 'Official institutional letter verifying current enrolment status for bank, visa, or scholarships.';
      case ServiceType.idCard:
        return 'Request replacement for lost, damaged, or stolen student smart identity cards.';
      case ServiceType.equipment:
        return 'Reserve AV projectors, lab sensors, high-end cameras, and developer testkits for campus work.';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.bonafide:
        return Icons.verified_rounded;
      case ServiceType.idCard:
        return Icons.badge_rounded;
      case ServiceType.equipment:
        return Icons.devices_other_rounded;
    }
  }

  String get standardSla {
    switch (this) {
      case ServiceType.bonafide:
        return '24-48 Business Hours';
      case ServiceType.idCard:
        return '3-5 Business Days';
      case ServiceType.equipment:
        return 'Same Day Verification';
    }
  }

  int get estimatedSteps {
    switch (this) {
      case ServiceType.bonafide:
        return 3; // Submit -> Dept Verify -> Admin Approval
      case ServiceType.idCard:
        return 4; // Submit -> Security Verify -> Fee Payment -> Admin Print
      case ServiceType.equipment:
        return 2; // Submit -> Custodian Approval
    }
  }

  static ServiceType fromSlug(String? slug) {
    if (slug == null) return ServiceType.bonafide;
    final lower = slug.toLowerCase();
    if (lower.contains('id-card') ||
        lower.contains('badge') ||
        lower.contains('identity')) {
      return ServiceType.idCard;
    }
    if (lower.contains('equipment') ||
        lower.contains('hardware') ||
        lower.contains('booking') ||
        lower.contains('facility')) {
      return ServiceType.equipment;
    }
    return ServiceType.bonafide;
  }
}

class CampusServiceItem {
  final String? id;
  final String? slug;
  final ServiceType type;
  final String title;
  final String category;
  final String description;
  final String sla;
  final IconData icon;
  final bool requiresFee;
  final int estimatedDays;
  final List<String> requiredDocuments;
  final String? responsibleDepartment;
  final int workflowStepCount;

  const CampusServiceItem({
    this.id,
    this.slug,
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.sla,
    required this.icon,
    this.requiresFee = false,
    this.estimatedDays = 2,
    this.requiredDocuments = const [],
    this.responsibleDepartment,
    this.workflowStepCount = 3,
  });

  factory CampusServiceItem.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String? ?? '';
    final type = ServiceType.fromSlug(slug);
    final name = json['name'] as String? ?? type.title;
    final category = json['category'] as String? ?? type.category;
    final description = json['description'] as String? ?? type.description;
    final estimatedDays = json['estimatedDays'] as int? ?? type.estimatedSteps;
    final sla =
        estimatedDays == 1 ? '1 Business Day' : '$estimatedDays Business Days';
    final docs = (json['requiredDocuments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    String? deptName;
    if (json['responsibleDepartment'] is Map<String, dynamic>) {
      deptName = json['responsibleDepartment']['name'] as String?;
    } else if (json['responsibleDepartment'] is String) {
      deptName = json['responsibleDepartment'] as String;
    }

    final stepCount = json['workflowStepCount'] as int? ?? type.estimatedSteps;

    return CampusServiceItem(
      id: json['id'] as String? ?? json['_id'] as String?,
      slug: slug,
      type: type,
      title: name,
      category: category,
      description: description,
      sla: sla,
      icon: type.icon,
      requiresFee: slug == 'id-card-replacement',
      estimatedDays: estimatedDays,
      requiredDocuments: docs,
      responsibleDepartment: deptName,
      workflowStepCount: stepCount,
    );
  }

  static const List<CampusServiceItem> availableServices = [
    CampusServiceItem(
      id: 'bonafide-certificate',
      slug: 'bonafide-certificate',
      type: ServiceType.bonafide,
      title: 'Bonafide Certificate',
      category: 'Academic & Records',
      description:
          'Official proof of study for educational loans, passport/visa filings, and student discounts.',
      sla: '24-48 Hours',
      icon: Icons.verified_rounded,
      requiresFee: false,
      estimatedDays: 2,
      workflowStepCount: 3,
    ),
    CampusServiceItem(
      id: 'id-card-replacement',
      slug: 'id-card-replacement',
      type: ServiceType.idCard,
      title: 'ID Card Replacement',
      category: 'Identity & Security',
      description:
          'Report lost or broken campus smart badge and initiate reissue with security approval.',
      sla: '3-5 Days',
      icon: Icons.badge_rounded,
      requiresFee: true,
      estimatedDays: 4,
      workflowStepCount: 4,
    ),
    CampusServiceItem(
      id: 'equipment-booking',
      slug: 'equipment-booking',
      type: ServiceType.equipment,
      title: 'Equipment Booking',
      category: 'Facilities & Hardware',
      description:
          'Check out lab equipment, digital cameras, audio kits, and projectors for campus projects.',
      sla: 'Instant / Same Day',
      icon: Icons.devices_other_rounded,
      requiresFee: false,
      estimatedDays: 1,
      workflowStepCount: 2,
    ),
  ];
}
