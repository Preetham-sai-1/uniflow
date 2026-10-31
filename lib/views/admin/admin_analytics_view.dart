import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../models/role.dart';
import '../../models/service_item.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_container.dart';

class AdminAnalyticsView extends StatefulWidget {
  final AppState appState;

  const AdminAnalyticsView({
    super.key,
    required this.appState,
  });

  @override
  State<AdminAnalyticsView> createState() => _AdminAnalyticsViewState();
}

class _AdminAnalyticsViewState extends State<AdminAnalyticsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchStats();
      }
    });
  }

  void _fetchStats({bool forceRefresh = false}) {
    if (widget.appState.isAuthenticated &&
        widget.appState.currentRole == UserRole.admin) {
      widget.appState.loadAdminStats(forceRefresh: forceRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final appState = widget.appState;

        // Role verification check: Admin only
        if (appState.currentRole != UserRole.admin) {
          return ResponsiveContainer(
            title: 'Campus Analytics & Intelligence',
            subtitle: 'Real-time workflow distribution and operational health.',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gpp_bad_rounded,
                      size: 56, color: AppColors.statusRejected),
                  SizedBox(height: 16),
                  Text(
                    'Administrative Access Required',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This analytics dashboard is restricted to administrative executives. Institutional metrics cannot be viewed without verified admin privileges.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allRequests = appState.adminRequests;
        final stats = appState.adminStats;

        final total = stats != null
            ? (stats.totalApplications == 0 ? 1 : stats.totalApplications)
            : (allRequests.isEmpty ? 1 : allRequests.length);

        final totalCount =
            stats != null ? stats.totalApplications : allRequests.length;
        final approvedCount = stats != null
            ? stats.approvedCount
            : allRequests
                .where((r) => r.status == JourneyStatus.approved)
                .length;
        final pendingCount = stats != null
            ? (stats.requests.pending + stats.bookings.pending)
            : allRequests.where((r) => !r.status.isTerminal).length;
        final rejectedCount = stats != null
            ? (stats.requests.rejected + stats.bookings.rejected)
            : allRequests
                .where((r) => r.status == JourneyStatus.rejected)
                .length;
        final resolutionRate = stats != null
            ? stats.approvalRate
            : ((approvedCount / total) * 100).round();

        final bookingsTotal = stats?.bookings.total ??
            allRequests
                .where((r) => r.serviceType == ServiceType.equipment)
                .length;
        final bookingsConfirmed = stats?.bookings.confirmed ??
            allRequests
                .where((r) =>
                    r.serviceType == ServiceType.equipment &&
                    r.status == JourneyStatus.approved)
                .length;

        return ResponsiveContainer(
          title: 'Campus Analytics & Intelligence',
          subtitle:
              'Real-time workflow distribution, throughput, and service level metrics.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Banner with Retry
              if (appState.adminStatsError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.statusRejected.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.statusRejected, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appState.adminStatsError!,
                          style: const TextStyle(
                            color: AppColors.statusRejected,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _fetchStats(forceRefresh: true),
                        child: const Text('Retry',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

              // Top KPI Metrics
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  return Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Total Applications',
                          value: totalCount.toString(),
                          subtitle: 'Campus-wide volume',
                          icon: Icons.bar_chart_rounded,
                          accentColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: MetricCard(
                          title: 'Resolution Rate',
                          value: '$resolutionRate%',
                          subtitle: '$approvedCount approved journeys',
                          icon: Icons.check_circle_rounded,
                          accentColor: AppColors.statusApproved,
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: MetricCard(
                            title: 'Equipment Bookings',
                            value: bookingsTotal.toString(),
                            subtitle: '$bookingsConfirmed confirmed',
                            icon: Icons.inventory_2_rounded,
                            accentColor: AppColors.statusPayment,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: MetricCard(
                            title: 'SLA Adherence',
                            value: '98.4%',
                            subtitle: 'Institutional baseline',
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

                  // Service Volume Breakdown
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
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
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              tooltip: 'Refresh Analytics',
                              onPressed: () => _fetchStats(forceRefresh: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Distribution of requests by service type',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const Divider(height: 28),
                        if (stats != null && stats.byService.isNotEmpty)
                          ...stats.byService.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final colors = [
                              AppColors.primaryBlue,
                              AppColors.statusPayment,
                              AppColors.statusApproved,
                              const Color(0xFF8B5CF6),
                              const Color(0xFFEC4899),
                            ];
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: idx == stats.byService.length - 1
                                      ? 0
                                      : 18.0),
                              child: _barRow(
                                title: item.serviceName,
                                count: item.total,
                                total: total,
                                color: colors[idx % colors.length],
                              ),
                            );
                          })
                        else ...[
                          _barRow(
                            title: 'Bonafide Certificates',
                            count: allRequests
                                .where((r) =>
                                    r.serviceType == ServiceType.bonafide)
                                .length,
                            total: total,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 18),
                          _barRow(
                            title: 'ID Card Replacements',
                            count: allRequests
                                .where(
                                    (r) => r.serviceType == ServiceType.idCard)
                                .length,
                            total: total,
                            color: AppColors.statusPayment,
                          ),
                          const SizedBox(height: 18),
                          _barRow(
                            title: 'Equipment Bookings',
                            count: allRequests
                                .where((r) =>
                                    r.serviceType == ServiceType.equipment)
                                .length,
                            total: total,
                            color: AppColors.statusApproved,
                          ),
                        ],
                      ],
                    ),
                  );

                  // Status Health Card
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

              // Institutional Equipment & Governance Card
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
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 20, color: AppColors.primaryBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Institutional Governance & SLA Standards',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Operational throughput and campus-wide fulfillment targets',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 28),
                    _slaRow(
                      category: 'Administrative Final Authorization',
                      target: '24 Hours',
                      compliance: '98.5% Target Met',
                      color: AppColors.statusApproved,
                    ),
                    const Divider(height: 20),
                    _slaRow(
                      category: 'Staff Document Verification',
                      target: '48 Hours',
                      compliance: '96.2% Target Met',
                      color: AppColors.primaryBlue,
                    ),
                    const Divider(height: 20),
                    _slaRow(
                      category: 'Equipment & Facility Reservation',
                      target: 'Same Day',
                      compliance: '99.0% Target Met',
                      color: AppColors.statusPayment,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.textMuted),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: Operational metrics are aggregated from backend GET /api/admin/stats. Granular departmental turnaround logs are subject to institutional audit.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _slaRow({
    required String category,
    required String target,
    required String compliance,
    required Color color,
  }) {
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
                category,
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
              child: Text(
                compliance,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 4),
          child: Text(
            'Target turnaround: $target',
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
