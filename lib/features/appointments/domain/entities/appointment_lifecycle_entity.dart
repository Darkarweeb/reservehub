/// Extended appointment status enum aligned with DB appointment_status ENUM.
/// Adds in_progress and rescheduled states missing from the base entity.
enum AppointmentLifecycleStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
  rescheduled,
  waitlisted,
}

extension AppointmentLifecycleStatusExt on AppointmentLifecycleStatus {
  String get dbValue => switch (this) {
    AppointmentLifecycleStatus.pending => 'pending',
    AppointmentLifecycleStatus.confirmed => 'confirmed',
    AppointmentLifecycleStatus.inProgress => 'in_progress',
    AppointmentLifecycleStatus.completed => 'completed',
    AppointmentLifecycleStatus.cancelled => 'cancelled',
    AppointmentLifecycleStatus.noShow => 'no_show',
    AppointmentLifecycleStatus.rescheduled => 'rescheduled',
    AppointmentLifecycleStatus.waitlisted => 'waitlisted',
  };

  String get label => switch (this) {
    AppointmentLifecycleStatus.pending => 'Pending',
    AppointmentLifecycleStatus.confirmed => 'Confirmed',
    AppointmentLifecycleStatus.inProgress => 'In Progress',
    AppointmentLifecycleStatus.completed => 'Completed',
    AppointmentLifecycleStatus.cancelled => 'Cancelled',
    AppointmentLifecycleStatus.noShow => 'No Show',
    AppointmentLifecycleStatus.rescheduled => 'Rescheduled',
    AppointmentLifecycleStatus.waitlisted => 'Waitlisted',
  };

  bool get isTerminal => switch (this) {
    AppointmentLifecycleStatus.completed ||
    AppointmentLifecycleStatus.cancelled ||
    AppointmentLifecycleStatus.noShow ||
    AppointmentLifecycleStatus.rescheduled => true,
    _ => false,
  };

  /// Returns valid next states from this state.
  List<AppointmentLifecycleStatus> get validTransitions => switch (this) {
    AppointmentLifecycleStatus.pending => [
      AppointmentLifecycleStatus.confirmed,
      AppointmentLifecycleStatus.cancelled,
    ],
    AppointmentLifecycleStatus.confirmed => [
      AppointmentLifecycleStatus.inProgress,
      AppointmentLifecycleStatus.completed,
      AppointmentLifecycleStatus.cancelled,
      AppointmentLifecycleStatus.noShow,
      AppointmentLifecycleStatus.rescheduled,
    ],
    AppointmentLifecycleStatus.inProgress => [
      AppointmentLifecycleStatus.completed,
      AppointmentLifecycleStatus.cancelled,
    ],
    AppointmentLifecycleStatus.rescheduled => [
      AppointmentLifecycleStatus.confirmed,
      AppointmentLifecycleStatus.cancelled,
    ],
    AppointmentLifecycleStatus.waitlisted => [
      AppointmentLifecycleStatus.confirmed,
      AppointmentLifecycleStatus.cancelled,
    ],
    _ => [],
  };

  bool canTransitionTo(AppointmentLifecycleStatus next) =>
      validTransitions.contains(next);

  static AppointmentLifecycleStatus fromDb(String s) => switch (s) {
    'confirmed' => AppointmentLifecycleStatus.confirmed,
    'in_progress' => AppointmentLifecycleStatus.inProgress,
    'completed' => AppointmentLifecycleStatus.completed,
    'cancelled' => AppointmentLifecycleStatus.cancelled,
    'no_show' => AppointmentLifecycleStatus.noShow,
    'rescheduled' => AppointmentLifecycleStatus.rescheduled,
    'waitlisted' => AppointmentLifecycleStatus.waitlisted,
    _ => AppointmentLifecycleStatus.pending,
  };
}

/// Rich appointment detail entity returned by get_appointment_detail RPC.
class AppointmentDetailEntity {
  final String id;
  final String organizationId;
  final String businessId;
  final String? branchId;
  final String? customerId;
  final AppointmentLifecycleStatus status;
  final String? title;
  final String? notes;
  final String? internalNotes;
  final DateTime startsAt;
  final DateTime endsAt;
  final int durationMins;
  final double totalPrice;
  final String currency;
  final String? bookingSource;
  final bool bookedOnline;

  // Lifecycle timestamps
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? noShowAt;
  final String? noShowReason;
  final DateTime? inProgressAt;
  final DateTime? rescheduledAt;
  final String? rescheduledFromId;

  // Joined data
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? branchName;
  final String? businessName;
  final List<AppointmentServiceDetail> services;
  final List<AppointmentEmployeeDetail> employees;
  final String? confirmedByName;
  final String? cancelledByName;
  final String? completedByName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentDetailEntity({
    required this.id,
    required this.organizationId,
    required this.businessId,
    this.branchId,
    this.customerId,
    required this.status,
    this.title,
    this.notes,
    this.internalNotes,
    required this.startsAt,
    required this.endsAt,
    required this.durationMins,
    required this.totalPrice,
    required this.currency,
    this.bookingSource,
    required this.bookedOnline,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.noShowAt,
    this.noShowReason,
    this.inProgressAt,
    this.rescheduledAt,
    this.rescheduledFromId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.branchName,
    this.businessName,
    this.services = const [],
    this.employees = const [],
    this.confirmedByName,
    this.cancelledByName,
    this.completedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTitle =>
      title ??
      (customerName != null
          ? '$customerName — ${services.isNotEmpty ? services.first.serviceName : ''}'
          : 'Appointment');
}

class AppointmentServiceDetail {
  final String serviceId;
  final String serviceName;
  final int durationMins;
  final double price;

  const AppointmentServiceDetail({
    required this.serviceId,
    required this.serviceName,
    required this.durationMins,
    required this.price,
  });
}

class AppointmentEmployeeDetail {
  final String employeeId;
  final String employeeName;
  final bool isPrimary;

  const AppointmentEmployeeDetail({
    required this.employeeId,
    required this.employeeName,
    required this.isPrimary,
  });
}

/// Audit history entry for an appointment.
class AppointmentAuditEntry {
  final String id;
  final String action;
  final String? actorEmail;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;

  const AppointmentAuditEntry({
    required this.id,
    required this.action,
    this.actorEmail,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  String get actionLabel => switch (action) {
    'appointment.confirmed' => 'Confirmed',
    'appointment.cancelled' => 'Cancelled',
    'appointment.completed' => 'Completed',
    'appointment.no_show' => 'Marked No-Show',
    'appointment.in_progress' => 'Started',
    'appointment.rescheduled' => 'Rescheduled',
    _ => action,
  };
}

/// Request to reschedule an appointment.
class RescheduleRequest {
  final String appointmentId;
  final DateTime newStartsAt;
  final String? newEmployeeId;
  final String? newBranchId;
  final String? reason;

  const RescheduleRequest({
    required this.appointmentId,
    required this.newStartsAt,
    this.newEmployeeId,
    this.newBranchId,
    this.reason,
  });
}

/// Result of a reschedule operation.
class RescheduleResult {
  final String oldAppointmentId;
  final String newAppointmentId;
  final DateTime newStartsAt;

  const RescheduleResult({
    required this.oldAppointmentId,
    required this.newAppointmentId,
    required this.newStartsAt,
  });
}

/// Result of a bulk operation.
class BulkOperationResult {
  final int succeeded;
  final int failed;
  final List<String> errors;

  const BulkOperationResult({
    required this.succeeded,
    required this.failed,
    this.errors = const [],
  });
}
