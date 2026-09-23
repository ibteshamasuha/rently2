import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'add_edit_apartment_screen.dart';
import 'landlord_maintenance_screen.dart';
import 'landlord_notices_screen.dart';
import 'landlord_requests_screen.dart';
import 'my_apartments_screen.dart';

class LandlordHomeScreen extends StatelessWidget {
  final UserModel currentUser;
  final ValueChanged<int>? onNavigateTab;

  const LandlordHomeScreen({
    super.key,
    required this.currentUser,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Greeting & Avatar (Picture 1 Screen 16)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Good Morning,',
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
                              'Landlord',
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
                        currentUser.name.isNotEmpty ? currentUser.name : 'Mr. Rahman',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: GenXPalette.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EBE5),
                      shape: BoxShape.circle,
                      border: Border.all(color: GenXPalette.cameoWhite),
                    ),
                    child: Center(
                      child: Text(
                        currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'R',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: GenXPalette.vineLeaf,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4 Stat Cards in 2x2 Grid (Picture 1 Screen 16: 4 My Properties, 3 Rental Requests, 2 Maintenance Requests, 5 Notices)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      number: '4',
                      label: 'My Properties',
                      color: GenXPalette.midnightBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyApartmentsScreen(currentUser: currentUser),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      number: '3',
                      label: 'Rental Requests',
                      color: const Color(0xFF2563EB),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LandlordRequestsScreen(currentUser: currentUser),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      number: '2',
                      label: 'Maintenance\nRequests',
                      color: const Color(0xFFEA580C),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LandlordMaintenanceScreen(currentUser: currentUser),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      number: '5',
                      label: 'Notices',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LandlordNoticesScreen(currentUser: currentUser),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Requests Section (Picture 1 Screen 16)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Requests',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: GenXPalette.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LandlordRequestsScreen(currentUser: currentUser),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: GenXPalette.midnightBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recent Request Card (Picture 1 Screen 16: "2 Bedroom Apartment", "Rajshahi", "2 hours ago", "Pending")
              Container(
                padding: const EdgeInsets.all(14),
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
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=200&q=80',
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 58,
                          height: 58,
                          color: GenXPalette.cameoWhite,
                          child: const Icon(Icons.apartment_rounded, color: GenXPalette.midnightBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '2 Bedroom Apartment',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Rajshahi  •  2 hours ago',
                            style: TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GenXPalette.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: GenXPalette.warning,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Action: Add New Apartment
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditApartmentScreen(currentUser: currentUser),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add New Property'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenXPalette.midnightBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String number,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 106,
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
            Text(
              number,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: GenXPalette.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
