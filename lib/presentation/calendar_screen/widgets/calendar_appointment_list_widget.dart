import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../features/appointments/presentation/providers/appointment_lifecycle_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../presentation/appointment_detail_panel/appointment_detail_panel.dart';
import '../../../widgets/status_badge_widget.dart';

/// Enhanced appointment list widget with lifecycle actions.
/// Replaces the stub quick-action buttons with real server-side calls.
class CalendarAppointmentListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final VoidCallback? onRefreshCalendar;

  const CalendarAppointmentListWidget({
    required this.appointments,
    this.onRefreshCalendar,
    super.key,
  });

  AppointmentStatus _statusFromString(String s) {
    return switch (s) {
      'pending' => AppointmentStatus.pending,
      'confirmed' => AppointmentStatus.confirmed,
      'checked_in' => AppointmentStatus.checkedIn,
      'in_progress' => AppointmentStatus.checkedIn,
      'completed' => AppointmentStatus.completed,
      'cancelled' => AppointmentStatus.cancelled,
      'no_show' => AppointmentStatus.noShow,
      _ => AppointmentStatus.pending,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(appointments.length, (i) {
          final apt = appointments[i];
          final status = _statusFromString(
            apt['status'] as String? ?? 'pending',
          );
          return _CalendarAppointmentItem(
            apt: apt,
            status: status,
            index: i,
            onRefreshCalendar: onRefreshCalendar,
          );
        }),
      ),
    );
  }
}

class _CalendarAppointmentItem extends StatefulWidget {
  final Map<String, dynamic> apt;
  final AppointmentStatus status;
  final int index;
  final VoidCallback? onRefreshCalendar;

  const _CalendarAppointmentItem({
    required this.apt,
    required this.status,
    required this.index,
    this.onRefreshCalendar,
  });

  @override
  State<_CalendarAppointmentItem> createState() =>
      _CalendarAppointmentItemState();
}

class _CalendarAppointmentItemState extends State<_CalendarAppointmentItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openDetail() {
    final id = widget.apt['id'] as String?;
    if (id == null) return;
    showAppointmentDetail(
      context,
      appointmentId: id,
      onRefreshCalendar: widget.onRefreshCalendar,
    );
  }

  Future<void> _quickConfirm() async {
    final id = widget.apt['id'] as String?;
    if (id == null) return;
    final provider = context.read<AppointmentLifecycleProvider>();
    final ok = await provider.confirmAppointment(id);
    if (ok && mounted) {
      widget.onRefreshCalendar?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.appointmentConfirmedMsg),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.actionError ?? AppStrings.failedToConfirm),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _quickCancel() async {
    final id = widget.apt['id'] as String?;
    if (id == null) return;

    final reason = await _showReasonDialog();
    if (reason == null || reason.isEmpty || !mounted) return;

    final provider = context.read<AppointmentLifecycleProvider>();
    final ok = await provider.cancelAppointment(id, reason: reason);
    if (ok && mounted) {
      widget.onRefreshCalendar?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.appointmentCancelledMsg)),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.actionError ?? AppStrings.failedToCancel),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<String?> _showReasonDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          AppStrings.cancelAppointment,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: AppStrings.reasonForCancellation,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(AppStrings.back),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: Text(AppStrings.cancelAppointment),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apt = widget.apt;
    final status = widget.status;
    final isCancelled = status == AppointmentStatus.cancelled;
    final isCompleted = status == AppointmentStatus.completed;
    final isTerminal =
        isCancelled || isCompleted || status == AppointmentStatus.noShow;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariantLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _openDetail,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppTheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Status bar
                      Container(
                        width: 4,
                        height: 56,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: status.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Main info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    apt['customerName'] as String? ?? 'Guest',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '\$${apt['price'] ?? '0'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              apt['service'] as String? ?? '—',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${apt['time'] ?? ''} · ${apt['duration'] ?? ''}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                const Spacer(),
                                StatusBadgeWidget(
                                  status: status,
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apt['employee'] as String? ?? '—',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Quick actions — only for non-terminal states
                      if (!isTerminal) ...[
                        if (status == AppointmentStatus.pending)
                          _QuickActionButton(
                            icon: Icons.check_rounded,
                            label: AppStrings.confirmAction,
                            color: AppTheme.success,
                            onTap: _quickConfirm,
                          ),
                        const SizedBox(width: 8),
                        if (status != AppointmentStatus.cancelled)
                          _QuickActionButton(
                            icon: Icons.close_rounded,
                            label: AppStrings.cancelAction,
                            color: AppTheme.error,
                            onTap: _quickCancel,
                          ),
                      ],
                      const SizedBox(width: 8),
                      // View detail
                      _QuickActionButton(
                        icon: Icons.open_in_new_rounded,
                        label: AppStrings.viewAction,
                        color: AppTheme.secondary,
                        onTap: _openDetail,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
