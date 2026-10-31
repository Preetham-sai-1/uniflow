import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/auth/auth_service.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/services/admin_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/views/admin/admin_dashboard_view.dart';
import 'package:uniflow_flutter_ui/views/auth/login_view.dart';
import 'package:uniflow_flutter_ui/views/auth/register_view.dart';

void main() {
  group('User Registration & Account Approval — Unit & Service Tests', () {
    test('AuthService.registerStudent sends payload with role: student',
        () async {
      String? capturedMethod;
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'user': {
                'id': '64a1b2c3d4e5f6a7b8c9d010',
                'name': 'Pooja Verma',
                'email': 'pooja.verma@campus.edu',
                'role': 'student',
                'approvalStatus': 'PENDING',
                'studentId': 'STU-2024-099',
              },
              'message':
                  'Registration submitted successfully. Your account is pending administrator approval.',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage(),
      );
      final authService = AuthService(apiClient: apiClient);

      final msg = await authService.registerStudent(
        name: 'Pooja Verma',
        email: 'pooja.verma@campus.edu',
        password: 'Password123!',
        studentId: 'STU-2024-099',
        departmentId: 'dept_cs_01',
      );

      expect(capturedMethod, 'POST');
      expect(capturedPath, contains('/auth/register'));
      expect(capturedBody?['role'], 'student');
      expect(capturedBody?['email'], 'pooja.verma@campus.edu');
      expect(capturedBody?['studentId'], 'STU-2024-099');
      expect(capturedBody?['departmentId'], 'dept_cs_01');
      expect(msg, contains('pending administrator approval'));
    });

    test('AuthService.fetchDepartments parses department list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'dept_1',
                'name': 'Computer Science & Engineering',
                'code': 'CSE',
              },
              {
                '_id': 'dept_2',
                'name': 'Mechanical Engineering',
                'code': 'MECH',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage(),
      );
      final authService = AuthService(apiClient: apiClient);

      final depts = await authService.fetchDepartments();
      expect(depts.length, 2);
      expect(depts[0].name, 'Computer Science & Engineering');
      expect(depts[0].code, 'CSE');
    });

    test(
        'AdminWorkflowService: fetchPendingUsers, approveUser, and rejectUser',
        () async {
      final calls = <String>[];

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        calls.add('${request.method} $path');

        if (path.contains('/admin/pending-users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'usr_pending_1',
                  'name': 'Rahul Nair',
                  'email': 'rahul@campus.edu',
                  'studentId': 'STU-001',
                  'approvalStatus': 'PENDING',
                  'department': {
                    'name': 'Computer Science',
                    'code': 'CS',
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (path.contains('/approve')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'approvalStatus': 'APPROVED', 'isActive': true},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (path.contains('/reject')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'approvalStatus': 'REJECTED',
                'rejectionReason': 'Invalid ID'
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"success": false}', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('admin_token_xyz'),
      );
      final adminService = AdminWorkflowService(apiClient: apiClient);

      final pending = await adminService.fetchPendingUsers();
      expect(pending.length, 1);
      expect(pending[0].name, 'Rahul Nair');
      expect(pending[0].studentId, 'STU-001');

      await adminService.approveUser('usr_pending_1');
      await adminService.rejectUser('usr_pending_1', reason: 'Invalid ID');

      expect(calls, contains('GET /api/admin/pending-users'));
      expect(calls, contains('PATCH /api/admin/users/usr_pending_1/approve'));
      expect(calls, contains('PATCH /api/admin/users/usr_pending_1/reject'));
    });
  });

  group('Student Registration View — Widget Tests', () {
    testWidgets(
        'RegisterView renders all inputs and enforces client validation',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/departments')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  '_id': 'dept_1',
                  'name': 'Computer Science',
                  'code': 'CS',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true, "data": {}}', 200);
      });

      final appState = AppState(
        authService: AuthService(
          apiClient: ApiClient(
            httpClient: mockClient,
            tokenStorage: InMemoryTokenStorage(),
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterView(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Verify fields exist
      expect(find.byKey(const Key('register_name_input')), findsOneWidget);
      expect(find.byKey(const Key('register_email_input')), findsOneWidget);
      expect(find.byKey(const Key('register_studentid_input')), findsOneWidget);
      expect(find.byKey(const Key('register_password_input')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_input')),
          findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);

      // Submit with empty inputs to trigger validation
      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Institutional email is required.'), findsOneWidget);
      expect(find.text('Student ID is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);

      // Enter short password and mismatched confirm
      await tester.enterText(
          find.byKey(const Key('register_name_input')), 'Test Student');
      await tester.enterText(
          find.byKey(const Key('register_email_input')), 'test@campus.edu');
      await tester.enterText(
          find.byKey(const Key('register_studentid_input')), 'STU-100');
      await tester.enterText(
          find.byKey(const Key('register_password_input')), 'short');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_input')), 'mismatch');

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('RegisterView transitions to Pending Approval on success',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/departments')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  '_id': 'dept_1',
                  'name': 'Computer Science',
                  'code': 'CS',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/auth/register')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'message':
                    'Your student account has been registered and is pending approval.',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": false}', 404);
      });

      final appState = AppState(
        authService: AuthService(
          apiClient: ApiClient(
            httpClient: mockClient,
            tokenStorage: InMemoryTokenStorage(),
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterView(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('register_name_input')), 'Kavya Sharma');
      await tester.enterText(
          find.byKey(const Key('register_email_input')), 'kavya@campus.edu');
      await tester.enterText(
          find.byKey(const Key('register_studentid_input')), 'STU-9900');
      await tester.enterText(
          find.byKey(const Key('register_password_input')), 'StrongPass123!');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_input')),
          'StrongPass123!');

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Registration Submitted'), findsOneWidget);
      expect(find.text('STATUS: PENDING APPROVAL'), findsOneWidget);
      expect(find.text('Return to Sign In'), findsOneWidget);
    });
  });

  group('Login View — Create Account Navigation & Approval Blocks', () {
    testWidgets('LoginView renders Create Account link and navigates',
        (tester) async {
      final appState = AppState(
        authService: AuthService(
          apiClient: ApiClient(
            httpClient: MockClient((_) async =>
                http.Response('{"success": true, "data": []}', 200)),
            tokenStorage: InMemoryTokenStorage(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: appState,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('login_create_account_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('login_create_account_button')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterView), findsOneWidget);
    });

    testWidgets('LoginView displays pending approval message on 403',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'ACCOUNT_PENDING_APPROVAL',
              'message':
                  'Your account registration is pending administrator approval.',
            },
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final appState = AppState(
        authService: AuthService(
          apiClient: ApiClient(
            httpClient: mockClient,
            tokenStorage: InMemoryTokenStorage(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: appState,
            onLoginSuccess: () {},
            initialEmail: 'pending.student@campus.edu',
            initialPassword: 'Password123!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Your account registration is pending administrator approval.'),
        findsOneWidget,
      );
    });
  });

  group('Admin Dashboard — Student Registration Approvals', () {
    testWidgets('AdminDashboardView displays pending student approvals',
        (tester) async {
      String? approvedUserId;

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('/admin/stats')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalApplications': 10,
                'pendingExecutiveSignOff': 2,
                'approvedCount': 7,
                'approvalRate': 70,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/admin/requests')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'pages': 1, 'page': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/admin/pending-users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'user_pending_77',
                  'name': 'Meera Sen',
                  'email': 'meera@campus.edu',
                  'studentId': 'STU-7700',
                  'approvalStatus': 'PENDING',
                  'department': {
                    'name': 'Information Technology',
                    'code': 'IT',
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/approve')) {
          approvedUserId = 'user_pending_77';
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'approvalStatus': 'APPROVED'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"success": false}', 404);
      });

      final appState = AppState(
        initialAuthenticated: true,
        adminWorkflowService: AdminWorkflowService(
          apiClient: ApiClient(
            httpClient: mockClient,
            tokenStorage: InMemoryTokenStorage('admin_token'),
          ),
        ),
      );
      appState.setRole(UserRole.admin);

      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminDashboardView(
              appState: appState,
              onNavigateTab: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section header
      expect(find.text('Student Account Approvals'), findsOneWidget);
      expect(find.text('Meera Sen'), findsOneWidget);
      expect(find.text('meera@campus.edu'), findsOneWidget);
      expect(find.text('ID: STU-7700'), findsOneWidget);

      // Tap Approve
      expect(find.byKey(const Key('approve_user_user_pending_77')),
          findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('approve_user_user_pending_77')));
      await tester
          .tap(find.byKey(const Key('approve_user_user_pending_77')));
      await tester.pumpAndSettle();

      expect(approvedUserId, 'user_pending_77');
    });

    testWidgets(
        'AdminDashboardView rejects student registration with reason dialog',
        (tester) async {
      String? rejectedUserId;
      String? capturedReason;

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('/admin/stats')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalApplications': 10,
                'pendingExecutiveSignOff': 2,
                'approvedCount': 7,
                'approvalRate': 70,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/admin/requests')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'pages': 1, 'page': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/admin/pending-users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'user_pending_88',
                  'name': 'Karan Gupta',
                  'email': 'karan@campus.edu',
                  'studentId': 'STU-8800',
                  'approvalStatus': 'PENDING',
                  'department': {
                    'name': 'Civil Engineering',
                    'code': 'CIVIL',
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/reject')) {
          rejectedUserId = 'user_pending_88';
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          capturedReason = body['reason'] as String?;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'approvalStatus': 'REJECTED',
                'rejectionReason': capturedReason
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"success": false}', 404);
      });

      final appState = AppState(
        initialAuthenticated: true,
        adminWorkflowService: AdminWorkflowService(
          apiClient: ApiClient(
            httpClient: mockClient,
            tokenStorage: InMemoryTokenStorage('admin_token'),
          ),
        ),
      );
      appState.setRole(UserRole.admin);

      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminDashboardView(
              appState: appState,
              onNavigateTab: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reject_user_user_pending_88')),
          findsOneWidget);
      await tester
          .ensureVisible(find.byKey(const Key('reject_user_user_pending_88')));
      await tester
          .tap(find.byKey(const Key('reject_user_user_pending_88')));
      await tester.pumpAndSettle();

      expect(find.text('Reject Registration: Karan Gupta'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('reject_reason_input')),
          'Invalid roll number verification');
      await tester.tap(find.byKey(const Key('confirm_reject_user_button')));
      await tester.pumpAndSettle();

      expect(rejectedUserId, 'user_pending_88');
      expect(capturedReason, 'Invalid roll number verification');
    });
  });
}
