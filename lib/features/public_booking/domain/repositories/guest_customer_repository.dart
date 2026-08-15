import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';

/// Domain entity for a guest customer.
class GuestCustomerEntity {
  final String id;
  final String? organizationId;
  final String name;
  final String? email;
  final String? phone;
  final DateTime createdAt;

  const GuestCustomerEntity({
    required this.id,
    this.organizationId,
    required this.name,
    this.email,
    this.phone,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GuestCustomerEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Contract for guest customer operations.
abstract interface class GuestCustomerRepository implements BaseRepository {
  /// Upserts a guest customer by email or phone.
  Future<Result<GuestCustomerEntity>> upsertGuestCustomer({
    required String name,
    String? email,
    String? phone,
    String? organizationId,
  });

  /// Fetches a guest customer by ID.
  Future<Result<GuestCustomerEntity>> getGuestCustomerById(String id);
}
