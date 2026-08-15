import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';

/// A single bookable time slot.
class AvailabilitySlotEntity {
  final DateTime startsAt;
  final DateTime endsAt;

  const AvailabilitySlotEntity({required this.startsAt, required this.endsAt});

  String get formattedTime {
    final h = startsAt.hour.toString().padLeft(2, '0');
    final m = startsAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Contract for public availability queries.
abstract interface class AvailabilityRepository implements BaseRepository {
  /// Returns available slots for a given service/employee/branch/date.
  /// Delegates to get_public_availability() RPC which uses check_slot_available().
  Future<Result<List<AvailabilitySlotEntity>>> getPublicAvailability({
    required String businessSlug,
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime date,
  });
}
