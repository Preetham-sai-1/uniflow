import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/api/api_exceptions.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/services/staff_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/services/student_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/journey_request.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/models/service_item.dart';
import 'package:uniflow_flutter_ui/views/staff/review_dialog.dart';
import 'package:uniflow_flutter_ui/views/staff/staff_queue_view.dart';
import 'package:uniflow_flutter_ui/views/student/request_detail_view.dart';

void main() {
  final sampleQueueList = [
    {
      'stepId': '6723a101-0',
      'requestId': '6723a101',
      'requestNumber': 'UF-20261031-BF01',
      'serviceName': 'Bonafide Certificate',
      'serviceCategory': 'academic',
      'studentName': 'Arjun Sharma',
      'studentEmail': 'student@uniflow.edu',
      'studentIdNumber': 'CS2021001',
      'stepIndex': 0,
      'stepName': 'Department Verification',
      'assignedRole': 'staff',
      'status': 'DEPARTMENT_VERIFICATION_PENDING',
      'submittedAt': '2026-10-31T09:00:00.000Z',
      'waitingHours': 3,
    },
    {
      'stepId': '6723a102-0',
      'requestId': '6723a102',
      'requestNumber': 'UF-20261031-IDC02',
      'serviceName': 'ID Card Replacement',
      'serviceCategory': 'administrative',
      'studentName': 'Priya Patel',
      'studentEmail': 'priya@uniflow.edu',
      'studentIdNumber': 'EC2022045',
      'stepIndex': 0,
      'stepName': 'Security Review',
      'assignedRole': 'staff',
      'status': 'SECURITY_REVIEW_PENDING',
      'submittedAt': '2026-10-31T08:30:00.000Z',
      'waitingHours': 4,
    },
    {
      'stepId': '6723a103-0',
      'requestId': '6723a103',
      'requestNumber': 'UF-20261031-EQ03',
      'serviceName': 'Equipment Booking',
      'serviceCategory': 'facilities',
      'studentName': 'Rahul Verma',
      'studentEmail': 'rahul@uniflow.edu',
      'studentIdNumber': 'ME2023012',
      'stepIndex': 0,
      'stepName': 'Lab Staff Review',
      'assignedRole': 'staff',
      'status': 'STAFF_REVIEW_PENDING',
      'submittedAt': '2026-10-31T07:15:00.000Z',
      'waitingHours': 5,
    },
  ];

  final sampleApprovedBonafide = {
    '_id': '6723a101',
    'requestNumber': 'UF-20261031-BF01',
    'service': {
      '_id': '6723s001',
      'name': 'Bonafide Certificate',
      'slug': 'bonafide-certificate',
      'category': 'academic',
    },
    'student': {
      '_id': '6723u001',
      'name': 'Arjun Sharma',
      'studentId': 'CS2021001',
    },
    'status': 'ADMIN_APPROVAL_PENDING',
    'currentStepIndex': 1,
    'runtimeSteps': [
      {
        'stepIndex': 0,
        'name': 'Department Verification',
        'assignedRole': 'staff',
        'status': 'APPROVED',
        'comment': 'All academic records verified.',
        'actionedAt': '2026-10-31T11:00:00.000Z',
      },
      {
        'stepIndex': 1,
        'name': 'Administrative Approval',
        'assignedRole': 'admin',
        'status': 'PENDING',
      },
    ],
    'auditLog': [
      {
        'action': 'APPROVED',
        'previousStatus': 'DEPARTMENT_VERIFICATION_PENDING',
        'newStatus': 'ADMIN_APPROVAL_PENDING',
        'comment': 'All academic records verified.',
      },
    ],
  };

  final sampleRejectedBonafide = {
    '_id': '6723a101',
    'requestNumber': 'UF-20261031-BF01',
    'service': {
      '_id': '6723s001',
      'name': 'Bonafide Certificate',
      'slug': 'bonafide-certificate',
      'category': 'academic',
    },
    'student': {
      '_id': '6723u001',
      'name': 'Arjun Sharma',
      'studentId': 'CS2021001',
    },
    'status': 'REJECTED',
    'currentStepIndex': 0,
    'runtimeSteps': [
      {
        'stepIndex': 0,
        'name': 'Department Verification',
        'assignedRole': 'staff',
        'status': 'REJECTED',
        'comment': 'Enrolment record mismatch in Semester 6.',
      },
    ],
    'auditLog': [
      {
        'action': 'REJECTED',
        'comment': 'Enrolment record mismatch in Semester 6.',
      },
    ],
  };

  group('StaffWorkflowService API Client Tests', () {
    test('fetchStaffQueue fetches and deserializes pending review queue items',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/staff/queue');
        expect(request.headers['Authorization'], 'Bearer staff_jwt_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleQueueList,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StaffWorkflowService(apiClient: apiClient);
      final queue = await service.fetchStaffQueue();

      expect(queue.length, 3);
      expect(queue[0].backendId, '6723a101');
      expect(queue[0].requestNumber, 'UF-20261031-BF01');
      expect(queue[0].serviceType, ServiceType.bonafide);
      expect(queue[0].status, JourneyStatus.departmentReview);
      expect(queue[0].waitingHours, 3);

      expect(queue[1].backendId, '6723a102');
      expect(queue[1].requestNumber, 'UF-20261031-IDC02');
      expect(queue[1].serviceType, ServiceType.idCard);
      expect(queue[1].status, JourneyStatus.securityReview);
      expect(queue[1].waitingHours, 4);
    });

    test('approveStep submits comment and returns updated backend request',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
            request.url.path, '/api/staff/requests/6723a101/steps/0/approve');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['comment'], 'All academic records verified.');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleApprovedBonafide,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StaffWorkflowService(apiClient: apiClient);
      final updated = await service.approveStep(
        requestId: '6723a101',
        stepIndex: 0,
        comment: 'All academic records verified.',
      );

      expect(updated.status, JourneyStatus.adminApproval);
      expect(updated.currentStepIndex, 1);
      expect(updated.timeline[0].isCompleted, true);
      expect(updated.timeline[0].comment, 'All academic records verified.');
    });

    test('rejectStep throws client-side validation error when comment is empty',
        () async {
      final service = StaffWorkflowService();
      expect(
        () => service.rejectStep(
          requestId: '6723a101',
          stepIndex: 0,
          comment: '   ',
        ),
        throwsA(isA<ApiException>().having(
          (e) => e.code,
          'code',
          'VALIDATION_ERROR',
        )),
      );
    });

    test('rejectStep submits mandatory comment and returns rejected request',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/staff/requests/6723a101/steps/0/reject');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['comment'], 'Enrolment record mismatch in Semester 6.');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleRejectedBonafide,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StaffWorkflowService(apiClient: apiClient);
      final rejected = await service.rejectStep(
        requestId: '6723a101',
        stepIndex: 0,
        comment: 'Enrolment record mismatch in Semester 6.',
      );

      expect(rejected.status, JourneyStatus.rejected);
      expect(rejected.status.isTerminal, true);
      expect(
          rejected.rejectionReason, 'Enrolment record mismatch in Semester 6.');
    });
  });

  group('AppState Staff Queue & Action Management Tests', () {
    test('loadStaffQueue caches queue and prevents duplicate requests',
        () async {
      int apiCalls = 0;
      final mockClient = MockClient((request) async {
        apiCalls++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleQueueList,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      expect(appState.hasLoadedStaffQueue, false);

      await appState.loadStaffQueue();

      expect(apiCalls, 1);
      expect(appState.hasLoadedStaffQueue, true);
      expect(appState.staffQueue.length, 3);
      expect(appState.staffQueueError, isNull);

      // Duplicate load without forceRefresh does not trigger network call
      await appState.loadStaffQueue(forceRefresh: false);
      expect(apiCalls, 1);

      // forceRefresh triggers re-fetch
      await appState.loadStaffQueue(forceRefresh: true);
      expect(apiCalls, 2);
    });

    test('submitStepApproval removes approved item from staff queue', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/staff/queue') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleQueueList,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path ==
            '/api/staff/requests/6723a101/steps/0/approve') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleApprovedBonafide,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"success": false}', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      await appState.loadStaffQueue();
      expect(appState.staffQueue.length, 3);

      final updated = await appState.submitStepApproval(
        requestId: '6723a101',
        stepIndex: 0,
        comment: 'All academic records verified.',
      );

      expect(updated.status, JourneyStatus.adminApproval);
      // Item removed from staff queue because it is no longer awaiting staff action!
      expect(appState.staffQueue.length, 2);
      expect(appState.staffQueue.any((r) => r.backendId == '6723a101'), false);
    });

    test('submitStepRejection removes rejected item and records reason',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/staff/queue') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleQueueList,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/staff/requests/6723a101/steps/0/reject') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleRejectedBonafide,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"success": false}', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      await appState.loadStaffQueue();
      expect(appState.staffQueue.length, 3);

      final rejected = await appState.submitStepRejection(
        requestId: '6723a101',
        stepIndex: 0,
        comment: 'Enrolment record mismatch in Semester 6.',
      );

      expect(rejected.status, JourneyStatus.rejected);
      expect(appState.staffQueue.length, 2);
      expect(appState.staffQueue.any((r) => r.backendId == '6723a101'), false);
    });
  });

  group('Staff UI Widget Integration Tests', () {
    testWidgets('StaffQueueView renders queue, filters, and waiting badges',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleQueueList,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffQueueView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Staff Review Queue'), findsOneWidget);
      expect(find.textContaining('UF-20261031-BF01'), findsWidgets);
      expect(find.textContaining('UF-20261031-IDC02'), findsWidgets);
      expect(find.textContaining('UF-20261031-EQ03'), findsWidgets);
      expect(find.text('Waiting: 3h'), findsOneWidget);
      expect(find.text('Waiting: 4h'), findsOneWidget);
      expect(find.text('Review & Decide'), findsNWidgets(3));

      // Filter by "ID Card"
      await tester.tap(find.text('ID Card'));
      await tester.pumpAndSettle();

      expect(find.textContaining('UF-20261031-IDC02'), findsWidgets);
      expect(find.textContaining('UF-20261031-BF01'), findsNothing);
      expect(find.textContaining('UF-20261031-EQ03'), findsNothing);
    });

    testWidgets('ReviewDecisionDialog enforces non-empty comment on rejection',
        (WidgetTester tester) async {
      final sampleReq = JourneyRequest.fromStaffQueueJson(sampleQueueList[0]);

      final appState = AppState(
        staffWorkflowService: StaffWorkflowService(
          apiClient: ApiClient(
            httpClient: MockClient((_) async => http.Response('{}', 200)),
            tokenStorage: InMemoryTokenStorage('staff_jwt'),
          ),
        ),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewDecisionDialog(
              request: sampleReq,
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Reject without entering comment
      await tester.tap(find.text('Reject Request'));
      await tester.pumpAndSettle();

      expect(
        find.text('A mandatory comment / reason is required for rejection.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'ReviewDecisionDialog executes approval and dispatches backend payload',
        (WidgetTester tester) async {
      bool approveCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path ==
            '/api/staff/requests/6723a101/steps/0/approve') {
          approveCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleApprovedBonafide,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": false}', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      final sampleReq = JourneyRequest.fromStaffQueueJson(sampleQueueList[0]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewDecisionDialog(
              request: sampleReq,
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter endorsement comment
      await tester.enterText(
        find.byType(TextField),
        'All academic records verified.',
      );

      // Tap Approve Step
      await tester.tap(find.text('Approve Step'));
      await tester.pumpAndSettle();

      expect(approveCalled, true);
    });

    testWidgets('Security: Student is denied access to Staff Review Queue',
        (WidgetTester tester) async {
      final appState = AppState(initialAuthenticated: true);
      appState.setRole(UserRole.student);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffQueueView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(
        find.text(
          'You do not have permissions to access the Staff Review Queue. This screen requires the "staff" or "admin" role.',
        ),
        findsOneWidget,
      );
      expect(find.text('UF-20261031-BF01'), findsNothing);
    });

    testWidgets(
        'RequestDetailView displays staff action banner and opens decision dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/requests/6723a101') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                '_id': '6723a101',
                'requestNumber': 'UF-20261031-BF01',
                'service': {
                  '_id': '6723s001',
                  'name': 'Bonafide Certificate',
                  'slug': 'bonafide-certificate',
                  'category': 'academic',
                },
                'student': {
                  '_id': '6723u001',
                  'name': 'Arjun Sharma',
                  'studentId': 'CS2021001',
                },
                'department': {
                  '_id': '6723d001',
                  'name': 'Computer Science',
                  'code': 'CS',
                },
                'status': 'DEPARTMENT_VERIFICATION_PENDING',
                'currentStepIndex': 0,
                'runtimeSteps': [
                  {
                    'stepIndex': 0,
                    'name': 'Department Verification',
                    'assignedRole': 'staff',
                    'status': 'PENDING',
                  },
                  {
                    'stepIndex': 1,
                    'name': 'Administrative Approval',
                    'assignedRole': 'admin',
                    'status': 'PENDING',
                  },
                ],
                'formData': {
                  'Purpose': 'Scholarship Application',
                  'Academic Semester': '6th Semester',
                },
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
        tokenStorage: InMemoryTokenStorage('staff_jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
        staffWorkflowService: StaffWorkflowService(apiClient: apiClient),
        initialAuthenticated: true,
      );
      appState.setRole(UserRole.staff);

      await tester.pumpWidget(
        MaterialApp(
          home: RequestDetailView(
            requestId: '6723a101',
            appState: appState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Staff Review Action Pending'), findsOneWidget);
      expect(find.text('Review & Decide'), findsOneWidget);

      await tester.tap(find.text('Review & Decide'));
      await tester.pumpAndSettle();

      expect(find.text('Staff Department Review'), findsOneWidget);
    });
  });
}
