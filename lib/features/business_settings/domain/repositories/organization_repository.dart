import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/organization_entity.dart';

/// Contract for organization data operations.
abstract interface class OrganizationRepository implements BaseRepository {
  /// Fetches the organization for the current user.
  Future<Result<OrganizationEntity?>> getCurrentOrganization();

  /// Fetches an organization by ID.
  Future<Result<OrganizationEntity>> getOrganizationById(String id);

  /// Creates a new organization.
  Future<Result<OrganizationEntity>> createOrganization({
    required String name,
    String? email,
    String? phone,
    String? timezone,
    String? currency,
  });

  /// Updates an organization.
  Future<Result<OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  );

  /// Fetches all organizations the current user belongs to.
  Future<Result<List<OrganizationEntity>>> getUserOrganizations();
}
