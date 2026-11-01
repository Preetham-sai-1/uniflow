import 'package:flutter/material.dart';
import '../../models/admin_stats.dart';
import '../../models/journey_request.dart';
import '../../models/managed_user.dart';
import '../../models/pending_user.dart';
import '../../models/role.dart';
import '../../models/service_item.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_service.dart';
import '../services/admin_workflow_service.dart';
import '../services/staff_workflow_service.dart';
import '../services/student_workflow_service.dart';

class AppState extends ChangeNotifier {
  final AuthService authService;
  final StudentWorkflowService studentWorkflowService;
  final StaffWorkflowService staffWorkflowService;
  final AdminWorkflowService adminWorkflowService;

  UserRole _currentRole = UserRole.student;
  UserProfile _currentUser = UserProfile.studentUser;
  bool _isAuthenticated = false;
  bool _isLoadingSession = false;
  String? _sessionError;

  final List<JourneyRequest> _requests = [];

  // Services Catalogue State
  List<CampusServiceItem> _services = [];
  bool _isLoadingServices = false;
  bool _hasLoadedServices = false;
  String? _servicesError;

  // Request Submission State
  bool _isSubmittingRequest = false;
  String? _submitError;
  SubmissionResult? _lastSubmissionResult;

  // Student Requests State
  List<JourneyRequest> _studentRequests = [];
  bool _isLoadingRequests = false;
  bool _hasLoadedRequests = false;
  String? _requestsError;

  // Payment Processing State
  bool _isProcessingPayment = false;
  String? _paymentError;

  // Staff Review Queue State
  List<JourneyRequest> _staffQueue = [];
  bool _isLoadingStaffQueue = false;
  bool _hasLoadedStaffQueue = false;
  String? _staffQueueError;

  // Step Actioning State
  bool _isActioningStep = false;
  String? _actionError;

  // Admin Analytics & Oversight State
  AdminStats? _adminStats;
  bool _isLoadingAdminStats = false;
  bool _hasLoadedAdminStats = false;
  String? _adminStatsError;

  List<JourneyRequest> _adminRequests = [];
  bool _isLoadingAdminRequests = false;
  bool _hasLoadedAdminRequests = false;
  String? _adminRequestsError;
  int _adminTotalRequests = 0;
  int _adminTotalPages = 1;
  int _adminCurrentPage = 1;

  // Pending Student User Approvals State
  List<PendingUser> _pendingUsers = [];
  bool _isLoadingPendingUsers = false;
  bool _hasLoadedPendingUsers = false;
  String? _pendingUsersError;

  // Managed Users State (Admin)
  List<ManagedUser> _managedUsers = [];
  bool _isLoadingManagedUsers = false;
  bool _hasLoadedManagedUsers = false;
  String? _managedUsersError;
  int _managedUsersTotal = 0;
  int _managedUsersPages = 1;
  int _managedUsersPage = 1;

  // Staff Student Management State
  List<ManagedUser> _staffStudents = [];
  bool _isLoadingStaffStudents = false;
  bool _hasLoadedStaffStudents = false;
  String? _staffStudentsError;
  int _staffStudentsTotal = 0;
  int _staffStudentsPages = 1;
  int _staffStudentsPage = 1;

  // Staff Pending Student Registrations State
  List<PendingUser> _staffPendingStudents = [];
  bool _isLoadingStaffPendingStudents = false;
  bool _hasLoadedStaffPendingStudents = false;
  String? _staffPendingStudentsError;

  AppState({
    AuthService? authService,
    StudentWorkflowService? studentWorkflowService,
    StaffWorkflowService? staffWorkflowService,
    AdminWorkflowService? adminWorkflowService,
    bool? initialAuthenticated,
  })  : authService = authService ?? AuthService(),
        studentWorkflowService = studentWorkflowService ??
            (authService != null
                ? StudentWorkflowService(apiClient: authService.apiClient)
                : StudentWorkflowService()),
        staffWorkflowService = staffWorkflowService ??
            (authService != null
                ? StaffWorkflowService(apiClient: authService.apiClient)
                : (studentWorkflowService != null
                    ? StaffWorkflowService(
                        apiClient: studentWorkflowService.apiClient)
                    : StaffWorkflowService())),
        adminWorkflowService = adminWorkflowService ??
            (authService != null
                ? AdminWorkflowService(apiClient: authService.apiClient)
                : (staffWorkflowService != null
                    ? AdminWorkflowService(
                        apiClient: staffWorkflowService.apiClient)
                    : AdminWorkflowService())),
        _isAuthenticated = initialAuthenticated ??
            (studentWorkflowService != null ||
                staffWorkflowService != null ||
                adminWorkflowService != null) {
    _initSeedData();
  }

  UserRole get currentRole => _currentRole;
  UserProfile get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoadingSession => _isLoadingSession;
  String? get sessionError => _sessionError;
  List<JourneyRequest> get requests => List.unmodifiable(_requests);

  List<CampusServiceItem> get services => _services;
  bool get isLoadingServices => _isLoadingServices;
  bool get hasLoadedServices => _hasLoadedServices;
  String? get servicesError => _servicesError;

  bool get isSubmittingRequest => _isSubmittingRequest;
  String? get submitError => _submitError;
  SubmissionResult? get lastSubmissionResult => _lastSubmissionResult;

  List<JourneyRequest> get studentRequests => _hasLoadedRequests
      ? List.unmodifiable(_studentRequests)
      : _requests
          .where((r) =>
              r.studentId == _currentUser.id ||
              r.studentId == UserProfile.studentUser.id)
          .toList();

  bool get isLoadingRequests => _isLoadingRequests;
  bool get hasLoadedRequests => _hasLoadedRequests;
  String? get requestsError => _requestsError;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get paymentError => _paymentError;

  List<JourneyRequest> get staffQueue => _hasLoadedStaffQueue
      ? List.unmodifiable(_staffQueue)
      : _requests
          .where((r) =>
              !r.status.isTerminal && r.status != JourneyStatus.adminApproval)
          .toList();

  bool get isLoadingStaffQueue => _isLoadingStaffQueue;
  bool get hasLoadedStaffQueue => _hasLoadedStaffQueue;
  String? get staffQueueError => _staffQueueError;
  bool get isActioningStep => _isActioningStep;
  String? get actionError => _actionError;

  List<JourneyRequest> get adminQueue => _hasLoadedAdminRequests
      ? _adminRequests
          .where((r) => r.status == JourneyStatus.adminApproval)
          .toList()
      : _requests
          .where((r) => r.status == JourneyStatus.adminApproval)
          .toList();

  AdminStats? get adminStats => _adminStats;
  bool get isLoadingAdminStats => _isLoadingAdminStats;
  bool get hasLoadedAdminStats => _hasLoadedAdminStats;
  String? get adminStatsError => _adminStatsError;

  List<JourneyRequest> get adminRequests =>
      _hasLoadedAdminRequests ? List.unmodifiable(_adminRequests) : _requests;
  bool get isLoadingAdminRequests => _isLoadingAdminRequests;
  bool get hasLoadedAdminRequests => _hasLoadedAdminRequests;
  String? get adminRequestsError => _adminRequestsError;
  int get adminTotalRequests => _adminTotalRequests;
  int get adminTotalPages => _adminTotalPages;
  int get adminCurrentPage => _adminCurrentPage;

  List<PendingUser> get pendingUsers => List.unmodifiable(_pendingUsers);
  bool get isLoadingPendingUsers => _isLoadingPendingUsers;
  bool get hasLoadedPendingUsers => _hasLoadedPendingUsers;
  String? get pendingUsersError => _pendingUsersError;

  List<ManagedUser> get managedUsers => List.unmodifiable(_managedUsers);
  bool get isLoadingManagedUsers => _isLoadingManagedUsers;
  bool get hasLoadedManagedUsers => _hasLoadedManagedUsers;
  String? get managedUsersError => _managedUsersError;
  int get managedUsersTotal => _managedUsersTotal;
  int get managedUsersPages => _managedUsersPages;
  int get managedUsersPage => _managedUsersPage;

  List<ManagedUser> get staffStudents => List.unmodifiable(_staffStudents);
  bool get isLoadingStaffStudents => _isLoadingStaffStudents;
  bool get hasLoadedStaffStudents => _hasLoadedStaffStudents;
  String? get staffStudentsError => _staffStudentsError;
  int get staffStudentsTotal => _staffStudentsTotal;
  int get staffStudentsPages => _staffStudentsPages;
  int get staffStudentsPage => _staffStudentsPage;

  List<PendingUser> get staffPendingStudents =>
      List.unmodifiable(_staffPendingStudents);
  bool get isLoadingStaffPendingStudents => _isLoadingStaffPendingStudents;
  bool get hasLoadedStaffPendingStudents => _hasLoadedStaffPendingStudents;
  String? get staffPendingStudentsError => _staffPendingStudentsError;

  void setRole(UserRole role) {
    _currentRole = role;
    switch (role) {
      case UserRole.student:
        _currentUser = UserProfile.studentUser;
        break;
      case UserRole.staff:
        _currentUser = UserProfile.staffUser;
        break;
      case UserRole.admin:
        _currentUser = UserProfile.adminUser;
        break;
    }
    notifyListeners();
  }

  /// Sets an authenticated session with the server-verified user profile.
  void setAuthenticatedUser(UserProfile user) {
    _currentUser = user;
    _currentRole = user.role;
    _isAuthenticated = true;
    _sessionError = null;
    notifyListeners();
  }

  /// Restores session on startup using persistent token storage.
  Future<bool> initializeSession() async {
    _isLoadingSession = true;
    _sessionError = null;
    notifyListeners();

    try {
      final user = await authService.restoreSession();
      if (user != null) {
        _currentUser = user;
        _currentRole = user.role;
        _isAuthenticated = true;
        return true;
      } else {
        _isAuthenticated = false;
        return false;
      }
    } catch (e) {
      _sessionError = e.toString();
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoadingSession = false;
      notifyListeners();
    }
  }

  /// Authenticate against real backend login endpoint.
  Future<void> login(String email, String password) async {
    final result = await authService.login(email: email, password: password);
    setAuthenticatedUser(result.user);
  }

  /// Log out and clear token session.
  Future<void> logout() async {
    await authService.logout();
    _isAuthenticated = false;
    _currentUser = UserProfile.studentUser;
    _currentRole = UserRole.student;
    _sessionError = null;
    _services = [];
    _hasLoadedServices = false;
    _servicesError = null;
    _lastSubmissionResult = null;
    _studentRequests = [];
    _hasLoadedRequests = false;
    _requestsError = null;
    _paymentError = null;
    _staffQueue = [];
    _hasLoadedStaffQueue = false;
    _staffQueueError = null;
    _actionError = null;
    _adminStats = null;
    _hasLoadedAdminStats = false;
    _adminStatsError = null;
    _adminRequests = [];
    _hasLoadedAdminRequests = false;
    _adminRequestsError = null;
    _adminTotalRequests = 0;
    _adminTotalPages = 1;
    _adminCurrentPage = 1;
    _pendingUsers = [];
    _hasLoadedPendingUsers = false;
    _pendingUsersError = null;
    _managedUsers = [];
    _hasLoadedManagedUsers = false;
    _managedUsersError = null;
    _managedUsersTotal = 0;
    _managedUsersPages = 1;
    _managedUsersPage = 1;
    _staffStudents = [];
    _hasLoadedStaffStudents = false;
    _staffStudentsError = null;
    _staffStudentsTotal = 0;
    _staffStudentsPages = 1;
    _staffStudentsPage = 1;
    _staffPendingStudents = [];
    _hasLoadedStaffPendingStudents = false;
    _staffPendingStudentsError = null;
    notifyListeners();
  }

  /// Locates a request by id, MongoDB ObjectId (backendId), or human-readable requestNumber.
  JourneyRequest? findRequest(String idOrBackendId) {
    try {
      return _studentRequests.firstWhere(
        (r) =>
            r.id == idOrBackendId ||
            r.backendId == idOrBackendId ||
            r.requestNumber == idOrBackendId,
      );
    } catch (_) {
      try {
        return _requests.firstWhere(
          (r) =>
              r.id == idOrBackendId ||
              r.backendId == idOrBackendId ||
              r.requestNumber == idOrBackendId,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Fetches authenticated student's requests from GET /api/requests.
  Future<void> loadStudentRequests({bool forceRefresh = false}) async {
    if (_isLoadingRequests) return;
    if (!forceRefresh && _hasLoadedRequests) return;

    _isLoadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      final fetched = await studentWorkflowService.fetchStudentRequests();
      _studentRequests = fetched;
      _hasLoadedRequests = true;
      _requestsError = null;

      // Sync with _requests for any active views
      for (final item in fetched) {
        final idx = _requests.indexWhere((r) =>
            r.id == item.id ||
            (r.backendId != null && r.backendId == item.backendId));
        if (idx != -1) {
          _requests[idx] = item;
        } else {
          _requests.insert(0, item);
        }
      }
    } on ApiException catch (e) {
      _requestsError = e.message;
    } catch (e) {
      _requestsError = 'Failed to load requests. Please check connection.';
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  /// Fetches detailed request instance from GET /api/requests/:id.
  Future<JourneyRequest> loadRequestDetails(String id) async {
    final req = await studentWorkflowService.fetchRequestDetails(id);

    // Update in _studentRequests
    final sIdx = _studentRequests.indexWhere((r) =>
        r.id == req.id ||
        (r.backendId != null && r.backendId == req.backendId));
    if (sIdx != -1) {
      _studentRequests[sIdx] = req;
    } else {
      _studentRequests.insert(0, req);
    }

    // Update in _requests
    final idx = _requests.indexWhere((r) =>
        r.id == req.id ||
        (r.backendId != null && r.backendId == req.backendId));
    if (idx != -1) {
      _requests[idx] = req;
    } else {
      _requests.insert(0, req);
    }

    notifyListeners();
    return req;
  }

  /// Submits simulated fee payment via PATCH /api/requests/:id/payment.
  Future<JourneyRequest> submitStudentPayment(String id) async {
    _isProcessingPayment = true;
    _paymentError = null;
    notifyListeners();

    try {
      final updated = await studentWorkflowService.confirmSimulatedPayment(id);

      // Update in _studentRequests
      final sIdx = _studentRequests.indexWhere((r) =>
          r.id == updated.id ||
          (r.backendId != null && r.backendId == updated.backendId));
      if (sIdx != -1) {
        _studentRequests[sIdx] = updated;
      } else {
        _studentRequests.insert(0, updated);
      }

      // Update in _requests
      final idx = _requests.indexWhere((r) =>
          r.id == updated.id ||
          (r.backendId != null && r.backendId == updated.backendId));
      if (idx != -1) {
        _requests[idx] = updated;
      } else {
        _requests.insert(0, updated);
      }

      return updated;
    } on ApiException catch (e) {
      _paymentError = e.message;
      rethrow;
    } catch (e) {
      _paymentError = e.toString();
      rethrow;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  /// Fetches pending requests from GET /api/staff/queue.
  Future<void> loadStaffQueue({bool forceRefresh = false}) async {
    if (_isLoadingStaffQueue) return;
    if (!forceRefresh && _hasLoadedStaffQueue) return;

    _isLoadingStaffQueue = true;
    _staffQueueError = null;
    notifyListeners();

    try {
      final fetched = await staffWorkflowService.fetchStaffQueue();
      _staffQueue = fetched;
      _hasLoadedStaffQueue = true;
      _staffQueueError = null;

      // Reconcile with _requests
      for (final item in fetched) {
        final idx = _requests.indexWhere((r) =>
            r.id == item.id ||
            (r.backendId != null && r.backendId == item.backendId));
        if (idx != -1) {
          _requests[idx] = item;
        } else {
          _requests.insert(0, item);
        }
      }
    } on ApiException catch (e) {
      _staffQueueError = e.message;
    } catch (e) {
      _staffQueueError = 'Failed to load staff queue. Please check connection.';
    } finally {
      _isLoadingStaffQueue = false;
      notifyListeners();
    }
  }

  /// Approves a pending workflow step at [stepIndex] for request [requestId].
  /// Uses authoritative backend response to update local state and queue.
  Future<JourneyRequest> submitStepApproval({
    required String requestId,
    required int stepIndex,
    String comment = '',
  }) async {
    if (_isActioningStep) {
      throw const ApiException(
        statusCode: 400,
        code: 'ACTION_IN_PROGRESS',
        message: 'A review action is already being processed.',
      );
    }

    _isActioningStep = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await staffWorkflowService.approveStep(
        requestId: requestId,
        stepIndex: stepIndex,
        comment: comment,
      );

      _syncActionedRequest(updated);
      _actionError = null;
      return updated;
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to approve step. Please check connection.';
      throw ApiException(
        statusCode: 500,
        code: 'NETWORK_ERROR',
        message: _actionError!,
      );
    } finally {
      _isActioningStep = false;
      notifyListeners();
    }
  }

  /// Rejects a pending workflow step at [stepIndex] for request [requestId].
  /// Enforces non-empty comment and updates local state upon server confirmation.
  Future<JourneyRequest> submitStepRejection({
    required String requestId,
    required int stepIndex,
    required String comment,
  }) async {
    if (_isActioningStep) {
      throw const ApiException(
        statusCode: 400,
        code: 'ACTION_IN_PROGRESS',
        message: 'A review action is already being processed.',
      );
    }

    _isActioningStep = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await staffWorkflowService.rejectStep(
        requestId: requestId,
        stepIndex: stepIndex,
        comment: comment,
      );

      _syncActionedRequest(updated);
      _actionError = null;
      return updated;
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to reject step. Please check connection.';
      throw ApiException(
        statusCode: 500,
        code: 'NETWORK_ERROR',
        message: _actionError!,
      );
    } finally {
      _isActioningStep = false;
      notifyListeners();
    }
  }

  /// Synchronizes an actioned request across _staffQueue, _studentRequests, _adminRequests, and _requests.
  void _syncActionedRequest(JourneyRequest updated) {
    // In staff queue, if step is no longer pending staff review or request is terminal, remove it
    _staffQueue.removeWhere((r) =>
        r.id == updated.id ||
        (r.backendId != null && r.backendId == updated.backendId));

    // Update in _requests
    final idx = _requests.indexWhere((r) =>
        r.id == updated.id ||
        (r.backendId != null && r.backendId == updated.backendId));
    if (idx != -1) {
      _requests[idx] = updated;
    } else {
      _requests.insert(0, updated);
    }

    // Update in _studentRequests if present
    final sIdx = _studentRequests.indexWhere((r) =>
        r.id == updated.id ||
        (r.backendId != null && r.backendId == updated.backendId));
    if (sIdx != -1) {
      _studentRequests[sIdx] = updated;
    }

    // Update in _adminRequests if present
    final aIdx = _adminRequests.indexWhere((r) =>
        r.id == updated.id ||
        (r.backendId != null && r.backendId == updated.backendId));
    if (aIdx != -1) {
      _adminRequests[aIdx] = updated;
    }
  }

  /// Fetches global system overview stats from GET /api/admin/stats.
  Future<void> loadAdminStats({bool forceRefresh = false}) async {
    if (_isLoadingAdminStats) return;
    if (!forceRefresh && _hasLoadedAdminStats) return;

    _isLoadingAdminStats = true;
    _adminStatsError = null;
    notifyListeners();

    try {
      final fetched = await adminWorkflowService.fetchAdminStats();
      _adminStats = fetched;
      _hasLoadedAdminStats = true;
      _adminStatsError = null;
    } on ApiException catch (e) {
      _adminStatsError = e.message;
    } catch (e) {
      _adminStatsError =
          'Failed to load system statistics. Please check connection.';
    } finally {
      _isLoadingAdminStats = false;
      notifyListeners();
    }
  }

  /// Fetches institutional requests from GET /api/admin/requests with optional filtering.
  Future<void> loadAdminRequests({
    String? status,
    String? serviceId,
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    if (_isLoadingAdminRequests) return;
    if (!forceRefresh &&
        _hasLoadedAdminRequests &&
        status == null &&
        serviceId == null &&
        page == _adminCurrentPage) {
      return;
    }

    _isLoadingAdminRequests = true;
    _adminRequestsError = null;
    notifyListeners();

    try {
      final result = await adminWorkflowService.fetchAdminRequests(
        status: status,
        serviceId: serviceId,
        page: page,
        limit: limit,
      );
      _adminRequests = result.items;
      _adminTotalRequests = result.total;
      _adminTotalPages = result.pages;
      _adminCurrentPage = result.page;
      _hasLoadedAdminRequests = true;
      _adminRequestsError = null;

      // Sync into _requests as well
      for (final item in result.items) {
        final idx = _requests.indexWhere((r) =>
            r.id == item.id ||
            (r.backendId != null && r.backendId == item.backendId));
        if (idx != -1) {
          _requests[idx] = item;
        } else {
          _requests.insert(0, item);
        }
      }
    } on ApiException catch (e) {
      _adminRequestsError = e.message;
    } catch (e) {
      _adminRequestsError =
          'Failed to load requests list. Please check connection.';
    } finally {
      _isLoadingAdminRequests = false;
      notifyListeners();
    }
  }

  /// Fetches pending student registrations awaiting administrator review.
  /// Calls GET /api/admin/pending-users.
  Future<void> loadPendingUsers({bool forceRefresh = false}) async {
    if (_isLoadingPendingUsers) return;
    if (!forceRefresh && _hasLoadedPendingUsers) return;

    _isLoadingPendingUsers = true;
    _pendingUsersError = null;
    notifyListeners();

    try {
      final list = await adminWorkflowService.fetchPendingUsers();
      _pendingUsers = list;
      _hasLoadedPendingUsers = true;
      _pendingUsersError = null;
    } on ApiException catch (e) {
      _pendingUsersError = e.message;
    } catch (e) {
      _pendingUsersError =
          'Failed to load pending users list. Please check connection.';
    } finally {
      _isLoadingPendingUsers = false;
      notifyListeners();
    }
  }

  /// Approves a pending student registration.
  /// Calls PATCH /api/admin/users/:id/approve and removes user from pending list.
  Future<void> approvePendingUser(String userId) async {
    _pendingUsersError = null;
    try {
      await adminWorkflowService.approveUser(userId);
      _pendingUsers.removeWhere((u) => u.id == userId);
      notifyListeners();
    } on ApiException catch (e) {
      _pendingUsersError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _pendingUsersError = 'Failed to approve user. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Rejects a pending student registration with an optional reason.
  /// Calls PATCH /api/admin/users/:id/reject and removes user from pending list.
  Future<void> rejectPendingUser(String userId, {String? reason}) async {
    _pendingUsersError = null;
    try {
      await adminWorkflowService.rejectUser(userId, reason: reason);
      _pendingUsers.removeWhere((u) => u.id == userId);
      notifyListeners();
    } on ApiException catch (e) {
      _pendingUsersError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _pendingUsersError = 'Failed to reject user. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Loads managed users for administrator oversight from GET /api/admin/users.
  Future<void> loadManagedUsers({
    bool forceRefresh = false,
    String? role,
    String? approvalStatus,
    String? search,
    int page = 1,
  }) async {
    if (_isLoadingManagedUsers) return;
    if (!forceRefresh && _hasLoadedManagedUsers && search == null && role == null && approvalStatus == null && page == _managedUsersPage) {
      return;
    }

    _isLoadingManagedUsers = true;
    _managedUsersError = null;
    notifyListeners();

    try {
      final result = await adminWorkflowService.fetchUsers(
        role: role,
        approvalStatus: approvalStatus,
        search: search,
        page: page,
      );
      _managedUsers = result.items;
      _managedUsersTotal = result.total;
      _managedUsersPages = result.pages;
      _managedUsersPage = result.page;
      _hasLoadedManagedUsers = true;
      _managedUsersError = null;
    } on ApiException catch (e) {
      _managedUsersError = e.message;
    } catch (e) {
      _managedUsersError = 'Unable to load user accounts. Please check connectivity.';
    } finally {
      _isLoadingManagedUsers = false;
      notifyListeners();
    }
  }

  /// Administratively creates a student or staff account.
  Future<ManagedUser> createManagedUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    String? studentId,
    String? staffId,
  }) async {
    try {
      final newUser = await adminWorkflowService.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        departmentId: departmentId,
        studentId: studentId,
        staffId: staffId,
      );
      _managedUsers.insert(0, newUser);
      _managedUsersTotal += 1;
      notifyListeners();
      return newUser;
    } on ApiException catch (e) {
      _managedUsersError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _managedUsersError = 'Failed to create user account. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Changes a user's role between student and staff.
  Future<ManagedUser> updateManagedUserRole({
    required String userId,
    required String newRole,
    String? studentId,
    String? staffId,
    String? departmentId,
  }) async {
    try {
      final updated = await adminWorkflowService.changeUserRole(
        userId: userId,
        newRole: newRole,
        studentId: studentId,
        staffId: staffId,
        departmentId: departmentId,
      );
      final index = _managedUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _managedUsers[index] = updated;
      }
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _managedUsersError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _managedUsersError = 'Failed to update user role. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Permanently deletes a user account (Admin).
  Future<void> deleteManagedUser(String userId) async {
    try {
      await adminWorkflowService.deleteUser(userId);
      _managedUsers.removeWhere((u) => u.id == userId);
      _managedUsersTotal = (_managedUsersTotal - 1).clamp(0, 999999);
      notifyListeners();
    } on ApiException catch (e) {
      _managedUsersError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _managedUsersError = 'Failed to delete user account. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Loads student accounts for staff review from GET /api/staff/students.
  Future<void> loadStaffStudents({
    bool forceRefresh = false,
    String? search,
    String? approvalStatus,
    int page = 1,
  }) async {
    if (_isLoadingStaffStudents) return;
    if (!forceRefresh &&
        _hasLoadedStaffStudents &&
        search == null &&
        approvalStatus == null &&
        page == _staffStudentsPage) {
      return;
    }

    _isLoadingStaffStudents = true;
    _staffStudentsError = null;
    notifyListeners();

    try {
      final result = await staffWorkflowService.fetchStudents(
        search: search,
        approvalStatus: approvalStatus,
        page: page,
      );
      _staffStudents = result.items;
      _staffStudentsTotal = result.total;
      _staffStudentsPages = result.pages;
      _staffStudentsPage = result.page;
      _hasLoadedStaffStudents = true;
      _staffStudentsError = null;
    } on ApiException catch (e) {
      _staffStudentsError = e.message;
    } catch (e) {
      _staffStudentsError = 'Unable to load student accounts. Please check connectivity.';
    } finally {
      _isLoadingStaffStudents = false;
      notifyListeners();
    }
  }

  /// Loads pending student registrations awaiting staff review from GET /api/staff/pending-students.
  Future<void> loadStaffPendingStudents({bool forceRefresh = false}) async {
    if (_isLoadingStaffPendingStudents) return;
    if (!forceRefresh && _hasLoadedStaffPendingStudents) return;

    _isLoadingStaffPendingStudents = true;
    _staffPendingStudentsError = null;
    notifyListeners();

    try {
      final list = await staffWorkflowService.fetchPendingStudents();
      _staffPendingStudents = list;
      _hasLoadedStaffPendingStudents = true;
      _staffPendingStudentsError = null;
    } on ApiException catch (e) {
      _staffPendingStudentsError = e.message;
    } catch (e) {
      _staffPendingStudentsError =
          'Unable to load pending student registrations. Please check connectivity.';
    } finally {
      _isLoadingStaffPendingStudents = false;
      notifyListeners();
    }
  }

  /// Creates a student account on behalf of a student (Staff).
  Future<ManagedUser> createStaffStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    String? departmentId,
  }) async {
    try {
      final newUser = await staffWorkflowService.createStudent(
        name: name,
        email: email,
        password: password,
        studentId: studentId,
        departmentId: departmentId,
      );
      _staffStudents.insert(0, newUser);
      _staffStudentsTotal += 1;
      notifyListeners();
      return newUser;
    } on ApiException catch (e) {
      _staffStudentsError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _staffStudentsError = 'Failed to create student account. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Approves a pending student registration (Staff).
  Future<void> approveStaffPendingStudent(String studentId) async {
    _staffPendingStudentsError = null;
    try {
      await staffWorkflowService.approveStudent(studentId);
      _staffPendingStudents.removeWhere((u) => u.id == studentId);
      notifyListeners();
    } on ApiException catch (e) {
      _staffPendingStudentsError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _staffPendingStudentsError = 'Failed to approve student registration. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Rejects a pending student registration with an optional reason (Staff).
  Future<void> rejectStaffPendingStudent(String studentId, {String? reason}) async {
    _staffPendingStudentsError = null;
    try {
      await staffWorkflowService.rejectStudent(studentId, reason: reason);
      _staffPendingStudents.removeWhere((u) => u.id == studentId);
      notifyListeners();
    } on ApiException catch (e) {
      _staffPendingStudentsError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _staffPendingStudentsError = 'Failed to reject student registration. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Permanently deletes a student account (Staff).
  Future<void> deleteStaffStudent(String studentId) async {
    try {
      await staffWorkflowService.deleteStudent(studentId);
      _staffStudents.removeWhere((u) => u.id == studentId);
      _staffStudentsTotal = (_staffStudentsTotal - 1).clamp(0, 999999);
      notifyListeners();
    } on ApiException catch (e) {
      _staffStudentsError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _staffStudentsError = 'Failed to delete student account. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches campus service catalogue from backend GET /api/services.
  /// Caches result to avoid unnecessary duplicate API calls.
  Future<void> loadServices({bool forceRefresh = false}) async {
    if (_isLoadingServices) return;
    if (!forceRefresh && _services.isNotEmpty) return;

    _isLoadingServices = true;
    _servicesError = null;
    notifyListeners();

    try {
      final fetched = await studentWorkflowService.fetchServices();
      _services = fetched;
      _servicesError = null;
      _hasLoadedServices = true;
    } on ApiException catch (e) {
      _servicesError = e.message;
    } catch (e) {
      _servicesError = 'Failed to load services. Please check connection.';
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  /// Submits a student service request to backend POST /api/requests.
  Future<SubmissionResult> submitStudentRequest({
    required String serviceId,
    required Map<String, dynamic> formData,
  }) async {
    _isSubmittingRequest = true;
    _submitError = null;
    notifyListeners();

    try {
      final result = await studentWorkflowService.submitRequest(
        serviceId: serviceId,
        formData: formData,
      );
      _lastSubmissionResult = result;

      // Also prepend new request into the local requests list for instant display
      try {
        final newJourney = JourneyRequest.fromJson(result.raw);
        _requests.insert(0, newJourney);
      } catch (_) {
        // Fallback gracefully if fields differ
      }

      return result;
    } on ApiException catch (e) {
      _submitError = e.message;
      rethrow;
    } catch (e) {
      _submitError = 'Failed to submit request: ${e.toString()}';
      rethrow;
    } finally {
      _isSubmittingRequest = false;
      notifyListeners();
    }
  }

  void _initSeedData() {
    final now = DateTime.now();

    _requests.addAll([
      JourneyRequest(
        id: 'UF-2026-0018',
        serviceType: ServiceType.bonafide,
        studentId: UserProfile.studentUser.id,
        studentName: UserProfile.studentUser.name,
        studentRoll: UserProfile.studentUser.identifier,
        department: UserProfile.studentUser.department,
        status: JourneyStatus.departmentReview,
        submittedAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        formData: {
          'Purpose': 'Higher Education Application (Master\'s Enrolment)',
          'Number of Copies': '2',
          'Urgent Processing': 'Yes (Deadline within 3 days)',
          'Academic Semester': '6th Semester - Spring 2026',
        },
        timeline: [
          TimelineStep(
            title: 'Request Submitted',
            description:
                'Application successfully uploaded and dispatched to Department Office.',
            actorRole: 'Student',
            actorName: UserProfile.studentUser.name,
            timestamp: now.subtract(const Duration(hours: 6)),
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Department Verification',
            description:
                'Enrolment records and student clearance being verified by Academic Staff.',
            actorRole: 'Department Staff',
            actorName: 'Dr. Sarah Jenkins',
            timestamp: now.subtract(const Duration(hours: 5)),
            isCurrent: true,
          ),
          TimelineStep(
            title: 'Administrative Approval',
            description:
                'Dean / Registrar seal and institutional digital signature.',
            actorRole: 'Administrator',
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
          TimelineStep(
            title: 'Issuance & Download',
            description:
                'Digitally authenticated certificate ready for collection/download.',
            actorRole: 'System',
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      JourneyRequest(
        id: 'UF-2026-0014',
        serviceType: ServiceType.idCard,
        studentId: UserProfile.studentUser.id,
        studentName: UserProfile.studentUser.name,
        studentRoll: UserProfile.studentUser.identifier,
        department: UserProfile.studentUser.department,
        status: JourneyStatus.paymentRequired,
        feeAmount: 200.0,
        isFeePaid: false,
        submittedAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        formData: {
          'Reason': 'Lost on campus shuttle bus',
          'Police Reference / FIR': 'N/A (Campus Incident Log #9912)',
          'Contact Phone': '+1 (555) 382-9102',
          'Delivery Mode': 'Campus Security Gate 2 Counter',
        },
        timeline: [
          TimelineStep(
            title: 'Incident Report Filed',
            description: 'ID card replacement request registered in system.',
            actorRole: 'Student',
            actorName: UserProfile.studentUser.name,
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Security Clearance Verified',
            description:
                'Security desk reviewed incident details and approved card re-issue.',
            actorRole: 'Security Desk Staff',
            actorName: 'Officer Miller',
            timestamp: now.subtract(const Duration(hours: 12)),
            isCompleted: true,
            comment:
                'Student identity confirmed from database photo; previous badge deactivated.',
          ),
          TimelineStep(
            title: 'Replacement Fee Payment',
            description:
                'Standard smart-card re-printing fee (₹200) pending payment.',
            actorRole: 'Student',
            timestamp: now.subtract(const Duration(hours: 10)),
            isCurrent: true,
          ),
          TimelineStep(
            title: 'Admin Printing Order',
            description:
                'Final issuance confirmation and card production queued.',
            actorRole: 'Administrator',
            timestamp: now.subtract(const Duration(hours: 8)),
          ),
        ],
      ),
      JourneyRequest(
        id: 'UF-2026-0009',
        serviceType: ServiceType.equipment,
        studentId: UserProfile.studentUser.id,
        studentName: UserProfile.studentUser.name,
        studentRoll: UserProfile.studentUser.identifier,
        department: UserProfile.studentUser.department,
        status: JourneyStatus.approved,
        submittedAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        formData: {
          'Equipment Category': 'Audio/Visual Projector (4K HD)',
          'Item Asset Tag': 'AV-PROJ-8841',
          'Booking Start': '2026-11-02 10:00 AM',
          'Return By': '2026-11-02 04:30 PM',
          'Supervisor Faculty': 'Prof. A. Henderson',
          'Usage Context': 'Final Year Capstone Design Presentation in Hall B',
        },
        timeline: [
          TimelineStep(
            title: 'Booking Request Submitted',
            description: 'Reservation scheduled for Audio/Visual Equipment.',
            actorRole: 'Student',
            actorName: UserProfile.studentUser.name,
            timestamp: now.subtract(const Duration(days: 3)),
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Custodian Approval',
            description:
                'Equipment availability confirmed; reserved under student roll.',
            actorRole: 'Equipment Custodian',
            actorName: 'Dr. Sarah Jenkins',
            timestamp: now.subtract(const Duration(days: 2)),
            isCompleted: true,
            comment:
                'Asset inspected and packaged with power cable and HDMI adapter.',
          ),
          TimelineStep(
            title: 'Confirmed & Ready for Pick-up',
            description:
                'Bring campus ID card to Tech Hub Counter at scheduled time.',
            actorRole: 'System',
            timestamp: now.subtract(const Duration(days: 2)),
            isCompleted: true,
          ),
        ],
      ),
      JourneyRequest(
        id: 'UF-2026-0004',
        serviceType: ServiceType.bonafide,
        studentId: 'u-std-999',
        studentName: 'Marcus Cole',
        studentRoll: 'MECH-2022-019',
        department: 'Mechanical Engineering',
        status: JourneyStatus.rejected,
        submittedAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
        rejectionReason:
            'Fee dues pending in Finance office. Clear semester fee before requesting certificate.',
        formData: {
          'Purpose': 'Personal Bank Account Verification',
          'Number of Copies': '1',
          'Academic Semester': '8th Semester',
        },
        timeline: [
          TimelineStep(
            title: 'Request Submitted',
            description: 'Application entered into workflow queue.',
            actorRole: 'Student',
            actorName: 'Marcus Cole',
            timestamp: now.subtract(const Duration(days: 5)),
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Department Verification',
            description:
                'Rejected by Department Secretary due to unresolved fee clearance.',
            actorRole: 'Department Staff',
            actorName: 'Dr. Sarah Jenkins',
            timestamp: now.subtract(const Duration(days: 4)),
            isCompleted: false,
            isRejected: true,
            comment:
                'Clear outstanding balance with Bursar before requesting official endorsement.',
          ),
        ],
      ),
    ]);
  }

  void submitRequest({
    required ServiceType serviceType,
    required Map<String, String> formData,
  }) {
    final now = DateTime.now();
    final newId = 'UF-2026-00${_requests.length + 21}';

    JourneyStatus initialStatus;
    List<TimelineStep> timeline = [];
    double fee = 0.0;

    switch (serviceType) {
      case ServiceType.bonafide:
        initialStatus = JourneyStatus.departmentReview;
        timeline = [
          TimelineStep(
            title: 'Request Submitted',
            description: 'Certificate petition logged with campus office.',
            actorRole: 'Student',
            actorName: _currentUser.name,
            timestamp: now,
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Department Verification',
            description: 'Staff checking academic records and eligibility.',
            actorRole: 'Department Staff',
            timestamp: now,
            isCurrent: true,
          ),
          TimelineStep(
            title: 'Administrative Approval',
            description: 'Dean / Registrar digital seal and sign-off.',
            actorRole: 'Administrator',
            timestamp: now,
          ),
          TimelineStep(
            title: 'Issuance & Ready',
            description: 'Digitally verified document ready.',
            actorRole: 'System',
            timestamp: now,
          ),
        ];
        break;

      case ServiceType.idCard:
        initialStatus = JourneyStatus.securityReview;
        fee = 200.0;
        timeline = [
          TimelineStep(
            title: 'Report Submitted',
            description: 'Replacement ticket created for smart badge.',
            actorRole: 'Student',
            actorName: _currentUser.name,
            timestamp: now,
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Security Verification',
            description:
                'Security office checking badge deactivation and records.',
            actorRole: 'Security Desk',
            timestamp: now,
            isCurrent: true,
          ),
          TimelineStep(
            title: 'Processing Fee Payment',
            description: 'Campus smart-card reprinting fee (₹200).',
            actorRole: 'Student',
            timestamp: now,
          ),
          TimelineStep(
            title: 'Card Production & Dispatch',
            description: 'Printing at Registrar card facility.',
            actorRole: 'Administrator',
            timestamp: now,
          ),
        ];
        break;

      case ServiceType.equipment:
        initialStatus = JourneyStatus.departmentReview;
        timeline = [
          TimelineStep(
            title: 'Booking Request Submitted',
            description: 'Asset reservation requested for review.',
            actorRole: 'Student',
            actorName: _currentUser.name,
            timestamp: now,
            isCompleted: true,
          ),
          TimelineStep(
            title: 'Equipment Custodian Review',
            description:
                'Custodian verifying inventory availability and condition.',
            actorRole: 'Equipment Custodian',
            timestamp: now,
            isCurrent: true,
          ),
          TimelineStep(
            title: 'Confirmed & Scheduled',
            description:
                'Equipment reserved and locked for the designated slot.',
            actorRole: 'System',
            timestamp: now,
          ),
        ];
        break;
    }

    final newRequest = JourneyRequest(
      id: newId,
      serviceType: serviceType,
      studentId: _currentUser.id,
      studentName: _currentUser.name,
      studentRoll: _currentUser.identifier,
      department: _currentUser.department,
      status: initialStatus,
      submittedAt: now,
      updatedAt: now,
      formData: formData,
      timeline: timeline,
      feeAmount: fee,
      isFeePaid: false,
    );

    _requests.insert(0, newRequest);
    notifyListeners();
  }

  void staffReviewRequest({
    required String requestId,
    required bool approve,
    required String comment,
  }) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    final now = DateTime.now();

    if (!approve) {
      // Rejection branch
      final updatedTimeline = req.timeline.map((step) {
        if (step.isCurrent) {
          return step.copyWith(
            isCurrent: false,
            isRejected: true,
            comment: comment,
            timestamp: now,
          );
        }
        return step;
      }).toList();

      _requests[index] = req.copyWith(
        status: JourneyStatus.rejected,
        updatedAt: now,
        staffComment: comment,
        rejectionReason: comment,
        timeline: updatedTimeline,
      );
    } else {
      // Approval branch
      JourneyStatus nextStatus;
      if (req.serviceType == ServiceType.bonafide) {
        nextStatus = JourneyStatus.adminApproval;
      } else if (req.serviceType == ServiceType.idCard) {
        nextStatus = JourneyStatus.paymentRequired;
      } else {
        // Equipment booking is approved by custodian directly
        nextStatus = JourneyStatus.approved;
      }

      int currentStepIndex = req.timeline.indexWhere((s) => s.isCurrent);
      final updatedTimeline = List<TimelineStep>.from(req.timeline);

      if (currentStepIndex != -1) {
        updatedTimeline[currentStepIndex] =
            updatedTimeline[currentStepIndex].copyWith(
          isCompleted: true,
          isCurrent: false,
          comment:
              comment.isNotEmpty ? comment : 'Approved by department staff',
          actorName: _currentUser.name,
          timestamp: now,
        );

        if (currentStepIndex + 1 < updatedTimeline.length) {
          if (nextStatus != JourneyStatus.approved) {
            updatedTimeline[currentStepIndex + 1] =
                updatedTimeline[currentStepIndex + 1].copyWith(isCurrent: true);
          } else {
            // All subsequent steps completed
            for (int i = currentStepIndex + 1;
                i < updatedTimeline.length;
                i++) {
              updatedTimeline[i] = updatedTimeline[i].copyWith(
                isCompleted: true,
                isCurrent: false,
                timestamp: now,
              );
            }
          }
        }
      }

      _requests[index] = req.copyWith(
        status: nextStatus,
        updatedAt: now,
        staffComment: comment,
        timeline: updatedTimeline,
      );
    }

    notifyListeners();
  }

  void studentPayFee(String requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    final now = DateTime.now();

    int currentStepIndex = req.timeline.indexWhere((s) => s.isCurrent);
    final updatedTimeline = List<TimelineStep>.from(req.timeline);

    if (currentStepIndex != -1) {
      updatedTimeline[currentStepIndex] =
          updatedTimeline[currentStepIndex].copyWith(
        isCompleted: true,
        isCurrent: false,
        comment:
            'Online payment received (₹${req.feeAmount.toStringAsFixed(0)})',
        timestamp: now,
      );
      if (currentStepIndex + 1 < updatedTimeline.length) {
        updatedTimeline[currentStepIndex + 1] =
            updatedTimeline[currentStepIndex + 1].copyWith(isCurrent: true);
      }
    }

    _requests[index] = req.copyWith(
      status: JourneyStatus.adminApproval,
      isFeePaid: true,
      updatedAt: now,
      timeline: updatedTimeline,
    );

    notifyListeners();
  }

  void adminReviewRequest({
    required String requestId,
    required bool approve,
    required String comment,
  }) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    final now = DateTime.now();

    if (!approve) {
      final updatedTimeline = req.timeline.map((step) {
        if (step.isCurrent) {
          return step.copyWith(
            isCurrent: false,
            isRejected: true,
            comment: comment,
            timestamp: now,
          );
        }
        return step;
      }).toList();

      _requests[index] = req.copyWith(
        status: JourneyStatus.rejected,
        updatedAt: now,
        adminComment: comment,
        rejectionReason: comment,
        timeline: updatedTimeline,
      );
    } else {
      final updatedTimeline = req.timeline.map((step) {
        return step.copyWith(
          isCompleted: true,
          isCurrent: false,
          comment: step.isCurrent
              ? (comment.isNotEmpty ? comment : 'Approved by Executive Admin')
              : step.comment,
        );
      }).toList();

      _requests[index] = req.copyWith(
        status: JourneyStatus.approved,
        updatedAt: now,
        adminComment: comment,
        timeline: updatedTimeline,
      );
    }

    notifyListeners();
  }
}
