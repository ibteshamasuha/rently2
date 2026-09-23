import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental_request_model.dart';
import '../../models/user_model.dart';
import '../../services/rental_request_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class LandlordRequestsScreen extends StatelessWidget {
  final UserModel currentUser;

  const LandlordRequestsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final requestService = RentalRequestService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Rental Requests'),
      ),
      body: StreamBuilder<List<RentalRequestModel>>(
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
      ),
    );
  }
}
