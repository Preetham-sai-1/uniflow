import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../models/service_item.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_container.dart';

class AdminAnalyticsView extends StatelessWidget {
  final AppState appState;

  const AdminAnalyticsView({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final allRequests = appState.requests;
        final total = allRequests.isEmpty ? 1 : allRequests.length;

        final bonafideCount = allRequests
            .where((r) => r.serviceType == ServiceType.bonafide)
            .length;
        final idCardCount = allRequests
            .where((r) => r.serviceType == ServiceType.idCard)
            .length;
        final equipCount = allRequests
            .where((r) => r.serviceType == ServiceType.equipment)
            .length;

        final approvedCount =
            allRequests.where((r) => r.status == JourneyStatus.approved).length;
        final pendingCount =
            allRequests.where((r) => !r.status.isTerminal).length;
        final rejectedCount =
            allRequests.where((r) => r.status == JourneyStatus.rejected).length;

        return ResponsiveContainer(
          title: 'Campus Analytics & Intelligence',
          subtitle:
              'Real-time workflow distribution, throughput, and service level metrics.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Metrics
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  return Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Total Applications',
                          value: allRequests.length.toString(),
                          subtitle: 'Campus-wide volume',
                          icon: Icons.bar_chart_rounded,
                          accentColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: MetricCard(
                          title: 'Resolution Rate',
                          value: '${((approvedCount / total) * 100).round()}%',
                          subtitle: '$approvedCount approved journeys',
                          icon: Icons.check_circle_rounded,
                          accentColor: AppColors.statusApproved,
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 14),
                        const Expanded(
                          child: MetricCard(
                            title: 'Average Cycle Time',
                            value: '18.4 hrs',
                            subtitle: 'Submission to seal',
                            icon: Icons.timelapse_rounded,
                            accentColor: AppColors.statusPayment,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: MetricCard(
                            title: 'SLA Adherence',
                            value: '99.1%',
                            subtitle: '0 breached deadlines',
                            icon: Icons.speed_rounded,
                            accentColor: AppColors.statusPending,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Two Column Analytics Grid (Desktop) or Stack (Mobile)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  final serviceVolumeCard = Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Service Volume Breakdown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.pie_chart_outline_rounded,
                                color: AppColors.primaryBlue, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Distribution of requests by service type',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const Divider(height: 28),
                        _barRow(
                          title: 'Bonafide Certificates',
                          count: bonafideCount,
                          total: total,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 18),
                        _barRow(
                          title: 'ID Card Replacements',
                          count: idCardCount,
                          total: total,
                          color: AppColors.statusPayment,
                        ),
                        const SizedBox(height: 18),
                        _barRow(
                          title: 'Equipment Bookings',
                          count: equipCount,
                          total: total,
                          color: AppColors.statusApproved,
                        ),
                      ],
                    ),
                  );

                  final statusHealthCard = Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Workflow Status Health',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.donut_large_rounded,
                                color: AppColors.statusApproved, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                            'Current state of all active and terminal requests',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const Divider(height: 28),
                        _barRow(
                          title: 'Approved & Completed',
                          count: approvedCount,
                          total: total,
                          color: AppColors.statusApproved,
                        ),
                        const SizedBox(height: 18),
                        _barRow(
                          title: 'In Review / In Progress',
                          count: pendingCount,
                          total: total,
                          color: AppColors.statusPending,
                        ),
                        const SizedBox(height: 18),
                        _barRow(
                          title: 'Rejected With Note',
                          count: rejectedCount,
                          total: total,
                          color: AppColors.statusRejected,
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: serviceVolumeCard),
                        const SizedBox(width: 20),
                        Expanded(child: statusHealthCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      serviceVolumeCard,
                      const SizedBox(height: 20),
                      statusHealthCard,
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Department Breakdown Table Card
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
                      'Departmental Request Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        'Student engagement and volume across campus colleges',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const Divider(height: 28),
                    _deptRow('Computer Science & Engineering', '48 Requests',
                        '98.5% On-Time', AppColors.primaryBlue),
                    const Divider(height: 20),
                    _deptRow('Mechanical Engineering', '24 Requests',
                        '96.2% On-Time', AppColors.statusPending),
                    const Divider(height: 20),
                    _deptRow('Electronics & Communication', '19 Requests',
                        '99.0% On-Time', AppColors.statusApproved),
                    const Divider(height: 20),
                    _deptRow('Civil & Environmental Engineering', '11 Requests',
                        '95.0% On-Time', AppColors.statusPayment),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _barRow({
    required String title,
    required int count,
    required int total,
    required Color color,
  }) {
    final ratio = total == 0 ? 0.0 : count / total;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primaryNavy),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count ($percent%)',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.05, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _deptRow(String department, String count, String sla, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                department,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primaryNavy),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(sla,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 4),
          child: Text(
            count,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
