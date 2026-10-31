import 'package:flutter/material.dart';

enum UserRole {
  student,
  staff,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Staff Member';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get subtitle {
    switch (this) {
      case UserRole.student:
        return 'Campus Service Requester';
      case UserRole.staff:
        return 'Department Reviewer';
      case UserRole.admin:
        return 'Campus Oversight & Approval';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.staff:
        return Icons.verified_user_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String department;
  final String identifier; // e.g. Roll No or Employee ID
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.identifier,
    required this.role,
  });

  static const studentUser = UserProfile(
    id: 'u-std-101',
    name: 'Alex Rivera',
    email: 'alex.rivera@campus.edu',
    department: 'Computer Science & Engineering',
    identifier: 'CSE-2023-042',
    role: UserRole.student,
  );

  static const staffUser = UserProfile(
    id: 'u-stf-202',
    name: 'Dr. Sarah Jenkins',
    email: 's.jenkins@campus.edu',
    department: 'Academic Affairs & Department Custodian',
    identifier: 'FAC-EMP-8821',
    role: UserRole.staff,
  );

  static const adminUser = UserProfile(
    id: 'u-adm-303',
    name: 'Dean Marcus Vance',
    email: 'dean.vance@campus.edu',
    department: 'Office of the Registrar',
    identifier: 'ADM-EXEC-01',
    role: UserRole.admin,
  );
}
