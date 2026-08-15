import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../features/appointments/domain/entities/appointment_lifecycle_entity.dart';
import '../../features/appointments/presentation/providers/appointment_lifecycle_provider.dart';

/// Full-screen appointment detail panel / modal.
/// Shows all appointment info, lifecycle actions, and audit history.
class AppointmentDetailPanel extends StatefulWidget {
  final String appointmentId;
  final VoidCallback? onRefreshCalendar;

  const AppointmentDetailPanel({
    required this.appointmentId,
    this.onRefreshCalendar,
    super.key,
  });

  @override
  State<AppointmentDetailPanel> createState() => _AppointmentDetailPanelState();
}

class _AppointmentDetailPanelState extends State<AppointmentDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<AppointmentLifecycleProvider>();
    await Future.wait([
      provider.loadDetail(widget.appointmentId),
      provider.loadAuditHistory(widget.appointmentId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentLifecycleProvider>(
      builder: (context, provider, _) {
        if (provider.detailLoading && provider.detail == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.detailError != null && provider.detail == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  provider.detailError!,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          );
        }
        final detail = provider.detail;
        if (detail == null) return const SizedBox.shrink();

        return _buildContent(context, provider, detail);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppointmentLifecycleProvider provider,
    AppointmentDetailEntity detail,
  ) {
    final status = detail.status;
    final statusBadge = _lifecycleStatusToAppointmentStatus(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            border: Border(
              bottom: BorderSide(color: AppTheme.outlineVariantLight),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.displayTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StatusBadgeWidget(status: statusBadge),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
                color: AppTheme.primary,
              ),
            ],
          ),
        ),

        // ── Action messages ──────────────────────────────────────────────────
        if (provider.actionError != null)
          _MessageBanner(
            message: provider.actionError!,
            isError: true,
            onDismiss: provider.clearMessages,
          ),
        if (provider.actionSuccess != null)
          _MessageBanner(
            message: provider.actionSuccess!,
            isError: false,
            onDismiss: provider.clearMessages,
          ),
        if (provider.rescheduleError != null)
          _MessageBanner(
            message: provider.rescheduleError!,
            isError: true,
            onDismiss: provider.clearMessages,
          ),

        // ── Tabs ─────────────────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
          labelColor: AppTheme.secondary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.secondary,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'History'),
          ],
        ),

        // ── Tab content ───────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DetailsTab(detail: detail),
              _HistoryTab(
                history: provider.auditHistory,
                isLoading: provider.historyLoading,
              ),
            ],
          ),
        ),

        // ── Actions bar ───────────────────────────────────────────────────────
        if (!status.isTerminal)
          _ActionsBar(
            detail: detail,
            provider: provider,
            onRefreshCalendar: widget.onRefreshCalendar,
          ),
      ],
    );
  }

  AppointmentStatus _lifecycleStatusToAppointmentStatus(
    AppointmentLifecycleStatus s,
  ) {
    return switch (s) {
      AppointmentLifecycleStatus.confirmed => AppointmentStatus.confirmed,
      AppointmentLifecycleStatus.completed => AppointmentStatus.completed,
      AppointmentLifecycleStatus.cancelled => AppointmentStatus.cancelled,
      AppointmentLifecycleStatus.noShow => AppointmentStatus.noShow,
      AppointmentLifecycleStatus.inProgress => AppointmentStatus.checkedIn,
      _ => AppointmentStatus.pending,
    };
  }
}

// ─── Details Tab ─────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final AppointmentDetailEntity detail;
  const _DetailsTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Customer'),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Name',
            value: detail.customerName ?? '—',
          ),
          if (detail.customerEmail != null)
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: detail.customerEmail!,
            ),
          if (detail.customerPhone != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: detail.customerPhone!,
            ),
          const SizedBox(height: 16),
          _SectionHeader('Appointment'),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(detail.startsAt),
          ),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value:
                '${_formatTime(detail.startsAt)} – ${_formatTime(detail.endsAt)}',
          ),
          _InfoRow(
            icon: Icons.timelapse_rounded,
            label: 'Duration',
            value: '${detail.durationMins} min',
          ),
          if (detail.services.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.spa_outlined,
              label: 'Service(s)',
              value: detail.services.map((s) => s.serviceName).join(', '),
            ),
          ],
          if (detail.employees.isNotEmpty)
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Staff',
              value: detail.employees.map((e) => e.employeeName).join(', '),
            ),
          if (detail.branchName != null)
            _InfoRow(
              icon: Icons.store_outlined,
              label: 'Branch',
              value: detail.branchName!,
            ),
          _InfoRow(
            icon: Icons.attach_money_rounded,
            label: 'Total',
            value: '${detail.currency} ${detail.totalPrice.toStringAsFixed(2)}',
          ),
          _InfoRow(
            icon: Icons.source_outlined,
            label: 'Source',
            value:
                detail.bookingSource ??
                (detail.bookedOnline ? 'Online' : 'Manual'),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Status Details'),
          if (detail.confirmedAt != null)
            _InfoRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Confirmed',
              value:
                  '${_formatDateTime(detail.confirmedAt!)}${detail.confirmedByName != null ? ' by ${detail.confirmedByName}' : ''}',
            ),
          if (detail.completedAt != null)
            _InfoRow(
              icon: Icons.task_alt_rounded,
              label: 'Completed',
              value:
                  '${_formatDateTime(detail.completedAt!)}${detail.completedByName != null ? ' by ${detail.completedByName}' : ''}',
            ),
          if (detail.cancelledAt != null) ...[
            _InfoRow(
              icon: Icons.cancel_outlined,
              label: 'Cancelled',
              value:
                  '${_formatDateTime(detail.cancelledAt!)}${detail.cancelledByName != null ? ' by ${detail.cancelledByName}' : ''}',
            ),
            if (detail.cancellationReason != null)
              _InfoRow(
                icon: Icons.comment_outlined,
                label: 'Reason',
                value: detail.cancellationReason!,
              ),
          ],
          if (detail.noShowAt != null) ...[
            _InfoRow(
              icon: Icons.person_off_outlined,
              label: 'No-Show',
              value: _formatDateTime(detail.noShowAt!),
            ),
            if (detail.noShowReason != null)
              _InfoRow(
                icon: Icons.comment_outlined,
                label: 'Reason',
                value: detail.noShowReason!,
              ),
          ],
          if (detail.rescheduledAt != null)
            _InfoRow(
              icon: Icons.update_rounded,
              label: 'Rescheduled',
              value: _formatDateTime(detail.rescheduledAt!),
            ),
          const SizedBox(height: 16),
          _SectionHeader('Notes'),
          if (detail.notes != null && detail.notes!.isNotEmpty)
            _NoteCard(note: detail.notes!, isInternal: false)
          else
            Text(
              'No customer notes.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
          if (detail.internalNotes != null &&
              detail.internalNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _NoteCard(note: detail.internalNotes!, isInternal: true),
          ],
          const SizedBox(height: 16),
          _SectionHeader('Record'),
          _InfoRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Created',
            value: _formatDateTime(detail.createdAt),
          ),
          _InfoRow(
            icon: Icons.update_rounded,
            label: 'Updated',
            value: _formatDateTime(detail.updatedAt),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[local.weekday - 1]}, ${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${_formatDate(local)} ${_formatTime(local)}';
  }
}

// ─── History Tab ─────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<AppointmentAuditEntry> history;
  final bool isLoading;

  const _HistoryTab({required this.history, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: AppTheme.outlineVariantLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No history yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _AuditEntryCard(entry: history[i]),
    );
  }
}

class _AuditEntryCard extends StatelessWidget {
  final AppointmentAuditEntry entry;
  const _AuditEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariantLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _actionIcon(entry.action),
              size: 16,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actionLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                if (entry.actorEmail != null)
                  Text(
                    'by ${entry.actorEmail}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                if (entry.newValues?['reason'] != null)
                  Text(
                    'Reason: ${entry.newValues!['reason']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(entry.createdAt),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  IconData _actionIcon(String action) => switch (action) {
    'appointment.confirmed' => Icons.check_circle_outline_rounded,
    'appointment.cancelled' => Icons.cancel_outlined,
    'appointment.completed' => Icons.task_alt_rounded,
    'appointment.no_show' => Icons.person_off_outlined,
    'appointment.in_progress' => Icons.play_circle_outline_rounded,
    'appointment.rescheduled' => Icons.update_rounded,
    _ => Icons.history_rounded,
  };

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Actions Bar ─────────────────────────────────────────────────────────────

class _ActionsBar extends StatelessWidget {
  final AppointmentDetailEntity detail;
  final AppointmentLifecycleProvider provider;
  final VoidCallback? onRefreshCalendar;

  const _ActionsBar({
    required this.detail,
    required this.provider,
    this.onRefreshCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.status;
    final transitions = status.validTransitions;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineVariantLight)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (transitions.contains(AppointmentLifecycleStatus.confirmed))
            _ActionButton(
              label: 'Confirm',
              icon: Icons.check_rounded,
              color: AppTheme.success,
              isLoading: provider.isActing,
              onTap: () => _confirm(context),
            ),
          if (transitions.contains(AppointmentLifecycleStatus.inProgress))
            _ActionButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              color: const Color(0xFF7C3AED),
              isLoading: provider.isActing,
              onTap: () => _start(context),
            ),
          if (transitions.contains(AppointmentLifecycleStatus.completed))
            _ActionButton(
              label: 'Complete',
              icon: Icons.task_alt_rounded,
              color: AppTheme.secondary,
              isLoading: provider.isActing,
              onTap: () => _complete(context),
            ),
          if (transitions.contains(AppointmentLifecycleStatus.noShow))
            _ActionButton(
              label: 'No-Show',
              icon: Icons.person_off_outlined,
              color: const Color(0xFF6B7280),
              isLoading: provider.isActing,
              onTap: () => _noShow(context),
            ),
          if (transitions.contains(AppointmentLifecycleStatus.rescheduled))
            _ActionButton(
              label: 'Reschedule',
              icon: Icons.update_rounded,
              color: AppTheme.warning,
              isLoading: provider.isRescheduling,
              onTap: () => _reschedule(context),
            ),
          if (transitions.contains(AppointmentLifecycleStatus.cancelled))
            _ActionButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              color: AppTheme.error,
              isLoading: provider.isActing,
              onTap: () => _cancel(context),
            ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await provider.confirmAppointment(detail.id);
    if (ok && context.mounted) {
      onRefreshCalendar?.call();
      _showSnack(context, 'Appointment confirmed.', isError: false);
    }
  }

  Future<void> _start(BuildContext context) async {
    final ok = await provider.startAppointment(detail.id);
    if (ok && context.mounted) {
      onRefreshCalendar?.call();
      _showSnack(context, 'Appointment started.', isError: false);
    }
  }

  Future<void> _complete(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Mark as Completed',
      message: 'Are you sure you want to mark this appointment as completed?',
      confirmLabel: 'Complete',
      confirmColor: AppTheme.secondary,
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await provider.completeAppointment(detail.id);
    if (ok && context.mounted) {
      onRefreshCalendar?.call();
      _showSnack(context, 'Appointment completed.', isError: false);
    }
  }

  Future<void> _noShow(BuildContext context) async {
    final reason = await _showReasonDialog(
      context,
      title: 'Mark as No-Show',
      hint: 'Optional reason...',
    );
    if (reason == null) return;
    if (!context.mounted) return;
    final ok = await provider.markNoShow(
      detail.id,
      reason: reason.isEmpty ? null : reason,
    );
    if (ok && context.mounted) {
      onRefreshCalendar?.call();
      _showSnack(context, 'Marked as no-show.', isError: false);
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await _showReasonDialog(
      context,
      title: 'Cancel Appointment',
      hint: 'Reason for cancellation...',
      required: true,
    );
    if (reason == null || reason.isEmpty) return;
    if (!context.mounted) return;
    final ok = await provider.cancelAppointment(detail.id, reason: reason);
    if (ok && context.mounted) {
      onRefreshCalendar?.call();
      _showSnack(context, 'Appointment cancelled.', isError: false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _reschedule(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => RescheduleDialog(
        appointmentId: detail.id,
        currentStartsAt: detail.startsAt,
        onRescheduled: () {
          onRefreshCalendar?.call();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReasonDialog(
    BuildContext context, {
    required String title,
    required String hint,
    bool required = false,
  }) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (required && ctrl.text.trim().isEmpty) return;
              Navigator.of(context).pop(ctrl.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }
}

// ─── Reschedule Dialog ────────────────────────────────────────────────────────

class RescheduleDialog extends StatefulWidget {
  final String appointmentId;
  final DateTime currentStartsAt;
  final VoidCallback? onRescheduled;

  const RescheduleDialog({
    required this.appointmentId,
    required this.currentStartsAt,
    this.onRescheduled,
    super.key,
  });

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentStartsAt.toLocal();
    _selectedTime = TimeOfDay.fromDateTime(widget.currentStartsAt.toLocal());
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final newStartsAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final provider = context.read<AppointmentLifecycleProvider>();
    final result = await provider.rescheduleAppointment(
      RescheduleRequest(
        appointmentId: widget.appointmentId,
        newStartsAt: newStartsAt,
        reason: _reasonCtrl.text.trim().isEmpty
            ? null
            : _reasonCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop();
      widget.onRescheduled?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment rescheduled successfully.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.rescheduleError ?? 'Failed to reschedule appointment.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reschedule Appointment',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a new date and time. The server will validate availability.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    label: 'Date',
                    value: _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Pick date',
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    label: 'Time',
                    value: _selectedTime?.format(context) ?? 'Pick time',
                    icon: Icons.access_time_rounded,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Consumer<AppointmentLifecycleProvider>(
          builder: (_, provider, __) => FilledButton(
            onPressed: provider.isRescheduling ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warning),
            child: provider.isRescheduling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Reschedule'),
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;
  final bool isInternal;

  const _NoteCard({required this.note, required this.isInternal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInternal
            ? const Color(0xFFFFF3CD)
            : AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInternal
              ? const Color(0xFFFFD700).withAlpha(100)
              : AppTheme.secondary.withAlpha(50),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isInternal ? Icons.lock_outline_rounded : Icons.notes_rounded,
            size: 14,
            color: isInternal ? const Color(0xFFB45309) : AppTheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isInternal ? const Color(0xFF92400E) : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppTheme.errorContainer : AppTheme.successContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AppTheme.error : AppTheme.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isError ? AppTheme.error : AppTheme.success,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isError ? AppTheme.error : AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withAlpha(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outlineVariantLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the appointment detail panel in a bottom sheet (mobile) or dialog (desktop).
void showAppointmentDetail(
  BuildContext context, {
  required String appointmentId,
  VoidCallback? onRefreshCalendar,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 1024;

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 560,
          height: MediaQuery.of(context).size.height * 0.85,
          child: AppointmentDetailPanel(
            appointmentId: appointmentId,
            onRefreshCalendar: onRefreshCalendar,
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, __) => AppointmentDetailPanel(
          appointmentId: appointmentId,
          onRefreshCalendar: onRefreshCalendar,
        ),
      ),
    );
  }
}