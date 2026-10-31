import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/api/api_exceptions.dart';
import 'package:uniflow_flutter_ui/core/auth/auth_service.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/views/auth/login_view.dart';
import 'package:uniflow_flutter_ui/views/shell/app_shell.dart';

void main() {
  group('UniFlow Automatic Role Detection & Authentication Tests', () {
    testWidgets('1. Login screen contains no role-selection controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState(initialAuthenticated: false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: state,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify branding and welcome text
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
          find.text(
              'Sign in with your institutional credentials to access your campus workspace.'),
          findsOneWidget);

      // Verify role selection controls are completely absent
      expect(find.text('CONTINUE AS'), findsNothing);
      expect(find.text('Interactive Demo Mode'), findsNothing);
      expect(find.text('Enter as Student'), findsNothing);
      expect(find.text('Enter as Staff Member'), findsNothing);
      expect(find.text('Enter as Administrator'), findsNothing);

      // Verify email and password text fields are present and initial text is empty
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      final emailField = tester.widget<TextField>(textFields.at(0));
      expect(emailField.controller?.text, '');

      final passwordField = tester.widget<TextField>(textFields.at(1));
      expect(passwordField.controller?.text, '');

      // Verify clean Sign In button
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets(
        '2. Student credentials route automatically to Student dashboard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'jwt_student_token_111',
                'user': {
                  'id': 'u_std_001',
                  'name': 'Arjun Student',
                  'email': 'student@uniflow.edu',
                  'role': 'student',
                  'studentId': 'CS2026-001',
                  'department': {'name': 'Computer Science'},
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/me')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 'u_std_001',
                  'name': 'Arjun Student',
                  'email': 'student@uniflow.edu',
                  'role': 'student',
                  'studentId': 'CS2026-001',
                  'department': {'name': 'Computer Science'},
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: false,
      );

      bool loginCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: appState,
            onLoginSuccess: () {
              loginCallbackCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).at(0), 'student@uniflow.edu');
      await tester.enterText(find.byType(TextField).at(1), 'Password123!');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(loginCallbackCalled, isTrue);
      expect(appState.isAuthenticated, isTrue);
      expect(appState.currentRole, UserRole.student);
      expect(appState.currentUser.name, 'Arjun Student');

      // Now verify that AppShell with this appState renders Student dashboard
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            appState: appState,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Journeys'), findsOneWidget);
      expect(find.text('Instant Service Actions'), findsOneWidget);
    });

    testWidgets(
        '3. Staff credentials route automatically to Staff review queue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login') ||
            request.url.path.endsWith('/auth/me')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'jwt_staff_token_222',
                'user': {
                  'id': 'u_stf_002',
                  'name': 'Dr. Sarah Jenkins',
                  'email': 'staff@uniflow.edu',
                  'role': 'staff',
                  'identifier': 'FAC-8821',
                  'department': {'name': 'Academic Affairs'},
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: false,
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

      await tester.enterText(find.byType(TextField).at(0), 'staff@uniflow.edu');
      await tester.enterText(find.byType(TextField).at(1), 'Password123!');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(appState.isAuthenticated, isTrue);
      expect(appState.currentRole, UserRole.staff);
      expect(appState.currentUser.role, UserRole.staff);

      // Verify AppShell routes automatically to Staff Queue
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            appState: appState,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Review Queue'), findsOneWidget);
    });

    testWidgets('4. Admin credentials route automatically to Admin dashboard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login') ||
            request.url.path.endsWith('/auth/me')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'jwt_admin_token_333',
                'user': {
                  'id': 'u_adm_003',
                  'name': 'Dean Marcus Vance',
                  'email': 'admin@uniflow.edu',
                  'role': 'admin',
                  'identifier': 'ADM-EXEC-01',
                  'department': {'name': 'Office of the Registrar'},
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: false,
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

      await tester.enterText(find.byType(TextField).at(0), 'admin@uniflow.edu');
      await tester.enterText(find.byType(TextField).at(1), 'Password123!');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(appState.isAuthenticated, isTrue);
      expect(appState.currentRole, UserRole.admin);

      // Verify AppShell routes automatically to Admin Executive Dashboard
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            appState: appState,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrative Executive Portal'), findsOneWidget);
    });

    test('5. Session restoration determines the correct role from backend',
        () async {
      final storage = InMemoryTokenStorage('persisted_admin_jwt');
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          expect(request.headers['Authorization'],
              'Bearer persisted_admin_jwt');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 'adm_id',
                  'name': 'Dean Marcus Vance',
                  'email': 'admin@uniflow.edu',
                  'role': 'admin',
                  'identifier': 'ADM-01',
                  'department': {'name': 'Administration'},
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: false,
      );

      final restored = await appState.initializeSession();

      expect(restored, isTrue);
      expect(appState.isAuthenticated, isTrue);
      expect(appState.currentRole, UserRole.admin);
      expect(appState.currentUser.role, UserRole.admin);
      expect(appState.currentUser.name, 'Dean Marcus Vance');
    });

    test('6. Expired tokens return users to unauthenticated login state',
        () async {
      final storage = InMemoryTokenStorage('expired_jwt');
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'INVALID_TOKEN',
              'message': 'Token has expired.',
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: false,
      );

      final restored = await appState.initializeSession();

      expect(restored, isFalse);
      expect(appState.isAuthenticated, isFalse);
      expect(await storage.hasToken(), isFalse);
    });

    test(
        '7. Unknown or unsupported roles from backend are rejected with authorization error',
        () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'jwt_unknown_role',
              'user': {
                'id': 'unknown_user_id',
                'name': 'Rogue User',
                'email': 'rogue@uniflow.edu',
                'role': 'super_admin_unauthorized',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: false,
      );

      expect(
        () async =>
            await appState.login('rogue@uniflow.edu', 'Password123!'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'FORBIDDEN')),
      );

      // Verify no session was created and storage remains clean
      expect(appState.isAuthenticated, isFalse);
      expect(await storage.hasToken(), isFalse);
    });

    testWidgets('8. Logout returns to login without role selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = InMemoryTokenStorage('active_token');
      final authService = AuthService(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
          tokenStorage: storage,
        ),
        tokenStorage: storage,
      );
      final appState = AppState(
        authService: authService,
        initialAuthenticated: true,
      );

      expect(appState.isAuthenticated, isTrue);

      await appState.logout();

      expect(appState.isAuthenticated, isFalse);
      expect(await storage.hasToken(), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: appState,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('CONTINUE AS'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets(
        '9. Security: AppShell does not expose manual role switching controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState(initialAuthenticated: true);

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            appState: appState,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure popup menu button for switching perspective does NOT exist
      expect(find.byType(PopupMenuButton<UserRole>), findsNothing);
      expect(find.text('Switch Campus Perspective'), findsNothing);
    });
  });
}
