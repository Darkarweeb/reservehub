import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  noShow,
}

extension AppointmentStatusExt on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.checkedIn:
        return 'Checked In';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return AppTheme.warning;
      case AppointmentStatus.confirmed:
        return AppTheme.secondary;
      case AppointmentStatus.checkedIn:
        return const Color(0xFF7C3AED);
      case AppointmentStatus.completed:
        return AppTheme.success;
      case AppointmentStatus.cancelled:
        return AppTheme.error;
      case AppointmentStatus.noShow:
        return const Color(0xFF6B7280);
    }
  }

  Color get bgColor {
    switch (this) {
      case AppointmentStatus.pending:
        return AppTheme.warningContainer;
      case AppointmentStatus.confirmed:
        return AppTheme.secondaryContainer;
      case AppointmentStatus.checkedIn:
        return const Color(0xFFF3E8FF);
      case AppointmentStatus.completed:
        return AppTheme.successContainer;
      case AppointmentStatus.cancelled:
        return AppTheme.errorContainer;
      case AppointmentStatus.noShow:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentStatus.pending:
        return Icons.schedule_rounded;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case AppointmentStatus.checkedIn:
        return Icons.login_rounded;
      case AppointmentStatus.completed:
        return Icons.task_alt_rounded;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.noShow:
        return Icons.person_off_outlined;
    }
  }
}

class StatusBadgeWidget extends StatelessWidget {
  final AppointmentStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 10 : 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: status.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
