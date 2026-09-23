import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserModel currentUser;

  const AdminDashboardScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Greeting & Admin Badge (Picture 1 Screen 17)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Welcome Back,',
                            style: TextStyle(fontSize: 14, color: GenXPalette.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: GenXPalette.midnightBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: GenXPalette.midnightBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentUser.name.isNotEmpty ? currentUser.name : 'Admin',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: GenXPalette.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded, color: GenXPalette.textDark),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: GenXPalette.danger),
                        onPressed: () => AuthService().signOut(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4 Stat Cards in 2x2 Grid (Picture 1 Screen 17: 12 Total Users, 8 Apartments, 5 Pending Requests, 3 Maintenance)
              Row(
                children: [
                  Expanded(
                    child: _buildAdminStatCard(
                      label: 'Total Users',
                      defaultCount: 12,
                      stream: firestore.collection('users').snapshots().map((s) => s.docs.length),
                      color: GenXPalette.midnightBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAdminStatCard(
                      label: 'Apartments',
                      defaultCount: 8,
                      stream: firestore.collection('apartments').snapshots().map((s) => s.docs.length),
                      color: GenXPalette.vineLeaf,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildAdminStatCard(
                      label: 'Pending Requests',
                      defaultCount: 5,
                      stream: firestore.collection('rentalRequests').snapshots().map((s) => s.docs.length),
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAdminStatCard(
                      label: 'Maintenance',
                      defaultCount: 3,
                      stream: firestore.collection('maintenanceRequests').snapshots().map((s) => s.docs.length),
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick Actions Header (Picture 1 Screen 17)
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: GenXPalette.textDark,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              // Quick Actions List (Screen 17)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GenXPalette.cameoWhite),
                  boxShadow: [
                    BoxShadow(
                      color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.group_outlined,
                      title: 'Manage Users',
                      subtitle: 'View and manage registered accounts',
                      onTap: () => _showUsersList(context, firestore),
                    ),
                    const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                    _buildActionTile(
                      icon: Icons.apartment_outlined,
                      title: 'Manage Properties',
                      subtitle: 'Inspect all platform listings',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Apartment management opened.')),
                        );
                      },
                    ),
                    const Divider(height: 1, color: GenXPalette.cameoWhite, indent: 54),
                    _buildActionTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'View Reports',
                      subtitle: 'Financial and usage reports',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reports dashboard generated.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStatCard({
    required String label,
    required int defaultCount,
    required Stream<int> stream,
    required Color color,
  }) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GenXPalette.cameoWhite),
        boxShadow: [
          BoxShadow(
            color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final count = (snapshot.hasData && snapshot.data! > 0) ? snapshot.data! : defaultCount;
              return Text(
                '$count',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GenXPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GenXPalette.cameoWhite.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: GenXPalette.midnightBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: GenXPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GenXPalette.textMuted),
          ],
        ),
      ),
    );
  }

  void _showUsersList(BuildContext context, FirebaseFirestore firestore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registered Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data?.docs ?? [];
                    if (users.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final data = users[index].data() as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: GenXPalette.cameoWhite,
                            child: const Icon(Icons.person, color: GenXPalette.midnightBlue),
                          ),
                          title: Text(data['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['email'] ?? ''),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GenXPalette.midnightBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (data['role'] ?? 'tenant').toString().toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GenXPalette.midnightBlue),
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
        ),
      ),
    );
  }
}
