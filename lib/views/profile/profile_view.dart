import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/role.dart';
import '../../widgets/responsive_container.dart';

class ProfileView extends StatelessWidget {
  final AppState appState;
  final VoidCallback onSignOut;

  const ProfileView({
    super.key,
    required this.appState,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        final currentRole = appState.currentRole;

        return ResponsiveContainer(
          maxWidth: 720,
          title: 'Campus Profile & Settings',
          subtitle: 'Active user authentication and institutional membership.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Identity Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Icon(
                            currentRole.icon,
                            color: AppColors.primaryBlue,
                            size: 44,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.statusApproved,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${currentRole.displayName.toUpperCase()} • ${user.identifier}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Divider(height: 36),
                    _profileInfoTile(
                      icon: Icons.account_balance_rounded,
                      label: 'Assigned Department / Branch',
                      value: user.department,
                    ),
                    const SizedBox(height: 12),
                    _profileInfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Institutional Identifier',
                      value: user.identifier,
                    ),
                    const SizedBox(height: 12),
                    _profileInfoTile(
                      icon: Icons.domain_rounded,
                      label: 'Campus Entity',
                      value: 'Vishnu Institute of Technology (VIT)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Perspective Switcher Card (For evaluators / testing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
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
                        Icon(Icons.swap_horiz_rounded,
                            color: AppColors.primaryBlue, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Switch Active Role Perspective',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Instantly test the campus journey from different user authorization levels.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: UserRole.values.map((role) {
                        final isSelected = currentRole == role;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.borderSubtle,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 4),
                              ),
                              onPressed: () => appState.setRole(role),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  role.shortName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRejected,
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out of Workspace'),
                  onPressed: onSignOut,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy)),
            ],
          ),
        ),
      ],
    );
  }
}
