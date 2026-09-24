import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_query_model.dart';
import '../../models/rental_request_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_query_service.dart';
import '../../services/rental_request_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class LandlordRequestsScreen extends StatelessWidget {
  final UserModel currentUser;
  final int initialTabIndex;

  const LandlordRequestsScreen({
    super.key,
    required this.currentUser,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final requestService = RentalRequestService();
    final queryService = ApartmentQueryService();

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests & Inquiries'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Applications'),
              Tab(text: 'Inquiries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Rental Applications
            _buildApplicationsTab(context, requestService),

            // Tab 2: Apartment Inquiries (Requirement 5)
            _buildInquiriesTab(context, queryService),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTab(BuildContext context, RentalRequestService requestService) {
    return StreamBuilder<List<RentalRequestModel>>(
      stream: requestService.getLandlordRequests(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'No Rental Requests',
            message: 'You have no incoming rental applications right now.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final dateStr = req.createdAt != null
                ? DateFormat('MMM d, y • h:mm a').format(req.createdAt!)
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            req.apartmentTitle ?? 'Apartment: ${req.apartmentId}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: req.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Received: $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applicant: ${req.tenantName ?? "Tenant"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tenant UID: ${req.tenantId}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (req.message != null && req.message!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '"${req.message}"',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (req.isPending) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await requestService.updateRequestStatus(
                                    request: req,
                                    newStatus: 'rejected',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request rejected.')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.close, color: Colors.red, size: 16),
                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await requestService.updateRequestStatus(
                                    request: req,
                                    newStatus: 'approved',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Request approved! Apartment marked rented.'),
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
                                }
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInquiriesTab(BuildContext context, ApartmentQueryService queryService) {
    return StreamBuilder<List<ApartmentQueryModel>>(
      stream: queryService.getLandlordQueries(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final queries = snapshot.data ?? [];

        if (queries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.question_answer_outlined,
            title: 'No Inquiries Yet',
            message: 'Prospective tenants asking questions about your listings will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: queries.length,
          itemBuilder: (context, index) {
            final q = queries[index];
            final dateStr = q.createdAt != null
                ? DateFormat('MMM d, y • h:mm a').format(q.createdAt!)
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            q.apartmentTitle ?? 'Apartment Query',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: q.isAnswered
                                ? GenXPalette.vineLeaf.withValues(alpha: 0.12)
                                : GenXPalette.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            q.isAnswered ? 'ANSWERED' : 'PENDING',
                            style: TextStyle(
                              color: q.isAnswered ? GenXPalette.vineLeaf : GenXPalette.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'From: ${q.tenantName ?? "Tenant"} • $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),

                    // Question Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Question:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GenXPalette.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.question,
                            style: const TextStyle(fontSize: 14, color: GenXPalette.textDark, fontWeight: FontWeight.w600),
                          ),
                          if (q.isAnswered && q.answer != null) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            const Text(
                              'Your Response:',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GenXPalette.vineLeaf),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              q.answer!,
                              style: const TextStyle(fontSize: 13.5, color: GenXPalette.textDark),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (!q.isAnswered) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAnswerModal(context, queryService, q),
                          icon: const Icon(Icons.reply_rounded, size: 16),
                          label: const Text('Reply to Tenant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GenXPalette.midnightBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAnswerModal(BuildContext context, ApartmentQueryService queryService, ApartmentQueryModel q) {
    final answerController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reply to Inquiry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Question: "${q.question}"',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: GenXPalette.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your answer to the tenant...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final ans = answerController.text.trim();
                        if (ans.isEmpty) return;

                        setModalState(() => isSubmitting = true);
                        try {
                          await queryService.answerQuery(queryId: q.id, answer: ans);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Answer sent to tenant!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          setModalState(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: GenXPalette.midnightBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Reply', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
