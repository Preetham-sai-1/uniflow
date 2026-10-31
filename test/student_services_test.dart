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
import 'package:uniflow_flutter_ui/views/student/request_form_view.dart';
import 'package:uniflow_flutter_ui/views/student/services_catalogue_view.dart';

void main() {
  final sampleBackendServices = [
    {
      'id': 'svc-001',
      'name': 'Bonafide Certificate',
      'slug': 'bonafide-certificate',
      'description':
          'Official institutional letter verifying current enrolment.',
      'category': 'Academic',
      'estimatedDays': 3,
      'requiredDocuments': ['Student ID card'],
      'responsibleDepartment': {
        'id': 'dept-01',
        'name': 'Administration',
        'code': 'ADMIN'
      },
      'workflowStepCount': 3,
      'isActive': true,
    },
    {
      'id': 'svc-002',
      'name': 'ID Card Replacement',
      'slug': 'id-card-replacement',
      'description': 'Request replacement for lost, damaged, or stolen badge.',
      'category': 'Identity',
      'estimatedDays': 5,
      'requiredDocuments': ['Photograph'],
      'responsibleDepartment': {
        'id': 'dept-02',
        'name': 'Security',
        'code': 'SEC'
      },
      'workflowStepCount': 4,
      'isActive': true,
    },
    {
      'id': 'svc-003',
      'name': 'Equipment Booking',
      'slug': 'equipment-booking',
      'description': 'Borrow university cameras, sensors, and AV projectors.',
      'category': 'Resources',
      'estimatedDays': 1,
      'requiredDocuments': [],
      'responsibleDepartment': {
        'id': 'dept-03',
        'name': 'Facilities',
        'code': 'FAC'
      },
      'workflowStepCount': 2,
      'isActive': true,
    },
  ];

  group('StudentWorkflowService Unit Tests', () {
    test('fetchServices parses backend JSON into CampusServiceItem models',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/services');
        expect(request.headers['Authorization'], 'Bearer valid_jwt_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleBackendServices,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('valid_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);
      final items = await service.fetchServices();

      expect(items.length, 3);
      expect(items[0].id, 'svc-001');
      expect(items[0].slug, 'bonafide-certificate');
      expect(items[0].title, 'Bonafide Certificate');
      expect(items[0].type, ServiceType.bonafide);
      expect(items[0].category, 'Academic');
      expect(items[0].estimatedDays, 3);
      expect(items[0].sla, '3 Business Days');
      expect(items[0].responsibleDepartment, 'Administration');
      expect(items[0].requiresFee, false);

      expect(items[1].slug, 'id-card-replacement');
      expect(items[1].type, ServiceType.idCard);
      expect(items[1].requiresFee, true);

      expect(items[2].slug, 'equipment-booking');
      expect(items[2].type, ServiceType.equipment);
      expect(items[2].sla, '1 Business Day');
    });

    test('fetchServices passes category filter query parameter', () async {
      String? queryParam;
      final mockClient = MockClient((request) async {
        queryParam = request.url.queryParameters['category'];
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('valid_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);
      await service.fetchServices(category: 'Academic');

      expect(queryParam, 'Academic');
    });

    test('fetchServices throws ApiException on HTTP 401 Unauthorized',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Authentication required or token expired.',
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('expired_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);

      expect(
        () async => await service.fetchServices(),
        throwsA(
            isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
      );
    });

    test('submitRequest posts payload and returns parsed SubmissionResult',
        () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/requests');
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer valid_jwt_token');

        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'req-999',
              'requestNumber': 'UF-20261031-999',
              'status': 'DEPARTMENT_VERIFICATION_PENDING',
              'service': {
                '_id': 'svc-001',
                'name': 'Bonafide Certificate',
                'slug': 'bonafide-certificate',
              },
              'runtimeSteps': [
                {
                  'stepIndex': 0,
                  'name': 'Department Verification',
                  'assignedRole': 'staff',
                  'status': 'PENDING',
                }
              ],
              'createdAt': '2026-10-31T12:00:00.000Z',
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('valid_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);
      final result = await service.submitRequest(
        serviceId: 'bonafide-certificate',
        formData: {
          'purpose': 'Educational Loan Application',
          'copies': 2,
        },
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['serviceId'], 'bonafide-certificate');
      expect(
          capturedBody!['formData']['purpose'], 'Educational Loan Application');
      expect(capturedBody!['formData']['copies'], 2);

      expect(result.id, 'req-999');
      expect(result.requestNumber, 'UF-20261031-999');
      expect(result.status, 'DEPARTMENT_VERIFICATION_PENDING');
      expect(result.serviceName, 'Bonafide Certificate');
    });

    test('submitRequest throws ApiException with validation details on 400',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid request parameters.',
              'details': [
                {'field': 'serviceId', 'message': 'Service ID is required.'}
              ]
            }
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage('valid_jwt_token'),
        baseUrl: 'http://localhost:3001/api',
      );

      final service = StudentWorkflowService(apiClient: apiClient);

      expect(
        () async => await service.submitRequest(
          serviceId: '',
          formData: {},
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });
  });

  group('AppState Services Integration Tests', () {
    test('loadServices fetches from backend and caches results', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleBackendServices,
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

      expect(appState.services.isEmpty, true);
      expect(appState.hasLoadedServices, false);

      await appState.loadServices();

      expect(requestCount, 1);
      expect(appState.services.length, 3);
      expect(appState.hasLoadedServices, true);
      expect(appState.servicesError, isNull);

      // Subsequent call without forceRefresh should not trigger another API request
      await appState.loadServices(forceRefresh: false);
      expect(requestCount, 1);

      // forceRefresh = true triggers second API call
      await appState.loadServices(forceRefresh: true);
      expect(requestCount, 2);
    });

    test(
        'submitStudentRequest prepends journey and updates lastSubmissionResult',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'req-1234',
              'requestNumber': 'UF-20261031-1234',
              'status': 'DEPARTMENT_VERIFICATION_PENDING',
              'service': {
                'name': 'Bonafide Certificate',
                'slug': 'bonafide-certificate',
              },
              'student': {
                'id': 'student-1',
                'name': 'Alex Student',
                'studentId': 'CS-2023-0042',
                'department': 'Computer Science',
              },
              'runtimeSteps': [],
              'createdAt': '2026-10-31T12:00:00.000Z',
            }
          }),
          201,
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

      final initialLength = appState.requests.length;

      final result = await appState.submitStudentRequest(
        serviceId: 'bonafide-certificate',
        formData: {'purpose': 'Scholarship', 'copies': 1},
      );

      expect(result.requestNumber, 'UF-20261031-1234');
      expect(appState.lastSubmissionResult, result);
      expect(appState.requests.length, initialLength + 1);
      expect(appState.requests.first.id, 'UF-20261031-1234');
      expect(appState.requests.first.serviceType, ServiceType.bonafide);
      expect(appState.requests.first.status, JourneyStatus.departmentReview);
    });
  });

  group('Student UI Widget Tests', () {
    testWidgets('ServicesCatalogueView displays loading, cards, and filtering',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleBackendServices,
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
            body: ServicesCatalogueView(appState: appState),
          ),
        ),
      );

      // Initial settle loads services from mock client
      await tester.pumpAndSettle();

      expect(find.text('Campus Services'), findsOneWidget);
      expect(find.text('Bonafide Certificate'), findsOneWidget);
      expect(find.text('ID Card Replacement'), findsOneWidget);
      expect(find.text('Equipment Booking'), findsOneWidget);

      // Test Search
      await tester.enterText(find.byType(TextField), 'Bonafide');
      await tester.pumpAndSettle();

      expect(find.text('Bonafide Certificate'), findsOneWidget);
      expect(find.text('ID Card Replacement'), findsNothing);

      // Clear Search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('ID Card Replacement'), findsOneWidget);
    });

    testWidgets('ServicesCatalogueView displays error and retries on failure',
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
                'message': 'Failed to reach campus service gateway.',
              }
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleBackendServices,
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
            body: ServicesCatalogueView(appState: appState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load services from server'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      // Now set shouldFail to false and tap Retry Connection
      shouldFail = false;
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Bonafide Certificate'), findsOneWidget);
    });

    testWidgets('RequestFormView validates and submits Bonafide request',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool submitted = false;
      final mockClient = MockClient((request) async {
        submitted = true;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'req-bonafide-101',
              'requestNumber': 'UF-20261031-BON01',
              'status': 'DEPARTMENT_VERIFICATION_PENDING',
              'service': {
                'name': 'Bonafide Certificate',
                'slug': 'bonafide-certificate',
              },
              'student': {'name': 'Student'},
              'runtimeSteps': [],
              'createdAt': '2026-10-31T12:00:00.000Z',
            }
          }),
          201,
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
          home: RequestFormView(
            serviceType: ServiceType.bonafide,
            appState: appState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Bonafide Certificate Request'), findsOneWidget);

      final submitBtn = find.text('Submit Request to Campus Office');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(submitted, true);
      expect(find.text('Application Submitted!'), findsOneWidget);
      expect(find.text('UF-20261031-BON01'), findsOneWidget);
      expect(find.text('Done & Return to Services'), findsOneWidget);

      await tester.tap(find.text('Done & Return to Services'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'RequestFormView enforces police complaint when ID card reason is Stolen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': {}}),
          201,
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
          home: RequestFormView(
            serviceType: ServiceType.idCard,
            appState: appState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change reason to Stolen
      await tester.tap(find.text('Lost on campus'));
      await tester.pumpAndSettle();

      await tester
          .tap(find.text('Stolen / Robbed (requires police note)').last);
      await tester.pumpAndSettle();

      // Submit without entering FIR
      final submitBtn = find.text('Submit Request to Campus Office');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Police Complaint / FIR reference is required when reporting a stolen card.'),
        findsOneWidget,
      );
    });
  });
}
