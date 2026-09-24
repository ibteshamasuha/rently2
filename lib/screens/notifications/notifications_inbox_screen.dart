import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../services/apartment_service.dart';
import '../../theme/app_theme.dart';
import '../tenant/my_rental_requests_screen.dart';
import '../tenant/tenant_maintenance_screen.dart';
import '../tenant/tenant_notices_screen.dart';
import '../tenant/tenant_rent_records_screen.dart';
import '../tenant/apartment_details_screen.dart';
import '../landlord/landlord_requests_screen.dart';
import '../landlord/landlord_maintenance_screen.dart';
import '../landlord/landlord_rent_records_screen.dart';

class NotificationsInboxScreen extends StatelessWidget {
  final UserModel currentUser;

  const NotificationsInboxScreen({super.key, required this.currentUser});

  String _formatTime(DateTime? date) {
    if (date == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'rental_approval':
      case 'rental_approved':
        return Icons.check_circle_rounded;
      case 'rental_rejection':
      case 'rental_rejected':
        return Icons.cancel_rounded;
      case 'rental_request':
        return Icons.assignment_ind_rounded;
      case 'inquiry':
      case 'inquiry_received':
        return Icons.chat_bubble_outline_rounded;
      case 'inquiry_reply':
      case 'inquiry_replied':
        return Icons.mark_chat_read_rounded;
      case 'maintenance_request':
      case 'maintenance_created':
        return Icons.handyman_outlined;
      case 'maintenance_status':
      case 'maintenance_updated':
        return Icons.build_circle_rounded;
      case 'notice':
      case 'notice_targeted':
      case 'notice_published':
        return Icons.campaign_rounded;
      case 'rent_reminder':
        return Icons.payments_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'rental_approval':
      case 'rental_approved':
        return GenXPalette.success;
      case 'rental_rejection':
      case 'rental_rejected':
        return GenXPalette.danger;
      case 'rental_request':
        return GenXPalette.midnightBlue;
      case 'inquiry':
      case 'inquiry_received':
        return GenXPalette.info;
      case 'inquiry_reply':
      case 'inquiry_replied':
        return GenXPalette.vineLeaf;
      case 'maintenance_request':
      case 'maintenance_created':
        return GenXPalette.warning;
      case 'maintenance_status':
      case 'maintenance_updated':
        return GenXPalette.info;
      case 'notice':
      case 'notice_targeted':
      case 'notice_published':
        return const Color(0xFF7C3AED);
      case 'rent_reminder':
        return const Color(0xFFD97706);
      default:
        return GenXPalette.midnightBlue;
    }
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notif) async {
    final notifService = NotificationService();
    if (!notif.isRead) {
      await notifService.markAsRead(notif.id);
    }

    if (!context.mounted) return;

    if (notif.inquiryId != null || notif.type.startsWith('inquiry')) {
      if (currentUser.isTenant) {
        if (notif.apartmentId != null) {
          final apt = await ApartmentService().getApartmentById(notif.apartmentId!);
          if (!context.mounted) return;
          if (apt != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApartmentDetailsScreen(apartment: apt, currentUser: currentUser),
              ),
            );
            return;
          }
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LandlordRequestsScreen(currentUser: currentUser, initialTabIndex: 1),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;

    if (notif.rentalRequestId != null || notif.type.startsWith('rental_')) {
      if (currentUser.isTenant) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyRentalRequestsScreen(currentUser: currentUser)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LandlordRequestsScreen(currentUser: currentUser)),
        );
      }
      return;
    }

    if (notif.maintenanceRequestId != null || notif.type.startsWith('maintenance_')) {
      if (currentUser.isTenant) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TenantMaintenanceScreen(currentUser: currentUser)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LandlordMaintenanceScreen(currentUser: currentUser)),
        );
      }
      return;
    }

    if (notif.type == 'notice' || notif.type == 'notice_targeted' || notif.type == 'notice_published') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TenantNoticesScreen(currentUser: currentUser)),
      );
      return;
    }

    if (notif.type == 'rent_reminder' || notif.rentRecordId != null) {
      if (currentUser.isTenant) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TenantRentRecordsScreen(currentUser: currentUser)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LandlordRentRecordsScreen(currentUser: currentUser)),
        );
      }
      return;
    }

    if (notif.apartmentId != null) {
      final apt = await ApartmentService().getApartmentById(notif.apartmentId!);
      if (!context.mounted) return;
      if (apt != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApartmentDetailsScreen(apartment: apt, currentUser: currentUser),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifService = NotificationService();

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: GenXPalette.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Clear all notifications',
            icon: const Icon(Icons.delete_sweep_outlined, size: 22),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Notifications'),
                  content: const Text('Are you sure you want to clear all notifications?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: GenXPalette.danger),
                      child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await notifService.clearAllForUser(currentUser.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications cleared.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifService.streamUserNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading notifications: ${snapshot.error}'),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 44,
                        color: GenXPalette.midnightBlue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Notifications Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GenXPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When you receive updates about rental requests, questions, maintenance, or notices, they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: GenXPalette.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final icon = _getIconForType(notif.type);
              final color = _getColorForType(notif.type);

              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: GenXPalette.danger,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  notifService.deleteNotification(notif.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted.')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: notif.isRead
                          ? GenXPalette.cameoWhite
                          : GenXPalette.vineLeaf.withValues(alpha: 0.3),
                      width: notif.isRead ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: GenXPalette.textDark,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: const TextStyle(fontSize: 12.5, color: GenXPalette.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      tooltip: 'Remove',
                      onPressed: () => notifService.deleteNotification(notif.id),
                    ),
                    onTap: () => _handleNotificationTap(context, notif),
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
