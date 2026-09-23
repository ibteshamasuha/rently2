import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/rental_request_service.dart';
import '../../widgets/status_badge.dart';

// Generation X Color Palette (Picture 2)
class GenXColors {
  static const Color whippedCream = Color(0xFFF7F5EE); // DC-001: Warm soft white
  static const Color cameoWhite = Color(0xFFE5E7E2);   // MQ3-32: Crisp pale white/border
  static const Color vineLeaf = Color(0xFF3B4D3C);     // N400-7: Rich deep forest green
  static const Color midnightBlue = Color(0xFF38454D); // N480-7: Deep slate midnight blue
  static const Color textDark = Color(0xFF1E2830);
  static const Color textMuted = Color(0xFF7A8490);
}

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
  final _requestService = RentalRequestService();
  bool _isSending = false;
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  final List<String> _apartmentPhotos = const [
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=800&q=80',
  ];

  // Screen 10: Rental Request Modal / Bottom Sheet
  void _showRentalRequestModal() {
    final messageController = TextEditingController();
    DateTime? selectedDate;
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 14),

                  // Header matching Screen 10
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.arrow_back_rounded, size: 22, color: GenXColors.textDark),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Request Rental',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GenXColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mini Apartment Summary Card matching Screen 10
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GenXColors.whippedCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GenXColors.cameoWhite),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 64,
                          width: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildImageWithFallback(_apartmentPhotos[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.apartment.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: GenXColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: GenXColors.textMuted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      widget.apartment.location.trim().isNotEmpty
                                          ? widget.apartment.location.trim()
                                          : 'Rajshahi',
                                      style: const TextStyle(fontSize: 11.5, color: GenXColors.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currencyFormatter.format(widget.apartment.rent)} / month',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: GenXColors.midnightBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Message to Landlord (Optional)
                  const Text(
                    'Message to Landlord (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: GenXColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us why you are interested...',
                      hintStyle: const TextStyle(color: GenXColors.textMuted, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GenXColors.cameoWhite),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GenXColors.midnightBlue, width: 1.5),
                      ),
                      filled: true,
                      fillColor: GenXColors.whippedCream,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preferred Move-in Date
                  const Text(
                    'Preferred Move-in Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: GenXColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: GenXColors.whippedCream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GenXColors.cameoWhite),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? DateFormat('MMMM d, yyyy').format(selectedDate!)
                                : 'Select Date',
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedDate != null ? GenXColors.textDark : GenXColors.textMuted,
                              fontWeight: selectedDate != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18, color: GenXColors.textMuted),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Request Button
                  ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : () async {
                            setModalState(() => _isSending = true);
                            try {
                              String finalMessage = messageController.text.trim();
                              if (selectedDate != null) {
                                final dateStr = DateFormat('MMM d, yyyy').format(selectedDate!);
                                finalMessage = finalMessage.isNotEmpty
                                    ? '$finalMessage (Preferred Move-in: $dateStr)'
                                    : 'Preferred Move-in: $dateStr';
                              }

                              await _requestService.sendRentalRequest(
                                tenantId: widget.currentUser.uid,
                                landlordId: widget.apartment.landlordId,
                                apartmentId: widget.apartment.id,
                                apartmentTitle: widget.apartment.title,
                                tenantName: widget.currentUser.name,
                                message: finalMessage.isNotEmpty ? finalMessage : null,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rental request submitted successfully!'),
                                    backgroundColor: GenXColors.vineLeaf,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              setModalState(() => _isSending = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: GenXColors.midnightBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Submit Request',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
              width: 24,
              height: 24,
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
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final locationText = widget.apartment.location.trim().isNotEmpty
        ? widget.apartment.location.trim()
        : 'Rajshahi';

    final descriptionText = widget.apartment.description.trim().isNotEmpty
        ? widget.apartment.description.trim()
        : 'A beautiful 2 bedroom apartment near RUET. Spacious, well-ventilated and in a peaceful neighborhood.';

    final currentImage = _apartmentPhotos[_currentImageIndex % _apartmentPhotos.length];

    return Scaffold(
      backgroundColor: GenXColors.whippedCream,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Header matching Screen 9
            Stack(
              children: [
                Container(
                  height: 310,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImageWithFallback(currentImage),
                ),

                // Top Floating Action Bar: Back button `<` & Favorite heart
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCircularButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildCircularButton(
                            icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            iconColor: _isFavorite ? Colors.red : GenXColors.textDark,
                            onTap: () => setState(() => _isFavorite = !_isFavorite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Page Indicator Dots matching Screen 9
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_apartmentPhotos.length, (index) {
                      final isSelected = _currentImageIndex == index;
                      return InkWell(
                        onTap: () => setState(() => _currentImageIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: isSelected ? 18 : 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            // Apartment Content matching Screen 9
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge matching Screen 9
                  StatusBadge(status: widget.apartment.status),

                  const SizedBox(height: 8),

                  // Title (Screen 9: "2 Bedroom Apartment")
                  Text(
                    widget.apartment.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: GenXColors.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Location (Screen 9: Pin icon + "Rajshahi")
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: GenXColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: const TextStyle(fontSize: 14, color: GenXColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price (Screen 9: "৳15,000 / month")
                  Text(
                    '${currencyFormatter.format(widget.apartment.rent)} / month',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: GenXColors.midnightBlue,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3 Specs Row: 2 Bedrooms, 1 Bathroom, 900 sq ft (Screen 9)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GenXColors.cameoWhite),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSpecItem(Icons.king_bed_outlined, '2 Bedrooms'),
                        Container(height: 20, width: 1, color: GenXColors.cameoWhite),
                        _buildSpecItem(Icons.bathtub_outlined, '1 Bathroom'),
                        Container(height: 20, width: 1, color: GenXColors.cameoWhite),
                        _buildSpecItem(Icons.square_foot_rounded, '900 sq ft'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "About this property" Section matching Screen 9
                  const Text(
                    'About this property',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: GenXColors.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descriptionText,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: GenXColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Landlord Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GenXColors.cameoWhite),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: GenXColors.cameoWhite,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: GenXColors.midnightBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Landlord ID', style: TextStyle(fontSize: 11, color: GenXColors.textMuted)),
                              Text(
                                widget.apartment.landlordId.isNotEmpty
                                    ? widget.apartment.landlordId
                                    : 'Registered Landlord',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GenXColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // padding for bottom button
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Sticky Button: "Request Rental" (Screen 9)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: widget.apartment.isAvailable ? _showRentalRequestModal : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: GenXColors.midnightBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              widget.apartment.isAvailable ? 'Request Rental' : 'Currently Unavailable / Rented',
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = GenXColors.textDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 17, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: GenXColors.midnightBlue),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GenXColors.textDark,
          ),
        ),
      ],
    );
  }
}
