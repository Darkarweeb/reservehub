import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/appointment_entity.dart';

/// Contract for appointment data operations.
abstract interface class AppointmentRepository implements BaseRepository {
  /// Fetches appointments for a given date range.
  Future<Result<List<AppointmentEntity>>> getAppointments({
    required DateTime from,
    required DateTime to,
    String? employeeId,
    String? customerId,
    AppointmentStatusEntity? status,
  });

  /// Fetches a single appointment by ID.
  Future<Result<AppointmentEntity>> getAppointmentById(String id);

  /// Creates a new appointment.
  Future<Result<AppointmentEntity>> createAppointment(
    AppointmentEntity appointment,
  );

  /// Updates an existing appointment.
  Future<Result<AppointmentEntity>> updateAppointment(
    AppointmentEntity appointment,
  );

  /// Cancels an appointment.
  Future<Result<void>> cancelAppointment(String id, {String? reason});

  /// Marks an appointment as no-show.
  Future<Result<void>> markNoShow(String id);

  /// Checks for scheduling conflicts.
  Future<Result<bool>> hasConflict({
    required String employeeId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  });
}
