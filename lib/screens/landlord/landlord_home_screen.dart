import 'package:flutter/material.dart';
import '../../models/apartment_model.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/notice_model.dart';
import '../../models/rental_request_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../services/maintenance_service.dart';
import '../../services/notice_service.dart';
import '../../services/rental_request_service.dart';
import '../../theme/app_theme.dart';
import 'add_edit_apartment_screen.dart';
import 'landlord_maintenance_screen.dart';
import 'landlord_notices_screen.dart';
import 'landlord_rent_records_screen.dart';
import 'landlord_requests_screen.dart';
import 'my_apartments_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../auth/welcome_screen.dart' show WelcomeScreen;
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/rently_logo.dart';

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
    final apartmentService = ApartmentService();
    final requestService = RentalRequestService();
    final maintenanceService = MaintenanceService();
    final noticeService = NoticeService();

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
                  Row(
                    children: [
                      // Notification Bell with Live Unread Badge (Issues 7, 10, 11)
                      StreamBuilder<List<NotificationModel>>(
                        stream: NotificationService().streamUnreadNotifications(currentUser.uid),
                        builder: (context, notifSnap) {
                          final unreadCount = notifSnap.data?.length ?? 0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationsInboxScreen(currentUser: currentUser),
                                ),
                              );
                            },
                            child: Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: GenXPalette.cameoWhite),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.notifications_none_rounded, size: 22, color: GenXPalette.textDark),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2EBE5),
                            shape: BoxShape.circle,
                            border: Border.all(color: GenXPalette.cameoWhite),
                          ),
                          child: Center(
                            child: Text(
                              currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'R',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: GenXPalette.vineLeaf,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4 Dynamic Stat Cards in 2x2 Grid (Picture 1 Screen 16: My Properties, Rental Requests, Maintenance Requests, Notices)
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ApartmentModel>>(
                      stream: apartmentService.getLandlordApartments(currentUser.uid),
                      builder: (context, snapshot) {
                        final count = (snapshot.data?.length ?? 0).toString();
                        return _buildStatCard(
                          number: count,
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<List<RentalRequestModel>>(
                      stream: requestService.getLandlordRequests(currentUser.uid),
                      builder: (context, snapshot) {
                        final count = (snapshot.data?.length ?? 0).toString();
                        return _buildStatCard(
                          number: count,
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
                    child: StreamBuilder<List<MaintenanceRequestModel>>(
                      stream: maintenanceService.getLandlordRequests(currentUser.uid),
                      builder: (context, snapshot) {
                        final count = (snapshot.data?.length ?? 0).toString();
                        return _buildStatCard(
                          number: count,
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<List<NoticeModel>>(
                      stream: noticeService.getLandlordNotices(currentUser.uid),
                      builder: (context, snapshot) {
                        final count = (snapshot.data?.length ?? 0).toString();
                        return _buildStatCard(
                          number: count,
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
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Dedicated Rent & Reminder Quick Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LandlordRentRecordsScreen(currentUser: currentUser),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFA78BFA), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Rent Records & Reminders',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Track payments, verify ticks & send reminders',
                                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

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

              // Dynamic Recent Request Card (Picture 1 Screen 16)
              StreamBuilder<List<RentalRequestModel>>(
                stream: requestService.getLandlordRequests(currentUser.uid),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? [];

                  if (requests.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inbox_outlined, size: 36, color: GenXPalette.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'No incoming rental requests yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: GenXPalette.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'New requests for your apartments will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  // Display the most recent request
                  final recent = requests.first;
                  final title = recent.apartmentTitle ?? 'Rental Application';
                  final tenant = recent.tenantName ?? 'Tenant (${recent.tenantId.substring(0, 5)}...)';
                  final statusText = recent.status.toUpperCase();

                  Color statusColor = GenXPalette.warning;
                  if (recent.status == 'approved') {
                    statusColor = GenXPalette.vineLeaf;
                  } else if (recent.status == 'rejected') {
                    statusColor = GenXPalette.danger;
                  }

                  return Container(
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
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LandlordRequestsScreen(currentUser: currentUser),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  color: GenXPalette.cameoWhite,
                                  child: const Icon(Icons.apartment_rounded, color: GenXPalette.midnightBlue, size: 28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'From $tenant',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
