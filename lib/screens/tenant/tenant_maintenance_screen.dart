import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/user_model.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class TenantMaintenanceScreen extends StatefulWidget {
  final UserModel currentUser;

  const TenantMaintenanceScreen({super.key, required this.currentUser});

  @override
  State<TenantMaintenanceScreen> createState() => _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  final _maintenanceService = MaintenanceService();

  void _showNewTicketModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final landlordIdController = TextEditingController();
    final apartmentIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                        'New Maintenance Request',
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
                    'Report an issue with your rented apartment to your landlord.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: titleController,
                    label: 'Issue Title',
                    hint: 'e.g. Water tap leaking, Electrical socket broken',
                    prefixIcon: Icons.build_outlined,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: apartmentIdController,
                    label: 'Apartment ID / Title',
                    hint: 'e.g. RvKz7GagxbSqqEXcGZHy or 2 Bedroom Apartment',
                    prefixIcon: Icons.home_outlined,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter apartment ID' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: landlordIdController,
                    label: 'Landlord ID',
                    hint: 'e.g. VRJqiSBDQ7frreWavr8MLfGHjlr1',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter landlord ID' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: descController,
                    label: 'Detailed Description',
                    hint: 'Describe the problem and when it started...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter a description' : null,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              await _maintenanceService.submitRequest(
                                tenantId: widget.currentUser.uid,
                                landlordId: landlordIdController.text.trim(),
                                apartmentId: apartmentIdController.text.trim(),
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                tenantName: widget.currentUser.name,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Maintenance ticket submitted!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
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
                        : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tickets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTicketModal,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: StreamBuilder<List<MaintenanceRequestModel>>(
        stream: _maintenanceService.getTenantRequests(widget.currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.handyman_outlined,
              title: 'No Maintenance Tickets',
              message: 'Everything looking good! Need repairs? Tap below to report an issue to your landlord.',
              actionLabel: 'Report Issue',
              onAction: _showNewTicketModal,
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
                margin: const EdgeInsets.only(bottom: 12.0),
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
                      Text(
                        ticket.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Text(
                        'Landlord ID: ${ticket.landlordId}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
