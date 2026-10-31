/// Models for administrator statistics strictly conforming to backend GET /api/admin/stats.
class RequestCounts {
  final int total;
  final int pending;
  final int completed;
  final int rejected;

  const RequestCounts({
    this.total = 0,
    this.pending = 0,
    this.completed = 0,
    this.rejected = 0,
  });

  factory RequestCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RequestCounts();
    return RequestCounts(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }
}

class BookingCounts {
  final int total;
  final int pending;
  final int confirmed;
  final int rejected;

  const BookingCounts({
    this.total = 0,
    this.pending = 0,
    this.confirmed = 0,
    this.rejected = 0,
  });

  factory BookingCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingCounts();
    return BookingCounts(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      confirmed: json['confirmed'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }
}

class ServiceStatItem {
  final String serviceName;
  final int total;
  final int pending;

  const ServiceStatItem({
    required this.serviceName,
    this.total = 0,
    this.pending = 0,
  });

  factory ServiceStatItem.fromJson(Map<String, dynamic> json) {
    return ServiceStatItem(
      serviceName: json['serviceName'] as String? ?? 'Service',
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}

class AdminStats {
  final RequestCounts requests;
  final BookingCounts bookings;
  final List<ServiceStatItem> byService;

  const AdminStats({
    this.requests = const RequestCounts(),
    this.bookings = const BookingCounts(),
    this.byService = const [],
  });

  int get totalApplications => requests.total;
  int get pendingExecutiveSignOff => requests.pending;
  int get approvedCount => requests.completed;
  int get rejectedCount => requests.rejected;
  int get approvalRate => requests.total == 0
      ? 0
      : ((requests.completed / requests.total) * 100).round();

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final reqs = json['requests'] as Map<String, dynamic>?;
    final bks = json['bookings'] as Map<String, dynamic>?;
    final rawByService = json['byService'] as List<dynamic>? ?? [];

    return AdminStats(
      requests: RequestCounts.fromJson(reqs),
      bookings: BookingCounts.fromJson(bks),
      byService: rawByService
          .map((item) => ServiceStatItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
