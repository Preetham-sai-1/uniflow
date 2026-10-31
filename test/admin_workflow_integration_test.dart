import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/api/api_exceptions.dart';
import 'package:uniflow_flutter_ui/core/auth/auth_service.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/services/admin_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/services/staff_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/services/student_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/journey_request.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/views/admin/admin_analytics_view.dart';
import 'package:uniflow_flutter_ui/views/admin/admin_dashboard_view.dart';
import 'package:uniflow_flutter_ui/views/staff/review_dialog.dart';

void main() {
  const adminStatsJson = '''
  {
    "success": true,
    "data": {
      "requests": {
        "total": 42,
        "pending": 7,
        "completed": 31,
        "rejected": 4
      },
      "bookings": {
        "total": 15,
        "pending": 3,
        "confirmed": 10,
        "rejected": 2
      },
      "byService": [
        { "serviceName": "Bonafide Certificate", "total": 24, "pending": 4 },
        { "serviceName": "ID Card Replacement", "total": 12, "pending": 2 },
        { "serviceName": "Lab Equipment Booking", "total": 6, "pending": 1 }
      ]
    }
  }
  ''';

  const adminRequestsJson = '''
  {
    "success": true,
    "data": [
      {
        "_id": "603d2b1f1f1b2c001f8e4d20",
        "requestNumber": "UF-20261031-ADM1",
        "serviceCategory": "bonafide",
        "serviceName": "Bonafide Certificate",
        "status": "ADMIN_APPROVAL_PENDING",
        "currentStepIndex": 1,
        "createdAt": "2026-10-31T08:00:00.000Z",
        "updatedAt": "2026-10-31T09:30:00.000Z",
        "formData": {
          "Reason for Certificate": "Passport Verification",
          "Academic Year": "2026-2027"
        },
        "studentId": {
          "_id": "usr_stu_01",
          "name": "Jane Student",
          "rollNumber": "21CS042",
          "department": "Computer Science & Engineering"
        },
        "workflowTimeline": [
          {
            "stepIndex": 0,
            "title": "HOD Verification",
            "actorRole": "department_staff",
            "status": "APPROVED",
            "completedAt": "2026-10-31T09:00:00.000Z",
            "comment": "Academic standing verified"
          },
          {
            "stepIndex": 1,
            "title": "Dean Final Seal",
            "actorRole": "admin",
            "status": "PENDING"
          }
        ]
      },
      {
        "_id": "603d2b1f1f1b2c001f8e4d21",
        "requestNumber": "UF-20261031-ADM2",
        "serviceCategory": "id_card",
        "serviceName": "ID Card Replacement",
        "status": "COMPLETED",
        "createdAt": "2026-10-30T10:00:00.000Z",
        "updatedAt": "2026-10-31T11:00:00.000Z",
        "formData": {
          "Replacement Reason": "Damaged Smartchip"
        },
        "studentId": {
          "_id": "usr_stu_02",
          "name": "Alex Rivera",
          "rollNumber": "22EE015",
          "department": "Electrical Engineering"
        },
        "workflowTimeline": [
          {
            "stepIndex": 0,
            "title": "Security Verification",
            "actorRole": "security_officer",
            "status": "APPROVED",
            "completedAt": "2026-10-30T11:00:00.000Z"
          },
          {
            "stepIndex": 1,
            "title": "Executive Seal",
            "actorRole": "admin",
            "status": "APPROVED",
            "completedAt": "2026-10-31T11:00:00.000Z"
          }
        ]
      }
    ],
    "pagination": {
      "total": 2,
      "page": 1,
      "limit": 50,
      "pages": 1
    }
  }
  ''';

  const approveStepResponseJson = '''
  {
    "success": true,
    "data": {
      "_id": "603d2b1f1f1b2c001f8e4d20",
      "requestNumber": "UF-20261031-ADM1",
      "serviceCategory": "bonafide",
      "serviceName": "Bonafide Certificate",
      "status": "COMPLETED",
      "createdAt": "2026-10-31T08:00:00.000Z",
      "updatedAt": "2026-10-31T12:00:00.000Z",
      "formData": {
        "Reason for Certificate": "Passport Verification"
      },
      "studentId": {
        "_id": "usr_stu_01",
        "name": "Jane Student",
        "rollNumber": "21CS042",
        "department": "Computer Science & Engineering"
      },
      "workflowTimeline": [
        {
          "stepIndex": 0,
          "title": "HOD Verification",
          "actorRole": "department_staff",
          "status": "APPROVED"
        },
        {
          "stepIndex": 1,
          "title": "Dean Final Seal",
          "actorRole": "admin",
          "status": "APPROVED",
          "completedAt": "2026-10-31T12:00:00.000Z",
          "comment": "Executive seal granted"
        }
      ]
    }
  }
  ''';

  group('AdminWorkflowService Tests', () {
    test('fetchAdminStats successfully parses stats and computed properties',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/admin/stats') {
          return http.Response(adminStatsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{"message":"Not found"}', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('valid-admin-jwt'),
        httpClient: mockClient,
      );

      final service = AdminWorkflowService(apiClient: apiClient);
      final stats = await service.fetchAdminStats();

      expect(stats.requests.total, 42);
      expect(stats.requests.completed, 31);
      expect(stats.requests.pending, 7);
      expect(stats.requests.rejected, 4);
      expect(stats.bookings.total, 15);
      expect(stats.bookings.confirmed, 10);
      expect(stats.byService.length, 3);
      expect(stats.byService.first.serviceName, 'Bonafide Certificate');
      expect(stats.totalApplications, 42);
      expect(stats.approvalRate, 74); // (31/42) * 100 = 73.8 -> 74
      expect(stats.pendingExecutiveSignOff, 7);
      expect(stats.approvedCount, 31);
      expect(stats.rejectedCount, 4);
    });

    test(
        'fetchAdminRequests passes filters and parses pagination & journey models',
        () async {
      String? recordedQuery;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/admin/requests') {
          recordedQuery = request.url.query;
          return http.Response(adminRequestsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{"message":"Not found"}', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('valid-admin-jwt'),
        httpClient: mockClient,
      );

      final service = AdminWorkflowService(apiClient: apiClient);
      final result = await service.fetchAdminRequests(
        status: 'ADMIN_APPROVAL_PENDING',
        serviceId: 'bonafide',
        page: 2,
        limit: 10,
      );

      expect(recordedQuery, contains('status=ADMIN_APPROVAL_PENDING'));
      expect(recordedQuery, contains('serviceId=bonafide'));
      expect(recordedQuery, contains('page=2'));
      expect(recordedQuery, contains('limit=10'));

      expect(result.items.length, 2);
      expect(result.total, 2);
      expect(result.page, 1);
      expect(result.items.first.requestNumber, 'UF-20261031-ADM1');
      expect(result.items.first.status, JourneyStatus.adminApproval);
      expect(result.items.first.studentName, 'Jane Student');
      expect(result.items.last.status, JourneyStatus.approved);
    });

    test('Access control: throws 403 Forbidden for unauthorized roles',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'FORBIDDEN',
              'message': 'Access denied: insufficient permissions',
            }
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('student-jwt'),
        httpClient: mockClient,
      );

      final service = AdminWorkflowService(apiClient: apiClient);

      expect(
        () => service.fetchAdminStats(),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('AppState Admin State Management Tests', () {
    test('loadAdminStats and loadAdminRequests populate state correctly',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/admin/stats') {
          return http.Response(adminStatsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/api/admin/requests') {
          return http.Response(adminRequestsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{"message":"Not found"}', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('admin-jwt'),
        httpClient: mockClient,
      );

      final appState = AppState(
        authService: AuthService(apiClient: apiClient),
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        adminWorkflowService: AdminWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.admin);

      await appState.loadAdminStats();
      expect(appState.hasLoadedAdminStats, isTrue);
      expect(appState.adminStats, isNotNull);
      expect(appState.adminStats!.totalApplications, 42);

      await appState.loadAdminRequests();
      expect(appState.hasLoadedAdminRequests, isTrue);
      expect(appState.adminRequests.length, 2);
      expect(appState.adminQueue.length, 1);
      expect(appState.adminQueue.first.requestNumber, 'UF-20261031-ADM1');
    });

    test('Executive step approval transitions request and syncs admin state',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path ==
            '/api/staff/requests/603d2b1f1f1b2c001f8e4d20/steps/1/approve') {
          return http.Response(approveStepResponseJson, 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/api/admin/requests') {
          return http.Response(adminRequestsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{"message":"Not found"}', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('admin-jwt'),
        httpClient: mockClient,
      );

      final appState = AppState(
        authService: AuthService(apiClient: apiClient),
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        adminWorkflowService: AdminWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.admin);

      await appState.loadAdminRequests();
      expect(appState.adminQueue.length, 1);

      // Execute approval on step 1 (admin Dean seal)
      final updated = await appState.submitStepApproval(
        requestId: '603d2b1f1f1b2c001f8e4d20',
        stepIndex: 1,
        comment: 'Executive seal granted',
      );

      expect(updated.status, JourneyStatus.approved);
      // Removed from adminQueue because it is now approved (terminal)
      expect(appState.adminQueue.length, 0);
      expect(
        appState.adminRequests
            .firstWhere((r) => r.backendId == '603d2b1f1f1b2c001f8e4d20')
            .status,
        JourneyStatus.approved,
      );
    });

    test('logout clears admin state and statistics', () async {
      final mockClient = MockClient((request) async {
        return http.Response(adminStatsJson, 200,
            headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('admin-jwt'),
        httpClient: mockClient,
      );

      final appState = AppState(
        authService: AuthService(apiClient: apiClient),
        adminWorkflowService: AdminWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.admin);
      await appState.loadAdminStats();
      expect(appState.adminStats, isNotNull);

      await appState.logout();
      expect(appState.adminStats, isNull);
      expect(appState.hasLoadedAdminStats, isFalse);
      expect(appState.hasLoadedAdminRequests, isFalse);
      expect(appState.currentRole, UserRole.student);
    });
  });

  group('Admin UI Widget Tests', () {
    testWidgets(
        'AdminDashboardView renders KPIs, executive queue, and executes seal',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/admin/stats') {
          return http.Response(adminStatsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/api/admin/requests') {
          return http.Response(adminRequestsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path ==
            '/api/staff/requests/603d2b1f1f1b2c001f8e4d20/steps/1/approve') {
          return http.Response(approveStepResponseJson, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{"message":"Not found"}', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('admin-jwt'),
        httpClient: mockClient,
      );

      final appState = AppState(
        authService: AuthService(apiClient: apiClient),
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        adminWorkflowService: AdminWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.admin);

      await tester.binding.setSurfaceSize(const Size(1280, 900));

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

      // Check header and high-level KPIs
      expect(find.text('Administrative Executive Portal'), findsOneWidget);
      expect(find.text('Total Applications'), findsOneWidget);
      expect(find.text('42'), findsOneWidget); // From stats
      expect(find.text('Awaiting Final Seal'), findsOneWidget);
      expect(find.text('Approval Rate'), findsOneWidget);
      expect(find.text('74%'), findsOneWidget);

      // Check executive queue item
      expect(find.textContaining('UF-20261031-ADM1'), findsWidgets);
      expect(find.textContaining('Jane Student'), findsWidgets);
      expect(find.text('Executive Seal & Approve'), findsOneWidget);

      // Tap Executive Seal & Approve button to open ReviewDecisionDialog
      await tester.tap(find.text('Executive Seal & Approve'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewDecisionDialog), findsOneWidget);
      expect(find.text('Executive Administrative Review'), findsOneWidget);

      // Confirm approval dialog
      await tester.tap(find.text('Approve & Issue'));
      await tester.pumpAndSettle();

      // Queue item should now be sealed and cleared from pending queue
      expect(find.text('No requests pending administrative sign-off'),
          findsOneWidget);
    });

    testWidgets(
        'AdminDashboardView denies access to students and staff (Role Authorization)',
        (tester) async {
      final appState = AppState();
      appState.setRole(UserRole.student);

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

      expect(find.text('Administrative Access Required'), findsOneWidget);
      expect(find.textContaining('verified administrative privileges'),
          findsOneWidget);
      expect(find.text('Awaiting Final Seal'), findsNothing);
    });

    testWidgets(
        'AdminAnalyticsView renders service volume, status health, and SLA standards',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/admin/stats') {
          return http.Response(adminStatsJson, 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{"message":"Not found"}', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3001/api',
        tokenStorage: InMemoryTokenStorage('admin-jwt'),
        httpClient: mockClient,
      );

      final appState = AppState(
        authService: AuthService(apiClient: apiClient),
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        adminWorkflowService: AdminWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.admin);

      await tester.binding.setSurfaceSize(const Size(1280, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAnalyticsView(
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Campus Analytics & Intelligence'), findsOneWidget);
      expect(find.text('Service Volume Breakdown'), findsOneWidget);
      expect(find.text('Workflow Status Health'), findsOneWidget);
      expect(find.text('Institutional Governance & SLA Standards'),
          findsOneWidget);

      // Verify stats items
      expect(find.text('Bonafide Certificate'), findsOneWidget);
      expect(find.text('Approved & Completed'), findsOneWidget);
      expect(find.text('Equipment Bookings'), findsOneWidget);
    });

    testWidgets('AdminAnalyticsView blocks non-admin access', (tester) async {
      final appState = AppState();
      appState.setRole(UserRole.staff);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAnalyticsView(
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Administrative Access Required'), findsOneWidget);
      expect(find.text('Service Volume Breakdown'), findsNothing);
    });
  });
}
