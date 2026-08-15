import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';

/// Domain entity for an employee with service assignments.
class EmployeeWithServicesEntity {
  final String id;
  final String organizationId;
  final String? branchId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final List<String> serviceIds;
  final bool isActive;
  final DateTime createdAt;

  const EmployeeWithServicesEntity({
    required this.id,
    required this.organizationId,
    this.branchId,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.role,
    this.serviceIds = const [],
    this.isActive = true,
    required this.createdAt,
  });
}

/// Contract for employee data operations.
abstract interface class EmployeeRepository implements BaseRepository {
  Future<Result<List<EmployeeWithServicesEntity>>> getEmployees(
    String organizationId,
  );

  Future<Result<EmployeeWithServicesEntity>> getEmployeeById(String id);

  Future<Result<EmployeeWithServicesEntity>> createEmployee(
    EmployeeWithServicesEntity employee,
  );

  Future<Result<EmployeeWithServicesEntity>> updateEmployee(
    EmployeeWithServicesEntity employee,
  );

  Future<Result<void>> deactivateEmployee(String id);

  Future<Result<void>> assignServices(
    String employeeId,
    List<String> serviceIds,
  );
}
