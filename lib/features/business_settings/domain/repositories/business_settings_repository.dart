import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/organization_entity.dart';
import '../entities/business_entities.dart';

/// Contract for business settings data operations.
abstract interface class BusinessSettingsRepository implements BaseRepository {
  /// Fetches the organization profile.
  Future<Result<OrganizationEntity>> getOrganization(String organizationId);

  /// Updates the organization profile.
  Future<Result<OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  );

  /// Fetches all services for an organization.
  Future<Result<List<ServiceEntity>>> getServices(String organizationId);

  /// Creates a new service.
  Future<Result<ServiceEntity>> createService(ServiceEntity service);

  /// Updates an existing service.
  Future<Result<ServiceEntity>> updateService(ServiceEntity service);

  /// Deletes a service.
  Future<Result<void>> deleteService(String serviceId);

  /// Fetches all employees for an organization.
  Future<Result<List<EmployeeEntity>>> getEmployees(String organizationId);

  /// Creates a new employee.
  Future<Result<EmployeeEntity>> createEmployee(EmployeeEntity employee);

  /// Updates an existing employee.
  Future<Result<EmployeeEntity>> updateEmployee(EmployeeEntity employee);

  /// Deactivates an employee.
  Future<Result<void>> deactivateEmployee(String employeeId);
}
