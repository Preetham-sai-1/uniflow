/// Represents a user account managed by Administrators and Staff in UniFlow.
class ManagedUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' | 'staff' | 'admin'
  final String? studentId;
  final String? staffId;
  final String? departmentId;
  final String? departmentName;
  final String? departmentCode;
  final String approvalStatus; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final String? rejectionReason;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.staffId,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
    this.approvalStatus = 'APPROVED',
    this.rejectionReason,
    this.isActive = true,
    this.mustChangePassword = false,
    this.createdAt,
  });

  bool get isStudent => role.toLowerCase() == 'student';
  bool get isStaff => role.toLowerCase() == 'staff';
  bool get isAdmin => role.toLowerCase() == 'admin';

  bool get isPending => approvalStatus.toUpperCase() == 'PENDING';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';

  String get identifier => studentId ?? staffId ?? '—';

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    String? deptId;
    String? deptName;
    String? deptCode;

    final dept = json['department'];
    if (dept is Map<String, dynamic>) {
      deptId = (dept['id'] ?? dept['_id'])?.toString();
      deptName = dept['name']?.toString();
      deptCode = dept['code']?.toString();
    } else if (dept is String) {
      deptId = dept;
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }

    return ManagedUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'student').toString().toLowerCase(),
      studentId: json['studentId']?.toString(),
      staffId: json['staffId']?.toString(),
      departmentId: deptId,
      departmentName: deptName,
      departmentCode: deptCode,
      approvalStatus: (json['approvalStatus'] ?? 'APPROVED').toString().toUpperCase(),
      rejectionReason: json['rejectionReason']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      mustChangePassword: json['mustChangePassword'] is bool
          ? json['mustChangePassword'] as bool
          : false,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'studentId': studentId,
      'staffId': staffId,
      'department': departmentId,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
      'isActive': isActive,
      'mustChangePassword': mustChangePassword,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ManagedUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? studentId,
    String? staffId,
    String? departmentId,
    String? departmentName,
    String? departmentCode,
    String? approvalStatus,
    String? rejectionReason,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? createdAt,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      staffId: staffId ?? this.staffId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

