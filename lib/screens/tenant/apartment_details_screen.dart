import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'rental_request_screen.dart';

class ApartmentDetailsScreen extends StatefulWidget {
  final ApartmentModel apartment;
  final UserModel currentUser;

  const ApartmentDetailsScreen({
    super.key,
    required this.apartment,
    required this.currentUser,
  });

  @override
  State<ApartmentDetailsScreen> createState() => _ApartmentDetailsScreenState();
}

class _ApartmentDetailsScreenState extends State<ApartmentDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  final List<String> _apartmentPhotos = const [
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final photos = widget.apartment.images.isNotEmpty ? widget.apartment.images : _apartmentPhotos;

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Gallery Header with counter (Screen 9)
                SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: photos.length,
                        onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                        itemBuilder: (context, index) {
                          return Image.network(
                            photos[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: GenXPalette.midnightBlue,
                              child: const Center(
                                child: Icon(Icons.apartment_rounded, color: Colors.white54, size: 64),
                              ),
                            ),
                          );
                        },
                      ),

                      // Photo Counter Badge (e.g. 1/4)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1}/${photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Details Card
                Container(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge (Available)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.apartment.isAvailable
                              ? GenXPalette.vineLeaf.withValues(alpha: 0.12)
                              : GenXPalette.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.apartment.isAvailable ? GenXPalette.vineLeaf : GenXPalette.warning,
                          ),
                        ),
                        child: Text(
                          widget.apartment.status.toUpperCase(),
                          style: TextStyle(
                            color: widget.apartment.isAvailable ? GenXPalette.vineLeaf : GenXPalette.warning,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Apartment Title (Screen 9)
                      Text(
                        widget.apartment.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: GenXPalette.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: GenXPalette.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            widget.apartment.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: GenXPalette.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Price (Screen 9)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: currencyFormatter.format(widget.apartment.rent),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: GenXPalette.midnightBlue,
                              ),
                            ),
                            const TextSpan(
                              text: ' / month',
                              style: TextStyle(
                                fontSize: 14,
                                color: GenXPalette.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Specs Row (Bedrooms, Bathrooms, Sq Ft)
                      Row(
                        children: [
                          _buildSpecPill(Icons.bed_outlined, '${widget.apartment.bedrooms} Bedrooms'),
                          const SizedBox(width: 8),
                          _buildSpecPill(Icons.shower_outlined, '${widget.apartment.bathrooms} Bathroom'),
                          const SizedBox(width: 8),
                          _buildSpecPill(Icons.crop_square_rounded, '${widget.apartment.areaSqFt} sq ft'),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: GenXPalette.cameoWhite),
                      const SizedBox(height: 16),

                      // About this property (Screen 9)
                      const Text(
                        'About this property',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: GenXPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.apartment.description.isNotEmpty
                            ? widget.apartment.description
                            : 'A beautiful 2 bedroom apartment near RUET. Spacious, well-ventilated and in a peaceful neighborhood.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: GenXPalette.textMuted,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amenities / Highlights
                      const Text(
                        'Features & Amenities',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: GenXPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildAmenityChip(Icons.wifi, 'High-Speed Wi-Fi'),
                          _buildAmenityChip(Icons.security, '24/7 Security'),
                          _buildAmenityChip(Icons.local_parking, 'Dedicated Parking'),
                          _buildAmenityChip(Icons.balcony, 'Balcony View'),
                          _buildAmenityChip(Icons.water_drop_outlined, '24/7 Running Water'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Top Back and Favorite Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GenXPalette.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? Colors.red : GenXPalette.textDark,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Bottom Button: "Request Rental" (Screen 9)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RentalRequestScreen(
                        apartment: widget.apartment,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenXPalette.midnightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Request Rental',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GenXPalette.cameoWhite),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: GenXPalette.textMuted),
          const SizedBox(width: 6),
          Text(
            text,
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

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GenXPalette.cameoWhite),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GenXPalette.midnightBlue),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: GenXPalette.textDark),
          ),
        ],
      ),
    );
  }
}
