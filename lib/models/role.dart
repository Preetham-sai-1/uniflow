import 'package:flutter/material.dart';
import '../core/api/api_exceptions.dart';

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

  /// Attempts to map string role from backend ('student', 'staff', 'admin') to [UserRole].
  /// Returns null if the role is unrecognized or unsupported.
  static UserRole? tryFromString(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'student':
        return UserRole.student;
      case 'staff':
        return UserRole.staff;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      default:
        return null;
    }
  }

  /// Maps string role from backend ('student', 'staff', 'admin') to [UserRole].
  /// Throws [ApiException] with code FORBIDDEN (403) if role is unknown or unsupported.
  static UserRole fromString(String? role) {
    final parsed = tryFromString(role);
    if (parsed == null) {
      throw ApiException(
        message: 'Access denied: unrecognized or unsupported user role ($role).',
        statusCode: 403,
        code: 'FORBIDDEN',
      );
    }
    return parsed;
  }

  /// Converts [UserRole] to backend string format.
  String toBackendString() {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.staff:
        return 'staff';
      case UserRole.admin:
        return 'admin';
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

  /// Factory constructor to parse backend user JSON from /api/auth/login or /api/auth/me.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Department can be populated object { _id, name, code } or an ID string or null
    String deptName = '';
    final dept = json['department'];
    if (dept is Map<String, dynamic>) {
      deptName = dept['name']?.toString() ?? '';
    } else if (dept is String) {
      deptName = dept;
    }

    final rollOrEmpId =
        json['studentId']?.toString() ?? json['identifier']?.toString() ?? '';

    return UserProfile(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      department: deptName,
      identifier: rollOrEmpId,
      role: UserRole.fromString(json['role']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'identifier': identifier,
      'role': role.toBackendString(),
    };
  }

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
