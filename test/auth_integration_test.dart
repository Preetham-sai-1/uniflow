import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniflow_flutter_ui/core/api/api_client.dart';
import 'package:uniflow_flutter_ui/core/api/api_config.dart';
import 'package:uniflow_flutter_ui/core/api/api_exceptions.dart';
import 'package:uniflow_flutter_ui/core/auth/auth_service.dart';
import 'package:uniflow_flutter_ui/core/auth/token_storage.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/views/auth/login_view.dart';

void main() {
  group('Step 2 & 3: Networking Layer & Secure Token Persistence', () {
    test('ApiConfig provides platform-aware base URLs and overrides', () {
      ApiConfig.reset();
      expect(ApiConfig.baseUrl.isNotEmpty, true);

      ApiConfig.setBaseUrl('http://custom-api:4000/api/');
      expect(ApiConfig.baseUrl, 'http://custom-api:4000/api');

      ApiConfig.reset();
      expect(ApiConfig.baseUrl, isNot('http://custom-api:4000/api'));
    });

    test('InMemoryTokenStorage saves, retrieves, and deletes JWT token',
        () async {
      final storage = InMemoryTokenStorage();
      expect(await storage.hasToken(), false);
      expect(await storage.getToken(), isNull);

      await storage.saveToken('test_jwt_token_123');
      expect(await storage.hasToken(), true);
      expect(await storage.getToken(), 'test_jwt_token_123');

      await storage.deleteToken();
      expect(await storage.hasToken(), false);
      expect(await storage.getToken(), isNull);
    });

    test('ApiClient attaches Bearer authorization header when required',
        () async {
      final storage = InMemoryTokenStorage('mock_bearer_jwt');
      String? capturedAuthHeader;

      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'status': 'ok'}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: storage,
        baseUrl: 'http://localhost:3001/api',
      );

      final response = await apiClient.get('/test-auth', requiresAuth: true);
      expect(response.success, true);
      expect(capturedAuthHeader, 'Bearer mock_bearer_jwt');

      // Unauthenticated request should omit header
      capturedAuthHeader = null;
      await apiClient.post('/test-public',
          body: {'data': 1}, requiresAuth: false);
      expect(capturedAuthHeader, isNull);
    });
  });

  group('Step 4 & 5: AuthService & Session Management', () {
    test('Login success: stores token and parses authentic user profile',
        () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'student@uniflow.edu');
          expect(body['password'], 'Demo@1234');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'auth_jwt_student_valid',
                'user': {
                  'id': '64a1b2c3d4e5f6a7b8c9d001',
                  'name': 'Arjun Sharma',
                  'email': 'student@uniflow.edu',
                  'role': 'student',
                  'studentId': 'CS2021001',
                  'department': {
                    '_id': 'dept001',
                    'name': 'Computer Science',
                  },
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

      expect(appState.isAuthenticated, false);

      await appState.login('student@uniflow.edu', 'Demo@1234');

      expect(appState.isAuthenticated, true);
      expect(appState.currentRole, UserRole.student);
      expect(appState.currentUser.name, 'Arjun Sharma');
      expect(appState.currentUser.email, 'student@uniflow.edu');
      expect(appState.currentUser.identifier, 'CS2021001');
      expect(appState.currentUser.department, 'Computer Science');
      expect(await storage.getToken(), 'auth_jwt_student_valid');
    });

    test('Login failure: rejects invalid credentials and clears state',
        () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'INVALID_TOKEN',
              'message': 'Invalid email or password.',
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

      expect(
        () async =>
            await appState.login('wrong@uniflow.edu', 'WrongPassword123'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Invalid email or password.')),
      );

      expect(appState.isAuthenticated, false);
      expect(await storage.hasToken(), false);
    });

    test('Network failure: throws NetworkException when server unreachable',
        () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final authService = AuthService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: storage),
        tokenStorage: storage,
      );

      expect(
        () async => await authService.login(
          email: 'student@uniflow.edu',
          password: 'Password123',
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Session restoration: restores staff profile and role on startup',
        () async {
      final storage = InMemoryTokenStorage('valid_staff_token_789');
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          expect(
              request.headers['Authorization'], 'Bearer valid_staff_token_789');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': '64a1b2c3d4e5f6a7b8c9d002',
                  'name': 'Dr. Sarah Jenkins',
                  'email': 'staff@uniflow.edu',
                  'role': 'staff',
                  'department': {
                    'name': 'Academic Affairs',
                  },
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
      expect(restored, true);
      expect(appState.isAuthenticated, true);
      expect(appState.currentRole, UserRole.staff);
      expect(appState.currentUser.name, 'Dr. Sarah Jenkins');
    });

    test(
        'Expired session handling: clears invalid token and stays unauthenticated',
        () async {
      final storage = InMemoryTokenStorage('expired_token_000');
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
      expect(restored, false);
      expect(appState.isAuthenticated, false);
      expect(await storage.hasToken(), false); // Token should have been evicted
    });

    test('Logout: clears token, resets authentication and default user state',
        () async {
      final storage = InMemoryTokenStorage('active_token');
      final authService = AuthService(tokenStorage: storage);
      final appState = AppState(
        authService: authService,
        initialAuthenticated: true,
      );

      appState.setAuthenticatedUser(UserProfile.adminUser);
      expect(appState.isAuthenticated, true);
      expect(appState.currentRole, UserRole.admin);

      await appState.logout();

      expect(appState.isAuthenticated, false);
      expect(appState.currentRole, UserRole.student);
      expect(await storage.hasToken(), false);
    });

    test('Role mapping: converts backend role strings into typed enums', () {
      expect(UserRole.fromString('student'), UserRole.student);
      expect(UserRole.fromString('STUDENT'), UserRole.student);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('administrator'), UserRole.admin);
      expect(UserRole.fromString('unknown_role'), UserRole.student);

      final jsonMap = {
        '_id': 'uid999',
        'name': 'Dean Marcus Vance',
        'email': 'dean.vance@campus.edu',
        'role': 'admin',
        'department': 'Office of the Registrar',
        'studentId': 'ADM-EXEC-01',
      };

      final profile = UserProfile.fromJson(jsonMap);
      expect(profile.id, 'uid999');
      expect(profile.name, 'Dean Marcus Vance');
      expect(profile.role, UserRole.admin);
      expect(profile.department, 'Office of the Registrar');
      expect(profile.identifier, 'ADM-EXEC-01');
    });
  });

  group('Step 4: LoginView UI & Error Handling', () {
    testWidgets('LoginView displays validation error on empty credentials',
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

      // Clear email and password
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pumpAndSettle();

      // Ensure button is visible and tap
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('LoginView displays backend error banner on failed login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'INVALID_TOKEN',
              'message': 'Invalid email or password.',
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
      final state = AppState(
        authService: authService,
        initialAuthenticated: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: state,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('LoginView triggers onLoginSuccess on valid authentication',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool loginSucceeded = false;
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'mock_jwt_token',
              'user': {
                'id': 'u1',
                'name': 'Arjun Sharma',
                'email': 'student@uniflow.edu',
                'role': 'student',
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
      final state = AppState(
        authService: authService,
        initialAuthenticated: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: state,
            onLoginSuccess: () {
              loginSucceeded = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(loginSucceeded, true);
      expect(state.isAuthenticated, true);
    });
  });
}
