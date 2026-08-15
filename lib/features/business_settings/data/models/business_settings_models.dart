import '../../../business_settings/domain/entities/business_entities.dart';

/// Data model for [ServiceEntity] — maps Supabase services table.
class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.organizationId,
    super.branchId,
    required super.name,
    super.description,
    super.category,
    required super.duration,
    required super.price,
    super.colorHex,
    super.isActive,
    super.employeeIds,
    required super.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final durationMinutes = json['duration_minutes'] as int? ?? 60;
    return ServiceModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      branchId: json['branch_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      duration: Duration(minutes: durationMinutes),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      colorHex: json['color_hex'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      employeeIds:
          (json['employee_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'branch_id': branchId,
    'name': name,
    'description': description,
    'category': category,
    'duration_minutes': duration.inMinutes,
    'price': price,
    'color_hex': colorHex,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toInsertJson() => {
    'organization_id': organizationId,
    'branch_id': branchId,
    'name': name,
    'description': description,
    'category': category,
    'duration_minutes': duration.inMinutes,
    'price': price,
    'color_hex': colorHex,
    'is_active': isActive,
  };
}

/// Data model for [EmployeeEntity] — maps Supabase employees table.
class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.id,
    required super.organizationId,
    super.branchId,
    required super.name,
    super.email,
    super.phone,
    super.avatarUrl,
    super.avatarLabel,
    super.role,
    super.serviceIds,
    super.isActive,
    required super.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      branchId: json['branch_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarLabel: json['avatar_label'] as String?,
      role: json['role'] as String?,
      serviceIds:
          (json['service_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'branch_id': branchId,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
    'role': role,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toInsertJson() => {
    'organization_id': organizationId,
    'branch_id': branchId,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
    'role': role,
    'is_active': isActive,
  };
}
