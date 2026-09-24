import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_wrapper.dart';
import '../landlord/landlord_maintenance_screen.dart';
import '../landlord/landlord_notices_screen.dart';
import '../landlord/landlord_rent_records_screen.dart';
import '../landlord/landlord_requests_screen.dart';
import '../landlord/my_apartments_screen.dart';
import '../tenant/my_rental_requests_screen.dart';
import '../tenant/tenant_maintenance_screen.dart';
import '../tenant/tenant_notices_screen.dart';
import '../tenant/tenant_rent_records_screen.dart';
import '../notifications/notifications_inbox_screen.dart';

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

  void _confirmDeleteAccount(BuildContext context, AuthService authService) {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: GenXPalette.danger, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold, color: GenXPalette.danger),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Permanently delete your account? This action cannot be undone and your personal profile will be removed.',
                style: TextStyle(fontSize: 13, color: GenXPalette.textDark),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter password to confirm:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Current Password',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: const TextStyle(fontSize: 12, color: GenXPalette.danger),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: GenXPalette.textMuted)),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      final pw = passwordController.text.trim();
                      if (pw.isEmpty) {
                        setDialogState(() => errorMessage = 'Please enter your password.');
                        return;
                      }

                      setDialogState(() {
                        isDeleting = true;
                        errorMessage = null;
                      });

                      try {
                        await authService.deleteAccount(currentPassword: pw);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isDeleting = false;
                          errorMessage = e.toString();
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: GenXPalette.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthService authService) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password (min 6 chars)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final current = currentPwController.text.trim();
                      final newPw = newPwController.text.trim();
                      final confirmPw = confirmPwController.text.trim();

                      if (current.isEmpty || newPw.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields.')),
                        );
                        return;
                      }

                      if (newPw.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New password must be at least 6 characters.')),
                        );
                        return;
                      }

                      if (newPw != confirmPw) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match.')),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        await authService.changePassword(
                          currentPassword: current,
                          newPassword: newPw,
                        );
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, UserModel currentUser, AuthService authService) {
    final nameController = TextEditingController(text: currentUser.name);
    final phoneController = TextEditingController(text: currentUser.phone ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showChangePasswordDialog(context, authService);
                },
                icon: const Icon(Icons.lock_outline),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();

                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your name.')),
                          );
                          return;
                        }

                        setSheetState(() => isSaving = true);
                        try {
                          await authService.updateCurrentUserProfile(
                            name: newName,
                            phone: newPhone,
                          );
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          setSheetState(() => isSaving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: GenXPalette.midnightBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserModel(user.uid),
      initialData: user,
      builder: (context, snapshot) {
        final currentUser = snapshot.data ?? user;
        final isLandlord = currentUser.role == 'landlord' || currentUser.role == 'both';

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

                // Avatar circle with initials
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
                        _getInitials(currentUser.name),
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
                  currentUser.name.isNotEmpty ? currentUser.name : 'Rently User',
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
                  currentUser.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GenXPalette.textMuted,
                  ),
                ),

                if (currentUser.phone != null && currentUser.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    currentUser.phone!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: GenXPalette.textMuted,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: GenXPalette.cameoWhite.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    currentUser.role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: GenXPalette.midnightBlue,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Edit Profile Button (Issue 11)
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileModal(context, currentUser, authService),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile & Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GenXPalette.midnightBlue,
                    side: const BorderSide(color: GenXPalette.cameoWhite),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),

                const SizedBox(height: 24),

                // Role-aware Menu Items List (Issue 11)
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
                      if (isLandlord) ...[
                        _buildMenuItem(
                          icon: Icons.apartment_rounded,
                          title: 'My Properties',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyApartmentsScreen(currentUser: currentUser),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                        _buildMenuItem(
                          icon: Icons.assignment_outlined,
                          title: 'Rental Requests & Inquiries',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LandlordRequestsScreen(currentUser: currentUser),
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
                                builder: (_) => LandlordMaintenanceScreen(currentUser: currentUser),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                        _buildMenuItem(
                          icon: Icons.campaign_outlined,
                          title: 'Manage Notices',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LandlordNoticesScreen(currentUser: currentUser),
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
                                builder: (_) => LandlordRentRecordsScreen(currentUser: currentUser),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        _buildMenuItem(
                          icon: Icons.assignment_outlined,
                          title: 'My Rental Requests',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyRentalRequestsScreen(currentUser: currentUser),
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
                                builder: (_) => TenantMaintenanceScreen(currentUser: currentUser),
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
                                builder: (_) => TenantRentRecordsScreen(currentUser: currentUser),
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
                                builder: (_) => TenantNoticesScreen(currentUser: currentUser),
                              ),
                            );
                          },
                        ),
                      ],
                      const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                      _buildMenuItem(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notifications & History',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationsInboxScreen(currentUser: currentUser),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Log Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context, authService),
                    icon: const Icon(Icons.logout_rounded, color: GenXPalette.danger, size: 18),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: GenXPalette.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Delete Account Button (Issue 14)
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, authService),
                    icon: const Icon(Icons.delete_forever_outlined, color: Colors.grey, size: 16),
                    label: const Text(
                      'Delete My Account',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GenXPalette.midnightBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: GenXPalette.midnightBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: GenXPalette.textDark,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GenXPalette.textMuted),
          ],
        ),
      ),
    );
  }
}
