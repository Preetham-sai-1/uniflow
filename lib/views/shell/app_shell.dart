import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/role.dart';
import '../../widgets/brand_logo.dart';
import '../admin/admin_analytics_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../admin/admin_user_management_view.dart';
import '../profile/profile_view.dart';
import '../staff/staff_queue_view.dart';
import '../staff/staff_student_management_view.dart';
import '../student/my_requests_view.dart';
import '../student/services_catalogue_view.dart';
import '../student/student_dashboard_view.dart';

class AppShell extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSignOut;

  const AppShell({
    super.key,
    required this.appState,
    required this.onSignOut,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final role = widget.appState.currentRole;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1024;
        final isTablet = screenWidth >= 768 && screenWidth < 1024;
        final useRail = isDesktop || isTablet;

        final destinations = _getDestinations(role);
        final pages = _getPages(role);

        // Clamp index if role changed and count differs
        if (_currentIndex >= pages.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          appBar: useRail
              ? null
              : AppBar(
                  title: const BrandLogo(fontSize: 17, iconSize: 22),
                  actions: [
                    _buildRoleBadge(role),
                    const SizedBox(width: 8),
                  ],
                ),
          body: Row(
            children: [
              // Desktop & Tablet Navigation Rail
              if (useRail)
                NavigationRail(
                  backgroundColor: Colors.white,
                  extended: isDesktop,
                  minExtendedWidth: 220,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  leading: Padding(
                    padding: const EdgeInsets.only(
                        top: 24, bottom: 20, left: 16, right: 16),
                    child: isDesktop
                        ? const BrandLogo(fontSize: 20, showBadge: true)
                        : const BrandLogo(fontSize: 18),
                  ),
                  destinations: destinations.map((d) {
                    return NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon:
                          Icon(d.selectedIcon, color: AppColors.primaryBlue),
                      label: Text(
                        d.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRoleBadge(role),
                            const SizedBox(height: 12),
                            IconButton(
                              tooltip: 'Sign Out',
                              icon: const Icon(Icons.logout_rounded,
                                  color: AppColors.textSecondary),
                              onPressed: widget.onSignOut,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Divider between Rail and Content
              if (useRail)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),

              // Main Active View
              Expanded(
                child: Column(
                  children: [
                    if (useRail) _buildTopHeaderBar(role),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey('${role.name}_$_currentIndex'),
                          child: pages[_currentIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  destinations: destinations.map((d) {
                    return NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon:
                          Icon(d.selectedIcon, color: AppColors.primaryBlue),
                      label: d.label,
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildTopHeaderBar(UserRole role) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${role.displayName} Workspace',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleBadge(role),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(role.icon, size: 16, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appState.currentUser.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    widget.appState.currentUser.identifier,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole currentRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(currentRole.icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            currentRole.displayName,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getPages(UserRole role) {
    switch (role) {
      case UserRole.student:
        return [
          StudentDashboardView(
            appState: widget.appState,
            onNavigateTab: (index) => setState(() => _currentIndex = index),
          ),
          ServicesCatalogueView(appState: widget.appState),
          MyRequestsView(appState: widget.appState),
          ProfileView(appState: widget.appState, onSignOut: widget.onSignOut),
        ];

      case UserRole.staff:
        return [
          StaffQueueView(appState: widget.appState, showHistoryOnly: false),
          StaffQueueView(appState: widget.appState, showHistoryOnly: true),
          StaffStudentManagementView(appState: widget.appState),
          ProfileView(appState: widget.appState, onSignOut: widget.onSignOut),
        ];

      case UserRole.admin:
        return [
          AdminDashboardView(
            appState: widget.appState,
            onNavigateTab: (index) => setState(() => _currentIndex = index),
          ),
          AdminUserManagementView(appState: widget.appState),
          AdminAnalyticsView(appState: widget.appState),
          ProfileView(appState: widget.appState, onSignOut: widget.onSignOut),
        ];
    }
  }

  List<_NavDestination> _getDestinations(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const [
          _NavDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded),
          _NavDestination(
              label: 'Services',
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded),
          _NavDestination(
              label: 'My Requests',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded),
          _NavDestination(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded),
        ];

      case UserRole.staff:
        return const [
          _NavDestination(
              label: 'Review Queue',
              icon: Icons.pending_actions_outlined,
              selectedIcon: Icons.pending_actions_rounded),
          _NavDestination(
              label: 'Action History',
              icon: Icons.history_rounded,
              selectedIcon: Icons.history_edu_rounded),
          _NavDestination(
              label: 'Students',
              icon: Icons.school_outlined,
              selectedIcon: Icons.school_rounded),
          _NavDestination(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded),
        ];

      case UserRole.admin:
        return const [
          _NavDestination(
              label: 'Oversight',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded),
          _NavDestination(
              label: 'Users',
              icon: Icons.manage_accounts_outlined,
              selectedIcon: Icons.manage_accounts_rounded),
          _NavDestination(
              label: 'Analytics',
              icon: Icons.insights_rounded,
              selectedIcon: Icons.analytics_rounded),
          _NavDestination(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded),
        ];
    }
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
