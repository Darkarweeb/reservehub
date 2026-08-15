import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../business/domain/entities/business_entity.dart';
import '../../../business/domain/repositories/business_repository.dart';
import '../../../business/data/models/business_model.dart';

/// Supabase implementation of [BusinessRepository].
class BusinessRepositoryImpl implements BusinessRepository {
  final SupabaseClient _client;

  BusinessRepositoryImpl({required SupabaseClient client}) : _client = client;

  @override
  Future<Result<List<BusinessEntity>>> getBusinesses(
    String organizationId,
  ) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final businesses = (response as List<dynamic>)
          .map((row) => BusinessModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return success(businesses);
    } on PostgrestException catch (e) {
      AppLogger.error('getBusinesses failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getBusinesses failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BusinessEntity>> getBusinessById(String id) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('id', id)
          .single();

      return success(BusinessModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('getBusinessById failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getBusinessById failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BusinessEntity>> getBusinessBySlug(String slug) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('slug', slug)
          .eq('publication_status', 'published')
          .single();

      return success(BusinessModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('getBusinessBySlug failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getBusinessBySlug failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BusinessEntity>> createBusiness(BusinessEntity business) async {
    try {
      final model = business is BusinessModel
          ? business
          : BusinessModel(
              id: business.id,
              organizationId: business.organizationId,
              name: business.name,
              slug: business.slug,
              description: business.description,
              categoryId: business.categoryId,
              timezone: business.timezone,
              email: business.email,
              phone: business.phone,
              address: business.address,
              city: business.city,
              country: business.country,
              createdAt: business.createdAt,
            );

      final response = await _client
          .from('businesses')
          .insert(model.toInsertJson())
          .select()
          .single();

      return success(BusinessModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('createBusiness failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'createBusiness failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BusinessEntity>> updateBusiness(BusinessEntity business) async {
    try {
      final model = business is BusinessModel
          ? business
          : BusinessModel(
              id: business.id,
              organizationId: business.organizationId,
              name: business.name,
              slug: business.slug,
              description: business.description,
              categoryId: business.categoryId,
              logoUrl: business.logoUrl,
              coverImageUrl: business.coverImageUrl,
              email: business.email,
              phone: business.phone,
              website: business.website,
              address: business.address,
              city: business.city,
              country: business.country,
              timezone: business.timezone,
              createdAt: business.createdAt,
            );

      final response = await _client
          .from('businesses')
          .update(model.toUpdateJson())
          .eq('id', business.id)
          .select()
          .single();

      return success(BusinessModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('updateBusiness failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'updateBusiness failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BusinessEntity>> publishBusiness(String businessId) async {
    try {
      final response = await _client.rpc(
        'publish_business',
        params: {'p_business_id': businessId},
      );

      if (response == null) {
        return failure(
          const ServerFailure(message: 'Failed to publish business.'),
        );
      }

      return getBusinessById(businessId);
    } on PostgrestException catch (e) {
      AppLogger.error('publishBusiness failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'publishBusiness failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BusinessEntity>> unpublishBusiness(String businessId) async {
    try {
      final response = await _client
          .from('businesses')
          .update({'publication_status': 'unpublished'})
          .eq('id', businessId)
          .select()
          .single();

      return success(BusinessModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('unpublishBusiness failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'unpublishBusiness failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<BranchEntity>>> getBranches(String businessId) async {
    try {
      final response = await _client
          .from('branches')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .order('created_at');

      final branches = (response as List<dynamic>)
          .map((row) => BranchModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return success(branches);
    } on PostgrestException catch (e) {
      AppLogger.error('getBranches failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'getBranches failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BranchEntity>> createBranch(BranchEntity branch) async {
    try {
      final model = branch is BranchModel
          ? branch
          : BranchModel(
              id: branch.id,
              organizationId: branch.organizationId,
              businessId: branch.businessId,
              name: branch.name,
              address: branch.address,
              city: branch.city,
              country: branch.country,
              phone: branch.phone,
              email: branch.email,
              timezone: branch.timezone,
              createdAt: branch.createdAt,
            );

      final response = await _client
          .from('branches')
          .insert({
            'organization_id': model.organizationId,
            'business_id': model.businessId,
            'name': model.name,
            'address': model.address,
            'city': model.city,
            'country': model.country,
            'phone': model.phone,
            'email': model.email,
            'timezone': model.timezone,
          })
          .select()
          .single();

      return success(BranchModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('createBranch failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'createBranch failed',
        tag: 'BizRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BranchEntity>> updateBranch(BranchEntity branch) async {
    try {
      final model = branch is BranchModel
          ? branch
          : BranchModel(
              id: branch.id,
              organizationId: branch.organizationId,
              businessId: branch.businessId,
              name: branch.name,
              address: branch.address,
              city: branch.city,
              country: branch.country,
              phone: branch.phone,
              email: branch.email,
              timezone: branch.timezone,
              createdAt: branch.createdAt,
            );

      final response = await _client
          .from('branches')
          .update({
            'name': model.name,
            'address': model.address,
            'city': model.city,
            'country': model.country,
            'phone': model.phone,
            'email': model.email,
            'timezone': model.timezone,
          })
          .eq('id', branch.id)
          .select()
          .single();

      return success(BranchModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('updateBranch failed', tag: 'BizRepo', error: e);
      return failure(_mapException(e));
    } catch (e, st) {
      AppLogger.error(
        'updateBranch failed',
        tag: 'BizRepo',
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
        message: 'A business with this slug already exists.',
      );
    }
    return ServerFailure(message: e.message);
  }
}
