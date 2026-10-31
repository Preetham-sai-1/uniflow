import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';
import 'request_detail_view.dart';
import 'services_catalogue_view.dart';

class MyRequestsView extends StatefulWidget {
  final AppState appState;

  const MyRequestsView({
    super.key,
    required this.appState,
  });

  @override
  State<MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends State<MyRequestsView> {
  String _filter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'All',
    'In Progress',
    'Completed',
    'Action Required',
    'Rejected'
  ];

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
        final allRequests = widget.appState.studentRequests;

        final filtered = allRequests.where((req) {
          final query = _searchController.text.trim().toLowerCase();
          final matchesQuery = query.isEmpty ||
              req.id.toLowerCase().contains(query) ||
              req.serviceType.title.toLowerCase().contains(query);

          bool matchesFilter = true;
          switch (_filter) {
            case 'In Progress':
              matchesFilter = !req.status.isTerminal &&
                  req.status != JourneyStatus.paymentRequired;
              break;
            case 'Completed':
              matchesFilter = req.status == JourneyStatus.approved;
              break;
            case 'Action Required':
              matchesFilter = req.status == JourneyStatus.paymentRequired;
              break;
            case 'Rejected':
              matchesFilter = req.status == JourneyStatus.rejected;
              break;
            default:
              matchesFilter = true;
          }

          return matchesQuery && matchesFilter;
        }).toList();

        return ResponsiveContainer(
          title: 'My Requests',
          subtitle:
              'Track your submitted campus service applications in real time.',
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Request'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Services Catalogue')),
                    body: ServicesCatalogueView(appState: widget.appState),
                  ),
                ),
              );
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter Card
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
                            'Search by ID (e.g. UF-2026-0018) or service name...',
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
                        children: _filters.map((f) {
                          final isSelected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _filter = f),
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

              // Request List
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
                      Icon(Icons.inbox_rounded,
                          size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('No requests found',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy)),
                      SizedBox(height: 4),
                      Text('Try changing your filters or create a new request.',
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
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestDetailView(
                              requestId: req.id,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${req.id})',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Submitted: ${_formatDate(req.submittedAt)} • Last update: ${_formatDate(req.updatedAt)}',
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
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted, size: 20),
                          ],
                        ),
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

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
