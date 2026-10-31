/// Represents a pending student registration awaiting administrator review.
class PendingUser {
  final String id;
  final String name;
  final String email;
  final String? studentId;
  final String? departmentName;
  final String? departmentCode;
  final DateTime? createdAt;
  final String approvalStatus;
  final String? rejectionReason;

  const PendingUser({
    required this.id,
    required this.name,
    required this.email,
    this.studentId,
    this.departmentName,
    this.departmentCode,
    this.createdAt,
    this.approvalStatus = 'PENDING',
    this.rejectionReason,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    String? deptName;
    String? deptCode;

    final dept = json['department'];
    if (dept is Map<String, dynamic>) {
      deptName = dept['name']?.toString();
      deptCode = dept['code']?.toString();
    } else if (dept is String) {
      deptName = dept;
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }

    return PendingUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      studentId: json['studentId']?.toString(),
      departmentName: deptName,
      departmentCode: deptCode,
      createdAt: created,
      approvalStatus: (json['approvalStatus'] ?? 'PENDING').toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'departmentName': departmentName,
      'departmentCode': departmentCode,
      'createdAt': createdAt?.toIso8601String(),
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
    };
  }
}

