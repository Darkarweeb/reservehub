/// Domain entity representing a service offered by a business.
class ServiceEntity {
  final String id;
  final String organizationId;
  final String? branchId;
  final String name;
  final String? description;
  final String? category;
  final Duration duration;
  final double price;
  final String? colorHex;
  final bool isActive;
  final List<String> employeeIds;
  final DateTime createdAt;

  const ServiceEntity({
    required this.id,
    required this.organizationId,
    this.branchId,
    required this.name,
    this.description,
    this.category,
    required this.duration,
    required this.price,
    this.colorHex,
    this.isActive = true,
    this.employeeIds = const [],
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ServiceEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Domain entity representing an employee.
class EmployeeEntity {
  final String id;
  final String organizationId;
  final String? branchId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? avatarLabel;
  final String? role;
  final List<String> serviceIds;
  final bool isActive;
  final DateTime createdAt;

  const EmployeeEntity({
    required this.id,
    required this.organizationId,
    this.branchId,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.avatarLabel,
    this.role,
    this.serviceIds = const [],
    this.isActive = true,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmployeeEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
