import '../../../appointments/domain/entities/appointment_entity.dart';

/// Data model for [AppointmentEntity] — maps Supabase appointments table.
class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.organizationId,
    super.branchId,
    required super.customerId,
    required super.employeeId,
    required super.serviceId,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.price,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      branchId: json['branch_id'] as String?,
      customerId:
          json['customer_id'] as String? ??
          json['guest_customer_id'] as String? ??
          '',
      employeeId: json['employee_id'] as String,
      serviceId: json['service_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['created_at'] as String,
      ),
    );
  }

  static AppointmentStatusEntity _parseStatus(String status) {
    return switch (status) {
      'confirmed' => AppointmentStatusEntity.confirmed,
      'checked_in' => AppointmentStatusEntity.checkedIn,
      'completed' => AppointmentStatusEntity.completed,
      'cancelled' => AppointmentStatusEntity.cancelled,
      'no_show' => AppointmentStatusEntity.noShow,
      _ => AppointmentStatusEntity.pending,
    };
  }

  static String statusToString(AppointmentStatusEntity status) {
    return switch (status) {
      AppointmentStatusEntity.pending => 'pending',
      AppointmentStatusEntity.confirmed => 'confirmed',
      AppointmentStatusEntity.checkedIn => 'checked_in',
      AppointmentStatusEntity.completed => 'completed',
      AppointmentStatusEntity.cancelled => 'cancelled',
      AppointmentStatusEntity.noShow => 'no_show',
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'branch_id': branchId,
    'customer_id': customerId,
    'employee_id': employeeId,
    'service_id': serviceId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'status': statusToString(status),
    'price': price,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
