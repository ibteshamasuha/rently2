import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../screens/landlord/landlord_maintenance_screen.dart';
import '../screens/landlord/landlord_notices_screen.dart';
import '../screens/landlord/landlord_rent_records_screen.dart';
import '../screens/landlord/landlord_requests_screen.dart';
import '../screens/tenant/apartment_details_screen.dart';
import '../screens/tenant/my_rental_requests_screen.dart';
import '../screens/tenant/tenant_maintenance_screen.dart';
import '../screens/tenant/tenant_notices_screen.dart';
import '../screens/tenant/tenant_rent_records_screen.dart';
import '../services/apartment_service.dart';

class InAppNotificationPopup extends StatefulWidget {
  final UserModel currentUser;
  final Widget child;

  const InAppNotificationPopup({
    super.key,
    required this.currentUser,
    required this.child,
  });

  @override
  State<InAppNotificationPopup> createState() => _InAppNotificationPopupState();
}

class _InAppNotificationPopupState extends State<InAppNotificationPopup> {
  final NotificationService _notificationService = NotificationService();
  static final Set<String> _shownNotificationIds = {};
  StreamSubscription<List<NotificationModel>>? _sub;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(covariant InAppNotificationPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.uid != widget.currentUser.uid) {
      _sub?.cancel();
      _startListening();
    }
  }

  void _startListening() {
    _sub = _notificationService
        .streamUnreadNotifications(widget.currentUser.uid)
        .listen((unreadList) {
      if (!mounted) return;
      for (final n in unreadList) {
        if (!_shownNotificationIds.contains(n.id)) {
          _shownNotificationIds.add(n.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _displayNotificationDialog(n);
          });
          break; // Show one popup at a time to avoid stacked modal chaos
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _displayNotificationDialog(NotificationModel n) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GenXPalette.midnightBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: GenXPalette.midnightBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                n.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GenXPalette.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.message,
              style: const TextStyle(fontSize: 13.5, color: GenXPalette.textDark, height: 1.35),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "View" to open this record.',
              style: TextStyle(fontSize: 11.5, color: GenXPalette.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _notificationService.markAsRead(n.id);
            },
            child: const Text('Dismiss', style: TextStyle(color: GenXPalette.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _notificationService.markAsRead(n.id);
              _navigateToRelatedContent(n);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GenXPalette.midnightBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRelatedContent(NotificationModel n) async {
    final user = widget.currentUser;
    final isLandlord = user.role == 'landlord' || user.role == 'both';

    try {
      switch (n.type) {
        case 'rental_request':
          if (isLandlord) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LandlordRequestsScreen(currentUser: user)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyRentalRequestsScreen(currentUser: user)),
            );
          }
          break;

        case 'rental_approval':
        case 'rental_rejection':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MyRentalRequestsScreen(currentUser: user)),
          );
          break;

        case 'inquiry':
          if (isLandlord) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LandlordRequestsScreen(currentUser: user, initialTabIndex: 1)),
            );
          }
          break;

        case 'inquiry_reply':
          if (n.apartmentId != null) {
            final apt = await ApartmentService().getApartmentById(n.apartmentId!);
            if (apt != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ApartmentDetailsScreen(apartment: apt, currentUser: user)),
              );
              return;
            }
          }
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TenantNoticesScreen(currentUser: user)),
          );
          break;

        case 'maintenance_request':
          if (isLandlord) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LandlordMaintenanceScreen(currentUser: user)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantMaintenanceScreen(currentUser: user)),
            );
          }
          break;

        case 'maintenance_status':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TenantMaintenanceScreen(currentUser: user)),
          );
          break;

        case 'rent_reminder':
          if (isLandlord) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LandlordRentRecordsScreen(currentUser: user)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantRentRecordsScreen(currentUser: user)),
            );
          }
          break;

        case 'notice':
          if (isLandlord) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LandlordNoticesScreen(currentUser: user)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantNoticesScreen(currentUser: user)),
            );
          }
          break;

        default:
          if (isLandlord) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LandlordNoticesScreen(currentUser: user)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantNoticesScreen(currentUser: user)),
            );
          }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The related record is no longer available.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
