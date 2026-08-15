import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../features/notifications/presentation/providers/notification_provider.dart';
import '../../../theme/app_theme.dart';

class SettingsNotificationsWidget extends StatefulWidget {
  const SettingsNotificationsWidget({super.key});

  @override
  State<SettingsNotificationsWidget> createState() =>
      _SettingsNotificationsWidgetState();
}

class _SettingsNotificationsWidgetState
    extends State<SettingsNotificationsWidget> {
  final _recipientController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<NotificationProvider>();
        provider.loadPreferences().then((_) {
          if (mounted) {
            _recipientController.text =
                provider.preferences.summaryRecipientEmail ?? '';
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _save(NotificationProvider provider) async {
    final updated = provider.preferences.copyWith(
      summaryRecipientEmail: _recipientController.text.trim().isEmpty
          ? null
          : _recipientController.text.trim(),
    );
    await provider.savePreferences(updated);
    if (mounted) {
      final msg = provider.successMessage ?? provider.error;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: provider.successMessage != null
                ? AppTheme.secondary
                : Colors.red,
          ),
        );
        provider.clearMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final prefs = provider.preferences;

        return _SettingsSection(
          title: 'Email Notifications',
          icon: Icons.email_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email notifications are sent via Resend. Configure secrets in your Supabase Edge Function settings.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Appointment Notifications ────────────────────────────────
              _SectionHeader('Appointment Notifications'),
              const SizedBox(height: 8),

              _NotifToggleRow(
                title: 'Appointment Notifications',
                subtitle: 'Master toggle for all appointment emails',
                icon: Icons.calendar_today_outlined,
                value: prefs.appointmentNotificationsEnabled,
                onChanged: (v) => provider.updateLocal(
                  prefs.copyWith(appointmentNotificationsEnabled: v),
                ),
              ),

              _NotifToggleRow(
                title: 'New Booking Alert',
                subtitle: 'Receive email when a new appointment is booked',
                icon: Icons.add_circle_outline_rounded,
                value: prefs.newAppointmentEmailEnabled,
                enabled: prefs.appointmentNotificationsEnabled,
                onChanged: (v) => provider.updateLocal(
                  prefs.copyWith(newAppointmentEmailEnabled: v),
                ),
              ),

              _NotifToggleRow(
                title: 'Cancellation Alert',
                subtitle: 'Receive email when a customer cancels',
                icon: Icons.cancel_outlined,
                value: prefs.cancellationEmailEnabled,
                enabled: prefs.appointmentNotificationsEnabled,
                onChanged: (v) => provider.updateLocal(
                  prefs.copyWith(cancellationEmailEnabled: v),
                ),
              ),

              _NotifToggleRow(
                title: 'Appointment Reminders',
                subtitle: 'Send reminder emails to customers (24h & 2h before)',
                icon: Icons.alarm_outlined,
                value: prefs.reminderEmailEnabled,
                enabled: prefs.appointmentNotificationsEnabled,
                onChanged: (v) => provider.updateLocal(
                  prefs.copyWith(reminderEmailEnabled: v),
                ),
              ),

              const SizedBox(height: 20),

              // ── Daily Summary ────────────────────────────────────────────
              _SectionHeader('Daily Summary'),
              const SizedBox(height: 8),

              _NotifToggleRow(
                title: 'Daily Appointment Summary',
                subtitle:
                    'Receive a summary of today\'s appointments at 7:00 AM local time',
                icon: Icons.summarize_outlined,
                value: prefs.dailySummaryEnabled,
                onChanged: (v) => provider.updateLocal(
                  prefs.copyWith(dailySummaryEnabled: v),
                ),
              ),

              if (prefs.dailySummaryEnabled) ...[
                const SizedBox(height: 12),
                Text(
                  'Summary Recipient Email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _recipientController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Leave blank to use business owner email',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.secondary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 4),
                Text(
                  'Delivered no later than 7:00 AM in your business timezone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Save Button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isSaving ? null : () => _save(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: provider.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Notification Settings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _NotifToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotifToggleRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppTheme.secondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value && enabled,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: AppTheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.secondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
