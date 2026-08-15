/// Domain entity representing a calendar day with appointment metadata.
class CalendarDayEntity {
  final DateTime date;
  final int appointmentCount;
  final bool hasConflict;

  const CalendarDayEntity({
    required this.date,
    required this.appointmentCount,
    this.hasConflict = false,
  });

  bool get hasAppointments => appointmentCount > 0;
}
