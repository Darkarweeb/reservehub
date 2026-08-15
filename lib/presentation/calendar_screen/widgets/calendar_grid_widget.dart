import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/scheduling/domain/repositories/appointment_repository.dart';
import '../../../theme/app_theme.dart';

class CalendarGridWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final List<CalendarDaySummaryEntity> monthSummary;

  const CalendarGridWidget({
    required this.focusedMonth,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onMonthChanged,
    this.monthSummary = const [],
    super.key,
  });

  static const List<String> _weekdays = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool _hasAppointments(int day) {
    return monthSummary.any(
      (s) =>
          s.date.year == focusedMonth.year &&
          s.date.month == focusedMonth.month &&
          s.date.day == day &&
          s.hasAppointments,
    );
  }

  bool _hasBlock(int day) {
    return monthSummary.any(
      (s) =>
          s.date.year == focusedMonth.year &&
          s.date.month == focusedMonth.month &&
          s.date.day == day &&
          s.hasBlock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final startOffset = (firstDay.weekday - 1) % 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundLight,
                  foregroundColor: AppTheme.primary,
                ),
              ),
              Text(
                '${_months[focusedMonth.month - 1]} ${focusedMonth.year}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundLight,
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final isSelected =
                  selectedDay.year == date.year &&
                  selectedDay.month == date.month &&
                  selectedDay.day == date.day;
              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;
              final hasBusy = _hasAppointments(day);
              final hasBlock = _hasBlock(day);

              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : isToday
                        ? AppTheme.secondaryContainer
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? AppTheme.secondary
                              : const Color(0xFF374151),
                        ),
                      ),
                      // Appointment dot (blue)
                      if (hasBusy && !isSelected)
                        Positioned(
                          bottom: 2,
                          left: hasBlock ? 8 : null,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      // Block dot (amber)
                      if (hasBlock && !isSelected)
                        Positioned(
                          bottom: 2,
                          right: hasBusy ? 8 : null,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
