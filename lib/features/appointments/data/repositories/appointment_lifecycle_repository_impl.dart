import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/appointment_lifecycle_entity.dart';
import '../../domain/repositories/appointment_lifecycle_repository.dart';

class AppointmentLifecycleRepositoryImpl
    implements AppointmentLifecycleRepository {
  final SupabaseClient _client;

  const AppointmentLifecycleRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<AppointmentDetailEntity>> getAppointmentDetail(
    String id,
  ) async {
    try {
      final response = await _client.rpc(
        'get_appointment_detail',
        params: {'p_appointment_id': id},
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        final appt = data['appointment'] as Map<String, dynamic>;
        return success(_parseDetail(appt));
      }
      return failure(
        ServerFailure(
          message: data['message'] as String? ?? 'Failed to load appointment.',
        ),
      );
    } catch (e, st) {
      AppLogger.error('getAppointmentDetail', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<List<AppointmentAuditEntry>>> getAuditHistory(String id) async {
    try {
      final response = await _client.rpc(
        'get_appointment_audit_history',
        params: {'p_appointment_id': id},
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        final history = (data['history'] as List<dynamic>? ?? [])
            .map((e) => _parseAuditEntry(e as Map<String, dynamic>))
            .toList();
        return success(history);
      }
      return failure(
        ServerFailure(
          message: data['message'] as String? ?? 'Failed to load history.',
        ),
      );
    } catch (e, st) {
      AppLogger.error('getAuditHistory', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> confirmAppointment(String id, {String? notes}) async {
    try {
      final response = await _client.rpc(
        'confirm_appointment',
        params: {'p_appointment_id': id, 'p_notes': notes},
      );
      return _handleVoidResponse(response);
    } catch (e, st) {
      AppLogger.error('confirmAppointment', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> cancelAppointmentBusiness(
    String id, {
    String? reason,
  }) async {
    try {
      final response = await _client.rpc(
        'cancel_appointment_business',
        params: {'p_appointment_id': id, 'p_cancellation_reason': reason},
      );
      return _handleVoidResponse(response);
    } catch (e, st) {
      AppLogger.error(
        'cancelAppointmentBusiness',
        tag: 'LifecycleRepo',
        error: e,
      );
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> completeAppointment(String id, {String? notes}) async {
    try {
      final response = await _client.rpc(
        'complete_appointment',
        params: {'p_appointment_id': id, 'p_notes': notes},
      );
      return _handleVoidResponse(response);
    } catch (e, st) {
      AppLogger.error('completeAppointment', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> markNoShow(String id, {String? reason}) async {
    try {
      final response = await _client.rpc(
        'mark_appointment_no_show',
        params: {'p_appointment_id': id, 'p_reason': reason},
      );
      return _handleVoidResponse(response);
    } catch (e, st) {
      AppLogger.error('markNoShow', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> startAppointment(String id) async {
    try {
      final response = await _client.rpc(
        'start_appointment',
        params: {'p_appointment_id': id},
      );
      return _handleVoidResponse(response);
    } catch (e, st) {
      AppLogger.error('startAppointment', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<RescheduleResult>> rescheduleAppointment(
    RescheduleRequest request,
  ) async {
    try {
      final response = await _client.rpc(
        'reschedule_appointment',
        params: {
          'p_appointment_id': request.appointmentId,
          'p_new_starts_at': request.newStartsAt.toUtc().toIso8601String(),
          'p_new_employee_id': request.newEmployeeId,
          'p_new_branch_id': request.newBranchId,
          'p_reason': request.reason,
        },
      );
      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return success(
          RescheduleResult(
            oldAppointmentId: data['old_appointment_id'] as String,
            newAppointmentId: data['new_appointment_id'] as String,
            newStartsAt: DateTime.parse(data['new_starts_at'] as String),
          ),
        );
      }
      return failure(
        ConflictFailure(
          message:
              data['message'] as String? ?? 'Failed to reschedule appointment.',
        ),
      );
    } catch (e, st) {
      AppLogger.error('rescheduleAppointment', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<BulkOperationResult>> bulkConfirm(List<String> ids) async {
    try {
      final response = await _client.rpc(
        'bulk_confirm_appointments',
        params: {'p_appointment_ids': ids},
      );
      return _handleBulkResponse(response);
    } catch (e, st) {
      AppLogger.error('bulkConfirm', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<BulkOperationResult>> bulkCancel(
    List<String> ids, {
    String? reason,
  }) async {
    try {
      final response = await _client.rpc(
        'bulk_cancel_appointments',
        params: {'p_appointment_ids': ids, 'p_reason': reason},
      );
      return _handleBulkResponse(response);
    } catch (e, st) {
      AppLogger.error('bulkCancel', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  Future<Result<BulkOperationResult>> bulkComplete(List<String> ids) async {
    try {
      final response = await _client.rpc(
        'bulk_complete_appointments',
        params: {'p_appointment_ids': ids},
      );
      return _handleBulkResponse(response);
    } catch (e, st) {
      AppLogger.error('bulkComplete', tag: 'LifecycleRepo', error: e);
      return failure(ServerFailure(message: _friendlyError(e), stackTrace: st));
    }
  }

  @override
  void dispose() {}

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Result<void> _handleVoidResponse(dynamic response) {
    final data = response as Map<String, dynamic>;
    if (data['status'] == 'success') return success(null);
    return failure(
      ServerFailure(message: data['message'] as String? ?? 'Operation failed.'),
    );
  }

  Result<BulkOperationResult> _handleBulkResponse(dynamic response) {
    final data = response as Map<String, dynamic>;
    if (data['status'] == 'success') {
      return success(
        BulkOperationResult(
          succeeded:
              (data['confirmed'] as int?) ??
              (data['cancelled'] as int?) ??
              (data['completed'] as int?) ??
              0,
          failed: (data['failed'] as int?) ?? 0,
        ),
      );
    }
    return failure(
      ServerFailure(
        message: data['message'] as String? ?? 'Bulk operation failed.',
      ),
    );
  }

  AppointmentDetailEntity _parseDetail(Map<String, dynamic> j) {
    return AppointmentDetailEntity(
      id: j['id'] as String,
      organizationId: j['organization_id'] as String,
      businessId: j['business_id'] as String,
      branchId: j['branch_id'] as String?,
      customerId: j['customer_id'] as String?,
      status: AppointmentLifecycleStatusExt.fromDb(
        j['status'] as String? ?? 'pending',
      ),
      title: j['title'] as String?,
      notes: j['notes'] as String?,
      internalNotes: j['internal_notes'] as String?,
      startsAt: DateTime.parse(j['starts_at'] as String),
      endsAt: DateTime.parse(j['ends_at'] as String),
      durationMins: (j['duration_mins'] as num).toInt(),
      totalPrice: (j['total_price'] as num?)?.toDouble() ?? 0.0,
      currency: j['currency'] as String? ?? 'USD',
      bookingSource: j['booking_source'] as String?,
      bookedOnline: j['booked_online'] as bool? ?? false,
      confirmedAt: j['confirmed_at'] != null
          ? DateTime.parse(j['confirmed_at'] as String)
          : null,
      completedAt: j['completed_at'] != null
          ? DateTime.parse(j['completed_at'] as String)
          : null,
      cancelledAt: j['cancelled_at'] != null
          ? DateTime.parse(j['cancelled_at'] as String)
          : null,
      cancellationReason: j['cancellation_reason'] as String?,
      noShowAt: j['no_show_at'] != null
          ? DateTime.parse(j['no_show_at'] as String)
          : null,
      noShowReason: j['no_show_reason'] as String?,
      inProgressAt: j['in_progress_at'] != null
          ? DateTime.parse(j['in_progress_at'] as String)
          : null,
      rescheduledAt: j['rescheduled_at'] != null
          ? DateTime.parse(j['rescheduled_at'] as String)
          : null,
      rescheduledFromId: j['rescheduled_from_id'] as String?,
      customerName: j['customer_name'] as String?,
      customerEmail: j['customer_email'] as String?,
      customerPhone: j['customer_phone'] as String?,
      branchName: j['branch_name'] as String?,
      businessName: j['business_name'] as String?,
      services: _parseServices(j['services']),
      employees: _parseEmployees(j['employees']),
      confirmedByName: j['confirmed_by_name'] as String?,
      cancelledByName: j['cancelled_by_name'] as String?,
      completedByName: j['completed_by_name'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }

  List<AppointmentServiceDetail> _parseServices(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map(
          (s) => AppointmentServiceDetail(
            serviceId: s['service_id'] as String,
            serviceName: s['service_name'] as String,
            durationMins: (s['duration_mins'] as num).toInt(),
            price: (s['price'] as num?)?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  List<AppointmentEmployeeDetail> _parseEmployees(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map(
          (e) => AppointmentEmployeeDetail(
            employeeId: e['employee_id'] as String,
            employeeName: e['employee_name'] as String? ?? '—',
            isPrimary: e['is_primary'] as bool? ?? false,
          ),
        )
        .toList();
  }

  AppointmentAuditEntry _parseAuditEntry(Map<String, dynamic> j) {
    return AppointmentAuditEntry(
      id: j['id'] as String,
      action: j['action'] as String,
      actorEmail: j['actor_email'] as String?,
      oldValues: j['old_values'] as Map<String, dynamic>?,
      newValues: j['new_values'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('not found')) return 'Appointment not found.';
    if (msg.contains('unauthorized') || msg.contains('access denied')) {
      return 'You are not authorized to perform this action.';
    }
    if (msg.contains('not available') || msg.contains('conflict')) {
      return 'The selected time slot is not available.';
    }
    if (msg.contains('cannot') || msg.contains('invalid')) {
      return 'This action is not allowed for the current appointment status.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Please check your connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
