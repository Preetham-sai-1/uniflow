import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/api/api_exceptions.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/services/student_workflow_service.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/journey_request.dart';
import 'package:uniflow_flutter_ui/models/service_item.dart';
import 'package:uniflow_flutter_ui/views/student/my_requests_view.dart';
import 'package:uniflow_flutter_ui/views/student/request_detail_view.dart';

void main() {
  final sampleRequestsList = [
    {
      '_id': 'req-001',
      'requestNumber': 'UF-20261031-BON01',
      'status': 'DEPARTMENT_VERIFICATION_PENDING',
      'currentStepIndex': 0,
      'service': {
        '_id': 'svc-001',
        'name': 'Bonafide Certificate',
        'slug': 'bonafide-certificate',
        'category': 'Academic',
        'estimatedDays': 3,
        'responsibleDepartment': {'name': 'Administration', 'code': 'ADMIN'},
      },
      'student': {
        '_id': 'std-001',
        'name': 'Alex Student',
        'studentId': 'CS-2023-0042',
        'department': 'Computer Science',
      },
      'formData': {
        'Purpose': 'Scholarship Application',
        'Copies': '2',
      },
      'runtimeSteps': [
        {
          'stepIndex': 0,
          'name': 'Department Verification',
          'assignedRole': 'staff',
          'isPaymentStep': false,
          'status': 'PENDING',
          'actor': null,
          'comment': null,
          'actionedAt': null,
        },
        {
          'stepIndex': 1,
          'name': 'Administrative Approval',
          'assignedRole': 'admin',
          'isPaymentStep': false,
          'status': 'PENDING',
          'actor': null,
          'comment': null,
          'actionedAt': null,
        },
      ],
      'createdAt': '2026-10-31T09:00:00.000Z',
      'updatedAt': '2026-10-31T09:00:00.000Z',
    },
    {
      '_id': 'req-002',
      'requestNumber': 'UF-20261031-IDC02',
      'status': 'PAYMENT_REQUIRED',
      'currentStepIndex': 1,
      'service': {
        '_id': 'svc-002',
        'name': 'ID Card Replacement',
        'slug': 'id-card-replacement',
        'category': 'Identity',
        'estimatedDays': 5,
        'responsibleDepartment': {'name': 'Security', 'code': 'SEC'},
      },
      'student': {
        '_id': 'std-001',
        'name': 'Alex Student',
        'studentId': 'CS-2023-0042',
        'department': 'Computer Science',
      },
      'formData': {
        'Reason for Replacement': 'Lost',
        'Estimated Fee': '₹200',
        'Contact Phone': '+1 555-0199',
      },
      'runtimeSteps': [
        {
          'stepIndex': 0,
          'name': 'Security Review',
          'assignedRole': 'staff',
          'isPaymentStep': false,
          'status': 'APPROVED',
          'actor': {'name': 'Officer Dave', 'role': 'staff'},
          'comment': 'Identity confirmed',
          'actionedAt': '2026-10-31T10:00:00.000Z',
        },
        {
          'stepIndex': 1,
          'name': 'Fee Payment',
          'assignedRole': 'student',
          'isPaymentStep': true,
          'status': 'PENDING',
          'actor': null,
          'comment': null,
          'actionedAt': null,
        },
        {
          'stepIndex': 2,
          'name': 'Badge Production',
          'assignedRole': 'admin',
          'isPaymentStep': false,
          'status': 'PENDING',
          'actor': null,
          'comment': null,
          'actionedAt': null,
        },
      ],
      'createdAt': '2026-10-31T08:00:00.000Z',
      'updatedAt': '2026-10-31T10:00:00.000Z',
    },
  ];

  group('StudentWorkflowService History & Tracking Unit Tests', () {
    test(
        'fetchStudentRequests parses GET /api/requests into JourneyRequest models',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/requests');
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleRequestsList,
            'pagination': {'total': 2, 'page': 1, 'limit': 50, 'pages': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('mock_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);
      final items = await service.fetchStudentRequests();

      expect(items.length, 2);
      expect(items[0].id, 'UF-20261031-BON01');
      expect(items[0].backendId, 'req-001');
      expect(items[0].serviceType, ServiceType.bonafide);
      expect(items[0].status, JourneyStatus.departmentReview);
      expect(items[0].timeline.length, 2);
      expect(items[0].timeline[0].isCurrent, true);
      expect(items[0].timeline[1].isCurrent, false);

      expect(items[1].id, 'UF-20261031-IDC02');
      expect(items[1].backendId, 'req-002');
      expect(items[1].serviceType, ServiceType.idCard);
      expect(items[1].status, JourneyStatus.paymentRequired);
      expect(items[1].feeAmount, 200.0);
      expect(items[1].timeline.length, 3);
      expect(items[1].timeline[0].isCompleted, true);
      expect(items[1].timeline[1].isCurrent, true);
      expect(items[1].timeline[1].isPaymentStep, true);
    });

    test(
        'fetchRequestDetails fetches and parses full request from GET /api/requests/:id',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/requests/req-002');
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleRequestsList[1],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('mock_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);
      final req = await service.fetchRequestDetails('req-002');

      expect(req.backendId, 'req-002');
      expect(req.requestNumber, 'UF-20261031-IDC02');
      expect(req.department, 'Security');
      expect(req.status, JourneyStatus.paymentRequired);
      expect(req.timeline[0].comment, 'Identity confirmed');
      expect(req.timeline[0].actorName, 'Officer Dave');
    });

    test('fetchRequestDetails throws 404 ApiException when request not found',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'NOT_FOUND',
              'message': 'Request not found: invalid-id',
            }
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('mock_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);

      expect(
        () async => await service.fetchRequestDetails('invalid-id'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test(
        'fetchRequestDetails throws 403 ApiException when student views foreign request',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'FORBIDDEN',
              'message': 'You do not have permission to view this request.',
            }
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('mock_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);

      expect(
        () async => await service.fetchRequestDetails('foreign-id'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test(
        'confirmSimulatedPayment transitions request to ADMIN_APPROVAL_PENDING',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/requests/req-002/payment');
        expect(request.method, 'PATCH');
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token');

        final updatedReq = Map<String, dynamic>.from(sampleRequestsList[1]);
        updatedReq['status'] = 'ADMIN_APPROVAL_PENDING';
        updatedReq['currentStepIndex'] = 2;
        final steps = List<Map<String, dynamic>>.from(
            (updatedReq['runtimeSteps'] as List)
                .map((s) => Map<String, dynamic>.from(s)));
        steps[1]['status'] = 'PAYMENT_COMPLETED';
        steps[1]['comment'] = 'Fee payment confirmed.';
        updatedReq['runtimeSteps'] = steps;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': updatedReq,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('mock_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);
      final updated = await service.confirmSimulatedPayment('req-002');

      expect(updated.status, JourneyStatus.adminApproval);
      expect(updated.isFeePaid, true);
      expect(updated.timeline[1].isCompleted, true);
    });
  });

  group('AppState Requests Management Tests', () {
    test('loadStudentRequests caches history and syncs with state', () async {
      int apiCalls = 0;
      final mockClient = MockClient((request) async {
        apiCalls++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleRequestsList,
            'pagination': {'total': 2, 'page': 1, 'limit': 50, 'pages': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
      );

      expect(appState.hasLoadedRequests, false);

      await appState.loadStudentRequests();

      expect(apiCalls, 1);
      expect(appState.hasLoadedRequests, true);
      expect(appState.studentRequests.length, 2);
      expect(appState.requestsError, isNull);

      // Duplicate load without forceRefresh does not trigger network call
      await appState.loadStudentRequests(forceRefresh: false);
      expect(apiCalls, 1);

      // forceRefresh triggers re-fetch
      await appState.loadStudentRequests(forceRefresh: true);
      expect(apiCalls, 2);
    });

    test('submitStudentPayment updates request state in place', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/requests') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleRequestsList,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/requests/req-002/payment') {
          final updatedReq = Map<String, dynamic>.from(sampleRequestsList[1]);
          updatedReq['status'] = 'ADMIN_APPROVAL_PENDING';
          updatedReq['currentStepIndex'] = 2;
          final steps = List<Map<String, dynamic>>.from(
              (updatedReq['runtimeSteps'] as List)
                  .map((s) => Map<String, dynamic>.from(s)));
          steps[1]['status'] = 'PAYMENT_COMPLETED';
          updatedReq['runtimeSteps'] = steps;

          return http.Response(
            jsonEncode({
              'success': true,
              'data': updatedReq,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(jsonEncode({'success': false}), 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
      );

      await appState.loadStudentRequests();
      final prePaid = appState.findRequest('req-002');
      expect(prePaid?.status, JourneyStatus.paymentRequired);

      final paid = await appState.submitStudentPayment('req-002');
      expect(paid.status, JourneyStatus.adminApproval);

      final postPaid = appState.findRequest('req-002');
      expect(postPaid?.status, JourneyStatus.adminApproval);
    });
  });

  group('Student Requests UI Widget Tests', () {
    testWidgets(
        'MyRequestsView renders requests, search filter, and category chips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleRequestsList,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyRequestsView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Requests'), findsOneWidget);
      expect(find.text('Bonafide Certificate'), findsOneWidget);
      expect(find.text('(UF-20261031-BON01)'), findsOneWidget);
      expect(find.text('ID Card Replacement'), findsOneWidget);
      expect(find.text('(UF-20261031-IDC02)'), findsOneWidget);

      // Search filter
      await tester.enterText(find.byType(TextField), 'BON01');
      await tester.pumpAndSettle();

      expect(find.text('(UF-20261031-BON01)'), findsOneWidget);
      expect(find.text('(UF-20261031-IDC02)'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('(UF-20261031-IDC02)'), findsOneWidget);

      // Filter by 'Action Required' (Payment required)
      await tester.tap(find.text('Action Required'));
      await tester.pumpAndSettle();

      expect(find.text('(UF-20261031-IDC02)'), findsOneWidget);
      expect(find.text('(UF-20261031-BON01)'), findsNothing);
    });

    testWidgets('MyRequestsView handles error state and retries successfully',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool shouldFail = true;
      final mockClient = MockClient((request) async {
        if (shouldFail) {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'SERVER_ERROR',
                'message': 'Cannot reach request service.',
              }
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleRequestsList,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyRequestsView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load requests from server'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Bonafide Certificate'), findsOneWidget);
    });

    testWidgets(
        'RequestDetailView renders stepper timeline and executes simulated payment',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool paymentCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/requests/req-002') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleRequestsList[1],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/requests/req-002/payment') {
          paymentCalled = true;
          final updatedReq = Map<String, dynamic>.from(sampleRequestsList[1]);
          updatedReq['status'] = 'ADMIN_APPROVAL_PENDING';
          updatedReq['currentStepIndex'] = 2;
          final steps = List<Map<String, dynamic>>.from(
              (updatedReq['runtimeSteps'] as List)
                  .map((s) => Map<String, dynamic>.from(s)));
          steps[1]['status'] = 'PAYMENT_COMPLETED';
          updatedReq['runtimeSteps'] = steps;

          return http.Response(
            jsonEncode({
              'success': true,
              'data': updatedReq,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(jsonEncode({'success': false}), 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RequestDetailView(
            requestId: 'req-002',
            appState: appState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('UF-20261031-IDC02'), findsWidgets);
      expect(find.text('ID Card Replacement'), findsOneWidget);
      expect(find.text('Action Required: Processing Fee'), findsOneWidget);
      expect(find.text('Pay ₹200 Now (Simulated)'), findsOneWidget);
      expect(find.text('Journey Progress'), findsOneWidget);
      expect(find.text('Security Review'), findsOneWidget);

      // Tap Pay Now
      final payBtn = find.text('Pay ₹200 Now (Simulated)');
      await tester.ensureVisible(payBtn);
      await tester.tap(payBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(paymentCalled, true);
      expect(
          find.text(
              'Fee payment confirmed! Request forwarded to Administrative Approval.'),
          findsOneWidget);
      expect(find.text('Action Required: Processing Fee'), findsNothing);
    });

    testWidgets(
        'RequestDetailView displays 404 error when request does not exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'NOT_FOUND',
              'message': 'Request not found: missing-id'
            }
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('jwt'),
        baseUrl: 'http://localhost:3001/api',
      );

      final appState = AppState(
        studentWorkflowService: StudentWorkflowService(apiClient: apiClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RequestDetailView(
            requestId: 'missing-id',
            appState: appState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Request not found (404).'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
