import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../models/role.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';
import '../student/request_detail_view.dart';
import 'review_dialog.dart';

class StaffQueueView extends StatefulWidget {
  final AppState appState;
  final bool showHistoryOnly;

  const StaffQueueView({
    super.key,
    required this.appState,
    this.showHistoryOnly = false,
  });

  @override
  State<StaffQueueView> createState() => _StaffQueueViewState();
}

class _StaffQueueViewState extends State<StaffQueueView> {
  String _selectedServiceFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _serviceFilters = [
    'All',
    'Bonafide',
    'ID Card',
    'Equipment'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.appState.isAuthenticated &&
          widget.appState.currentRole != UserRole.student) {
        widget.appState.loadStaffQueue();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        if (widget.appState.currentRole == UserRole.student) {
          return const ResponsiveContainer(
            title: 'Staff Review Queue',
            subtitle: 'Restricted area for faculty and staff officers.',
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gpp_bad_rounded,
                        size: 56, color: AppColors.statusRejected),
                    SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You do not have permissions to access the Staff Review Queue. This screen requires the "staff" or "admin" role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final allRequests = widget.appState.requests;
        final pendingQueue = widget.appState.staffQueue;

        if (widget.appState.isLoadingStaffQueue && pendingQueue.isEmpty) {
          return const ResponsiveContainer(
            title: 'Staff Review Queue',
            subtitle:
                'Requests awaiting verification from academic and security departments.',
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading staff review queue...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (widget.appState.staffQueueError != null && pendingQueue.isEmpty) {
          return ResponsiveContainer(
            title: 'Staff Review Queue',
            subtitle:
                'Requests awaiting verification from academic and security departments.',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 56, color: AppColors.statusRejected),
                    const SizedBox(height: 16),
                    Text(
                      widget.appState.staffQueueError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Connection'),
                      onPressed: () =>
                          widget.appState.loadStaffQueue(forceRefresh: true),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final sourceList = widget.showHistoryOnly ? allRequests : pendingQueue;

        final filtered = sourceList.where((req) {
          final query = _searchController.text.trim().toLowerCase();
          final matchesQuery = query.isEmpty ||
              req.id.toLowerCase().contains(query) ||
              req.studentName.toLowerCase().contains(query) ||
              req.studentRoll.toLowerCase().contains(query);

          bool matchesService = true;
          switch (_selectedServiceFilter) {
            case 'Bonafide':
              matchesService = req.serviceType.title.contains('Bonafide');
              break;
            case 'ID Card':
              matchesService = req.serviceType.title.contains('ID Card');
              break;
            case 'Equipment':
              matchesService = req.serviceType.title.contains('Equipment');
              break;
            default:
              matchesService = true;
          }

          return matchesQuery && matchesService;
        }).toList();

        final pendingCount = pendingQueue.length;
        final resolvedCount =
            allRequests.where((r) => r.status.isTerminal).length;

        return ResponsiveContainer(
          title: widget.showHistoryOnly
              ? 'Staff Action History'
              : 'Staff Review Queue',
          subtitle: widget.showHistoryOnly
              ? 'Comprehensive log of verified campus requests.'
              : 'Requests awaiting verification from academic and security departments.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Pending Staff Review',
                          value: pendingCount.toString().padLeft(2, '0'),
                          subtitle: 'Items requiring action',
                          icon: Icons.hourglass_top_rounded,
                          accentColor: AppColors.statusPending,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: MetricCard(
                          title: 'Total Handled',
                          value: allRequests.length.toString().padLeft(2, '0'),
                          subtitle: '$resolvedCount resolved cases',
                          icon: Icons.assignment_turned_in_rounded,
                          accentColor: AppColors.statusApproved,
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 14),
                        const Expanded(
                          child: MetricCard(
                            title: 'Average Turnaround',
                            value: '4.2 hrs',
                            subtitle: 'Well within standard SLA',
                            icon: Icons.speed_rounded,
                            accentColor: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Search & Service Filter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        hintText:
                            'Search by student name, roll number, or request ticket...',
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _serviceFilters.map((f) {
                          final isSelected = _selectedServiceFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _selectedServiceFilter = f),
                              selectedColor: const Color(0xFFEFF6FF),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.borderSubtle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Queue List
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.done_all_rounded,
                          size: 48, color: AppColors.statusApproved),
                      SizedBox(height: 12),
                      Text('No requests waiting in this queue',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy)),
                      SizedBox(height: 4),
                      Text('All student requests have been processed.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = filtered[index];
                    final canReview = !req.status.isTerminal &&
                        req.status != JourneyStatus.adminApproval;

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
                                    color: AppColors.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          req.serviceType.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: AppColors.primaryNavy),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${req.requestNumber.isNotEmpty ? req.requestNumber : req.id})',
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Student: ${req.studentName} • ${req.studentRoll} • ${req.department}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                    if (req.stepName != null ||
                                        req.waitingHours != null) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          if (req.stepName != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Step: ${req.stepName}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          if (req.waitingHours != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Waiting: ${req.waitingHours}h',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF92400E),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              StatusBadge(status: req.status, isCompact: true),
                            ],
                          ),
                          const Divider(height: 24),
                          // Summary row of submitted fields
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
                                label: const Text('View Journey'),
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
                                        initialRequest: req,
                                        appState: widget.appState,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (canReview)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.rate_review_rounded,
                                      size: 16),
                                  label: const Text('Review & Decide'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
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
                                        appState: widget.appState,
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
            ],
          ),
        );
      },
    );
  }
}
