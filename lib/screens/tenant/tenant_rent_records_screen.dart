import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class TenantRentRecordsScreen extends StatefulWidget {
  final UserModel currentUser;

  const TenantRentRecordsScreen({super.key, required this.currentUser});

  @override
  State<TenantRentRecordsScreen> createState() => _TenantRentRecordsScreenState();
}

class _TenantRentRecordsScreenState extends State<TenantRentRecordsScreen> {
  String _selectedTab = 'All'; // 'All', 'Paid', 'Pending'

  final List<RentRecordItem> _records = const [
    RentRecordItem(
      monthYear: 'October 2026',
      amount: '৳15,000',
      paidDate: 'Paid on Oct 1, 2026',
      isPaid: true,
    ),
    RentRecordItem(
      monthYear: 'September 2026',
      amount: '৳15,000',
      paidDate: 'Paid on Sep 1, 2026',
      isPaid: true,
    ),
    RentRecordItem(
      monthYear: 'August 2026',
      amount: '৳15,000',
      paidDate: 'Paid on Aug 1, 2026',
      isPaid: true,
    ),
    RentRecordItem(
      monthYear: 'July 2026',
      amount: '৳15,000',
      paidDate: 'Paid on Jul 1, 2026',
      isPaid: true,
    ),
    RentRecordItem(
      monthYear: 'November 2026',
      amount: '৳15,000',
      paidDate: 'Due on Nov 1, 2026',
      isPaid: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _records.where((r) {
      if (_selectedTab == 'Paid') return r.isPaid;
      if (_selectedTab == 'Pending') return !r.isPaid;
      return true;
    }).toList();

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
      body: Column(
        children: [
          // Filter Tabs matching Picture 1 Screen 12: [All], [Paid], [Pending]
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

          const SizedBox(height: 6),

          // List of Rent Records
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final record = filtered[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GenXPalette.cameoWhite),
                    boxShadow: [
                      BoxShadow(
                        color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.monthYear,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: GenXPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            record.amount,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: GenXPalette.midnightBlue,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            record.paidDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: GenXPalette.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Status Badge (Paid / Pending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: record.isPaid
                              ? GenXPalette.vineLeaf.withValues(alpha: 0.12)
                              : GenXPalette.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.isPaid ? 'Paid' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: record.isPaid ? GenXPalette.vineLeaf : GenXPalette.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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

class RentRecordItem {
  final String monthYear;
  final String amount;
  final String paidDate;
  final bool isPaid;

  const RentRecordItem({
    required this.monthYear,
    required this.amount,
    required this.paidDate,
    required this.isPaid,
  });
}
