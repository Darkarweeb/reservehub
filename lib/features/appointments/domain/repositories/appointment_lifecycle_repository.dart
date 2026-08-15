import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/appointment_lifecycle_entity.dart';

/// Contract for appointment lifecycle operations.
abstract interface class AppointmentLifecycleRepository
    implements BaseRepository {
  /// Fetches full appointment detail (joined data).
  Future<Result<AppointmentDetailEntity>> getAppointmentDetail(String id);

  /// Fetches audit history for an appointment.
  Future<Result<List<AppointmentAuditEntry>>> getAuditHistory(String id);

  /// Confirms a pending appointment.
  Future<Result<void>> confirmAppointment(String id, {String? notes});

  /// Cancels an appointment (business-side).
  Future<Result<void>> cancelAppointmentBusiness(String id, {String? reason});

  /// Marks an appointment as completed.
  Future<Result<void>> completeAppointment(String id, {String? notes});

  /// Marks an appointment as no-show.
  Future<Result<void>> markNoShow(String id, {String? reason});

  /// Transitions a confirmed appointment to in_progress.
  Future<Result<void>> startAppointment(String id);

  /// Reschedules an appointment to a new time slot via server-side validation.
  Future<Result<RescheduleResult>> rescheduleAppointment(
    RescheduleRequest request,
  );

  /// Bulk confirms multiple appointments.
  Future<Result<BulkOperationResult>> bulkConfirm(List<String> ids);

  /// Bulk cancels multiple appointments.
  Future<Result<BulkOperationResult>> bulkCancel(
    List<String> ids, {
    String? reason,
  });

  /// Bulk completes multiple appointments.
  Future<Result<BulkOperationResult>> bulkComplete(List<String> ids);
}