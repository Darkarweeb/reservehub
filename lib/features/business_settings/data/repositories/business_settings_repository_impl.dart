import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/entities/business_entities.dart';
import '../../domain/repositories/business_settings_repository.dart';
import '../models/organization_model.dart';
import '../models/business_settings_models.dart';

/// Supabase implementation of [BusinessSettingsRepository].
class BusinessSettingsRepositoryImpl implements BusinessSettingsRepository {
  final SupabaseClient _client;

  BusinessSettingsRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<OrganizationEntity>> getOrganization(
    String organizationId,
  ) async {
    try {
      final response = await _client
          .from('organizations')
          .select()
          .eq('id', organizationId)
          .single();

      return success(OrganizationModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error(
        'getOrganization failed',
        tag: 'BizSettingsRepo',
        error: e,
      );
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getOrganization failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final model = organization is OrganizationModel
          ? organization
          : OrganizationModel(
              id: organization.id,
              name: organization.name,
              logoUrl: organization.logoUrl,
              email: organization.email,
              phone: organization.phone,
              website: organization.website,
              address: organization.address,
              timezone: organization.timezone,
              currency: organization.currency,
              locale: organization.locale,
              subscriptionTier: organization.subscriptionTier,
              isActive: organization.isActive,
              createdAt: organization.createdAt,
            );

      final response = await _client
          .from('organizations')
          .update(model.toUpdateJson())
          .eq('id', organization.id)
          .select()
          .single();

      return success(OrganizationModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error(
        'updateOrganization failed',
        tag: 'BizSettingsRepo',
        error: e,
      );
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'updateOrganization failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ServiceEntity>>> getServices(String organizationId) async {
    try {
      final response = await _client
          .from('services')
          .select()
          .eq('organization_id', organizationId)
          .order('name');

      final services = (response as List<dynamic>)
          .map((row) => ServiceModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return success(services);
    } on PostgrestException catch (e) {
      AppLogger.error('getServices failed', tag: 'BizSettingsRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getServices failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ServiceEntity>> createService(ServiceEntity service) async {
    try {
      final model = service is ServiceModel
          ? service
          : ServiceModel(
              id: service.id,
              organizationId: service.organizationId,
              branchId: service.branchId,
              name: service.name,
              description: service.description,
              category: service.category,
              duration: service.duration,
              price: service.price,
              colorHex: service.colorHex,
              isActive: service.isActive,
              createdAt: service.createdAt,
            );

      final response = await _client
          .from('services')
          .insert(model.toInsertJson())
          .select()
          .single();

      return success(ServiceModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('createService failed', tag: 'BizSettingsRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'createService failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ServiceEntity>> updateService(ServiceEntity service) async {
    try {
      final model = service is ServiceModel
          ? service
          : ServiceModel(
              id: service.id,
              organizationId: service.organizationId,
              branchId: service.branchId,
              name: service.name,
              description: service.description,
              category: service.category,
              duration: service.duration,
              price: service.price,
              colorHex: service.colorHex,
              isActive: service.isActive,
              createdAt: service.createdAt,
            );

      final response = await _client
          .from('services')
          .update(model.toInsertJson())
          .eq('id', service.id)
          .select()
          .single();

      return success(ServiceModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('updateService failed', tag: 'BizSettingsRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'updateService failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteService(String serviceId) async {
    try {
      await _client
          .from('services')
          .update({'is_active': false})
          .eq('id', serviceId);

      return success(null);
    } on PostgrestException catch (e) {
      AppLogger.error('deleteService failed', tag: 'BizSettingsRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'deleteService failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<EmployeeEntity>>> getEmployees(
    String organizationId,
  ) async {
    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('organization_id', organizationId)
          .order('name');

      final employees = (response as List<dynamic>)
          .map((row) => EmployeeModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return success(employees);
    } on PostgrestException catch (e) {
      AppLogger.error('getEmployees failed', tag: 'BizSettingsRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getEmployees failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EmployeeEntity>> createEmployee(EmployeeEntity employee) async {
    try {
      final model = employee is EmployeeModel
          ? employee
          : EmployeeModel(
              id: employee.id,
              organizationId: employee.organizationId,
              branchId: employee.branchId,
              name: employee.name,
              email: employee.email,
              phone: employee.phone,
              avatarUrl: employee.avatarUrl,
              role: employee.role,
              isActive: employee.isActive,
              createdAt: employee.createdAt,
            );

      final response = await _client
          .from('employees')
          .insert(model.toInsertJson())
          .select()
          .single();

      return success(EmployeeModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error(
        'createEmployee failed',
        tag: 'BizSettingsRepo',
        error: e,
      );
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'createEmployee failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<EmployeeEntity>> updateEmployee(EmployeeEntity employee) async {
    try {
      final model = employee is EmployeeModel
          ? employee
          : EmployeeModel(
              id: employee.id,
              organizationId: employee.organizationId,
              branchId: employee.branchId,
              name: employee.name,
              email: employee.email,
              phone: employee.phone,
              avatarUrl: employee.avatarUrl,
              role: employee.role,
              isActive: employee.isActive,
              createdAt: employee.createdAt,
            );

      final response = await _client
          .from('employees')
          .update(model.toInsertJson())
          .eq('id', employee.id)
          .select()
          .single();

      return success(EmployeeModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error(
        'updateEmployee failed',
        tag: 'BizSettingsRepo',
        error: e,
      );
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'updateEmployee failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deactivateEmployee(String employeeId) async {
    try {
      await _client
          .from('employees')
          .update({'is_active': false})
          .eq('id', employeeId);

      return success(null);
    } on PostgrestException catch (e) {
      AppLogger.error(
        'deactivateEmployee failed',
        tag: 'BizSettingsRepo',
        error: e,
      );
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'deactivateEmployee failed',
        tag: 'BizSettingsRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  void dispose() {}

  Failure _mapException(PostgrestException e) {
    if (e.code == 'PGRST116') return const NotFoundFailure();
    if (e.code == '42501') return const PermissionFailure();
    if (e.code == '23505') {
      return const ConflictFailure(
        message: 'A record with this information already exists.',
      );
    }
    return ServerFailure(message: e.message);
  }
}
