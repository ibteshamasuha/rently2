import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/apartment_query_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_query_service.dart';
import '../../services/apartment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apartment_image_widget.dart';
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


  IconData _getFeatureAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('wi-fi') || lower.contains('internet')) {
      return Icons.wifi;
    } else if (lower.contains('park')) {
      return Icons.local_parking;
    } else if (lower.contains('balcony') || lower.contains('veranda')) {
      return Icons.balcony;
    } else if (lower.contains('secur') || lower.contains('guard') || lower.contains('cctv')) {
      return Icons.security;
    } else if (lower.contains('water')) {
      return Icons.water_drop_outlined;
    } else if (lower.contains('ac') || lower.contains('air condition') || lower.contains('cooler')) {
      return Icons.ac_unit;
    } else if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator;
    } else if (lower.contains('generator') || lower.contains('power') || lower.contains('backup')) {
      return Icons.power_rounded;
    } else if (lower.contains('gas')) {
      return Icons.local_fire_department_rounded;
    } else if (lower.contains('furnish') || lower.contains('bed') || lower.contains('sofa')) {
      return Icons.chair_rounded;
    } else if (lower.contains('tile')) {
      return Icons.grid_view_rounded;
    } else if (lower.contains('roof')) {
      return Icons.roofing_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final apartmentService = ApartmentService();

    return StreamBuilder<ApartmentModel?>(
      stream: apartmentService.streamApartment(widget.apartment.id),
      initialData: widget.apartment,
      builder: (context, snapshot) {
        final apt = snapshot.data ?? widget.apartment;
        final photos = apt.images;
        final allSpecificItems = {...apt.features, ...apt.amenities}.toList();

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
                      child: photos.isNotEmpty
                          ? Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: photos.length,
                                  onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                                  itemBuilder: (context, index) {
                                    return ApartmentImageWidget(
                                      imageUrl: photos[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  },
                                ),
                                if (photos.length > 1)
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
                            )
                          : Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [GenXPalette.midnightBlue, Color(0xFF2C3942)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.apartment_rounded, size: 72, color: Colors.white70),
                                  const SizedBox(height: 12),
                                  Text(
                                    apt.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    apt.location,
                                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                                  ),
                                ],
                              ),
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
                              color: apt.isAvailable
                                  ? GenXPalette.vineLeaf.withValues(alpha: 0.12)
                                  : GenXPalette.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: apt.isAvailable ? GenXPalette.vineLeaf : GenXPalette.warning,
                              ),
                            ),
                            child: Text(
                              apt.status.toUpperCase(),
                              style: TextStyle(
                                color: apt.isAvailable ? GenXPalette.vineLeaf : GenXPalette.warning,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Apartment Title (Screen 9)
                          Text(
                            apt.title,
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
                                apt.location,
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
                                  text: currencyFormatter.format(apt.rent),
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
                              _buildSpecPill(Icons.bed_outlined, '${apt.bedrooms} Bedrooms'),
                              const SizedBox(width: 8),
                              _buildSpecPill(Icons.shower_outlined, '${apt.bathrooms} Bathroom'),
                              const SizedBox(width: 8),
                              _buildSpecPill(Icons.crop_square_rounded, '${apt.areaSqFt} sq ft'),
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
                            apt.description.isNotEmpty
                                ? apt.description
                                : 'A beautiful apartment in a prime location. Spacious, well-ventilated and in a peaceful neighborhood.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: GenXPalette.textMuted,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Apartment Specific Features & Amenities
                          const Text(
                            'Features & Amenities',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: GenXPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (allSpecificItems.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: allSpecificItems
                                  .map((item) => _buildAmenityChip(_getFeatureAmenityIcon(item), item))
                                  .toList(),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: GenXPalette.cameoWhite),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.info_outline_rounded, size: 16, color: GenXPalette.textMuted),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Standard apartment amenities. Ask landlord for specific details.',
                                      style: TextStyle(fontSize: 12.5, color: GenXPalette.textMuted),
                                    ),
                                  ),
                                ],
                              ),
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

              // Floating Bottom Buttons: "Inquire" & "Request Rental" (Screen 9)
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
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showQueryBottomSheet(context, apt),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Inquire'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GenXPalette.midnightBlue,
                          side: const BorderSide(color: GenXPalette.midnightBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RentalRequestScreen(
                                  apartment: apt,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQueryBottomSheet(BuildContext context, ApartmentModel apt) {
    final queryService = ApartmentQueryService();
    final questionController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: GenXPalette.whippedCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ask the Landlord',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: GenXPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inquiry for: ${apt.title}',
                        style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Conversation history between this tenant and the landlord for this apartment
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: StreamBuilder<List<ApartmentQueryModel>>(
                  stream: queryService.getApartmentQueriesForTenant(
                    apt.id,
                    widget.currentUser.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GenXPalette.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GenXPalette.danger.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Could not load questions: ${snapshot.error}',
                          style: const TextStyle(fontSize: 12, color: GenXPalette.danger),
                        ),
                      );
                    }

                    final queries = snapshot.data ?? [];
                    if (queries.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GenXPalette.cameoWhite),
                        ),
                        child: const Center(
                          child: Text(
                            'No questions asked yet. Send a question below and the landlord will respond directly to you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: GenXPalette.textMuted),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: queries.length,
                      itemBuilder: (context, index) {
                        final q = queries[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GenXPalette.cameoWhite),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.help_outline_rounded, size: 16, color: GenXPalette.midnightBlue),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      q.question,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: GenXPalette.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (q.isAnswered && q.answer != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: GenXPalette.vineLeaf.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 14, color: GenXPalette.vineLeaf),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Landlord: ${q.answer!}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: GenXPalette.vineLeaf,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Text(
                                  'Waiting for landlord\'s response...',
                                  style: TextStyle(fontSize: 11.5, color: GenXPalette.warning, fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Question input
              TextField(
                controller: questionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Is gas bill included? When is move-in available?',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: GenXPalette.cameoWhite),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final question = questionController.text.trim();
                        if (question.isEmpty) return;

                        setModalState(() => isSubmitting = true);
                        try {
                          await queryService.sendQuery(
                            apartmentId: apt.id,
                            question: question,
                            landlordId: apt.landlordId,
                            apartmentTitle: apt.title,
                            tenantName: widget.currentUser.name,
                          );
                          questionController.clear();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inquiry sent to landlord!'),
                                backgroundColor: GenXPalette.vineLeaf,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: GenXPalette.danger),
                            );
                          }
                        } finally {
                          setModalState(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenXPalette.midnightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Question to Landlord', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
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
