import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/auth/auth_service.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/services/admin_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/services/staff_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/views/admin/admin_user_management_view.dart';
import 'package:uniflow_flutter_ui/views/staff/staff_student_management_view.dart';

void main() {
  group('Role-Based User Management — Service & Network Unit Tests', () {
    test('AdminWorkflowService.fetchUsers queries /admin/users with filters',
        () async {
      String? capturedPath;
      Map<String, String>? capturedQuery;

      final mockClient = MockClient((request) async {
        capturedPath = request.url.path;
        capturedQuery = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': '64a1b2c3d4e5f6a7b8c9d011',
                'name': 'Aarav Patel',
                'email': 'aarav.patel@uniflow.edu',
                'role': 'student',
                'studentId': 'STU2026001',
                'approvalStatus': 'APPROVED',
              },
            ],
            'pagination': {
              'total': 1,
              'page': 1,
              'limit': 50,
              'pages': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('admin-jwt-token'),
      );
      final service = AdminWorkflowService(apiClient: apiClient);

      final result = await service.fetchUsers(
        role: 'student',
        approvalStatus: 'APPROVED',
        search: 'Aarav',
      );

      expect(capturedPath, contains('/admin/users'));
      expect(capturedQuery?['role'], 'student');
      expect(capturedQuery?['approvalStatus'], 'APPROVED');
      expect(capturedQuery?['search'], 'Aarav');
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Aarav Patel');
      expect(result.items.first.isStudent, true);
    });

    test('AdminWorkflowService.createUser sends correct student payload',
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
              'id': '64a1b2c3d4e5f6a7b8c9d012',
              'name': 'Kavita Iyer',
              'email': 'kavita.iyer@uniflow.edu',
              'role': 'student',
              'studentId': 'STU2026002',
              'approvalStatus': 'APPROVED',
              'mustChangePassword': true,
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('admin-jwt-token'),
      );
      final service = AdminWorkflowService(apiClient: apiClient);

      final created = await service.createUser(
        name: 'Kavita Iyer',
        email: 'kavita.iyer@uniflow.edu',
        password: 'Password123!',
        role: 'student',
        studentId: 'STU2026002',
      );

      expect(capturedMethod, 'POST');
      expect(capturedPath, contains('/admin/users'));
      expect(capturedBody?['role'], 'student');
      expect(capturedBody?['studentId'], 'STU2026002');
      expect(created.name, 'Kavita Iyer');
      expect(created.isStudent, true);
    });

    test('AdminWorkflowService.changeUserRole sends PATCH to /admin/users/:id/role',
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
              'id': '64a1b2c3d4e5f6a7b8c9d011',
              'name': 'Aarav Patel',
              'email': 'aarav.patel@uniflow.edu',
              'role': 'staff',
              'staffId': 'STF-ENG-01',
              'approvalStatus': 'APPROVED',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('admin-jwt-token'),
      );
      final service = AdminWorkflowService(apiClient: apiClient);

      final updated = await service.changeUserRole(
        userId: '64a1b2c3d4e5f6a7b8c9d011',
        newRole: 'staff',
        staffId: 'STF-ENG-01',
      );

      expect(capturedMethod, 'PATCH');
      expect(capturedPath, contains('/admin/users/64a1b2c3d4e5f6a7b8c9d011/role'));
      expect(capturedBody?['role'], 'staff');
      expect(capturedBody?['staffId'], 'STF-ENG-01');
      expect(updated.role, 'staff');
      expect(updated.isStaff, true);
    });

    test('AdminWorkflowService.deleteUser sends DELETE to /admin/users/:id',
        () async {
      String? capturedMethod;
      String? capturedPath;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'deleted': true,
              'userId': '64a1b2c3d4e5f6a7b8c9d011',
              'role': 'student',
              'message': 'Account permanently deleted.',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('admin-jwt-token'),
      );
      final service = AdminWorkflowService(apiClient: apiClient);

      await service.deleteUser('64a1b2c3d4e5f6a7b8c9d011');

      expect(capturedMethod, 'DELETE');
      expect(capturedPath, contains('/admin/users/64a1b2c3d4e5f6a7b8c9d011'));
    });

    test('StaffWorkflowService.fetchPendingStudents queries /staff/pending-students',
        () async {
      String? capturedMethod;
      String? capturedPath;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': '64a1b2c3d4e5f6a7b8c9d033',
                'name': 'Pending Student',
                'email': 'pending@uniflow.edu',
                'role': 'student',
                'studentId': 'STU2026033',
                'approvalStatus': 'PENDING',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final service = StaffWorkflowService(apiClient: apiClient);

      final list = await service.fetchPendingStudents();

      expect(capturedMethod, 'GET');
      expect(capturedPath, contains('/staff/pending-students'));
      expect(list.length, 1);
      expect(list.first.name, 'Pending Student');
    });

    test('StaffWorkflowService.createStudent sends POST to /staff/students',
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
              'id': '64a1b2c3d4e5f6a7b8c9d044',
              'name': 'New Student',
              'email': 'new.student@uniflow.edu',
              'role': 'student',
              'studentId': 'STU2026044',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final service = StaffWorkflowService(apiClient: apiClient);

      final created = await service.createStudent(
        name: 'New Student',
        email: 'new.student@uniflow.edu',
        password: 'Password123!',
        studentId: 'STU2026044',
      );

      expect(capturedMethod, 'POST');
      expect(capturedPath, contains('/staff/students'));
      expect(capturedBody?['studentId'], 'STU2026044');
      expect(created.name, 'New Student');
    });

    test('StaffWorkflowService.approveStudent sends PATCH to /staff/students/:id/approve',
        () async {
      String? capturedMethod;
      String? capturedPath;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': '64a1b2c3d4e5f6a7b8c9d033', 'approvalStatus': 'APPROVED'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final service = StaffWorkflowService(apiClient: apiClient);

      await service.approveStudent('64a1b2c3d4e5f6a7b8c9d033');

      expect(capturedMethod, 'PATCH');
      expect(capturedPath, contains('/staff/students/64a1b2c3d4e5f6a7b8c9d033/approve'));
    });

    test('StaffWorkflowService.rejectStudent sends PATCH to /staff/students/:id/reject with reason',
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
            'data': {'id': '64a1b2c3d4e5f6a7b8c9d033', 'approvalStatus': 'REJECTED'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final service = StaffWorkflowService(apiClient: apiClient);

      await service.rejectStudent('64a1b2c3d4e5f6a7b8c9d033', reason: 'Invalid student ID');

      expect(capturedMethod, 'PATCH');
      expect(capturedPath, contains('/staff/students/64a1b2c3d4e5f6a7b8c9d033/reject'));
      expect(capturedBody?['reason'], 'Invalid student ID');
    });

    test('StaffWorkflowService.fetchStudents queries /staff/students with status and search',
        () async {
      String? capturedMethod;
      String? capturedPath;
      Map<String, String>? capturedQuery;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        capturedQuery = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': '64a1b2c3d4e5f6a7b8c9d011',
                'name': 'Aarav Patel',
                'email': 'aarav.patel@uniflow.edu',
                'role': 'student',
                'studentId': 'STU2026001',
              },
            ],
            'pagination': {'total': 1, 'page': 1, 'limit': 50, 'pages': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final service = StaffWorkflowService(apiClient: apiClient);

      final result = await service.fetchStudents(
        approvalStatus: 'APPROVED',
        search: 'Aarav',
      );

      expect(capturedMethod, 'GET');
      expect(capturedPath, contains('/staff/students'));
      expect(capturedQuery?['approvalStatus'], 'APPROVED');
      expect(capturedQuery?['search'], 'Aarav');
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Aarav Patel');
    });

    test('StaffWorkflowService.deleteStudent sends DELETE to /staff/students/:id',
        () async {
      String? capturedMethod;
      String? capturedPath;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'deleted': true,
              'userId': '64a1b2c3d4e5f6a7b8c9d011',
              'role': 'student',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final service = StaffWorkflowService(apiClient: apiClient);

      await service.deleteStudent('64a1b2c3d4e5f6a7b8c9d011');

      expect(capturedMethod, 'DELETE');
      expect(capturedPath, contains('/staff/students/64a1b2c3d4e5f6a7b8c9d011'));
    });
  });

  group('Role-Based User Management — Widget UI Tests', () {
    testWidgets('AdminUserManagementView renders user search, filter chips and users',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/admin/users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': '64a1b2c3d4e5f6a7b8c9d011',
                  'name': 'Pooja Verma',
                  'email': 'pooja.verma@uniflow.edu',
                  'role': 'student',
                  'studentId': 'STU2026099',
                  'approvalStatus': 'APPROVED',
                  'isActive': true,
                },
                {
                  'id': '64a1b2c3d4e5f6a7b8c9d012',
                  'name': 'Rajesh Sharma',
                  'email': 'rajesh.sharma@uniflow.edu',
                  'role': 'staff',
                  'staffId': 'STF-REG-01',
                  'approvalStatus': 'APPROVED',
                  'isActive': true,
                },
              ],
              'pagination': {'total': 2, 'page': 1, 'limit': 50, 'pages': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true}', 200);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('admin-jwt-token'),
      );
      final authService = AuthService(apiClient: apiClient);
      final adminService = AdminWorkflowService(apiClient: apiClient);
      final appState = AppState(
        authService: authService,
        adminWorkflowService: adminService,
      );

      appState.setRole(UserRole.admin);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUserManagementView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Pooja Verma'), findsOneWidget);
      expect(find.text('Rajesh Sharma'), findsOneWidget);
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
      expect(find.text('Change Role'), findsNWidgets(2));
      expect(find.text('Delete Account'), findsNWidgets(2));
    });

    testWidgets('Create Account Dialog restricts role options to Student and Staff',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/departments')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 'dept_1', 'name': 'Computer Science', 'code': 'CSE'}
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/admin/users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'page': 1, 'limit': 50, 'pages': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true}', 200);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('admin-jwt-token'),
      );
      final authService = AuthService(apiClient: apiClient);
      final adminService = AdminWorkflowService(apiClient: apiClient);
      final appState = AppState(
        authService: authService,
        adminWorkflowService: adminService,
      );

      appState.setRole(UserRole.admin);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUserManagementView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Create User Account'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Staff Member'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Administrator'), findsNothing);
    });

    testWidgets('StaffStudentManagementView renders registrations and directory tabs',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/staff/pending-students')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': '64a1b2c3d4e5f6a7b8c9d090',
                  'name': 'Pending Student Amit',
                  'email': 'amit.p@uniflow.edu',
                  'role': 'student',
                  'studentId': 'STU2026090',
                  'approvalStatus': 'PENDING',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/staff/students')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': '64a1b2c3d4e5f6a7b8c9d020',
                  'name': 'Sunil Gavaskar',
                  'email': 'sunil.g@uniflow.edu',
                  'role': 'student',
                  'studentId': 'STU2026055',
                  'approvalStatus': 'APPROVED',
                },
              ],
              'pagination': {'total': 1, 'page': 1, 'limit': 50, 'pages': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true}', 200);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage()..saveToken('staff-jwt-token'),
      );
      final authService = AuthService(apiClient: apiClient);
      final staffService = StaffWorkflowService(apiClient: apiClient);
      final appState = AppState(
        authService: authService,
        staffWorkflowService: staffService,
      );

      appState.setRole(UserRole.staff);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffStudentManagementView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Section A: Registrations Tab
      expect(find.text('Student Registrations'), findsOneWidget);
      expect(find.text('Pending Student Amit'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Switch to Section B: Student Management Tab
      await tester.tap(find.text('Student Directory (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Create Student'), findsOneWidget);
      expect(find.text('Sunil Gavaskar'), findsOneWidget);
      expect(find.text('ID: STU2026055'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
