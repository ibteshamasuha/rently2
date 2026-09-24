import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_model.dart';
import '../../models/rent_record_model.dart';
import '../../models/user_model.dart';
import '../../services/notice_service.dart';
import '../../services/rent_record_service.dart';
import '../../theme/app_theme.dart';

class TenantRentRecordsScreen extends StatefulWidget {
  final UserModel currentUser;

  const TenantRentRecordsScreen({super.key, required this.currentUser});

  @override
  State<TenantRentRecordsScreen> createState() => _TenantRentRecordsScreenState();
}

class _TenantRentRecordsScreenState extends State<TenantRentRecordsScreen> {
  String _selectedTab = 'All'; // 'All', 'Paid', 'Pending'
  final RentRecordService _recordService = RentRecordService();
  final NoticeService _noticeService = NoticeService();
  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

  // Fallback demo records if tenant hasn't rented an apartment yet
  final List<RentRecordModel> _demoRecords = [
    RentRecordModel(
      id: 'demo-1',
      tenantId: 'demo',
      landlordId: 'demo_landlord',
      apartmentId: 'demo-apt-1',
      apartmentTitle: '2 Bedroom Apartment',
      amount: 15000,
      month: 'October 2026',
      status: 'unpaid',
      createdAt: DateTime(2026, 10, 1),
    ),
    RentRecordModel(
      id: 'demo-2',
      tenantId: 'demo',
      landlordId: 'demo_landlord',
      apartmentId: 'demo-apt-1',
      apartmentTitle: '2 Bedroom Apartment',
      amount: 15000,
      month: 'September 2026',
      status: 'paid',
      paidAt: DateTime(2026, 9, 2),
      createdAt: DateTime(2026, 9, 1),
    ),
    RentRecordModel(
      id: 'demo-3',
      tenantId: 'demo',
      landlordId: 'demo_landlord',
      apartmentId: 'demo-apt-1',
      apartmentTitle: '2 Bedroom Apartment',
      amount: 15000,
      month: 'August 2026',
      status: 'paid',
      paidAt: DateTime(2026, 8, 3),
      createdAt: DateTime(2026, 8, 1),
    ),
  ];

  Future<void> _payRent(RentRecordModel record) async {
    // If it's a real record in Firestore, update it
    if (!record.id.startsWith('demo-')) {
      try {
        await _recordService.updatePaymentStatus(
          recordId: record.id,
          status: 'paid',
        );

        // Notify landlord about payment
        try {
          await FirebaseFirestore.instance.collection('notices').add({
            'title': 'Rent Paid! ✓',
            'message': '${widget.currentUser.name.isNotEmpty ? widget.currentUser.name : "Tenant"} has cleared rent of ৳${record.amount} for ${record.month} (${record.apartmentTitle ?? "Apartment"}).',
            'authorId': widget.currentUser.uid,
            'authorName': widget.currentUser.name,
            'authorRole': 'tenant',
            'targetTenantId': null,
            'isPublic': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Rent payment confirmed! Status updated to Paid ✓'),
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
            SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // Local demo payment simulation
      setState(() {
        final idx = _demoRecords.indexWhere((r) => r.id == record.id);
        if (idx != -1) {
          _demoRecords[idx] = RentRecordModel(
            id: record.id,
            tenantId: record.tenantId,
            landlordId: record.landlordId,
            apartmentId: record.apartmentId,
            apartmentTitle: record.apartmentTitle,
            amount: record.amount,
            month: record.month,
            status: 'paid',
            paidAt: DateTime.now(),
            createdAt: record.createdAt,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rent payment simulated! Marked as Paid ✓'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Rent Records'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: StreamBuilder<List<RentRecordModel>>(
        stream: _recordService.getTenantRentRecords(widget.currentUser.uid),
        builder: (context, snapshot) {
          final liveRecords = snapshot.data ?? [];
          final records = liveRecords.isNotEmpty ? liveRecords : _demoRecords;

          final filtered = records.where((r) {
            if (_selectedTab == 'Paid') return r.isPaid;
            if (_selectedTab == 'Pending') return r.isUnpaid;
            return true;
          }).toList();

          return Column(
            children: [
              // Live Reminder Notification Banner from Landlord (Requirement 3 & 4)
              StreamBuilder<List<NoticeModel>>(
                stream: _noticeService.getTenantNotices(widget.currentUser.uid),
                builder: (context, noticeSnapshot) {
                  final notices = noticeSnapshot.data ?? [];
                  final rentReminders = notices.where((n) {
                    return n.title.toLowerCase().contains('rent') ||
                        n.message.toLowerCase().contains('rent reminder');
                  }).toList();

                  if (rentReminders.isNotEmpty) {
                    final latest = rentReminders.first;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      latest.title,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5B21B6),
                                      ),
                                    ),
                                    const Text(
                                      'Notice',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  latest.message,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4C1D95)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Filter Tabs: [All], [Paid], [Pending]
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

              const SizedBox(height: 4),

              // List of Rent Records
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No $_selectedTab records found.',
                          style: const TextStyle(color: GenXPalette.textMuted, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final record = filtered[index];
                          final isPaid = record.isPaid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                                          record.month,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: GenXPalette.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          record.apartmentTitle ?? 'Rented Apartment',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: GenXPalette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _currencyFormatter.format(record.amount),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: GenXPalette.midnightBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Requirement: Green Tick (✓) for Paid Months!
                                        if (isPaid)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: GenXPalette.warning.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Due',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: GenXPalette.warning,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Pay Rent button for unpaid months
                                if (!isPaid) ...[
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Payment pending',
                                        style: TextStyle(fontSize: 12, color: GenXPalette.warning, fontWeight: FontWeight.w600),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _payRent(record),
                                        icon: const Icon(Icons.payment_rounded, size: 16),
                                        label: const Text('Pay Rent Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GenXPalette.midnightBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (record.paidAt != null) ...[
                                  const Divider(height: 16),
                                  Text(
                                    'Paid on ${DateFormat('MMM dd, yyyy').format(record.paidAt!)}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
}
