import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/user_model.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class LandlordMaintenanceScreen extends StatelessWidget {
  final UserModel currentUser;

  const LandlordMaintenanceScreen({super.key, required this.currentUser});

  void _showStatusDialog(BuildContext context, MaintenanceService service, MaintenanceRequestModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Ticket Status'),
        children: [
          _statusOption(ctx, service, ticket, 'pending', 'Pending Review', Colors.amber),
          _statusOption(ctx, service, ticket, 'in-progress', 'In Progress / Assigned', Colors.blue),
          _statusOption(ctx, service, ticket, 'completed', 'Completed / Resolved', Colors.green),
          _statusOption(ctx, service, ticket, 'rejected', 'Rejected / Not Applicable', Colors.red),
        ],
      ),
    );
  }

  Widget _statusOption(
    BuildContext ctx,
    MaintenanceService service,
    MaintenanceRequestModel ticket,
    String status,
    String label,
    Color color,
  ) {
    final isCurrent = ticket.status == status;
    return SimpleDialogOption(
      onPressed: isCurrent
          ? null
          : () async {
              Navigator.pop(ctx);
              try {
                await service.updateStatus(request: ticket, newStatus: status);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Status updated to: $label'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
      child: Row(
        children: [
          Icon(isCurrent ? Icons.radio_button_checked : Icons.radio_button_off, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceService = MaintenanceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Management'),
      ),
      body: StreamBuilder<List<MaintenanceRequestModel>>(
        stream: maintenanceService.getLandlordRequests(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.task_alt,
              title: 'All Clear!',
              message: 'No tenant maintenance requests reported right now.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final dateStr = ticket.createdAt != null
                  ? DateFormat('MMM d, y • h:mm a').format(ticket.createdAt!)
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
                              ticket.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: ticket.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reported: $dateStr',
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
                              ticket.description,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade900),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Text(
                              'Tenant: ${ticket.tenantName ?? ticket.tenantId}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Apartment ID: ${ticket.apartmentId}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showStatusDialog(context, maintenanceService, ticket),
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('Update Status'),
                        ),
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
