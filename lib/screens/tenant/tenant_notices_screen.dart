import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_model.dart';
import '../../models/user_model.dart';
import '../../services/notice_service.dart';
import '../../theme/app_theme.dart';
import 'tenant_rent_records_screen.dart';

class TenantNoticesScreen extends StatelessWidget {
  final UserModel? currentUser;

  const TenantNoticesScreen({super.key, this.currentUser});

  final List<NoticeItemData> _defaultNotices = const [
    NoticeItemData(
      title: 'Maintence Work',
      date: 'Sep 20, 2026',
      preview: 'Water supply will be unavailable from 10 AM to 2 PM.',
      tag: 'Urgent',
      icon: Icons.notifications_none_rounded,
      iconColor: Color(0xFFEF4444),
      iconBg: Color(0xFFFEE2E2),
      isRentReminder: false,
    ),
    NoticeItemData(
      title: 'Rent Reminder',
      date: 'Sep 15, 2026',
      preview: 'Monthly rent is due on 1st October. Kindly clear dues.',
      tag: 'Reminder',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF8B5CF6),
      iconBg: Color(0xFFEDE9FE),
      isRentReminder: true,
    ),
    NoticeItemData(
      title: 'Building Rules Update',
      date: 'Sep 10, 2026',
      preview: 'New parking rules are in effect. Please park in designated slots.',
      tag: 'Notice',
      icon: Icons.home_work_outlined,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFEF3C7),
      isRentReminder: false,
    ),
    NoticeItemData(
      title: 'Festival Holiday',
      date: 'Sep 06, 2026',
      preview: 'Office will remain closed on Sunday on the occasion of holiday.',
      tag: 'Event',
      icon: Icons.celebration_outlined,
      iconColor: Color(0xFFEC4899),
      iconBg: Color(0xFFFCE7F3),
      isRentReminder: false,
    ),
  ];

  void _showNoticeDetails(BuildContext context, NoticeItemData notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: GenXPalette.cameoWhite,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: notice.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notice.icon, color: notice.iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GenXPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notice.iconBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notice.tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: notice.iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notice.date,
                            style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              notice.preview,
              style: const TextStyle(
                fontSize: 14.5,
                color: GenXPalette.textDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            if (notice.isRentReminder) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final user = currentUser ??
                      UserModel(
                        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                        email: FirebaseAuth.instance.currentUser?.email ?? '',
                        name: FirebaseAuth.instance.currentUser?.displayName ?? 'Tenant',
                        role: 'tenant',
                        createdAt: DateTime.now(),
                      );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantRentRecordsScreen(currentUser: user),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('View Rent Records & Pay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: GenXPalette.cameoWhite),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Close', style: TextStyle(color: GenXPalette.textDark)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noticeService = NoticeService();
    final tenantId = currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Notices'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: StreamBuilder<List<NoticeModel>>(
        stream: noticeService.getTenantNotices(tenantId),
        builder: (context, snapshot) {
          final firestoreNotices = snapshot.data ?? [];
          final liveItems = firestoreNotices.map((n) {
            final isRent = n.title.toLowerCase().contains('rent') ||
                n.message.toLowerCase().contains('rent');
            final isMaint = n.title.toLowerCase().contains('maint') ||
                n.message.toLowerCase().contains('water') ||
                n.message.toLowerCase().contains('repair');

            IconData icon = Icons.campaign_rounded;
            Color iconColor = GenXPalette.midnightBlue;
            Color iconBg = GenXPalette.cameoWhite;
            String tag = 'General';

            if (isRent) {
              icon = Icons.receipt_long_rounded;
              iconColor = const Color(0xFF8B5CF6);
              iconBg = const Color(0xFFEDE9FE);
              tag = 'Reminder';
            } else if (isMaint) {
              icon = Icons.notifications_none_rounded;
              iconColor = const Color(0xFFEF4444);
              iconBg = const Color(0xFFFEE2E2);
              tag = 'Urgent';
            }

            return NoticeItemData(
              title: n.title,
              date: n.createdAt != null
                  ? DateFormat('MMM dd, yyyy').format(n.createdAt!)
                  : 'Recent',
              preview: n.message,
              tag: tag,
              icon: icon,
              iconColor: iconColor,
              iconBg: iconBg,
              isRentReminder: isRent,
            );
          }).toList();

          // Combine live notices with default notices
          final items = [...liveItems, ..._defaultNotices];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final notice = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showNoticeDetails(context, notice),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Colored circular icon (Screen 13)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: notice.iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notice.icon, color: notice.iconColor, size: 22),
                          ),

                          const SizedBox(width: 14),

                          // Title & Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notice.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: GenXPalette.textDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      notice.date,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: GenXPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  notice.preview,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: GenXPalette.textMuted,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GenXPalette.textMuted),
                        ],
                      ),
                    ),
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

class NoticeItemData {
  final String title;
  final String date;
  final String preview;
  final String tag;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isRentReminder;

  const NoticeItemData({
    required this.title,
    required this.date,
    required this.preview,
    required this.tag,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isRentReminder = false,
  });
}
