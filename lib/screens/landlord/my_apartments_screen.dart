import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'add_edit_apartment_screen.dart';

class MyApartmentsScreen extends StatelessWidget {
  final UserModel currentUser;

  const MyApartmentsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final apartmentService = ApartmentService();
    final currencyFormatter = NumberFormat.currency(symbol: '৳ ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Apartments'),
        actions: [
          StreamBuilder<List<ApartmentModel>>(
            stream: apartmentService.getLandlordApartments(currentUser.uid),
            builder: (context, snapshot) {
              final apts = snapshot.data ?? [];
              if (apts.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                tooltip: 'Clear All My Listings (Reset to 0)',
                onPressed: () => _confirmClearAll(context, apartmentService, apts),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_my_apartments',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditApartmentScreen(currentUser: currentUser),
            ),
          );
        },
        icon: const Icon(Icons.add_home),
        label: const Text('Add Listing'),
      ),
      body: StreamBuilder<List<ApartmentModel>>(
        stream: apartmentService.getLandlordApartments(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final apartments = snapshot.data ?? [];

          if (apartments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.apartment,
              title: 'No Apartments Listed',
              message: 'You have not listed any apartments yet. Add your first rental listing today!',
              actionLabel: 'Add Apartment',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditApartmentScreen(currentUser: currentUser),
                  ),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: apartments.length,
            itemBuilder: (context, index) {
              final apt = apartments[index];

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
                              apt.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: apt.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 15, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              apt.location,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${currencyFormatter.format(apt.rent)} / month',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        apt.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final newStatus = apt.isAvailable ? 'rented' : 'available';
                              apartmentService.updateApartmentStatus(apt.id, newStatus);
                            },
                            icon: Icon(
                              apt.isAvailable ? Icons.lock_outline : Icons.lock_open,
                              size: 16,
                            ),
                            label: Text(
                              apt.isAvailable ? 'Mark Rented' : 'Mark Available',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditApartmentScreen(
                                    currentUser: currentUser,
                                    apartment: apt,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Delete Listing',
                            onPressed: () => _confirmDelete(context, apartmentService, apt),
                          ),
                        ],
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

  void _confirmDelete(BuildContext context, ApartmentService service, ApartmentModel apt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Apartment'),
        content: Text('Are you sure you want to permanently delete "${apt.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.deleteApartment(apt.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, ApartmentService service, List<ApartmentModel> apts) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Property Count to 0?'),
        content: Text(
          'This will permanently remove all ${apts.length} listing(s) created under your account so your "My Properties" count becomes 0.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final apt in apts) {
                await service.deleteApartment(apt.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All listings cleared. My Properties is now 0!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
