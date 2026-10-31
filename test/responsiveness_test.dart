import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/main.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/models/service_item.dart';
import 'package:uniflow_flutter_ui/views/admin/admin_analytics_view.dart';
import 'package:uniflow_flutter_ui/views/admin/admin_dashboard_view.dart';
import 'package:uniflow_flutter_ui/views/auth/login_view.dart';
import 'package:uniflow_flutter_ui/views/profile/profile_view.dart';
import 'package:uniflow_flutter_ui/views/shell/app_shell.dart';
import 'package:uniflow_flutter_ui/views/staff/review_dialog.dart';
import 'package:uniflow_flutter_ui/views/staff/staff_queue_view.dart';
import 'package:uniflow_flutter_ui/views/student/my_requests_view.dart';
import 'package:uniflow_flutter_ui/views/student/request_detail_view.dart';
import 'package:uniflow_flutter_ui/views/student/request_form_view.dart';
import 'package:uniflow_flutter_ui/views/student/services_catalogue_view.dart';
import 'package:uniflow_flutter_ui/views/student/student_dashboard_view.dart';

void main() {
  group('Screen Responsiveness Tests (360px, 390px, 430px, Tablet & Desktop)',
      () {
    final screenSizes = [
      const Size(360, 640), // Small Android phone
      const Size(390, 844), // Standard iPhone
      const Size(430, 932), // Large phone
      const Size(768, 1024), // Tablet
      const Size(1280, 800), // Desktop
    ];

    for (final size in screenSizes) {
      testWidgets(
          'UniFlowApp renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const UniFlowApp());
        await tester.pumpAndSettle();

        expect(find.text('Uni'), findsWidgets);
        expect(find.text('Flow'), findsWidgets);
      });
    }

    testWidgets('LoginView renders cleanly at 360px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(
            appState: state,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('CONTINUE AS'), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Student views render cleanly at 360px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();

      // Dashboard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentDashboardView(
              appState: state,
              onNavigateTab: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active Journeys'), findsOneWidget);

      // Services Catalogue
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServicesCatalogueView(appState: state),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Campus Services'), findsOneWidget);

      // Request Form (Bonafide)
      await tester.pumpWidget(
        MaterialApp(
          home: RequestFormView(
            serviceType: ServiceType.bonafide,
            appState: state,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Request Information'), findsOneWidget);

      // Request Detail with INR fee
      final idCardReq =
          state.requests.firstWhere((r) => r.serviceType == ServiceType.idCard);
      await tester.pumpWidget(
        MaterialApp(
          home: RequestDetailView(
            requestId: idCardReq.id,
            appState: state,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Action Required: Processing Fee'), findsOneWidget);
      expect(find.text('Pay ₹200 Now (Simulated)'), findsOneWidget);

      // My Requests
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyRequestsView(appState: state),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Requests'), findsOneWidget);
    });

    testWidgets('Staff queue and review dialog render cleanly at 360px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      state.setRole(UserRole.staff);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffQueueView(appState: state),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff Review Queue'), findsOneWidget);

      // Test Review Dialog
      final pendingReq = state.staffQueue.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewDecisionDialog(
              request: pendingReq,
              appState: state,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff Department Review'), findsOneWidget);
      expect(find.text('Reject Request'), findsOneWidget);
      expect(find.text('Approve Step'), findsOneWidget);
    });

    testWidgets('Admin dashboard and analytics render cleanly at 360px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      state.setRole(UserRole.admin);

      // Admin Dashboard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminDashboardView(
              appState: state,
              onNavigateTab: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Administrative Executive Portal'), findsOneWidget);

      // Admin Analytics
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAnalyticsView(appState: state),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Campus Analytics & Intelligence'), findsOneWidget);

      // Profile View
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileView(
              appState: state,
              onSignOut: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Campus Profile & Settings'), findsOneWidget);
    });

    testWidgets(
        'AppShell role switching across Student, Staff, and Admin works seamlessly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            appState: state,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts as Student
      expect(find.text('Active Journeys'), findsOneWidget);

      // Switch to Staff
      state.setRole(UserRole.staff);
      await tester.pumpAndSettle();
      expect(find.text('Staff Review Queue'), findsOneWidget);

      // Switch to Admin
      state.setRole(UserRole.admin);
      await tester.pumpAndSettle();
      expect(find.text('Administrative Executive Portal'), findsOneWidget);
    });
  });
}
