import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow_flutter_ui/core/state/app_state.dart';
import 'package:uniflow_flutter_ui/main.dart';
import 'package:uniflow_flutter_ui/models/journey_request.dart';
import 'package:uniflow_flutter_ui/models/role.dart';
import 'package:uniflow_flutter_ui/models/service_item.dart';

void main() {
  testWidgets('UniFlow smoke test - loads student dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('Uni'), findsWidgets);
    expect(find.text('Flow'), findsWidgets);
    expect(find.text('Active Journeys'), findsOneWidget);
    expect(find.text('Instant Service Actions'), findsOneWidget);
  });

  test('AppState workflow state transitions test', () {
    final state = AppState();
    expect(state.requests.isNotEmpty, true);

    // Initial count
    final initialCount = state.requests.length;

    // Student submits new Bonafide certificate request
    state.submitRequest(
      serviceType: ServiceType.bonafide,
      formData: {
        'Purpose': 'Passport Verification',
        'Academic Semester': '6th Semester',
      },
    );

    expect(state.requests.length, initialCount + 1);
    final created = state.requests.first;
    expect(created.serviceType, ServiceType.bonafide);
    expect(created.status, JourneyStatus.departmentReview);

    // Staff approves the request
    state.staffReviewRequest(
      requestId: created.id,
      approve: true,
      comment: 'Verified student records.',
    );

    final staffApproved = state.requests.firstWhere((r) => r.id == created.id);
    expect(staffApproved.status, JourneyStatus.adminApproval);

    // Admin approves the request
    state.adminReviewRequest(
      requestId: created.id,
      approve: true,
      comment: 'Digital certificate authorized.',
    );

    final adminApproved = state.requests.firstWhere((r) => r.id == created.id);
    expect(adminApproved.status, JourneyStatus.approved);
    expect(adminApproved.status.isTerminal, true);
  });

  test('AppState ID card workflow with simulated fee payment', () {
    final state = AppState();

    state.submitRequest(
      serviceType: ServiceType.idCard,
      formData: {
        'Reason for Replacement': 'Lost on shuttle bus',
        'Contact Phone': '+1 555-0199',
      },
    );

    final created = state.requests.first;
    expect(created.serviceType, ServiceType.idCard);
    expect(created.status, JourneyStatus.securityReview);

    // Security Staff approves
    state.staffReviewRequest(
      requestId: created.id,
      approve: true,
      comment: 'Identity confirmed against database.',
    );

    final securityApproved =
        state.requests.firstWhere((r) => r.id == created.id);
    expect(securityApproved.status, JourneyStatus.paymentRequired);

    // Student pays simulated fee
    state.studentPayFee(created.id);
    final paid = state.requests.firstWhere((r) => r.id == created.id);
    expect(paid.isFeePaid, true);
    expect(paid.status, JourneyStatus.adminApproval);
  });

  test('AppState rejection workflow with mandatory comment', () {
    final state = AppState();

    state.submitRequest(
      serviceType: ServiceType.equipment,
      formData: {
        'Equipment Category': 'Audio/Visual 4K Projector',
      },
    );

    final created = state.requests.first;

    // Staff rejects with reason
    state.staffReviewRequest(
      requestId: created.id,
      approve: false,
      comment: 'Item is reserved for annual university convocation.',
    );

    final rejected = state.requests.firstWhere((r) => r.id == created.id);
    expect(rejected.status, JourneyStatus.rejected);
    expect(rejected.status.isTerminal, true);
    expect(rejected.rejectionReason, contains('reserved'));
  });

  test('AppState role switching updates user profile', () {
    final state = AppState();
    expect(state.currentRole, UserRole.student);

    state.setRole(UserRole.staff);
    expect(state.currentRole, UserRole.staff);
    expect(state.currentUser.role, UserRole.staff);

    state.setRole(UserRole.admin);
    expect(state.currentRole, UserRole.admin);
    expect(state.currentUser.role, UserRole.admin);
  });
}
