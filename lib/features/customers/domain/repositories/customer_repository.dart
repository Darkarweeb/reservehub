import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/customer_entity.dart';

/// Contract for customer data operations.
abstract interface class CustomerRepository implements BaseRepository {
  /// Fetches a paginated list of customers.
  Future<Result<List<CustomerEntity>>> getCustomers({
    String? searchQuery,
    CustomerStatusEntity? status,
    CustomerTierEntity? tier,
    int page = 0,
    int pageSize = 20,
  });

  /// Fetches a single customer by ID.
  Future<Result<CustomerEntity>> getCustomerById(String id);

  /// Creates a new customer profile.
  Future<Result<CustomerEntity>> createCustomer(CustomerEntity customer);

  /// Updates an existing customer profile.
  Future<Result<CustomerEntity>> updateCustomer(CustomerEntity customer);

  /// Soft-deletes a customer.
  Future<Result<void>> deleteCustomer(String id);

  /// Returns the total customer count.
  Future<Result<int>> getCustomerCount();
}
