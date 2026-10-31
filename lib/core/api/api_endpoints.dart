/// Centralized endpoint paths corresponding strictly to docs/API_CONTRACT.md.
class ApiEndpoints {
  // Authentication & Profile
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // System & Health
  static const String health = '/health';

  // Core Campus Workflows
  static const String departments = '/departments';
  static const String services = '/services';
  static const String requests = '/requests';
  static const String staffQueue = '/staff/queue';
  static const String adminStats = '/admin/stats';
  static const String adminRequests = '/admin/requests';
  static const String adminPendingUsers = '/admin/pending-users';
  static const String notifications = '/notifications';

  /// Helper to build path for GET /api/requests/:id
  static String requestDetails(String id) => '/requests/$id';

  /// Helper to build path for PATCH /api/requests/:id/payment
  static String requestPayment(String id) => '/requests/$id/payment';

  /// Helper to build path for PATCH /api/staff/requests/:id/steps/:stepIndex/approve
  static String approveStep(String id, int stepIndex) =>
      '/staff/requests/$id/steps/$stepIndex/approve';

  /// Helper to build path for PATCH /api/staff/requests/:id/steps/:stepIndex/reject
  static String rejectStep(String id, int stepIndex) =>
      '/staff/requests/$id/steps/$stepIndex/reject';

  /// Helper to build path for PATCH /api/admin/users/:id/approve
  static String approveUser(String id) => '/admin/users/$id/approve';

  /// Helper to build path for PATCH /api/admin/users/:id/reject
  static String rejectUser(String id) => '/admin/users/$id/reject';
}
