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
}

class CampusServiceItem {
  final ServiceType type;
  final String title;
  final String category;
  final String description;
  final String sla;
  final IconData icon;
  final bool requiresFee;

  const CampusServiceItem({
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.sla,
    required this.icon,
    this.requiresFee = false,
  });

  static const List<CampusServiceItem> availableServices = [
    CampusServiceItem(
      type: ServiceType.bonafide,
      title: 'Bonafide Certificate',
      category: 'Academic & Records',
      description:
          'Official proof of study for educational loans, passport/visa filings, and student discounts.',
      sla: '24-48 Hours',
      icon: Icons.verified_rounded,
      requiresFee: false,
    ),
    CampusServiceItem(
      type: ServiceType.idCard,
      title: 'ID Card Replacement',
      category: 'Identity & Security',
      description:
          'Report lost or broken campus smart badge and initiate reissue with security approval.',
      sla: '3-5 Days',
      icon: Icons.badge_rounded,
      requiresFee: true,
    ),
    CampusServiceItem(
      type: ServiceType.equipment,
      title: 'Equipment Booking',
      category: 'Facilities & Hardware',
      description:
          'Check out lab equipment, digital cameras, audio kits, and projectors for campus projects.',
      sla: 'Instant / Same Day',
      icon: Icons.devices_other_rounded,
      requiresFee: false,
    ),
  ];
}
