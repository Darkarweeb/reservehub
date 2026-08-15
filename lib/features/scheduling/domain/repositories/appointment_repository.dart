import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';

/// Rich calendar appointment view model (includes joined data from RPC).
class CalendarAppointmentEntity {
  final String id;
  final String? title;
  final AppointmentStatusEntity status;
  final DateTime startsAt;
  final DateTime endsAt;
  final int durationMins;
  final double totalPrice;
  final String currency;
  final String? notes;
  final String? internalNotes;
  final String? bookingSource;
  final bool bookedOnline;
  final String? branchId;
  final String? customerId;
  final String? customerName;
  final String? serviceName;
  final String? employeeId;
  final String? employeeName;
  final DateTime createdAt;

  const CalendarAppointmentEntity({
    required this.id,
    this.title,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.durationMins,
    required this.totalPrice,
    required this.currency,
    this.notes,
    this.internalNotes,
    this.bookingSource,
    required this.bookedOnline,
    this.branchId,
    this.customerId,
    this.customerName,
    this.serviceName,
    this.employeeId,
    this.employeeName,
    required this.createdAt,
  });

  bool get isManual => !(bookedOnline);
  bool get isUpcoming => startsAt.isAfter(DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarAppointmentEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Calendar day summary for month grid dots.
class CalendarDaySummaryEntity {
  final DateTime date;
  final int appointmentCount;
  final bool hasBlock;

  const CalendarDaySummaryEntity({
    required this.date,
    required this.appointmentCount,
    this.hasBlock = false,
  });

  bool get hasAppointments => appointmentCount > 0;
}

/// Contract for appointment data operations.
abstract interface class AppointmentRepository implements BaseRepository {
  /// Fetches appointments and time blocks for a date range (calendar dashboard).
  Future<Result<Map<String, dynamic>>> getBusinessAppointments({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  });

  /// Fetches per-day summary for the calendar month grid.
  Future<Result<List<CalendarDaySummaryEntity>>> getCalendarMonthSummary({
    required int year,
    required int month,
  });

  /// Creates a manual appointment via authenticated RPC.
  Future<Result<String>> createManualAppointment({
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime startsAt,
    required String customerName,
    String? customerId,
    String? notes,
    String? internalNotes,
    String bookingSource = 'manual',
  });

  /// Cancels an appointment.
  Future<Result<void>> cancelAppointment(String id, {String? reason});

  /// Marks an appointment as no-show.
  Future<Result<void>> markNoShow(String id);
}
