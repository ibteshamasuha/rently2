import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rent_record_model.dart';
import '../../models/user_model.dart';
import '../../services/rent_record_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class LandlordRentRecordsScreen extends StatelessWidget {
  final UserModel currentUser;

  const LandlordRentRecordsScreen({super.key, required this.currentUser});

  void _showCreateBillModal(BuildContext context, RentRecordService service) {
    final tenantIdController = TextEditingController();
    final aptIdController = TextEditingController();
    final aptTitleController = TextEditingController();
    final amountController = TextEditingController();
    final monthController = TextEditingController(
      text: DateFormat('MMMM yyyy').format(DateTime.now()),
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        'Generate Rent Record / Bill',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: tenantIdController,
                    label: 'Tenant User ID',
                    hint: 'e.g. NgAeOY7B8DhOgoLeWEhv1buFCbN2',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter tenant UID' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: aptIdController,
                    label: 'Apartment ID',
                    hint: 'e.g. RvKz7GagxbSqqEXcGZHy',
                    prefixIcon: Icons.apartment,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter apartment ID' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: aptTitleController,
                    label: 'Apartment Title (Optional)',
                    hint: 'e.g. 2 Bedroom Apartment',
                    prefixIcon: Icons.label_outline,
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
                    prefixIcon: Icons.calendar_month_outlined,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter month' : null,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final amount = num.tryParse(amountController.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid amount')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            try {
                              final record = RentRecordModel(
                                id: '',
                                tenantId: tenantIdController.text.trim(),
                                landlordId: currentUser.uid,
                                apartmentId: aptIdController.text.trim(),
                                apartmentTitle: aptTitleController.text.isNotEmpty
                                    ? aptTitleController.text.trim()
                                    : null,
                                amount: amount,
                                month: monthController.text.trim(),
                                status: 'unpaid',
                                createdAt: DateTime.now(),
                              );
                              await service.createRentRecord(record);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rent record generated!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Generate Record', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordService = RentRecordService();
    final currencyFormatter = NumberFormat.currency(symbol: '৳ ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Records Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBillModal(context, recordService),
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
      body: StreamBuilder<List<RentRecordModel>>(
        stream: recordService.getLandlordRentRecords(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Rent Records',
              message: 'Generate a rent record to track monthly tenant payments.',
              actionLabel: 'New Bill',
              onAction: () => _showCreateBillModal(context, recordService),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final rec = records[index];

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.month,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rec.apartmentTitle ?? 'Apartment: ${rec.apartmentId}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormatter.format(rec.amount),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(status: rec.status),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Tenant: ${rec.tenantId}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final newStatus = rec.isPaid ? 'unpaid' : 'paid';
                              recordService.updatePaymentStatus(
                                recordId: rec.id,
                                status: newStatus,
                              );
                            },
                            icon: Icon(
                              rec.isPaid ? Icons.undo : Icons.check_circle_outline,
                              color: rec.isPaid ? Colors.orange : Colors.green,
                              size: 16,
                            ),
                            label: Text(
                              rec.isPaid ? 'Mark as Unpaid' : 'Mark as Paid',
                              style: TextStyle(
                                color: rec.isPaid ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () => recordService.deleteRentRecord(rec.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
