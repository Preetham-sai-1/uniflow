import 'package:flutter/material.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/department.dart';
import '../../models/managed_user.dart';
import '../../models/pending_user.dart';
import '../../models/role.dart';
import '../../widgets/responsive_container.dart';

/// Staff Student Management View
/// Provides departmental staff with full student registration management:
/// 1. Student Registrations (review, approve, reject with reason)
/// 2. Student Management (create student accounts, search/filter directory, permanent deletion)
class StaffStudentManagementView extends StatefulWidget {
  final AppState appState;

  const StaffStudentManagementView({
    super.key,
    required this.appState,
  });

  @override
  State<StaffStudentManagementView> createState() =>
      _StaffStudentManagementViewState();
}

class _StaffStudentManagementViewState extends State<StaffStudentManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchAll(forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAll({bool forceRefresh = false}) {
    if (widget.appState.isAuthenticated &&
        widget.appState.currentRole == UserRole.staff) {
      widget.appState.loadStaffPendingStudents(forceRefresh: forceRefresh);
      _fetchStudents(forceRefresh: forceRefresh);
    }
  }

  void _fetchStudents({bool forceRefresh = false, int page = 1}) {
    if (widget.appState.isAuthenticated &&
        widget.appState.currentRole == UserRole.staff) {
      widget.appState.loadStaffStudents(
        forceRefresh: forceRefresh,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        approvalStatus:
            _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
        page: page,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final appState = widget.appState;

        // RBAC check: Staff only
        if (appState.currentRole != UserRole.staff) {
          return ResponsiveContainer(
            title: 'Student Directory',
            subtitle: 'Enrolled campus student directory and account review.',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Staff Authorization Required',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Only departmental staff members have access to the student directory.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final pendingCount = appState.staffPendingStudents.length;

        return ResponsiveContainer(
          title: 'Student Registration & Directory',
          subtitle:
              'Review student registrations, onboard new student accounts, and oversee enrollment credentials.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tab Navigation Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryBlue,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.how_to_reg_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Student Registrations',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.statusPending.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusPending,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Student Directory (${appState.staffStudentsTotal})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Views
              SizedBox(
                height: 700,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Section A: Student Registrations
                    _buildStudentRegistrationsTab(appState),

                    // Section B: Student Management
                    _buildStudentManagementTab(appState),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION A: STUDENT REGISTRATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentRegistrationsTab(AppState appState) {
    final pendingStudents = appState.staffPendingStudents;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Text(
                    'Pending Student Registrations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pendingStudents.isNotEmpty
                          ? AppColors.statusPending.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pendingStudents.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: pendingStudents.isNotEmpty
                            ? AppColors.statusPending
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh pending list',
                onPressed: () =>
                    appState.loadStaffPendingStudents(forceRefresh: true),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (appState.staffPendingStudentsError != null) ...[
            _buildErrorBanner(appState.staffPendingStudentsError!),
            const SizedBox(height: 12),
          ],

          if (appState.isLoadingStaffPendingStudents &&
              !appState.hasLoadedStaffPendingStudents)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (pendingStudents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 44, color: AppColors.statusApproved),
                  SizedBox(height: 12),
                  Text(
                    'No Pending Registrations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All student registration requests have been reviewed.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = pendingStudents[index];
                return _buildPendingStudentCard(student);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPendingStudentCard(PendingUser student) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.amber.shade50,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildBadge('PENDING', Colors.amber.shade50,
                            Colors.amber.shade900),
                        if (student.studentId != null)
                          _buildChip(
                              Icons.badge_outlined, 'ID: ${student.studentId}'),
                        if (student.departmentName != null)
                          _buildChip(Icons.apartment_rounded,
                              student.departmentName!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _handleRejectStudent(student),
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.red),
                label: const Text('Reject',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _handleApproveStudent(student),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusApproved,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveStudent(PendingUser student) async {
    try {
      await widget.appState.approveStaffPendingStudent(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration for ${student.name} approved.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        _fetchStudents(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectStudent(PendingUser student) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Student Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting registration for ${student.name} (${student.email}).'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Rejection',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await widget.appState.rejectStaffPendingStudent(
          student.id,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration for ${student.name} was rejected.'),
              backgroundColor: Colors.red,
            ),
          );
          _fetchStudents(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject registration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION B: STUDENT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentManagementTab(AppState appState) {
    final students = appState.staffStudents;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar with Create Student Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${appState.staffStudentsTotal} Student Accounts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh Students',
                    onPressed: () => _fetchStudents(forceRefresh: true),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showCreateStudentModal,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text(
                      'Create Student',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Box & Status Filters
          _buildDirectoryFilterSection(),
          const SizedBox(height: 16),

          if (appState.staffStudentsError != null) ...[
            _buildErrorBanner(appState.staffStudentsError!),
            const SizedBox(height: 14),
          ],

          if (appState.isLoadingStaffStudents &&
              !appState.hasLoadedStaffStudents)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (students.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildStudentCard(student);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDirectoryFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name, email, or student ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchStudents(forceRefresh: true);
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  onSubmitted: (_) => _fetchStudents(forceRefresh: true),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _fetchStudents(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Status:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _buildFilterChip('All', _selectedStatusFilter == 'all', () {
                setState(() => _selectedStatusFilter = 'all');
                _fetchStudents(forceRefresh: true);
              }),
              _buildFilterChip(
                  'Approved', _selectedStatusFilter == 'APPROVED', () {
                setState(() => _selectedStatusFilter = 'APPROVED');
                _fetchStudents(forceRefresh: true);
              }),
              _buildFilterChip(
                  'Pending', _selectedStatusFilter == 'PENDING', () {
                setState(() => _selectedStatusFilter = 'PENDING');
                _fetchStudents(forceRefresh: true);
              }),
              _buildFilterChip(
                  'Rejected', _selectedStatusFilter == 'REJECTED', () {
                setState(() => _selectedStatusFilter = 'REJECTED');
                _fetchStudents(forceRefresh: true);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlue.withOpacity(0.15),
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStudentCard(ManagedUser student) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade50,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusBadge(student.approvalStatus),
                    if (student.studentId != null)
                      _buildChip(
                          Icons.badge_outlined, 'ID: ${student.studentId}'),
                    if (student.departmentName != null)
                      _buildChip(Icons.apartment_rounded,
                          student.departmentName!),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
            tooltip: 'Delete Student Account',
            onPressed: () => _showDeleteConfirmation(student),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'PENDING':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case 'REJECTED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
    }
    return _buildBadge(status.toUpperCase(), bg, fg);
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 20, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Column(
        children: [
          Icon(Icons.school_outlined,
              size: 44, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'No Student Records Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No student accounts matched your query.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCreateStudentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StaffCreateStudentDialog(
        appState: widget.appState,
        onSuccess: () => _fetchStudents(forceRefresh: true),
      ),
    );
  }

  void _showDeleteConfirmation(ManagedUser student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Student Account?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                      text: 'Are you sure you want to permanently delete '),
                  TextSpan(
                    text: '${student.name} (${student.email})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                      text:
                          '?\n\nLogin credentials will be permanently removed. Any requests submitted by this student will remain intact for institutional records.'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.appState.deleteStaffStudent(student.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Student account for ${student.name} was deleted.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete student: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}

// ─── Staff Create Student Dialog (Student role strictly enforced) ───────────

class _StaffCreateStudentDialog extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSuccess;

  const _StaffCreateStudentDialog({
    required this.appState,
    required this.onSuccess,
  });

  @override
  State<_StaffCreateStudentDialog> createState() =>
      _StaffCreateStudentDialogState();
}

class _StaffCreateStudentDialogState extends State<_StaffCreateStudentDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Department> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoadingDepartments = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoadingDepartments = true);
    try {
      final list = await widget.appState.authService.fetchDepartments();
      if (mounted) {
        setState(() {
          _departments = list;
          if (_departments.isNotEmpty) {
            _selectedDepartmentId = _departments.first.id;
          }
        });
      }
    } catch (_) {
      // Ignored: dropdown remains optional
    } finally {
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.createStaffStudent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        studentId: _studentIdController.text.trim(),
        departmentId: _selectedDepartmentId,
      );

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student account created successfully.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create student account.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Student Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create an active student account on behalf of an enrolled student.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Colors.red.shade900, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Full Name *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return 'Enter full name (minimum 2 characters)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Institutional Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Institutional Email *',
                      hintText: 'student@uniflow.edu',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || !v.contains('@') || !v.contains('.')) {
                        return 'Enter a valid institutional email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Student ID
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      hintText: 'e.g. STU2026101',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please provide a valid Student ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Department Dropdown
                  if (_isLoadingDepartments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else if (_departments.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _departments.map((d) {
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text('${d.name} (${d.code})'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDepartmentId = val),
                    ),
                  const SizedBox(height: 14),

                  // Temporary Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Temporary Password *',
                      hintText: 'At least 8 chars, 1 uppercase, 1 digit',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Password must be at least 8 characters long';
                      }
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain at least 1 uppercase letter';
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain at least 1 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Student Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
