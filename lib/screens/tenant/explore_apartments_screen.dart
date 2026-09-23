import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'apartment_details_screen.dart';

// Generation X Color Palette (Picture 2)
class GenXColors {
  static const Color whippedCream = Color(0xFFF7F5EE); // DC-001: Warm soft white/cream
  static const Color cameoWhite = Color(0xFFE5E7E2);   // MQ3-32: Crisp pale white/border
  static const Color vineLeaf = Color(0xFF3B4D3C);     // N400-7: Rich deep forest green
  static const Color midnightBlue = Color(0xFF38454D); // N480-7: Deep slate midnight blue
  static const Color textDark = Color(0xFF1E2830);
  static const Color textMuted = Color(0xFF7A8490);
}

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

  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Available', 'Rented'
  final Set<String> _favoriteIds = {};

  final List<String> _apartmentImages = const [
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=600&q=80',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildImageWithFallback(String? url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    const fallbackColors = [GenXColors.midnightBlue, GenXColors.vineLeaf];
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: fallbackColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(
          child: Icon(Icons.apartment_rounded, color: Colors.white60, size: 36),
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width,
          color: GenXColors.cameoWhite,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: GenXColors.midnightBlue),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: fallbackColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: const Center(
            child: Icon(Icons.apartment_rounded, color: Colors.white60, size: 32),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXColors.whippedCream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Rently Logo + Notifications Icon (Screen 7 Header)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo & Title
                    Row(
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: GenXColors.vineLeaf,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Rently',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: GenXColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // Notification Bell with Red Dot
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: GenXColors.cameoWhite),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, size: 22, color: GenXColors.textDark),
                          Positioned(
                            top: 9,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar matching Screen 7 & 8
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: GenXColors.cameoWhite),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search apartments, locations...',
                      hintStyle: const TextStyle(color: GenXColors.textMuted, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: GenXColors.textMuted, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: GenXColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                    ),
                  ),
                ),
              ),

              // "Find Your Next Home" Banner Card (Screen 7)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [GenXColors.midnightBlue, Color(0xFF2C3A44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: GenXColors.midnightBlue.withValues(alpha: 0.15),
                        blurRadius: 12,
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
                            const Text(
                              'Find Your Next Home',
                              style: TextStyle(
                                fontSize: 18,
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
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedStatusFilter = 'All';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: GenXColors.textDark,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text(
                                'Browse Listings',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        height: 80,
                        width: 95,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildImageWithFallback(_apartmentImages[0]),
                      ),
                    ],
                  ),
                ),
              ),

              // 4 Quick Actions Row: My Requests, Maintenance, Notices, Profile (Screen 7)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      icon: Icons.assignment_outlined,
                      label: 'My Requests',
                      bgColor: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFE65100),
                      onTap: () => widget.onTabSelected?.call(1),
                    ),
                    _buildQuickAction(
                      icon: Icons.build_outlined,
                      label: 'Maintenance',
                      bgColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF7B1FA2),
                      onTap: () => widget.onTabSelected?.call(2),
                    ),
                    _buildQuickAction(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notices',
                      bgColor: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFC62828),
                      onTap: () => widget.onTabSelected?.call(4),
                    ),
                    _buildQuickAction(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      bgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () => widget.onTabSelected?.call(5),
                    ),
                  ],
                ),
              ),

              // Status Filter Chips: All, Available, Rented (Screen 8)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: ['All', 'Available', 'Rented'].map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedStatusFilter = status),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? GenXColors.midnightBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? GenXColors.midnightBlue : GenXColors.cameoWhite,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : GenXColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // "Featured Apartments" Section Title (Screen 7)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Apartments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GenXColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedStatusFilter = 'All';
                        });
                      },
                      child: const Text(
                        'View All >',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: GenXColors.vineLeaf,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Real Firebase Apartments Stream
              StreamBuilder<List<ApartmentModel>>(
                stream: _apartmentService.getAllApartments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: CircularProgressIndicator(color: GenXColors.midnightBlue),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error loading apartments: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final allApartments = snapshot.data ?? [];

                  // Apply client filters: search query & status filter
                  final filtered = allApartments.where((apt) {
                    final matchQuery = apt.title.toLowerCase().contains(_searchQuery) ||
                        apt.location.toLowerCase().contains(_searchQuery) ||
                        apt.description.toLowerCase().contains(_searchQuery);

                    final matchStatus = _selectedStatusFilter == 'All' ||
                        apt.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

                    return matchQuery && matchStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No Apartments Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No apartments match "$_searchQuery".'
                            : 'No apartments available under this filter.',
                      ),
                    );
                  }

                  // Render list of apartment cards matching Screen 7 & 8
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final apt = filtered[index];
                      final imgUrl = _apartmentImages[index % _apartmentImages.length];
                      return _buildApartmentCard(apt, imgUrl);
                    },
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

  // Quick action circular button matching Screen 7
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: GenXColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // Apartment card matching Screen 7 and Screen 8
  Widget _buildApartmentCard(ApartmentModel apt, String imageUrl) {
    final isFav = _favoriteIds.contains(apt.id);
    final locationText = apt.location.trim().isNotEmpty ? apt.location.trim() : 'Rajshahi';

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GenXColors.cameoWhite),
        boxShadow: [
          BoxShadow(
            color: GenXColors.midnightBlue.withValues(alpha: 0.04),
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
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Image Thumbnail
              Container(
                height: 100,
                width: 105,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImageWithFallback(imageUrl),
              ),
              const SizedBox(width: 14),

              // Right details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge + Favorite Heart Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: apt.status),
                        InkWell(
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
                            size: 19,
                            color: isFav ? Colors.red : GenXColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      apt.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: GenXColors.textDark,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: GenXColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            locationText,
                            style: const TextStyle(fontSize: 12, color: GenXColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price
                    Text(
                      '${_currencyFormat.format(apt.rent)} / month',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: GenXColors.midnightBlue,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Specs Row (2 Bedrooms • 1 Bath • 900 sq ft)
                    Row(
                      children: const [
                        Icon(Icons.king_bed_outlined, size: 12, color: GenXColors.textMuted),
                        SizedBox(width: 3),
                        Text('2 Bed', style: TextStyle(fontSize: 11, color: GenXColors.textMuted)),
                        SizedBox(width: 8),
                        Icon(Icons.bathtub_outlined, size: 12, color: GenXColors.textMuted),
                        SizedBox(width: 3),
                        Text('1 Bath', style: TextStyle(fontSize: 11, color: GenXColors.textMuted)),
                        SizedBox(width: 8),
                        Icon(Icons.square_foot_rounded, size: 12, color: GenXColors.textMuted),
                        SizedBox(width: 3),
                        Text('900 sq ft', style: TextStyle(fontSize: 11, color: GenXColors.textMuted)),
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
