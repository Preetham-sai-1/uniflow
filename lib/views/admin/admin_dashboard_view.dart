import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';
import '../staff/review_dialog.dart';
import '../student/request_detail_view.dart';

class AdminDashboardView extends StatelessWidget {
  final AppState appState;
  final ValueChanged<int> onNavigateTab;

  const AdminDashboardView({
    super.key,
    required this.appState,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final allRequests = appState.requests;
        final adminQueue = appState.adminQueue;
        final approvedCount =
            allRequests.where((r) => r.status == JourneyStatus.approved).length;
        final approvalRate = allRequests.isEmpty
            ? 0
            : ((approvedCount / allRequests.length) * 100).round();

        return ResponsiveContainer(
          title: 'Administrative Executive Portal',
          subtitle:
              'Campus-wide governance, final authorization, and operational health.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin High-level KPIs
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
                        title: 'Total Applications',
                        value: allRequests.length.toString().padLeft(2, '0'),
                        subtitle: 'Across all departments',
                        icon: Icons.hub_rounded,
                        accentColor: AppColors.primaryBlue,
                      ),
                      MetricCard(
                        title: 'Awaiting Final Seal',
                        value: adminQueue.length.toString().padLeft(2, '0'),
                        subtitle: 'Requires Dean sign-off',
                        icon: Icons.approval_rounded,
                        accentColor: AppColors.statusPending,
                      ),
                      MetricCard(
                        title: 'Approval Rate',
                        value: '$approvalRate%',
                        subtitle: '$approvedCount certified documents',
                        icon: Icons.verified_user_rounded,
                        accentColor: AppColors.statusApproved,
                      ),
                      const MetricCard(
                        title: 'SLA Adherence',
                        value: '98.4%',
                        subtitle: 'Under standard deadline',
                        icon: Icons.speed_rounded,
                        accentColor: AppColors.statusPayment,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Pending Executive Approval Queue
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Text(
                    'Pending Final Authorization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('View Full Analytics'),
                    onPressed: () => onNavigateTab(2), // Analytics Tab
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (adminQueue.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 48, color: AppColors.statusApproved),
                        SizedBox(height: 10),
                        Text('No requests pending administrative sign-off',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy)),
                        SizedBox(height: 4),
                        Text(
                            'All department-verified requests have been sealed.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: adminQueue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = adminQueue[index];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(req.serviceType.icon,
                                    color: AppColors.primaryBlue, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${req.serviceType.title} • ${req.id}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.primaryNavy),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Student: ${req.studentName} (${req.studentRoll}) • ${req.department}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: req.status, isCompact: true),
                            ],
                          ),
                          const Divider(height: 22),
                          // Submitted highlights
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: req.formData.entries.take(3).map((e) {
                              return Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${e.key}: ',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: e.value,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primaryNavy,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.visibility_outlined,
                                    size: 16),
                                label: const Text('View Full Journey'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
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
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.verified_rounded,
                                    size: 16),
                                label: const Text('Executive Seal & Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusApproved,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ReviewDecisionDialog(
                                      request: req,
                                      appState: appState,
                                      isAdmin: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Recent Campus Activity Table
              const Text(
                'Recent Campus Journey Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allRequests.take(4).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final req = allRequests[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(req.serviceType.icon,
                            color: AppColors.primaryBlue, size: 18),
                      ),
                      title: Text(
                        '${req.serviceType.title} (${req.id})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryNavy),
                      ),
                      subtitle: Text(
                        '${req.studentName} • ${req.department}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing:
                          StatusBadge(status: req.status, isCompact: true),
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
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
