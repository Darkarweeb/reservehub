import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../features/appointments/presentation/providers/appointment_lifecycle_provider.dart';
import '../../features/scheduling/presentation/providers/appointment_provider.dart';
import '../../features/scheduling/presentation/providers/time_block_provider.dart';
import '../../localization/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/calendar_appointment_list_widget.dart';
import './widgets/calendar_grid_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Bulk selection
  bool _bulkMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final apptProvider = context.read<AppointmentProvider>();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    await Future.wait([
      apptProvider.loadAppointments(dateFrom: firstDay, dateTo: lastDay),
      apptProvider.loadMonthSummary(
        year: _focusedMonth.year,
        month: _focusedMonth.month,
      ),
    ]);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _bulkMode = false;
      _selectedIds.clear();
    });
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _focusedMonth = month;
      _selectedDay = DateTime(month.year, month.month, 1);
      _bulkMode = false;
      _selectedIds.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _showCreateAppointmentDialog() {
    showDialog(
      context: context,
      builder: (_) => _ManualAppointmentDialog(selectedDay: _selectedDay),
    ).then((_) => _loadData());
  }

  void _showCreateBlockDialog() {
    showDialog(
      context: context,
      builder: (_) => _TimeBlockDialog(selectedDay: _selectedDay),
    ).then((_) => _loadData());
  }

  void _toggleBulkMode() {
    setState(() {
      _bulkMode = !_bulkMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _bulkConfirm() async {
    if (_selectedIds.isEmpty) return;
    final provider = context.read<AppointmentLifecycleProvider>();
    final result = await provider.bulkConfirm(_selectedIds.toList());
    if (!mounted) return;
    _loadData();
    setState(() {
      _bulkMode = false;
      _selectedIds.clear();
    });
    if (result != null) {
      final failedSuffix = result.failed > 0
          ? ', ${result.failed} ${AppStrings.bulkFailedSuffix}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.succeeded} ${AppStrings.statusConfirmed.toLowerCase()}$failedSuffix.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _bulkCancel() async {
    if (_selectedIds.isEmpty) return;
    final reason = await _showBulkReasonDialog();
    if (reason == null || reason.isEmpty || !mounted) return;

    final provider = context.read<AppointmentLifecycleProvider>();
    final result = await provider.bulkCancel(
      _selectedIds.toList(),
      reason: reason,
    );
    if (!mounted) return;
    _loadData();
    setState(() {
      _bulkMode = false;
      _selectedIds.clear();
    });
    if (result != null) {
      final failedSuffix = result.failed > 0
          ? ', ${result.failed} ${AppStrings.bulkFailedSuffix}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.succeeded} ${AppStrings.statusCancelled.toLowerCase()}$failedSuffix.',
          ),
        ),
      );
    }
  }

  Future<void> _bulkComplete() async {
    if (_selectedIds.isEmpty) return;
    final provider = context.read<AppointmentLifecycleProvider>();
    final result = await provider.bulkComplete(_selectedIds.toList());
    if (!mounted) return;
    _loadData();
    setState(() {
      _bulkMode = false;
      _selectedIds.clear();
    });
    if (result != null) {
      final failedSuffix = result.failed > 0
          ? ', ${result.failed} ${AppStrings.bulkFailedSuffix}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.succeeded} ${AppStrings.statusCompleted.toLowerCase()}$failedSuffix.',
          ),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  Future<String?> _showBulkReasonDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '${AppStrings.cancelAction} ${_selectedIds.length} ${AppStrings.appointments}',
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
            child: Text(AppStrings.cancelAll),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBarWidget(
        title: AppStrings.calendar,
        actions: [
          // Bulk mode toggle
          IconButton(
            icon: Icon(
              _bulkMode ? Icons.close_rounded : Icons.checklist_rounded,
              size: 20,
            ),
            tooltip: _bulkMode
                ? AppStrings.exitBulkMode
                : AppStrings.selectMultiple,
            onPressed: _toggleBulkMode,
            color: _bulkMode ? AppTheme.error : AppTheme.primary,
          ),
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.today_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            tooltip: AppStrings.today,
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedMonth = DateTime.now();
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _bulkMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'block_fab',
                  backgroundColor: AppTheme.surfaceLight,
                  foregroundColor: AppTheme.primary,
                  tooltip: AppStrings.blockTime,
                  onPressed: _showCreateBlockDialog,
                  child: const Icon(Icons.block_rounded, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'appt_fab',
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  label: Text(
                    AppStrings.nuevaCita,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: _showCreateAppointmentDialog,
                ),
              ],
            ),
      body: SafeArea(
        child: Consumer<AppointmentProvider>(
          builder: (context, apptProvider, _) {
            final dayAppointments = apptProvider.appointmentsForDay(
              _selectedDay,
            );
            final dayBlocks = apptProvider.timeBlocksForDay(_selectedDay);

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.secondary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: CalendarGridWidget(
                      focusedMonth: _focusedMonth,
                      selectedDay: _selectedDay,
                      onDaySelected: _onDaySelected,
                      onMonthChanged: _onMonthChanged,
                      monthSummary: apptProvider.monthSummary,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            _formatSelectedDay(_selectedDay),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          const Spacer(),
                          if (apptProvider.isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${dayAppointments.length} ${AppStrings.appts}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Bulk action bar
                  if (_bulkMode)
                    SliverToBoxAdapter(
                      child: _BulkActionBar(
                        selectedCount: _selectedIds.length,
                        onConfirm: _bulkConfirm,
                        onCancel: _bulkCancel,
                        onComplete: _bulkComplete,
                      ),
                    ),
                  // Time blocks section
                  if (dayBlocks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _TimeBlocksSection(
                        blocks: dayBlocks,
                        onDelete: (id) async {
                          final tbProvider = context.read<TimeBlockProvider>();
                          final ok = await tbProvider.deleteBlock(id);
                          if (ok && mounted) {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.timeBlockRemoved),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  // Error
                  if (apptProvider.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            apptProvider.errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Appointments
                  dayAppointments.isEmpty && !apptProvider.isLoading
                      ? SliverFillRemaining(
                          child: EmptyStateWidget(
                            icon: Icons.event_available_rounded,
                            title: AppStrings.emptyAppointments,
                            subtitle: AppStrings.emptyCalendarSubtitle,
                            ctaLabel: AppStrings.nuevaCita,
                            onCta: _showCreateAppointmentDialog,
                          ),
                        )
                      : _bulkMode
                      ? SliverToBoxAdapter(
                          child: _BulkSelectableList(
                            appointments: dayAppointments
                                .map(
                                  (a) => {
                                    'id': a.id,
                                    'customerName': a.customerName ?? 'Guest',
                                    'service': a.serviceName ?? '—',
                                    'time': _formatTime(a.startsAt),
                                    'duration': '${a.durationMins} min',
                                    'employee': a.employeeName ?? '—',
                                    'status': _statusString(a.status),
                                    'price': a.totalPrice.toStringAsFixed(0),
                                  },
                                )
                                .toList(),
                            selectedIds: _selectedIds,
                            onToggle: _toggleSelect,
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: CalendarAppointmentListWidget(
                            appointments: dayAppointments
                                .map(
                                  (a) => {
                                    'id': a.id,
                                    'customerName': a.customerName ?? 'Guest',
                                    'service': a.serviceName ?? '—',
                                    'time': _formatTime(a.startsAt),
                                    'duration': '${a.durationMins} min',
                                    'employee': a.employeeName ?? '—',
                                    'status': _statusString(a.status),
                                    'price': a.totalPrice.toStringAsFixed(0),
                                  },
                                )
                                .toList(),
                            onRefreshCalendar: _loadData,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatSelectedDay(DateTime d) {
    const months = [
      AppStrings.monthJan,
      AppStrings.monthFeb,
      AppStrings.monthMar,
      AppStrings.monthApr,
      AppStrings.monthMay,
      AppStrings.monthJun,
      AppStrings.monthJul,
      AppStrings.monthAug,
      AppStrings.monthSep,
      AppStrings.monthOct,
      AppStrings.monthNov,
      AppStrings.monthDec,
    ];
    const weekdays = [
      AppStrings.weekdayShortMon,
      AppStrings.weekdayShortTue,
      AppStrings.weekdayShortWed,
      AppStrings.weekdayShortThu,
      AppStrings.weekdayShortFri,
      AppStrings.weekdayShortSat,
      AppStrings.weekdayShortSun,
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _statusString(AppointmentStatusEntity status) {
    return switch (status) {
      AppointmentStatusEntity.confirmed => 'confirmed',
      AppointmentStatusEntity.checkedIn => 'in_progress',
      AppointmentStatusEntity.inProgress => 'in_progress',
      AppointmentStatusEntity.completed => 'completed',
      AppointmentStatusEntity.cancelled => 'cancelled',
      AppointmentStatusEntity.noShow => 'no_show',
      AppointmentStatusEntity.rescheduled => 'rescheduled',
      AppointmentStatusEntity.waitlisted => 'waitlisted',
      AppointmentStatusEntity.pending => 'pending',
    };
  }
}

// ─── Bulk Action Bar ──────────────────────────────────────────────────────────

class _BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const _BulkActionBar({
    required this.selectedCount,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentLifecycleProvider>(
      builder: (_, provider, __) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.secondary.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedCount == 0
                  ? AppStrings.tapToSelect
                  : '$selectedCount ${AppStrings.selectedCount}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
              ),
            ),
            if (selectedCount > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _BulkButton(
                    label: AppStrings.confirmAll,
                    icon: Icons.check_rounded,
                    color: AppTheme.success,
                    isLoading: provider.isBulkActing,
                    onTap: onConfirm,
                  ),
                  _BulkButton(
                    label: AppStrings.completeAll,
                    icon: Icons.task_alt_rounded,
                    color: AppTheme.secondary,
                    isLoading: provider.isBulkActing,
                    onTap: onComplete,
                  ),
                  _BulkButton(
                    label: AppStrings.cancelAll,
                    icon: Icons.close_rounded,
                    color: AppTheme.error,
                    isLoading: provider.isBulkActing,
                    onTap: onCancel,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _BulkButton({
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
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 13, color: color),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─── Bulk Selectable List ─────────────────────────────────────────────────────

class _BulkSelectableList extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;

  const _BulkSelectableList({
    required this.appointments,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: appointments.map((apt) {
          final id = apt['id'] as String? ?? '';
          final isSelected = selectedIds.contains(id);
          return GestureDetector(
            onTap: () => onToggle(id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondaryContainer
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.secondary
                      : AppTheme.outlineVariantLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isSelected
                        ? AppTheme.secondary
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt['customerName'] as String? ?? 'Guest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          '${apt['service'] ?? '—'} · ${apt['time'] ?? ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    apt['status'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Time Blocks Section ──────────────────────────────────────────────────────

class _TimeBlocksSection extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;
  final void Function(String id) onDelete;

  const _TimeBlocksSection({required this.blocks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.blockedPeriods,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          ...blocks.map((b) => _TimeBlockItem(block: b, onDelete: onDelete)),
        ],
      ),
    );
  }
}

class _TimeBlockItem extends StatelessWidget {
  final Map<String, dynamic> block;
  final void Function(String id) onDelete;

  const _TimeBlockItem({required this.block, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final blockDate = block['block_date'] as String? ?? '';
    final isPast =
        blockDate.isNotEmpty &&
        DateTime.tryParse(blockDate)?.isBefore(DateTime.now()) == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block['title'] as String? ?? AppStrings.timeBlock,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                Text(
                  '${block['start_time'] ?? ''} – ${block['end_time'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          if (!isPast)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: const Color(0xFFB45309),
              onPressed: () => onDelete(block['id'] as String),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

// ─── Manual Appointment Dialog ────────────────────────────────────────────────

class _ManualAppointmentDialog extends StatefulWidget {
  final DateTime selectedDay;
  const _ManualAppointmentDialog({required this.selectedDay});

  @override
  State<_ManualAppointmentDialog> createState() =>
      _ManualAppointmentDialogState();
}

class _ManualAppointmentDialogState extends State<_ManualAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _branchIdCtrl = TextEditingController();
  final _serviceIdCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _source = 'manual';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _branchIdCtrl.dispose();
    _serviceIdCtrl.dispose();
    _employeeIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startsAt = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final provider = context.read<AppointmentProvider>();
    final ok = await provider.createManualAppointment(
      branchId: _branchIdCtrl.text.trim(),
      serviceId: _serviceIdCtrl.text.trim(),
      employeeId: _employeeIdCtrl.text.trim(),
      startsAt: startsAt,
      customerName: _nameCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      bookingSource: _source,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.appointmentCreatedMsg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? AppStrings.failedToCreate),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.newManualAppointment,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  _nameCtrl,
                  AppStrings.customerNameLabel,
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildField(
                  _branchIdCtrl,
                  AppStrings.branchIdLabel,
                  required: true,
                  hint: AppStrings.branchIdHint,
                ),
                const SizedBox(height: 12),
                _buildField(
                  _serviceIdCtrl,
                  AppStrings.serviceIdLabel,
                  required: true,
                  hint: AppStrings.serviceIdHint,
                ),
                const SizedBox(height: 12),
                _buildField(
                  _employeeIdCtrl,
                  AppStrings.employeeIdLabel,
                  required: true,
                  hint: AppStrings.employeeIdHint,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.outlineVariantLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime.format(context),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _source,
                  decoration: InputDecoration(
                    labelText: AppStrings.bookingSourceLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text(AppStrings.bookingSourceManual),
                    ),
                    DropdownMenuItem(
                      value: 'phone',
                      child: Text(AppStrings.bookingSourcePhone),
                    ),
                    DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text(AppStrings.bookingSourceWhatsApp),
                    ),
                    DropdownMenuItem(
                      value: 'walk_in',
                      child: Text(AppStrings.bookingSourceWalkIn),
                    ),
                    DropdownMenuItem(
                      value: 'instagram',
                      child: Text(AppStrings.bookingSourceInstagram),
                    ),
                  ],
                  onChanged: (v) => setState(() => _source = v ?? 'manual'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  _notesCtrl,
                  AppStrings.notesOptional,
                  required: false,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        Consumer<AppointmentProvider>(
          builder: (_, provider, __) => FilledButton(
            onPressed: provider.isCreating ? null : _submit,
            child: provider.isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(AppStrings.createAction),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? '$label ${AppStrings.fieldRequired}'
                : null
          : null,
    );
  }
}

// ─── Time Block Dialog ────────────────────────────────────────────────────────

class _TimeBlockDialog extends StatefulWidget {
  final DateTime selectedDay;
  const _TimeBlockDialog({required this.selectedDay});

  @override
  State<_TimeBlockDialog> createState() => _TimeBlockDialogState();
}

class _TimeBlockDialogState extends State<_TimeBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _branchIdCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reasonCtrl.dispose();
    _branchIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _formatTOD(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TimeBlockProvider>();
    final ok = await provider.createBlock(
      branchId: _branchIdCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      blockDate: widget.selectedDay,
      startTime: _formatTOD(_startTime),
      endTime: _formatTOD(_endTime),
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.timeBlockCreated)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.failedToCreateBlock,
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
        AppStrings.blockTime,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.titleLabel,
                  hintText: AppStrings.titleHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.titleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchIdCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.branchIdLabel,
                  hintText: AppStrings.branchIdHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.branchIdRequired
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStart,
                      borderRadius: BorderRadius.circular(8),
                      child: _timeTile(
                        AppStrings.startLabel,
                        _startTime.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEnd,
                      borderRadius: BorderRadius.circular(8),
                      child: _timeTile(
                        AppStrings.endLabel,
                        _endTime.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.reasonOptional,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        Consumer<TimeBlockProvider>(
          builder: (_, provider, __) => FilledButton(
            onPressed: provider.isLoading ? null : _submit,
            child: provider.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(AppStrings.blockAction),
          ),
        ),
      ],
    );
  }

  Widget _timeTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
