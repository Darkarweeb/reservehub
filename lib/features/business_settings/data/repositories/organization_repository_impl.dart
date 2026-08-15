import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/repositories/organization_repository.dart';
import '../models/organization_model.dart';

/// Supabase implementation of [OrganizationRepository].
class OrganizationRepositoryImpl implements OrganizationRepository {
  final SupabaseClient _client;

  OrganizationRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<OrganizationEntity?>> getCurrentOrganization() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return success(null);

      final response = await _client
          .from('organization_members')
          .select('organization_id, organizations(*)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (response == null) return success(null);

      final orgData = response['organizations'] as Map<String, dynamic>?;
      if (orgData == null) return success(null);

      return success(OrganizationModel.fromJson(orgData));
    } on PostgrestException catch (e) {
      AppLogger.error(
        'getCurrentOrganization failed',
        tag: 'OrgRepo',
        error: e,
      );
      return failure(_mapPostgrestException(e));
    } catch (e, st) {
      AppLogger.error(
        'getCurrentOrganization failed',
        tag: 'OrgRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrganizationEntity>> getOrganizationById(String id) async {
    try {
      final response = await _client
          .from('organizations')
          .select()
          .eq('id', id)
          .single();

      return success(OrganizationModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('getOrganizationById failed', tag: 'OrgRepo', error: e);
      return failure(_mapPostgrestException(e));
    } catch (e, st) {
      AppLogger.error(
        'getOrganizationById failed',
        tag: 'OrgRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrganizationEntity>> createOrganization({
    required String name,
    String? email,
    String? phone,
    String? timezone,
    String? currency,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return failure(const UnauthorizedFailure());
      }

      final response = await _client
          .from('organizations')
          .insert({
            'name': name,
            'email': email,
            'phone': phone,
            'timezone': timezone ?? 'UTC',
            'currency': currency ?? 'USD',
            'owner_id': userId,
          })
          .select()
          .single();

      return success(OrganizationModel.fromJson(response));
    } on PostgrestException catch (e) {
      AppLogger.error('createOrganization failed', tag: 'OrgRepo', error: e);
      return failure(_mapPostgrestException(e));
    } catch (e, st) {
      AppLogger.error(
        'createOrganization failed',
        tag: 'OrgRepo',
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
      AppLogger.error('updateOrganization failed', tag: 'OrgRepo', error: e);
      return failure(_mapPostgrestException(e));
    } catch (e, st) {
      AppLogger.error(
        'updateOrganization failed',
        tag: 'OrgRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<OrganizationEntity>>> getUserOrganizations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return success([]);

      final response = await _client
          .from('organization_members')
          .select('organizations(*)')
          .eq('user_id', userId)
          .eq('is_active', true);

      final orgs = (response as List<dynamic>)
          .map((row) {
            final orgData = row['organizations'] as Map<String, dynamic>?;
            if (orgData == null) return null;
            return OrganizationModel.fromJson(orgData);
          })
          .whereType<OrganizationEntity>()
          .toList();

      return success(orgs);
    } on PostgrestException catch (e) {
      AppLogger.error('getUserOrganizations failed', tag: 'OrgRepo', error: e);
      return failure(_mapPostgrestException(e));
    } catch (e, st) {
      AppLogger.error(
        'getUserOrganizations failed',
        tag: 'OrgRepo',
        error: e,
        stackTrace: st,
      );
      return failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  void dispose() {}

  Failure _mapPostgrestException(PostgrestException e) {
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
