import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../models/pending_user.dart';
import '../../models/role.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';
import '../staff/review_dialog.dart';
import '../student/request_detail_view.dart';

class AdminDashboardView extends StatefulWidget {
  final AppState appState;
  final ValueChanged<int> onNavigateTab;

  const AdminDashboardView({
    super.key,
    required this.appState,
    required this.onNavigateTab,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  void _fetchData({bool forceRefresh = false}) {
    if (widget.appState.isAuthenticated &&
        widget.appState.currentRole == UserRole.admin) {
      widget.appState.loadAdminStats(forceRefresh: forceRefresh);
      widget.appState.loadAdminRequests(forceRefresh: forceRefresh);
      widget.appState.loadPendingUsers(forceRefresh: forceRefresh);
    }
  }

  Future<void> _approveUser(PendingUser user) async {
    try {
      await widget.appState.approvePendingUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} has been approved and can now log in.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve user: $e'),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    }
  }

  Future<void> _showRejectUserDialog(PendingUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _RejectUserDialog(user: user, appState: widget.appState),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration for ${user.name} has been rejected.'),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final appState = widget.appState;

        // Role verification check: Admin role required
        if (appState.currentRole != UserRole.admin) {
          return ResponsiveContainer(
            title: 'Administrative Executive Portal',
            subtitle: 'Campus-wide governance and operational oversight.',
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
                    'This portal requires verified administrative privileges. Your current role is not authorized to inspect institutional stats or execute executive seals.',
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
        final adminQueue = appState.adminQueue;
        final stats = appState.adminStats;

        final totalApplications =
            stats != null ? stats.totalApplications : allRequests.length;
        final awaitingFinalSeal = stats != null
            ? (stats.pendingExecutiveSignOff > 0
                ? stats.pendingExecutiveSignOff
                : adminQueue.length)
            : adminQueue.length;
        final approvedCount = stats != null
            ? stats.approvedCount
            : allRequests
                .where((r) => r.status == JourneyStatus.approved)
                .length;
        final approvalRate = stats != null
            ? stats.approvalRate
            : (allRequests.isEmpty
                ? 0
                : ((approvedCount / allRequests.length) * 100).round());

        return ResponsiveContainer(
          title: 'Administrative Executive Portal',
          subtitle:
              'Campus-wide governance, final authorization, and operational health.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Banner with Retry
              if (appState.adminStatsError != null ||
                  appState.adminRequestsError != null)
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
                          appState.adminStatsError ??
                              appState.adminRequestsError ??
                              'Failed to load administrative data.',
                          style: const TextStyle(
                            color: AppColors.statusRejected,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _fetchData(forceRefresh: true),
                        child: const Text('Retry',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

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
                        value: totalApplications.toString().padLeft(2, '0'),
                        subtitle: 'Across all departments',
                        icon: Icons.hub_rounded,
                        accentColor: AppColors.primaryBlue,
                      ),
                      MetricCard(
                        title: 'Awaiting Final Seal',
                        value: awaitingFinalSeal.toString().padLeft(2, '0'),
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
                        subtitle: 'Institutional baseline',
                        icon: Icons.speed_rounded,
                        accentColor: AppColors.statusPayment,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Student Account Approvals Section
              _buildUserApprovalsSection(appState),

              const SizedBox(height: 32),

              // Pending Executive Approval Queue Header
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Refresh queue',
                        onPressed: () => _fetchData(forceRefresh: true),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                        label: const Text('Manage Users'),
                        onPressed: () =>
                            widget.onNavigateTab(1), // User Management Tab
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('View Full Analytics'),
                        onPressed: () =>
                            widget.onNavigateTab(2), // Analytics Tab
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (appState.isLoadingAdminRequests &&
                  !appState.hasLoadedAdminRequests)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (adminQueue.isEmpty)
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
                                      '${req.serviceType.title} • ${req.requestNumber}',
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
                                        requestId: req.backendId ?? req.id,
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
                child: allRequests.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No campus journeys registered yet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allRequests.take(6).length,
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
                              '${req.serviceType.title} (${req.requestNumber})',
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
                            trailing: StatusBadge(
                                status: req.status, isCompact: true),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RequestDetailView(
                                    requestId: req.backendId ?? req.id,
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

  Widget _buildUserApprovalsSection(AppState appState) {
    final pendingUsers = appState.pendingUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Text(
                  'Student Account Approvals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pendingUsers.isNotEmpty
                        ? AppColors.statusPending.withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingUsers.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: pendingUsers.isNotEmpty
                          ? AppColors.statusPending
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.people_outline_rounded, size: 16),
                  label: const Text('View All Users'),
                  onPressed: () => widget.onNavigateTab(1),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh pending accounts',
                  onPressed: () =>
                      appState.loadPendingUsers(forceRefresh: true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (appState.isLoadingPendingUsers && !appState.hasLoadedPendingUsers)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (pendingUsers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 40, color: AppColors.statusApproved),
                  SizedBox(height: 8),
                  Text(
                    'No pending student registrations',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All student registration requests have been approved or reviewed.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              return Container(
                padding: const EdgeInsets.all(16),
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
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primaryNavy.withOpacity(0.1),
                          child: const Icon(Icons.school_rounded,
                              color: AppColors.primaryNavy, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: const Text(
                            'PENDING REVIEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        if (user.studentId != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.badge_outlined,
                                  size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'ID: ${user.studentId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        if (user.departmentName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_outlined,
                                  size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                user.departmentName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          key: Key('reject_user_${user.id}'),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 16, color: AppColors.statusRejected),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: AppColors.statusRejected),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.statusRejected),
                          ),
                          onPressed: () => _showRejectUserDialog(user),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          key: Key('approve_user_${user.id}'),
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 16),
                          label: const Text('Approve Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusApproved,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _approveUser(user),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _RejectUserDialog extends StatefulWidget {
  final PendingUser user;
  final AppState appState;

  const _RejectUserDialog({required this.user, required this.appState});

  @override
  State<_RejectUserDialog> createState() => _RejectUserDialogState();
}

class _RejectUserDialogState extends State<_RejectUserDialog> {
  late final TextEditingController _reasonController;
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleReject() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _localError = 'A rejection reason is required.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    try {
      await widget.appState.rejectPendingUser(widget.user.id, reason: reason);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localError = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reject Registration: ${widget.user.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please provide a reason for rejecting this student registration (e.g. invalid student ID or institutional email).',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_localError != null) ...[
            Text(
              _localError!,
              style: const TextStyle(
                color: AppColors.statusRejected,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('reject_reason_input'),
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('confirm_reject_user_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusRejected,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _handleReject,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Reject Registration'),
        ),
      ],
    );
  }
}
