import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';
import './ob_step_wrapper.dart';

/// Step 6: Business hours configuration.
class ObStepHoursWidget extends StatefulWidget {
  const ObStepHoursWidget({super.key});

  @override
  State<ObStepHoursWidget> createState() => _ObStepHoursWidgetState();
}

class _ObStepHoursWidgetState extends State<ObStepHoursWidget> {
  Future<void> _onNext() async {
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.saveBusinessHours();
    if (ok && mounted) {
      provider.completeStep(OnboardingStep.businessHours);
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return ObStepWrapper(
      title: AppStrings.obStepTitleHours,
      subtitle: AppStrings.obStepSubtitleHours,
      isLoading: provider.isLoading,
      onBack: () => provider.goToStep(OnboardingStep.employees),
      onNext: _onNext,
      child: ObSectionCard(
        title: AppStrings.obWeeklySchedule,
        child: Column(
          children: provider.businessHours.map((day) {
            return _DayHoursRow(
              day: day,
              onChanged: (updated) => provider.updateDayHours(updated),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Returns the localized Spanish day abbreviation (3 chars) for a given day index.
String _localizedDayAbbr(int dayOfWeek) {
  const dayNames = [
    AppStrings.daySunday,
    AppStrings.dayMonday,
    AppStrings.dayTuesday,
    AppStrings.dayWednesday,
    AppStrings.dayThursday,
    AppStrings.dayFriday,
    AppStrings.daySaturday,
  ];
  final name = dayNames[dayOfWeek % 7];
  return name.length >= 3 ? name.substring(0, 3) : name;
}

class _DayHoursRow extends StatelessWidget {
  final OnboardingDayHours day;
  final ValueChanged<OnboardingDayHours> onChanged;

  const _DayHoursRow({required this.day, required this.onChanged});

  static const _times = [
    '00:00',
    '00:30',
    '01:00',
    '01:30',
    '02:00',
    '02:30',
    '03:00',
    '03:30',
    '04:00',
    '04:30',
    '05:00',
    '05:30',
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
    '22:30',
    '23:00',
    '23:30',
  ];

  String _format12h(String time24) {
    final parts = time24.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Day toggle
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Switch(
                  value: day.isOpen,
                  onChanged: (v) => onChanged(day.copyWith(isOpen: v)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _localizedDayAbbr(day.dayOfWeek),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: day.isOpen
                          ? AppTheme.primary
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (day.isOpen) ...[
            Expanded(
              child: _TimeDropdown(
                value: day.openTime,
                items: _times,
                onChanged: (v) => onChanged(day.copyWith(openTime: v)),
                format: _format12h,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '–',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              child: _TimeDropdown(
                value: day.closeTime,
                items: _times,
                onChanged: (v) => onChanged(day.copyWith(closeTime: v)),
                format: _format12h,
              ),
            ),
          ] else
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.closed,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String Function(String) format;

  const _TimeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      items: items
          .map((t) => DropdownMenuItem(value: t, child: Text(format(t))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
