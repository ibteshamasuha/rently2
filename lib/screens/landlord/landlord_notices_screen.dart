import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/notice_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
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
    final apartmentService = ApartmentService();

    String targetAudience = 'all'; // 'all', 'apartment', 'tenant'
    ApartmentModel? selectedApartment;
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
                  const SizedBox(height: 14),

                  // Target Audience Selector (Requirement 5)
                  const Text(
                    'Target Audience',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTargetChip('All Tenants', 'all', targetAudience, (val) {
                        setModalState(() {
                          targetAudience = val;
                          selectedApartment = null;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildTargetChip('Specific Flat', 'apartment', targetAudience, (val) {
                        setModalState(() {
                          targetAudience = val;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildTargetChip('Specific Tenant', 'tenant', targetAudience, (val) {
                        setModalState(() {
                          targetAudience = val;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Apartment Selector if targeting a flat or specific tenant
                  if (targetAudience != 'all') ...[
                    StreamBuilder<List<ApartmentModel>>(
                      stream: apartmentService.getLandlordApartments(currentUser.uid),
                      builder: (context, aptSnap) {
                        final myApts = aptSnap.data ?? [];
                        if (myApts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: const Text(
                              'You have no published properties to target. Post will be published to all tenants.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          );
                        }

                        final filteredApts = targetAudience == 'tenant'
                            ? myApts.where((a) => a.currentTenantId != null && a.currentTenantId!.isNotEmpty).toList()
                            : myApts;

                        return DropdownButtonFormField<ApartmentModel>(
                          initialValue: selectedApartment != null && filteredApts.any((a) => a.id == selectedApartment!.id)
                              ? filteredApts.firstWhere((a) => a.id == selectedApartment!.id)
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: targetAudience == 'tenant' ? 'Select Occupied Unit (Tenant)' : 'Select Apartment / Flat',
                            prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          hint: Text(
                            filteredApts.isEmpty
                                ? (targetAudience == 'tenant' ? 'No occupied flats found' : 'Select a flat')
                                : 'Choose apartment',
                            style: const TextStyle(fontSize: 13),
                          ),
                          items: filteredApts.map((apt) {
                            final subtitle = apt.currentTenantId != null ? ' (Occupied)' : '';
                            return DropdownMenuItem<ApartmentModel>(
                              value: apt,
                              child: Text(
                                '${apt.title}$subtitle',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (apt) => setModalState(() => selectedApartment = apt),
                          validator: (val) {
                            if (targetAudience != 'all' && val == null && filteredApts.isNotEmpty) {
                              return 'Please select an apartment';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

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
                              final effectiveApartmentId = selectedApartment?.id;
                              final effectiveTenantId = selectedApartment?.currentTenantId;

                              await service.createNotice(
                                title: titleController.text.trim(),
                                message: messageController.text.trim(),
                                authorId: currentUser.uid,
                                authorName: currentUser.name,
                                authorRole: currentUser.role,
                                isPublic: targetAudience == 'all',
                                apartmentId: effectiveApartmentId,
                                targetTenantId: targetAudience == 'tenant' ? effectiveTenantId : null,
                                targetType: targetAudience,
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

  Widget _buildTargetChip(String label, String value, String current, Function(String) onSelected) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
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
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notice.isPublic
                                  ? Colors.green.shade50
                                  : (notice.targetTenantId != null ? Colors.purple.shade50 : Colors.blue.shade50),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: notice.isPublic
                                    ? Colors.green.shade200
                                    : (notice.targetTenantId != null ? Colors.purple.shade200 : Colors.blue.shade200),
                              ),
                            ),
                            child: Text(
                              notice.isPublic
                                  ? 'All Tenants'
                                  : (notice.targetTenantId != null ? 'Direct to Tenant' : 'Flat Notice'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: notice.isPublic
                                    ? Colors.green.shade800
                                    : (notice.targetTenantId != null ? Colors.purple.shade800 : Colors.blue.shade800),
                              ),
                            ),
                          ),
                        ],
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
