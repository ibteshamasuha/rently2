import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/rent_record_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../services/notice_service.dart';
import '../../services/rent_record_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';

class LandlordRentRecordsScreen extends StatefulWidget {
  final UserModel currentUser;

  const LandlordRentRecordsScreen({super.key, required this.currentUser});

  @override
  State<LandlordRentRecordsScreen> createState() => _LandlordRentRecordsScreenState();
}

class _LandlordRentRecordsScreenState extends State<LandlordRentRecordsScreen> {
  final RentRecordService _recordService = RentRecordService();
  final ApartmentService _apartmentService = ApartmentService();
  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '৳ ', decimalDigits: 0);

  String _filter = 'All'; // 'All', 'Paid', 'Pending'

  void _showCreateBillModal(BuildContext context) {
    final amountController = TextEditingController();
    final monthController = TextEditingController(
      text: DateFormat('MMMM yyyy').format(DateTime.now()),
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    ApartmentModel? selectedApartment;
    final tenantIdController = TextEditingController();
    final tenantNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generate Monthly Rent Bill',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Select from Landlord's Apartments stream
                  StreamBuilder<List<ApartmentModel>>(
                    stream: _apartmentService.getLandlordApartments(widget.currentUser.uid),
                    builder: (context, snapshot) {
                      final apts = snapshot.data ?? [];
                      if (apts.isNotEmpty) {
                        return DropdownButtonFormField<ApartmentModel>(
                          decoration: InputDecoration(
                            labelText: 'Select Property',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.apartment_rounded),
                          ),
                          initialValue: selectedApartment,
                          items: apts.map((a) {
                            return DropdownMenuItem(
                              value: a,
                              child: Text(a.title, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedApartment = val;
                              if (val != null) {
                                amountController.text = val.rent.toString();
                              }
                            });
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: tenantNameController,
                    label: 'Tenant Name',
                    hint: 'e.g. Oishy or Karim',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter tenant name' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: tenantIdController,
                    label: 'Tenant User ID or Phone',
                    hint: 'e.g. tenant_user_id',
                    prefixIcon: Icons.badge_outlined,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter tenant ID' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: amountController,
                    label: 'Rent Amount (BDT ৳)',
                    hint: 'e.g. 15000',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter rent amount' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: monthController,
                    label: 'Billing Month',
                    hint: 'e.g. October 2026',
                    prefixIcon: Icons.calendar_today,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter month and year' : null,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);

                            try {
                              final aptId = selectedApartment?.id ?? 'apt_${DateTime.now().millisecondsSinceEpoch}';
                              final aptTitle = selectedApartment?.title ?? 'Apartment';

                              final newRecord = RentRecordModel(
                                id: '',
                                tenantId: tenantIdController.text.trim(),
                                landlordId: widget.currentUser.uid,
                                apartmentId: aptId,
                                apartmentTitle: aptTitle,
                                tenantName: tenantNameController.text.trim(),
                                amount: num.tryParse(amountController.text.trim()) ?? 0,
                                month: monthController.text.trim(),
                                status: 'unpaid',
                                createdAt: DateTime.now(),
                              );

                              await _recordService.createRentRecord(newRecord);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rent record generated successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: GenXPalette.midnightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Generate Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRentReminder(RentRecordModel rec) async {
    try {
      // 1. Create targeted Notice in Firestore for tenant
      await NoticeService().createNotice(
        title: 'Rent Reminder for ${rec.month}',
        message: 'Reminder from Landlord: Your monthly rent of ৳${rec.amount} for "${rec.apartmentTitle ?? "your apartment"}" is due. Kindly clear your dues.',
        authorId: widget.currentUser.uid,
        authorName: widget.currentUser.name.isNotEmpty ? widget.currentUser.name : 'Landlord',
        authorRole: 'landlord',
        isPublic: false,
        targetTenantId: rec.tenantId,
        apartmentId: rec.apartmentId,
      );

      // 2. Mark reminder sent on record
      try {
        await FirebaseFirestore.instance
            .collection('rent_records')
            .doc(rec.id)
            .update({'reminderSentAt': FieldValue.serverTimestamp()});
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Rent reminder sent to tenant for ${rec.month}!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reminder: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Rent Records & Reminders'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_landlord_rent_records',
        onPressed: () => _showCreateBillModal(context),
        backgroundColor: GenXPalette.midnightBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                _buildFilterTab('All'),
                const SizedBox(width: 8),
                _buildFilterTab('Paid'),
                const SizedBox(width: 8),
                _buildFilterTab('Pending'),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<RentRecordModel>>(
              stream: _recordService.getLandlordRentRecords(widget.currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data ?? [];

                final filtered = records.where((r) {
                  if (_filter == 'Paid') return r.isPaid;
                  if (_filter == 'Pending') return r.isUnpaid;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Rent Records Found',
                    message: records.isEmpty
                        ? 'When you approve a rental request, the rent record will start automatically from that month!'
                        : 'No records match the selected filter.',
                    actionLabel: 'New Bill',
                    onAction: () => _showCreateBillModal(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final rec = filtered[index];
                    return _buildRecordCard(rec);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GenXPalette.midnightBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GenXPalette.midnightBlue : GenXPalette.cameoWhite,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : GenXPalette.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(RentRecordModel rec) {
    final isPaid = rec.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid ? const Color(0xFF10B981).withValues(alpha: 0.3) : GenXPalette.cameoWhite,
        ),
        boxShadow: [
          BoxShadow(
            color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.month,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GenXPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.apartmentTitle ?? 'Apartment: ${rec.apartmentId}',
                      style: const TextStyle(fontSize: 12.5, color: GenXPalette.textMuted),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormatter.format(rec.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: GenXPalette.midnightBlue,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Requirement: Green Tick (✓) for paid months!
                    if (isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Paid ✓',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: GenXPalette.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pending Due',
                          style: TextStyle(
                            color: GenXPalette.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 15, color: GenXPalette.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Tenant: ${rec.tenantName ?? rec.tenantId}',
                  style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                ),
                if (rec.paidAt != null) ...[
                  const Spacer(),
                  Text(
                    'Paid: ${DateFormat('dd MMM yyyy').format(rec.paidAt!)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Action row: Send Reminder & Mark Paid/Unpaid
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Landlord Reminder Button
                if (!isPaid)
                  TextButton.icon(
                    onPressed: () => _sendRentReminder(rec),
                    icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF8B5CF6), size: 17),
                    label: const Text(
                      'Send Rent Reminder',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),

                // Toggle status button
                TextButton.icon(
                  onPressed: () {
                    final newStatus = isPaid ? 'unpaid' : 'paid';
                    _recordService.updatePaymentStatus(
                      recordId: rec.id,
                      status: newStatus,
                    );
                  },
                  icon: Icon(
                    isPaid ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                    color: isPaid ? Colors.orange : const Color(0xFF10B981),
                    size: 17,
                  ),
                  label: Text(
                    isPaid ? 'Mark as Unpaid' : 'Mark as Paid ✓',
                    style: TextStyle(
                      color: isPaid ? Colors.orange : const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                  tooltip: 'Delete Bill',
                  onPressed: () => _recordService.deleteRentRecord(rec.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
