import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class SettingsWorkingHoursWidget extends StatefulWidget {
  const SettingsWorkingHoursWidget({super.key});

  @override
  State<SettingsWorkingHoursWidget> createState() =>
      _SettingsWorkingHoursWidgetState();
}

class _SettingsWorkingHoursWidgetState
    extends State<SettingsWorkingHoursWidget> {
  // TODO: Replace with Riverpod WorkingHoursNotifier for production
  final List<Map<String, dynamic>> _hours = [
    {'day': 'Monday', 'open': true, 'start': '09:00', 'end': '19:00'},
    {'day': 'Tuesday', 'open': true, 'start': '09:00', 'end': '19:00'},
    {'day': 'Wednesday', 'open': true, 'start': '09:00', 'end': '19:00'},
    {'day': 'Thursday', 'open': true, 'start': '09:00', 'end': '20:00'},
    {'day': 'Friday', 'open': true, 'start': '09:00', 'end': '20:00'},
    {'day': 'Saturday', 'open': true, 'start': '10:00', 'end': '18:00'},
    {'day': 'Sunday', 'open': false, 'start': '10:00', 'end': '16:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionWidget(
      title: 'Working Hours',
      icon: Icons.schedule_outlined,
      child: Column(
        children: List.generate(_hours.length, (i) {
          final h = _hours[i];
          final isOpen = h['open'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    h['day'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOpen
                          ? AppTheme.primary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (v) => setState(() => _hours[i]['open'] = v),
                  activeThumbColor: AppTheme.secondary,
                ),
                if (isOpen) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _TimeChip(time: h['start'] as String)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '–',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Expanded(child: _TimeChip(time: h['end'] as String)),
                      ],
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Closed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  const _TimeChip({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SettingsSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSectionWidget({
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
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
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
