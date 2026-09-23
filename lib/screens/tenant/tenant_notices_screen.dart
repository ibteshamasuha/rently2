import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../models/user_model.dart';
import '../../services/notice_service.dart';
import '../../theme/app_theme.dart';

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
    ),
    NoticeItemData(
      title: 'Rent Reminder',
      date: 'Sep 15, 2026',
      preview: 'Monthly rent is due on 1st October. Kindly clear dues.',
      tag: 'Reminder',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF8B5CF6),
      iconBg: Color(0xFFEDE9FE),
    ),
    NoticeItemData(
      title: 'Building Rules Update',
      date: 'Sep 10, 2026',
      preview: 'New parking rules are in effect. Please park in designated slots.',
      tag: 'Notice',
      icon: Icons.home_work_outlined,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFEF3C7),
    ),
    NoticeItemData(
      title: 'Festival Holiday',
      date: 'Sep 06, 2026',
      preview: 'Office will remain closed on Sunday on the occasion of holiday.',
      tag: 'Event',
      icon: Icons.celebration_outlined,
      iconColor: Color(0xFFEC4899),
      iconBg: Color(0xFFFCE7F3),
    ),
  ];

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
          // If Firestore has notices, we display them; otherwise fallback to the Picture 1 demo list
          final firestoreNotices = snapshot.data ?? [];
          final items = firestoreNotices.isNotEmpty
              ? firestoreNotices.map((n) {
                  return NoticeItemData(
                    title: n.title,
                    date: n.createdAt != null
                        ? '${n.createdAt!.day}/${n.createdAt!.month}/${n.createdAt!.year}'
                        : 'Recent',
                    preview: n.message,
                    tag: 'General',
                    icon: Icons.campaign_rounded,
                    iconColor: GenXPalette.midnightBlue,
                    iconBg: GenXPalette.cameoWhite,
                  );
                }).toList()
              : _defaultNotices;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final notice = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
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
                              Text(
                                notice.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: GenXPalette.textDark,
                                ),
                              ),
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
                          ),
                        ],
                      ),
                    ),
                  ],
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

  const NoticeItemData({
    required this.title,
    required this.date,
    required this.preview,
    required this.tag,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}
