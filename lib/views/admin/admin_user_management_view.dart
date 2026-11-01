import 'package:flutter/material.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/department.dart';
import '../../models/managed_user.dart';
import '../../models/role.dart';
import '../../widgets/responsive_container.dart';

/// Administrator User Management View
/// Provides full role-based administration for student and staff accounts.
class AdminUserManagementView extends StatefulWidget {
  final AppState appState;

  const AdminUserManagementView({
    super.key,
    required this.appState,
  });

  @override
  State<AdminUserManagementView> createState() =>
      _AdminUserManagementViewState();
}

class _AdminUserManagementViewState extends State<AdminUserManagementView> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchUsers(forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchUsers({bool forceRefresh = false, int page = 1}) {
    if (widget.appState.isAuthenticated &&
        widget.appState.currentRole == UserRole.admin) {
      widget.appState.loadManagedUsers(
        forceRefresh: forceRefresh,
        role: _selectedRoleFilter == 'all' ? null : _selectedRoleFilter,
        approvalStatus:
            _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
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

        // RBAC check: Admin only
        if (appState.currentRole != UserRole.admin) {
          return ResponsiveContainer(
            title: 'User Management',
            subtitle: 'Campus account administration and role management.',
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
                  Icon(Icons.shield_outlined,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Administrative Authorization Required',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'User administration and role assignment are restricted to institutional administrators.',
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

        final users = appState.managedUsers;

        return ResponsiveContainer(
          title: 'User Management',
          subtitle:
              'Manage campus accounts, assign student and staff roles, review registrations, and oversee access.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action & Controls Bar
              _buildTopActionBar(),
              const SizedBox(height: 16),

              // Search & Filter Card
              _buildFilterSection(),
              const SizedBox(height: 20),

              // Error State Banner
              if (appState.managedUsersError != null) ...[
                _buildErrorBanner(appState.managedUsersError!),
                const SizedBox(height: 16),
              ],

              // Loading State or User List
              if (appState.isLoadingManagedUsers &&
                  !appState.hasLoadedManagedUsers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (users.isEmpty)
                _buildEmptyState()
              else
                _buildUsersList(users),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${widget.appState.managedUsersTotal} Accounts',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh Accounts',
              onPressed: () => _fetchUsers(forceRefresh: true),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showCreateUserModal,
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text(
            'Create Account',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                    hintText: 'Search by name, email, or student/staff ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchUsers(forceRefresh: true);
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  onSubmitted: (_) => _fetchUsers(forceRefresh: true),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _fetchUsers(forceRefresh: true),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Role filter
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  const Text('Role:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  _buildFilterChip('All', _selectedRoleFilter == 'all', () {
                    setState(() => _selectedRoleFilter = 'all');
                    _fetchUsers(forceRefresh: true);
                  }),
                  _buildFilterChip(
                      'Students', _selectedRoleFilter == 'student', () {
                    setState(() => _selectedRoleFilter = 'student');
                    _fetchUsers(forceRefresh: true);
                  }),
                  _buildFilterChip('Staff', _selectedRoleFilter == 'staff', () {
                    setState(() => _selectedRoleFilter = 'staff');
                    _fetchUsers(forceRefresh: true);
                  }),
                ],
              ),
              const SizedBox(width: 16),
              // Status filter
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  const Text('Status:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  _buildFilterChip('All', _selectedStatusFilter == 'all', () {
                    setState(() => _selectedStatusFilter = 'all');
                    _fetchUsers(forceRefresh: true);
                  }),
                  _buildFilterChip(
                      'Approved', _selectedStatusFilter == 'APPROVED', () {
                    setState(() => _selectedStatusFilter = 'APPROVED');
                    _fetchUsers(forceRefresh: true);
                  }),
                  _buildFilterChip(
                      'Pending', _selectedStatusFilter == 'PENDING', () {
                    setState(() => _selectedStatusFilter = 'PENDING');
                    _fetchUsers(forceRefresh: true);
                  }),
                  _buildFilterChip(
                      'Rejected', _selectedStatusFilter == 'REJECTED', () {
                    setState(() => _selectedStatusFilter = 'REJECTED');
                    _fetchUsers(forceRefresh: true);
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBlue.withOpacity(0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
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
          TextButton(
            onPressed: () => _fetchUsers(forceRefresh: true),
            child: const Text('Retry'),
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
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'No Accounts Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No user accounts match your search and filter criteria.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedRoleFilter = 'all';
                _selectedStatusFilter = 'all';
              });
              _fetchUsers(forceRefresh: true);
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<ManagedUser> users) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(ManagedUser user) {
    final isSelf = widget.appState.currentUser.email.toLowerCase() ==
        user.email.toLowerCase();

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
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: _getRoleBgColor(user.role),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _getRoleTextColor(user.role),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildRoleBadge(user.role),
                        _buildStatusBadge(user.approvalStatus),
                        if (user.identifier != '—')
                          _buildChip(
                            Icons.badge_outlined,
                            user.isStudent
                                ? 'Student ID: ${user.identifier}'
                                : 'Staff ID: ${user.identifier}',
                          ),
                        if (user.departmentName != null &&
                            user.departmentName!.isNotEmpty)
                          _buildChip(
                            Icons.apartment_rounded,
                            user.departmentName!,
                          ),
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
          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Pending actions
              if (user.isPending) ...[
                OutlinedButton.icon(
                  onPressed: () => _handleRejectUser(user),
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: Colors.red),
                  label: const Text('Reject',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleApproveUser(user),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusApproved,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Role change (Only for student or staff; Admin role cannot be changed)
              if (!user.isAdmin) ...[
                TextButton.icon(
                  onPressed: () => _showChangeRoleModal(user),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Change Role',
                      style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
              ],

              // Permanent deletion (Disabled for admin accounts and self)
              if (!user.isAdmin && !isSelf) ...[
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(user),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  label: const Text('Delete Account',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ] else if (user.isAdmin) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Admin Protected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleBgColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.blue.shade50;
      case 'staff':
        return Colors.teal.shade50;
      case 'admin':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getRoleTextColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.blue.shade800;
      case 'staff':
        return Colors.teal.shade800;
      case 'admin':
        return Colors.purple.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Widget _buildRoleBadge(String role) {
    final bg = _getRoleBgColor(role);
    final fg = _getRoleTextColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
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
          Icon(icon, size: 13, color: AppColors.textSecondary),
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

  // ─── Modal Actions ──────────────────────────────────────────────────────────

  Future<void> _handleApproveUser(ManagedUser user) async {
    try {
      await widget.appState.approvePendingUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account for ${user.name} approved successfully.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        _fetchUsers(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectUser(ManagedUser user) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Student Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting registration for ${user.name} (${user.email}).'),
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
        await widget.appState.rejectPendingUser(
          user.id,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration for ${user.name} was rejected.'),
              backgroundColor: Colors.red,
            ),
          );
          _fetchUsers(forceRefresh: true);
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

  void _showCreateUserModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateUserDialog(
        appState: widget.appState,
        onSuccess: () => _fetchUsers(forceRefresh: true),
      ),
    );
  }

  void _showChangeRoleModal(ManagedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangeRoleDialog(
        user: user,
        appState: widget.appState,
        onSuccess: () => _fetchUsers(forceRefresh: true),
      ),
    );
  }

  void _showDeleteConfirmation(ManagedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Permanently Delete Account?'),
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
                    text: '${user.name} (${user.email})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                      text:
                          '?\n\nThis action cannot be undone. Login credentials will be permanently destroyed.\n\nAll existing campus service requests and workflow history will remain intact.'),
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
                await widget.appState.deleteManagedUser(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account for ${user.name} was permanently deleted.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
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

// ─── Create User Dialog (Student or Staff only) ─────────────────────────────

class _CreateUserDialog extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSuccess;

  const _CreateUserDialog({
    required this.appState,
    required this.onSuccess,
  });

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  // Role selector: STRICTLY student or staff
  String _selectedRole = 'student';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _identifierController = TextEditingController();
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
    _identifierController.dispose();
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
      await widget.appState.createManagedUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole, // Strictly 'student' or 'staff'
        departmentId: _selectedDepartmentId,
        studentId: _selectedRole == 'student'
            ? _identifierController.text.trim()
            : null,
        staffId: _selectedRole == 'staff'
            ? _identifierController.text.trim()
            : null,
      );

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_selectedRole == 'student' ? 'Student' : 'Staff'} account created successfully.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create user account.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                        'Create User Account',
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
                    'Create an administrative account for campus students or staff.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Role Selector — STRICTLY Student or Staff (No Admin!)
                  const Text(
                    'Account Role',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'student',
                        label: Text('Student'),
                        icon: Icon(Icons.school_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: 'staff',
                        label: Text('Staff Member'),
                        icon: Icon(Icons.badge_rounded, size: 18),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedRole = newSelection.first;
                        _identifierController.clear();
                      });
                    },
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
                      labelText: 'Full Name *',
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
                      hintText: 'name@uniflow.edu',
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

                  // Student ID or Staff ID
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: _selectedRole == 'student'
                          ? 'Student ID *'
                          : 'Staff ID *',
                      hintText: _selectedRole == 'student'
                          ? 'e.g. STU2026101'
                          : 'e.g. STF-DEPT-01',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please provide a ${_selectedRole == 'student' ? 'student ID' : 'staff ID'}';
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
                            : const Text('Create Account'),
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

// ─── Change Role Dialog (Student <-> Staff strictly) ────────────────────────

class _ChangeRoleDialog extends StatefulWidget {
  final ManagedUser user;
  final AppState appState;
  final VoidCallback onSuccess;

  const _ChangeRoleDialog({
    required this.user,
    required this.appState,
    required this.onSuccess,
  });

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  late String _targetRole;
  final _idController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to the opposite role
    _targetRole = widget.user.isStudent ? 'staff' : 'student';
    _idController.text = widget.user.isStudent
        ? (widget.user.staffId ?? '')
        : (widget.user.studentId ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _handleRoleChange() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.updateManagedUserRole(
        userId: widget.user.id,
        newRole: _targetRole, // STRICTLY 'student' or 'staff'
        studentId:
            _targetRole == 'student' ? _idController.text.trim() : null,
        staffId: _targetRole == 'staff' ? _idController.text.trim() : null,
      );

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Role updated to ${_targetRole == 'student' ? 'Student' : 'Staff'}.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update user role.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Account Role'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifying role for ${widget.user.name} (${widget.user.email}).'),
            const SizedBox(height: 6),
            Text(
              'Current role: ${widget.user.role.toUpperCase()}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select New Role',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            // STRICTLY Student and Staff only!
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'student',
                  label: Text('Student'),
                  icon: Icon(Icons.school_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 'staff',
                  label: Text('Staff Member'),
                  icon: Icon(Icons.badge_rounded, size: 18),
                ),
              ],
              selected: {_targetRole},
              onSelectionChanged: (newSel) {
                setState(() {
                  _targetRole = newSel.first;
                });
              },
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: _targetRole == 'student'
                    ? 'Student ID (optional)'
                    : 'Staff ID (optional)',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleRoleChange,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update Role'),
        ),
      ],
    );
  }
}

