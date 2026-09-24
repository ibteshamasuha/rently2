import 'package:flutter/material.dart';
import '../../models/apartment_model.dart';
import '../../models/notice_model.dart';
import '../../models/rental_request_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../services/notice_service.dart';
import '../../services/rental_request_service.dart';
import '../../theme/app_theme.dart';
import 'apartment_details_screen.dart';
import 'apartment_listings_screen.dart';
import 'tenant_notices_screen.dart';
import 'my_rental_requests_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/welcome_screen.dart' show WelcomeScreen;
import '../../widgets/rently_logo.dart';

class TenantDashboardRoleScreen extends StatelessWidget {
  final UserModel currentUser;

  const TenantDashboardRoleScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final requestService = RentalRequestService();
    final noticeService = NoticeService();
    final apartmentService = ApartmentService();

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Greeting & Avatar (Picture 1 Screen 15)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            RentlyLogo.mark(size: 20, borderRadius: 6),
                            const SizedBox(width: 6),
                            const Text(
                              'Rently',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: GenXPalette.midnightBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Good Morning,',
                        style: TextStyle(fontSize: 14, color: GenXPalette.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentUser.name.isNotEmpty ? currentUser.name : 'Ibteshama Suha',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: GenXPalette.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEAF4),
                        shape: BoxShape.circle,
                        border: Border.all(color: GenXPalette.cameoWhite),
                      ),
                      child: Center(
                        child: Text(
                          currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'I',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: GenXPalette.midnightBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Dynamic Active Rental Card (Picture 1 Screen 15)
              StreamBuilder<List<RentalRequestModel>>(
                stream: requestService.getTenantRequests(currentUser.uid),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? [];
                  final approvedList = requests.where((r) => r.status == 'approved').toList();

                  if (approvedList.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: GenXPalette.cameoWhite),
                        boxShadow: [
                          BoxShadow(
                            color: GenXPalette.midnightBlue.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GenXPalette.midnightBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Rental Status',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: GenXPalette.midnightBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No Active Rental',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: GenXPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Find and request your next apartment now.',
                            style: TextStyle(fontSize: 13, color: GenXPalette.textMuted),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApartmentListingsScreen(currentUser: currentUser),
                                ),
                              );
                            },
                            child: Row(
                              children: const [
                                Text(
                                  'Explore Available Apartments',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: GenXPalette.midnightBlue,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 14, color: GenXPalette.midnightBlue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final activeRental = approvedList.first;
                  final aptTitle = activeRental.apartmentTitle ?? 'Rented Apartment';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: GenXPalette.cameoWhite),
                      boxShadow: [
                        BoxShadow(
                          color: GenXPalette.midnightBlue.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Badge: Active Rental
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: GenXPalette.vineLeaf.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Active Rental',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: GenXPalette.vineLeaf,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                aptTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: GenXPalette.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lease Approved',
                                style: const TextStyle(fontSize: 13, color: GenXPalette.textMuted),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () async {
                                  // Fetch apartment details if possible
                                  try {
                                    final apt = await apartmentService.getApartmentById(activeRental.apartmentId);
                                    if (apt != null && context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ApartmentDetailsScreen(
                                            apartment: apt,
                                            currentUser: currentUser,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  } catch (_) {}

                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApartmentDetailsScreen(
                                          apartment: ApartmentModel(
                                            id: activeRental.apartmentId,
                                            title: aptTitle,
                                            location: 'Rented Residence',
                                            rent: 0,
                                            status: 'rented',
                                            description: 'Your currently rented apartment.',
                                            landlordId: activeRental.landlordId,
                                            bedrooms: 2,
                                            bathrooms: 1,
                                            areaSqFt: 850,
                                          ),
                                          currentUser: currentUser,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  children: const [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: GenXPalette.midnightBlue,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, size: 14, color: GenXPalette.midnightBlue),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 90,
                            height: 90,
                            color: GenXPalette.cameoWhite,
                            child: const Icon(Icons.home_rounded, color: GenXPalette.midnightBlue, size: 36),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Dynamic Stat Cards Grid: Pending Requests, Past Requests, Notices (Screen 15)
              StreamBuilder<List<RentalRequestModel>>(
                stream: requestService.getTenantRequests(currentUser.uid),
                builder: (context, reqSnapshot) {
                  final requests = reqSnapshot.data ?? [];
                  final pendingCount = requests.where((r) => r.status == 'pending').length.toString();
                  final pastCount = requests.where((r) => r.status != 'pending').length.toString();

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          number: pendingCount,
                          label: 'Pending Requests',
                          color: const Color(0xFFEA580C),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyRentalRequestsScreen(currentUser: currentUser),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          number: pastCount,
                          label: 'Past Requests',
                          color: GenXPalette.midnightBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyRentalRequestsScreen(currentUser: currentUser),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<NoticeModel>>(
                      stream: noticeService.getTenantNotices(currentUser.uid),
                      builder: (context, notSnapshot) {
                        final noticesCount = (notSnapshot.data?.length ?? 0).toString();
                        return _buildStatCard(
                          number: noticesCount,
                          label: 'Notices',
                          color: const Color(0xFF8B5CF6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TenantNoticesScreen(currentUser: currentUser)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApartmentListingsScreen(currentUser: currentUser),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: GenXPalette.midnightBlue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.explore_outlined, color: Colors.white, size: 24),
                            SizedBox(height: 12),
                            Text(
                              'Explore More',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Find apartments',
                              style: TextStyle(fontSize: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GenXPalette.cameoWhite),
          boxShadow: [
            BoxShadow(
              color: GenXPalette.midnightBlue.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}
