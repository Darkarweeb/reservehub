/// Domain entity representing an appointment.
class AppointmentEntity {
  final String id;
  final String organizationId;
  final String? branchId;
  final String customerId;
  final String employeeId;
  final String serviceId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatusEntity status;
  final double price;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentEntity({
    required this.id,
    required this.organizationId,
    this.branchId,
    required this.customerId,
    required this.employeeId,
    required this.serviceId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => endTime.difference(startTime);

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());

  AppointmentEntity copyWith({
    AppointmentStatusEntity? status,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return AppointmentEntity(
      id: id,
      organizationId: organizationId,
      branchId: branchId,
      customerId: customerId,
      employeeId: employeeId,
      serviceId: serviceId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      price: price,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppointmentEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum AppointmentStatusEntity {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  noShow,
}
