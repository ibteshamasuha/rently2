import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_wrapper.dart';
import '../tenant/my_rental_requests_screen.dart';
import '../tenant/tenant_maintenance_screen.dart';
import '../tenant/tenant_notices_screen.dart';
import '../tenant/tenant_rent_records_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _confirmSignOut(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: GenXPalette.textDark)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: GenXPalette.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GenXPalette.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Avatar circle with initials (Picture 1 Screen 14: e.g. "IS")
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAF4),
                  shape: BoxShape.circle,
                  border: Border.all(color: GenXPalette.cameoWhite, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(user.name),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: GenXPalette.midnightBlue,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // User Name
            Text(
              user.name.isNotEmpty ? user.name : 'Ibteshama Suha',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: GenXPalette.textDark,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            // User Email
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: GenXPalette.textMuted,
              ),
            ),

            const SizedBox(height: 8),

            // Role Badge (e.g. "Tenant")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: GenXPalette.cameoWhite.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GenXPalette.midnightBlue,
                  letterSpacing: 0.4,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Menu Items List (Picture 1 Screen 14)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GenXPalette.cameoWhite),
                boxShadow: [
                  BoxShadow(
                    color: GenXPalette.midnightBlue.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.assignment_outlined,
                    title: 'My Rental Requests',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyRentalRequestsScreen(currentUser: user),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                  _buildMenuItem(
                    icon: Icons.build_outlined,
                    title: 'Maintenance Requests',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TenantMaintenanceScreen(currentUser: user),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Rent Records',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TenantRentRecordsScreen(currentUser: user),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notices',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TenantNoticesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings preferences coming soon.')),
                      );
                    },
                  ),
                  const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support at support@rently.app')),
                      );
                    },
                  ),
                  const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    titleColor: GenXPalette.danger,
                    iconColor: GenXPalette.danger,
                    hideChevron: true,
                    onTap: () => _confirmSignOut(context, authService),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    bool hideChevron = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? GenXPalette.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? GenXPalette.textDark,
                ),
              ),
            ),
            if (!hideChevron)
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GenXPalette.textMuted),
          ],
        ),
      ),
    );
  }
}
