import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../models/service_item.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';
import 'request_detail_view.dart';
import 'request_form_view.dart';

class StudentDashboardView extends StatelessWidget {
  final AppState appState;
  final ValueChanged<int> onNavigateTab;

  const StudentDashboardView({
    super.key,
    required this.appState,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final requests = appState.studentRequests;
        final inReviewCount = requests
            .where((r) =>
                r.status == JourneyStatus.departmentReview ||
                r.status == JourneyStatus.securityReview ||
                r.status == JourneyStatus.adminApproval)
            .length;
        final approvedCount =
            requests.where((r) => r.status == JourneyStatus.approved).length;
        final actionNeededCount = requests
            .where((r) => r.status == JourneyStatus.paymentRequired)
            .length;

        final activeRequests =
            requests.where((r) => !r.status.isTerminal).toList();

        return ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryNavy, Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'STUDENT PORTAL',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome back, ${appState.currentUser.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${appState.currentUser.department} • ${appState.currentUser.identifier}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryBlue,
                                ),
                                icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18),
                                label: const Text('Start New Request'),
                                onPressed: () =>
                                    onNavigateTab(1), // Services Tab
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                icon: const Icon(Icons.receipt_long_rounded,
                                    size: 18),
                                label: const Text('Track Submissions'),
                                onPressed: () =>
                                    onNavigateTab(2), // My Requests Tab
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Decorative icon for wide screens
                    if (MediaQuery.of(context).size.width >= 680)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 64,
                          color: Colors.white30,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // KPI Metric Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  final isMedium = constraints.maxWidth >= 480;
                  final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 2);
                  final aspectRatio =
                      isWide ? 1.5 : (constraints.maxWidth < 380 ? 1.35 : 1.45);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: aspectRatio,
                    children: [
                      MetricCard(
                        title: 'Total Requests',
                        value: requests.length.toString().padLeft(2, '0'),
                        subtitle: 'All time submissions',
                        icon: Icons.folder_outlined,
                        accentColor: AppColors.primaryBlue,
                      ),
                      MetricCard(
                        title: 'In Review',
                        value: inReviewCount.toString().padLeft(2, '0'),
                        subtitle: 'Staff & admin queues',
                        icon: Icons.hourglass_top_rounded,
                        accentColor: AppColors.statusPending,
                      ),
                      MetricCard(
                        title: 'Completed',
                        value: approvedCount.toString().padLeft(2, '0'),
                        subtitle: 'Approved & issued',
                        icon: Icons.check_circle_outline_rounded,
                        accentColor: AppColors.statusApproved,
                      ),
                      MetricCard(
                        title: 'Action Needed',
                        value: actionNeededCount.toString().padLeft(2, '0'),
                        subtitle: 'Payment or feedback',
                        icon: Icons.notification_important_outlined,
                        accentColor: AppColors.statusPayment,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Active Journeys In-Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Active Journeys',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(2),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (activeRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Center(
                    child: Text(
                      'No requests currently in progress. Start one from the Services tab!',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: activeRequests.map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestDetailView(
                                requestId: req.id,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(req.serviceType.icon,
                                    color: AppColors.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.serviceType.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${req.id} • ${_formatDate(req.submittedAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: StatusBadge(
                                    status: req.status, isCompact: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              // Quick Campus Services Shortcuts
              const Text(
                'Instant Service Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 3 : 1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isWide ? 2.2 : 3.0,
                    children: CampusServiceItem.availableServices.map((svc) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestFormView(
                                serviceType: svc.type,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(svc.icon,
                                    color: AppColors.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      svc.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      svc.sla,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
