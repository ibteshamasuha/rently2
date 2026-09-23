import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rent_record_model.dart';
import '../../models/user_model.dart';
import '../../services/rent_record_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class TenantRentRecordsScreen extends StatelessWidget {
  final UserModel currentUser;

  const TenantRentRecordsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final recordService = RentRecordService();
    final currencyFormatter = NumberFormat.currency(symbol: '৳ ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Payment Records'),
      ),
      body: StreamBuilder<List<RentRecordModel>>(
        stream: recordService.getTenantRentRecords(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No Rent Records',
              message: 'You have no rent records logged by your landlord yet.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final rec = records[index];
              final paidDateStr = rec.paidAt != null
                  ? DateFormat('MMM d, y').format(rec.paidAt!)
                  : null;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: rec.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          rec.isPaid ? Icons.check : Icons.priority_high,
                          color: rec.isPaid ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rec.month,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rec.apartmentTitle ?? 'Apartment: ${rec.apartmentId}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            if (paidDateStr != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Paid on $paidDateStr',
                                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(rec.amount),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          StatusBadge(status: rec.status),
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
