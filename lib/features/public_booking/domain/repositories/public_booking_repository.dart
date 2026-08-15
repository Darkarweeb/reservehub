import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';

/// Domain entity for a guest customer booking token lookup.
class AppointmentTokenResult {
  final String appointmentId;
  final String tokenType;
  final String tokenStatus;
  final String customerName;
  final String? customerEmail;
  final String businessName;
  final String serviceName;
  final String? employeeName;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? branchName;
  final String? branchAddress;

  const AppointmentTokenResult({
    required this.appointmentId,
    required this.tokenType,
    required this.tokenStatus,
    required this.customerName,
    this.customerEmail,
    required this.businessName,
    required this.serviceName,
    this.employeeName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.branchName,
    this.branchAddress,
  });
}

/// Result of a public booking operation.
class PublicBookingResult {
  final String appointmentId;
  final String bookingToken;
  final String cancellationToken;
  final DateTime startTime;
  final DateTime endTime;
  final String serviceName;
  final String? employeeName;
  final String businessName;

  const PublicBookingResult({
    required this.appointmentId,
    required this.bookingToken,
    required this.cancellationToken,
    required this.startTime,
    required this.endTime,
    required this.serviceName,
    this.employeeName,
    required this.businessName,
  });
}

/// Contract for public booking operations (no auth required).
abstract interface class PublicBookingRepository implements BaseRepository {
  /// Books an appointment as a guest.
  Future<Result<PublicBookingResult>> bookAppointment({
    required String businessSlug,
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime startTime,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? notes,
  });

  /// Looks up an appointment by secure token.
  Future<Result<AppointmentTokenResult>> getAppointmentByToken(String token);

  /// Confirms an appointment via token.
  Future<Result<void>> confirmAppointmentByToken(String token);

  /// Cancels an appointment via token.
  Future<Result<void>> cancelAppointmentByToken(String token, {String? reason});

  /// Fetches available time slots for a service/employee/date.
  Future<Result<List<DateTime>>> getAvailableSlots({
    required String businessId,
    required String serviceId,
    required String employeeId,
    required DateTime date,
  });
}
