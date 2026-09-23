import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/maintenance_service.dart';
import '../../theme/app_theme.dart';

class TenantMaintenanceScreen extends StatefulWidget {
  final UserModel currentUser;

  const TenantMaintenanceScreen({super.key, required this.currentUser});

  @override
  State<TenantMaintenanceScreen> createState() => _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  final _maintenanceService = MaintenanceService();
  final _descriptionController = TextEditingController();

  String? _selectedIssueType;
  bool _isSubmitting = false;
  bool _hasPhoto = false;

  final List<String> _issueTypes = const [
    'Plumbing',
    'Electrical',
    'Heating / AC',
    'Appliance',
    'Structural / Wall',
    'Other Issue',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue type.'),
          backgroundColor: GenXPalette.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description of the issue.'),
          backgroundColor: GenXPalette.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String targetAptId = 'active_apartment';
      String targetLandlordId = 'landlord_system';
      String targetAptTitle = 'Apartment';

      // 1. Try to find tenant's approved lease
      final approvedQuery = await FirebaseFirestore.instance
          .collection('rentalRequests')
          .where('tenantId', isEqualTo: widget.currentUser.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (approvedQuery.docs.isNotEmpty) {
        final approvedData = approvedQuery.docs.first.data();
        targetAptId = approvedData['apartmentId'] ?? targetAptId;
        targetLandlordId = approvedData['landlordId'] ?? targetLandlordId;
        targetAptTitle = approvedData['apartmentTitle'] ?? targetAptTitle;
      } else {
        // 2. Otherwise find the first available apartment
        final apts = await FirebaseFirestore.instance.collection('apartments').limit(1).get();
        if (apts.docs.isNotEmpty) {
          final aptData = apts.docs.first.data();
          targetAptId = apts.docs.first.id;
          targetLandlordId = aptData['landlordId'] ?? targetLandlordId;
          targetAptTitle = aptData['title'] ?? targetAptTitle;
        }
      }

      await _maintenanceService.createTicket(
        tenantId: widget.currentUser.uid,
        landlordId: targetLandlordId,
        apartmentId: targetAptId,
        title: '$_selectedIssueType Issue',
        description: _descriptionController.text.trim(),
        apartmentTitle: targetAptTitle,
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
                'Maintenance request submitted successfully!',
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

      _descriptionController.clear();
      setState(() {
        _selectedIssueType = null;
        _hasPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
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
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Maintenance Request'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Tool Illustration / Icon Container matching Picture 1 Screen 11
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: GenXPalette.cameoWhite),
                    boxShadow: [
                      BoxShadow(
                        color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.build_rounded,
                      size: 32,
                      color: GenXPalette.midnightBlue,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Heading & Subtitle (Screen 11)
              const Text(
                'Report a Maintenance Issue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: GenXPalette.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Help us keep your home in the best condition.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: GenXPalette.textMuted,
                ),
              ),

              const SizedBox(height: 28),

              // Issue Type Dropdown (Screen 11)
              const Text(
                'Issue Type',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GenXPalette.cameoWhite),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedIssueType,
                    hint: const Text('Select issue type', style: TextStyle(color: GenXPalette.textMuted, fontSize: 14)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: GenXPalette.textMuted),
                    items: _issueTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 14, color: GenXPalette.textDark)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedIssueType = val),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description Field (Screen 11)
              const Text(
                'Description',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail...',
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

              const SizedBox(height: 20),

              // Upload Photo Box (Picture 1 Screen 11)
              const Text(
                'Upload Photo (optional)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _hasPhoto = !_hasPhoto);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_hasPhoto ? 'Photo selected!' : 'Photo removed.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasPhoto ? GenXPalette.vineLeaf : GenXPalette.cameoWhite,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasPhoto ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                          size: 32,
                          color: _hasPhoto ? GenXPalette.vineLeaf : GenXPalette.textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hasPhoto ? 'Photo Attached (Tap to remove)' : 'Tap to upload',
                          style: TextStyle(
                            fontSize: 13,
                            color: _hasPhoto ? GenXPalette.vineLeaf : GenXPalette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button (Screen 11)
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
                        'Submit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
