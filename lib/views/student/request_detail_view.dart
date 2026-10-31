import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../widgets/journey_timeline.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';

class RequestDetailView extends StatelessWidget {
  final String requestId;
  final AppState appState;

  const RequestDetailView({
    super.key,
    required this.requestId,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final request = appState.requests.firstWhere(
          (r) => r.id == requestId,
          orElse: () => throw Exception('Request not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(request.id),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: StatusBadge(status: request.status, isCompact: true),
                ),
              ),
            ],
          ),
          body: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            maxWidth: 840,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Service Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          request.serviceType.icon,
                          size: 28,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.serviceType.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted on ${_formatDate(request.submittedAt)} • ${request.studentRoll}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Simulated Payment Callout (if Payment Required)
                if (request.status == JourneyStatus.paymentRequired) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC4B5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment_rounded,
                                color: AppColors.statusPayment, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Action Required: Processing Fee',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusPayment,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your security clearance has been verified. Please pay the standard campus replacement fee (₹${request.feeAmount.toStringAsFixed(0)}) to proceed with card production.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusPayment,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 18),
                            label: Text(
                                'Pay ₹${request.feeAmount.toStringAsFixed(0)} Now (Simulated)'),
                            onPressed: () {
                              appState.studentPayFee(request.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.statusApproved,
                                  content: Text(
                                      'Fee payment confirmed! Request forwarded to Admin.'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejection Alert Banner (if Rejected)
                if (request.status == JourneyStatus.rejected) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.statusRejected.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.statusRejected, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Request Rejected',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusRejected,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.rejectionReason ??
                                    'The request could not be processed at this time.',
                                style: const TextStyle(
                                  color: AppColors.statusRejected,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Live Journey Stepper Timeline
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Journey Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Live audit trail showing reviewers and decisions.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 28),
                      JourneyTimelineWidget(steps: request.timeline),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Request Submission Details / Form Fields
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Information submitted with this request.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 28),
                      ...request.formData.entries.map((entry) {
                        final isMobile =
                            MediaQuery.of(context).size.width < 600;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
