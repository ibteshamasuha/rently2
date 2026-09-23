import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'available':
        bg = const Color(0xFFEBF6ED);
        fg = const Color(0xFF2E6930);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'rented':
        bg = const Color(0xFFECEEF0);
        fg = const Color(0xFF4A5568);
        icon = Icons.home_rounded;
        break;
      case 'upcoming':
      case 'pending':
        bg = const Color(0xFFFBF4E6);
        fg = const Color(0xFFB45309);
        icon = Icons.schedule_rounded;
        break;
      case 'approved':
      case 'completed':
      case 'paid':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
        icon = Icons.check_circle_rounded;
        break;
      case 'in-progress':
        bg = const Color(0xFFEBF4FF);
        fg = const Color(0xFF1D4ED8);
        icon = Icons.timelapse_rounded;
        break;
      case 'rejected':
      case 'unpaid':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
