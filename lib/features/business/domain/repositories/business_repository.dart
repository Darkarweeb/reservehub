import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/business_entity.dart';

/// Contract for business data operations.
abstract interface class BusinessRepository implements BaseRepository {
  /// Fetches all businesses for an organization.
  Future<Result<List<BusinessEntity>>> getBusinesses(String organizationId);

  /// Fetches a single business by ID.
  Future<Result<BusinessEntity>> getBusinessById(String id);

  /// Fetches a business by slug (public).
  Future<Result<BusinessEntity>> getBusinessBySlug(String slug);

  /// Creates a new business.
  Future<Result<BusinessEntity>> createBusiness(BusinessEntity business);

  /// Updates an existing business.
  Future<Result<BusinessEntity>> updateBusiness(BusinessEntity business);

  /// Publishes a business (makes it publicly discoverable).
  Future<Result<BusinessEntity>> publishBusiness(String businessId);

  /// Unpublishes a business.
  Future<Result<BusinessEntity>> unpublishBusiness(String businessId);

  /// Fetches all branches for a business.
  Future<Result<List<BranchEntity>>> getBranches(String businessId);

  /// Creates a branch.
  Future<Result<BranchEntity>> createBranch(BranchEntity branch);

  /// Updates a branch.
  Future<Result<BranchEntity>> updateBranch(BranchEntity branch);
}
