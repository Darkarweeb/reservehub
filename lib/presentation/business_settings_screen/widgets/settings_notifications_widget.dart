import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class SettingsNotificationsWidget extends StatefulWidget {
  const SettingsNotificationsWidget({super.key});

  @override
  State<SettingsNotificationsWidget> createState() =>
      _SettingsNotificationsWidgetState();
}

class _SettingsNotificationsWidgetState
    extends State<SettingsNotificationsWidget> {
  // TODO: Replace with Riverpod NotificationSettingsNotifier for production
  final List<Map<String, dynamic>> _settings = [
    {
      'title': 'Booking Confirmation',
      'subtitle': 'Send confirmation when appointment is booked',
      'icon': Icons.check_circle_outline_rounded,
      'email': true,
      'sms': true,
      'push': true,
    },
    {
      'title': 'Appointment Reminder',
      'subtitle': '24h and 1h before appointment',
      'icon': Icons.alarm_outlined,
      'email': true,
      'sms': true,
      'push': false,
    },
    {
      'title': 'Cancellation Alert',
      'subtitle': 'Notify when customer cancels',
      'icon': Icons.cancel_outlined,
      'email': true,
      'sms': false,
      'push': true,
    },
    {
      'title': 'Review Request',
      'subtitle': 'Request review after appointment',
      'icon': Icons.star_outline_rounded,
      'email': true,
      'sms': false,
      'push': false,
    },
    {
      'title': 'Marketing Campaigns',
      'subtitle': 'Promotional messages and offers',
      'icon': Icons.campaign_outlined,
      'email': false,
      'sms': false,
      'push': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                _ChannelLabel('Email'),
                _ChannelLabel('SMS'),
                _ChannelLabel('Push'),
              ],
            ),
          ),
          ...List.generate(_settings.length, (i) {
            final s = _settings[i];
            return Padding(
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
                    child: Icon(
                      s['icon'] as IconData,
                      size: 16,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          s['subtitle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MiniToggle(
                    value: s['email'] as bool,
                    onChanged: (v) => setState(() => _settings[i]['email'] = v),
                  ),
                  _MiniToggle(
                    value: s['sms'] as bool,
                    onChanged: (v) => setState(() => _settings[i]['sms'] = v),
                  ),
                  _MiniToggle(
                    value: s['push'] as bool,
                    onChanged: (v) => setState(() => _settings[i]['push'] = v),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChannelLabel extends StatelessWidget {
  final String label;
  const _ChannelLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Transform.scale(
        scale: 0.75,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.secondary,
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
