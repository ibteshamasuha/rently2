import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_model.dart';
import '../../models/user_model.dart';
import '../../services/notice_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';

class LandlordNoticesScreen extends StatelessWidget {
  final UserModel currentUser;

  const LandlordNoticesScreen({super.key, required this.currentUser});

  void _showCreateNoticeModal(BuildContext context, NoticeService service) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

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
                        'Publish Community Notice',
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
                    controller: titleController,
                    label: 'Notice Title',
                    hint: 'e.g. Water Tank Cleaning on Friday',
                    prefixIcon: Icons.campaign_outlined,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: messageController,
                    label: 'Announcement Message',
                    hint: 'Provide details, timings, instructions for tenants...',
                    prefixIcon: Icons.message_outlined,
                    maxLines: 4,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter message' : null,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              await service.createNotice(
                                title: titleController.text.trim(),
                                message: messageController.text.trim(),
                                authorId: currentUser.uid,
                                authorName: currentUser.name,
                                authorRole: currentUser.role,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notice published successfully!'),
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
                              setModalState(() => isSubmitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Publish Notice', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final noticeService = NoticeService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notices'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_landlord_notices',
        onPressed: () => _showCreateNoticeModal(context, noticeService),
        icon: const Icon(Icons.add_comment),
        label: const Text('Post Notice'),
      ),
      body: StreamBuilder<List<NoticeModel>>(
        stream: noticeService.getLandlordNotices(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No Notices Published',
              message: 'Share important updates, maintenance schedules, or rules with your tenants.',
              actionLabel: 'Post Notice',
              onAction: () => _showCreateNoticeModal(context, noticeService),
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
              final isMyNotice = notice.authorId == currentUser.uid;

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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isMyNotice)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              tooltip: 'Delete Notice',
                              onPressed: () => noticeService.deleteNotice(notice.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.message,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
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
