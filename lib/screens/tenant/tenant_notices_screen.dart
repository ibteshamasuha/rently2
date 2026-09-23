import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_model.dart';
import '../../services/notice_service.dart';
import '../../widgets/empty_state.dart';

class TenantNoticesScreen extends StatelessWidget {
  const TenantNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final noticeService = NoticeService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
      ),
      body: StreamBuilder<List<NoticeModel>>(
        stream: noticeService.getNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No Notices Yet',
              message: 'Check back later for building announcements and community notices.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final dateStr = notice.createdAt != null
                  ? DateFormat('MMM d, y • h:mm a').format(notice.createdAt!)
                  : 'Recent';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.campaign, color: Colors.amber.shade900, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notice.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notice.message,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                      ),
                      if (notice.authorName != null && notice.authorName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Posted by: ${notice.authorName} (${notice.authorRole ?? "Landlord"})',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
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
