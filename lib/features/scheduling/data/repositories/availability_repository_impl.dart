import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  final SupabaseClient _client;

  const AvailabilityRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<List<AvailabilitySlotEntity>>> getPublicAvailability({
    required String businessSlug,
    required String branchId,
    required String serviceId,
    required String employeeId,
    required DateTime date,
  }) async {
    try {
      final response = await _client.rpc(
        'get_public_availability',
        params: {
          'p_business_slug': businessSlug,
          'p_branch_id': branchId,
          'p_service_id': serviceId,
          'p_employee_id': employeeId,
          'p_date': date.toIso8601String().substring(0, 10),
        },
      );

      final data = response as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return failure(ServerFailure(message: data['error'] as String));
      }

      final slots = (data['slots'] as List<dynamic>? ?? [])
          .map(
            (s) => AvailabilitySlotEntity(
              startsAt: DateTime.parse(s['starts_at'] as String),
              endsAt: DateTime.parse(s['ends_at'] as String),
            ),
          )
          .toList();

      return success(slots);
    } catch (e, st) {
      AppLogger.error(
        'getPublicAvailability failed',
        tag: 'AvailabilityRepo',
        error: e,
      );
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  void dispose() {}
}
