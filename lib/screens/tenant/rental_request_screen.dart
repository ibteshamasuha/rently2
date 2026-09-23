import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/rental_request_service.dart';
import '../../theme/app_theme.dart';

class RentalRequestScreen extends StatefulWidget {
  final ApartmentModel apartment;
  final UserModel currentUser;

  const RentalRequestScreen({
    super.key,
    required this.apartment,
    required this.currentUser,
  });

  @override
  State<RentalRequestScreen> createState() => _RentalRequestScreenState();
}

class _RentalRequestScreenState extends State<RentalRequestScreen> {
  final _messageController = TextEditingController();
  final _requestService = RentalRequestService();
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: GenXPalette.midnightBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: GenXPalette.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      await _requestService.createRequest(
        tenantId: widget.currentUser.uid,
        landlordId: widget.apartment.landlordId.isNotEmpty
            ? widget.apartment.landlordId
            : 'system_landlord',
        apartmentId: widget.apartment.id,
        message: _messageController.text.trim(),
        apartmentTitle: widget.apartment.title,
        tenantName: widget.currentUser.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Rental request submitted successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: GenXPalette.vineLeaf,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: GenXPalette.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final photo = widget.apartment.images.isNotEmpty
        ? widget.apartment.images.first
        : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=600&q=80';

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Request Rental'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mini Apartment Summary Card (Picture 1 Screen 10)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GenXPalette.cameoWhite),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 76,
                          height: 76,
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
                          Text(
                            widget.apartment.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: GenXPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: GenXPalette.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                widget.apartment.location,
                                style: const TextStyle(fontSize: 13, color: GenXPalette.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currencyFormatter.format(widget.apartment.rent)} / month',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: GenXPalette.midnightBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Message to Landlord (Optional)
              const Text(
                'Message to Landlord (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GenXPalette.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us why you are interested...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: GenXPalette.cameoWhite),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: GenXPalette.cameoWhite),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Preferred Move-in Date
              const Text(
                'Preferred Move-in Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GenXPalette.textDark,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GenXPalette.cameoWhite),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                            : 'Select Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null ? GenXPalette.textDark : GenXPalette.textMuted,
                          fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 20, color: GenXPalette.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit Request Button (Picture 1 Screen 10)
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenXPalette.midnightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
