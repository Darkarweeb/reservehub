import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final SupabaseClient _client;

  const AppointmentRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<Map<String, dynamic>>> getBusinessAppointments({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_business_appointments',
        params: {
          'p_date_from': dateFrom.toIso8601String().substring(0, 10),
          'p_date_to': dateTo.toIso8601String().substring(0, 10),
          'p_branch_id': branchId,
        },
      );

      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return success(data);
      }
      return failure(
        ServerFailure(
          message: data['message'] as String? ?? 'Failed to load appointments.',
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'getBusinessAppointments failed',
        tag: 'AppointmentRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<List<CalendarDaySummaryEntity>>> getCalendarMonthSummary({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _client.rpc(
        'get_calendar_month_summary',
        params: {'p_year': year, 'p_month': month},
      );

      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        final days = (data['days'] as List<dynamic>? ?? [])
            .map(
              (d) => CalendarDaySummaryEntity(
                date: DateTime.parse(d['date'] as String),
                appointmentCount: (d['appointment_count'] as num).toInt(),
                hasBlock: d['has_block'] as bool? ?? false,
              ),
            )
            .toList();
        return success(days);
      }
      return failure(
        ServerFailure(
          message:
              data['message'] as String? ?? 'Failed to load calendar summary.',
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'getCalendarMonthSummary failed',
        tag: 'AppointmentRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
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
  }) async {
    try {
      final response = await _client.rpc(
        'create_manual_appointment',
        params: {
          'p_branch_id': branchId,
          'p_service_id': serviceId,
          'p_employee_id': employeeId,
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_customer_name': customerName,
          'p_customer_id': customerId,
          'p_notes': notes,
          'p_internal_notes': internalNotes,
          'p_booking_source': bookingSource,
        },
      );

      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return success(data['appointment_id'] as String);
      }
      return failure(
        ConflictFailure(
          message:
              data['message'] as String? ?? 'Failed to create appointment.',
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'createManualAppointment failed',
        tag: 'AppointmentRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> cancelAppointment(String id, {String? reason}) async {
    try {
      await _client
          .from('appointments')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toUtc().toIso8601String(),
            'cancellation_reason': reason,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      return success(null);
    } catch (e, st) {
      AppLogger.error(
        'cancelAppointment failed',
        tag: 'AppointmentRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> markNoShow(String id) async {
    try {
      await _client
          .from('appointments')
          .update({
            'status': 'no_show',
            'no_show_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      return success(null);
    } catch (e, st) {
      AppLogger.error('markNoShow failed', tag: 'AppointmentRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  void dispose() {}
}

// ─── Helper: parse appointment status ────────────────────────────────────────
AppointmentStatusEntity _parseStatus(String s) {
  return switch (s) {
    'confirmed' => AppointmentStatusEntity.confirmed,
    'checked_in' => AppointmentStatusEntity.checkedIn,
    'in_progress' => AppointmentStatusEntity.inProgress,
    'completed' => AppointmentStatusEntity.completed,
    'cancelled' => AppointmentStatusEntity.cancelled,
    'no_show' => AppointmentStatusEntity.noShow,
    'rescheduled' => AppointmentStatusEntity.rescheduled,
    'waitlisted' => AppointmentStatusEntity.waitlisted,
    _ => AppointmentStatusEntity.pending,
  };
}

/// Maps a raw RPC appointment map to [CalendarAppointmentEntity].
CalendarAppointmentEntity calendarAppointmentFromJson(
  Map<String, dynamic> json,
) {
  return CalendarAppointmentEntity(
    id: json['id'] as String,
    title: json['title'] as String?,
    status: _parseStatus(json['status'] as String? ?? 'pending'),
    startsAt: DateTime.parse(json['starts_at'] as String),
    endsAt: DateTime.parse(json['ends_at'] as String),
    durationMins: (json['duration_mins'] as num).toInt(),
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'USD',
    notes: json['notes'] as String?,
    internalNotes: json['internal_notes'] as String?,
    bookingSource: json['booking_source'] as String?,
    bookedOnline: json['booked_online'] as bool? ?? false,
    branchId: json['branch_id'] as String?,
    customerId: json['customer_id'] as String?,
    customerName: json['customer_name'] as String?,
    serviceName: json['service_name'] as String?,
    employeeId: json['employee_id'] as String?,
    employeeName: json['employee_name'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
