import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/repositories/appointment_repository.dart';

// Re-export entity for convenience
export '../../domain/repositories/appointment_repository.dart'
    show CalendarAppointmentEntity, CalendarDaySummaryEntity;
export '../../../appointments/domain/entities/appointment_entity.dart'
    show AppointmentStatusEntity;

/// State for the business calendar dashboard.
class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository _repository;

  List<CalendarAppointmentEntity> _appointments = [];
  List<Map<String, dynamic>> _timeBlocks = [];
  List<CalendarDaySummaryEntity> _monthSummary = [];

  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  String? _successMessage;

  AppointmentProvider({required AppointmentRepository repository})
      : _repository = repository;

  List<CalendarAppointmentEntity> get appointments => List.unmodifiable(_appointments);
  List<Map<String, dynamic>> get timeBlocks => List.unmodifiable(_timeBlocks);
  List<CalendarDaySummaryEntity> get monthSummary => List.unmodifiable(_monthSummary);
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Returns appointments for a specific day.
  List<CalendarAppointmentEntity> appointmentsForDay(DateTime day) {
    return _appointments.where((a) {
      final d = a.startsAt.toLocal();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  /// Returns time blocks for a specific day.
  List<Map<String, dynamic>> timeBlocksForDay(DateTime day) {
    return _timeBlocks.where((b) {
      final dateStr = b['block_date'] as String?;
      if (dateStr == null) return false;
      final d = DateTime.parse(dateStr);
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  /// Returns the day summary for a specific day (for calendar grid dots).
  CalendarDaySummaryEntity? summaryForDay(DateTime day) {
    try {
      return _monthSummary.firstWhere(
        (s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Loads appointments and time blocks for a date range.
  Future<void> loadAppointments({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getBusinessAppointments(
      dateFrom: dateFrom,
      dateTo: dateTo,
      branchId: branchId,
    );

    result.fold(
      onSuccess: (data) {
        final rawAppts = data['appointments'] as List<dynamic>? ?? [];
        _appointments = rawAppts
            .map((a) => calendarAppointmentFromJson(a as Map<String, dynamic>))
            .toList();

        final rawBlocks = data['time_blocks'] as List<dynamic>? ?? [];
        _timeBlocks = rawBlocks.cast<Map<String, dynamic>>();
        _isLoading = false;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        AppLogger.error('loadAppointments error', tag: 'AppointmentProvider', error: failure.message);
      },
    );

    notifyListeners();
  }

  /// Loads month summary for calendar grid dots.
  Future<void> loadMonthSummary({required int year, required int month}) async {
    final result = await _repository.getCalendarMonthSummary(
      year: year,
      month: month,
    );

    result.fold(
      onSuccess: (summary) {
        _monthSummary = summary;
      },
      onFailure: (failure) {
        AppLogger.error('loadMonthSummary error', tag: 'AppointmentProvider', error: failure.message);
      },
    );

    notifyListeners();
  }

  /// Creates a manual appointment.
  Future<bool> createManualAppointment({
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime startsAt,
    required String customerName,
    String? customerId,
    String? notes,
    String? internalNotes,
    String bookingSource = 'manual',
  }) async {
    _isCreating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.createManualAppointment(
      branchId: branchId,
      serviceId: serviceId,
      employeeId: employeeId,
      startsAt: startsAt,
      customerName: customerName,
      customerId: customerId,
      notes: notes,
      internalNotes: internalNotes,
      bookingSource: bookingSource,
    );

    _isCreating = false;

    return result.fold(
      onSuccess: (_) {
        _successMessage = 'Appointment created successfully.';
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  /// Cancels an appointment and refreshes the local list.
  Future<bool> cancelAppointment(String id, {String? reason}) async {
    final result = await _repository.cancelAppointment(id, reason: reason);
    return result.fold(
      onSuccess: (_) {
        _appointments = _appointments.map((a) {
          if (a.id == id) {
            return CalendarAppointmentEntity(
              id: a.id,
              title: a.title,
              status: AppointmentStatusEntity.cancelled,
              startsAt: a.startsAt,
              endsAt: a.endsAt,
              durationMins: a.durationMins,
              totalPrice: a.totalPrice,
              currency: a.currency,
              notes: a.notes,
              internalNotes: a.internalNotes,
              bookingSource: a.bookingSource,
              bookedOnline: a.bookedOnline,
              branchId: a.branchId,
              customerId: a.customerId,
              customerName: a.customerName,
              serviceName: a.serviceName,
              employeeId: a.employeeId,
              employeeName: a.employeeName,
              createdAt: a.createdAt,
            );
          }
          return a;
        }).toList();
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}