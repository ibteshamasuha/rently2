import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../theme/app_theme.dart';
import 'apartment_details_screen.dart';
import 'apartment_listings_screen.dart';
import 'my_rental_requests_screen.dart';
import 'tenant_maintenance_screen.dart';
import 'tenant_notices_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../auth/welcome_screen.dart' show WelcomeScreen;
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/rently_logo.dart';

class ExploreApartmentsScreen extends StatefulWidget {
  final UserModel currentUser;
  final ValueChanged<int>? onTabSelected;

  const ExploreApartmentsScreen({
    super.key,
    required this.currentUser,
    this.onTabSelected,
  });

  @override
  State<ExploreApartmentsScreen> createState() => _ExploreApartmentsScreenState();
}

class _ExploreApartmentsScreenState extends State<ExploreApartmentsScreen> {
  final _apartmentService = ApartmentService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

  final Set<String> _favoriteIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToListings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartmentListingsScreen(currentUser: widget.currentUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Rently Logo + Notifications Icon (Picture 1 Screen 7)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo & Title
                    // Brand Logo & Title (Issue 18: Logo navigates to Welcome/Home page)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          RentlyLogo.mark(size: 38, borderRadius: 10),
                          const SizedBox(width: 10),
                          const Text(
                            'Rently',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: GenXPalette.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Notification Bell with Live Unread Badge (Issues 7, 10, 11)
                        StreamBuilder<List<NotificationModel>>(
                          stream: NotificationService().streamUnreadNotifications(widget.currentUser.uid),
                          builder: (context, notifSnap) {
                            final unreadCount = notifSnap.data?.length ?? 0;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotificationsInboxScreen(currentUser: widget.currentUser),
                                  ),
                                );
                              },
                              child: Container(
                                height: 40,
                                width: 40,
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

                        // Profile Icon (Issue 11 & 18: opens user profile)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.currentUser)),
                            );
                          },
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCEAF4),
                              shape: BoxShape.circle,
                              border: Border.all(color: GenXPalette.cameoWhite),
                            ),
                            child: Center(
                              child: Text(
                                widget.currentUser.name.isNotEmpty
                                    ? widget.currentUser.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: GenXPalette.midnightBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar (Screen 7)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: _navigateToListings,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GenXPalette.cameoWhite),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search_rounded, color: GenXPalette.textMuted, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Search apartments, locations...',
                          style: TextStyle(color: GenXPalette.textMuted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // "Find Your Next Home" Banner Card (Screen 7)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [GenXPalette.midnightBlue, Color(0xFF2C3942)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: GenXPalette.midnightBlue.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Find Your Next Home',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quality homes. Trusted by many.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _navigateToListings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: GenXPalette.midnightBlue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text(
                                'Browse Listings',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=260&q=80',
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 84,
                            height: 84,
                            color: Colors.white24,
                            child: const Icon(Icons.apartment_rounded, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4 Circular Quick Action Buttons (Picture 1 Screen 7: My Requests, Maintenance, Notices, Profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      icon: Icons.assignment_outlined,
                      label: 'My Requests',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyRentalRequestsScreen(currentUser: widget.currentUser),
                          ),
                        );
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.build_outlined,
                      label: 'Maintenance',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TenantMaintenanceScreen(currentUser: widget.currentUser),
                          ),
                        );
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notices',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TenantNoticesScreen(currentUser: widget.currentUser)),
                        );
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: widget.currentUser),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // "Featured Apartments" Header + "View All >" (Screen 7)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Apartments',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: GenXPalette.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToListings,
                      child: Row(
                        children: const [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: GenXPalette.midnightBlue,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: GenXPalette.midnightBlue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Featured Apartments List
              StreamBuilder<List<ApartmentModel>>(
                stream: _apartmentService.getAvailableApartments(),
                builder: (context, snapshot) {
                  final apartments = snapshot.data ?? [];
                  if (apartments.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GenXPalette.cameoWhite),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.apartment_rounded, size: 44, color: GenXPalette.textMuted),
                          SizedBox(height: 10),
                          Text(
                            'No Available Apartments Yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Newly listed apartments from landlords will appear here in real time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: GenXPalette.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: apartments.map((apt) => _buildFeaturedCard(apt)).toList(),
                  );
                },
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: GenXPalette.cameoWhite),
              boxShadow: [
                BoxShadow(
                  color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: GenXPalette.midnightBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: GenXPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(ApartmentModel apt) {
    final photo = apt.images.isNotEmpty
        ? apt.images.first
        : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=600&q=80';
    final isFav = _favoriteIds.contains(apt.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApartmentDetailsScreen(
                apartment: apt,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  photo,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 96,
                    height: 96,
                    color: GenXPalette.cameoWhite,
                    child: const Icon(Icons.apartment_rounded, color: GenXPalette.midnightBlue),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: GenXPalette.vineLeaf.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Available',
                            style: TextStyle(
                              color: GenXPalette.vineLeaf,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFav) {
                                _favoriteIds.remove(apt.id);
                              } else {
                                _favoriteIds.add(apt.id);
                              }
                            });
                          },
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav ? Colors.red : GenXPalette.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      apt.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: GenXPalette.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: GenXPalette.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          apt.location,
                          style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${_currencyFormat.format(apt.rent)} / month',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: GenXPalette.midnightBlue,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.bed_outlined, size: 14, color: GenXPalette.textMuted),
                        const SizedBox(width: 3),
                        Text('${apt.bedrooms} Bed', style: const TextStyle(fontSize: 11, color: GenXPalette.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.shower_outlined, size: 14, color: GenXPalette.textMuted),
                        const SizedBox(width: 3),
                        Text('${apt.bathrooms} Bath', style: const TextStyle(fontSize: 11, color: GenXPalette.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.crop_square_rounded, size: 14, color: GenXPalette.textMuted),
                        const SizedBox(width: 3),
                        Text('${apt.areaSqFt} sq ft', style: const TextStyle(fontSize: 11, color: GenXPalette.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
