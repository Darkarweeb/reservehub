import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../features/scheduling/presentation/providers/appointment_provider.dart';
import '../../features/scheduling/presentation/providers/time_block_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final apptProvider = context.read<AppointmentProvider>();
    final now = DateTime.now();
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
    setState(() => _selectedDay = day);
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _focusedMonth = month;
      _selectedDay = DateTime(month.year, month.month, 1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBarWidget(
        title: 'Calendar',
        actions: [
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
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedMonth = DateTime.now();
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'block_fab',
            backgroundColor: AppTheme.surfaceLight,
            foregroundColor: AppTheme.primary,
            tooltip: 'Block Time',
            onPressed: _showCreateBlockDialog,
            child: const Icon(Icons.block_rounded, size: 18),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'appt_fab',
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            label: Text(
              'New Appointment',
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
                                '${dayAppointments.length} appts',
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
                              const SnackBar(
                                content: Text('Time block removed.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  // Appointments section
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
                  dayAppointments.isEmpty && !apptProvider.isLoading
                      ? SliverFillRemaining(
                          child: EmptyStateWidget(
                            icon: Icons.event_available_rounded,
                            title: 'No appointments',
                            subtitle:
                                'This day is free. Add an appointment to fill the schedule.',
                            ctaLabel: 'New Appointment',
                            onCta: _showCreateAppointmentDialog,
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
                                    'avatarUrl':
                                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=96&h=96&fit=crop',
                                    'avatarLabel': 'Customer avatar',
                                    'isManual': a.isManual,
                                  },
                                )
                                .toList(),
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
      AppointmentStatusEntity.checkedIn => 'checked_in',
      AppointmentStatusEntity.completed => 'completed',
      AppointmentStatusEntity.cancelled => 'cancelled',
      AppointmentStatusEntity.noShow => 'no_show',
      AppointmentStatusEntity.pending => 'pending',
    };
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
            'Blocked Periods',
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
                  block['title'] as String? ?? 'Block',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment created successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to create appointment.',
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
        'New Manual Appointment',
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
                _buildField(_nameCtrl, 'Customer Name', required: true),
                const SizedBox(height: 12),
                _buildField(
                  _branchIdCtrl,
                  'Branch ID',
                  required: true,
                  hint: 'UUID of the branch',
                ),
                const SizedBox(height: 12),
                _buildField(
                  _serviceIdCtrl,
                  'Service ID',
                  required: true,
                  hint: 'UUID of the service',
                ),
                const SizedBox(height: 12),
                _buildField(
                  _employeeIdCtrl,
                  'Employee ID',
                  required: true,
                  hint: 'UUID of the employee',
                ),
                const SizedBox(height: 12),
                // Time picker
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
                // Source dropdown
                DropdownButtonFormField<String>(
                  initialValue: _source,
                  decoration: InputDecoration(
                    labelText: 'Booking Source',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('Manual')),
                    DropdownMenuItem(value: 'phone', child: Text('Phone')),
                    DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text('WhatsApp'),
                    ),
                    DropdownMenuItem(value: 'walk_in', child: Text('Walk-in')),
                    DropdownMenuItem(
                      value: 'instagram',
                      child: Text('Instagram'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _source = v ?? 'manual'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  _notesCtrl,
                  'Notes (optional)',
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
          child: const Text('Cancel'),
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
                : const Text('Create'),
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
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
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
      ).showSnackBar(const SnackBar(content: Text('Time block created.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to create block.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Block Time',
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
                  labelText: 'Title',
                  hintText: 'e.g. Lunch, Meeting, Maintenance',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Branch ID',
                  hintText: 'UUID of the branch',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Branch ID is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStart,
                      borderRadius: BorderRadius.circular(8),
                      child: _timeTile('Start', _startTime.format(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEnd,
                      borderRadius: BorderRadius.circular(8),
                      child: _timeTile('End', _endTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
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
          child: const Text('Cancel'),
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
                : const Text('Block'),
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
