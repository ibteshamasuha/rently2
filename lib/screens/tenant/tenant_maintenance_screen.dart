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
  final MaintenanceService _maintenanceService = MaintenanceService();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedIssueType;
  bool _hasPhoto = false;
  bool _isSubmitting = false;

  final List<String> _issueTypes = const [
    'Plumbing',
    'Electrical',
    'Gas Supply',
    'Appliance / AC',
    'Structural / Painting',
    'Lift / Common Area',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit({
    required String targetAptId,
    required String targetLandlordId,
    required String targetAptTitle,
  }) async {
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
      await _maintenanceService.createTicket(
        tenantId: widget.currentUser.uid,
        landlordId: targetLandlordId,
        apartmentId: targetAptId,
        title: '$_selectedIssueType Issue',
        description: _descriptionController.text.trim(),
        issueType: _selectedIssueType,
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
                'Maintenance request submitted to landlord!',
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Listen to tenant's active approved tenancy (Issue 4)
          stream: FirebaseFirestore.instance
              .collection('rentalRequests')
              .where('tenantId', isEqualTo: widget.currentUser.uid)
              .where('status', isEqualTo: 'approved')
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            final approvedDocs = snapshot.data?.docs ?? [];
            final hasActiveTenancy = approvedDocs.isNotEmpty;

            String activeAptId = '';
            String activeLandlordId = '';
            String activeAptTitle = 'No active apartment';

            if (hasActiveTenancy) {
              final data = approvedDocs.first.data();
              activeAptId = data['apartmentId'] ?? '';
              activeLandlordId = data['landlordId'] ?? '';
              activeAptTitle = data['apartmentTitle'] ?? 'Rented Apartment';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Tool Illustration
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

                  const SizedBox(height: 20),

                  // Tenancy status banner (Issue 4)
                  if (!hasActiveTenancy)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GenXPalette.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GenXPalette.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded, color: GenXPalette.warning, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can only submit maintenance requests if you have an active, approved lease. Once approved, maintenance requests go directly to your apartment landlord.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: GenXPalette.textDark,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GenXPalette.vineLeaf.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GenXPalette.vineLeaf.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_work_rounded, color: GenXPalette.vineLeaf, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Tenancy',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GenXPalette.vineLeaf),
                                ),
                                Text(
                                  activeAptTitle,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Issue Type Dropdown
                  const Text(
                    'Issue Type',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: hasActiveTenancy ? Colors.white : Colors.grey.shade100,
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
                        onChanged: hasActiveTenancy ? (val) => setState(() => _selectedIssueType = val) : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description Field
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    enabled: hasActiveTenancy,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: hasActiveTenancy ? 'Describe the issue in detail...' : 'Lease required to submit maintenance',
                      filled: true,
                      fillColor: hasActiveTenancy ? Colors.white : Colors.grey.shade100,
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

                  // Upload Photo Box
                  const Text(
                    'Upload Photo (optional)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: hasActiveTenancy
                        ? () {
                            setState(() => _hasPhoto = !_hasPhoto);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_hasPhoto ? 'Photo selected!' : 'Photo removed.'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: hasActiveTenancy ? Colors.white : Colors.grey.shade100,
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
                              size: 30,
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

                  // Submit Button
                  ElevatedButton(
                    onPressed: (!hasActiveTenancy || _isSubmitting)
                        ? null
                        : () => _handleSubmit(
                              targetAptId: activeAptId,
                              targetLandlordId: activeLandlordId,
                              targetAptTitle: activeAptTitle,
                            ),
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
            );
          },
        ),
      ),
    );
  }
}
