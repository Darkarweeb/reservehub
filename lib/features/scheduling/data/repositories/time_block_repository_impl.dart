import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/time_block_repository.dart';

class TimeBlockRepositoryImpl implements TimeBlockRepository {
  final SupabaseClient _client;

  const TimeBlockRepositoryImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<Result<String>> createTimeBlock({
    required String branchId,
    required String title,
    required DateTime blockDate,
    required String startTime,
    required String endTime,
    String? employeeId,
    String? reason,
    bool isAllDay = false,
  }) async {
    try {
      final response = await _client.rpc(
        'create_time_block',
        params: {
          'p_branch_id': branchId,
          'p_title': title,
          'p_block_date': blockDate.toIso8601String().substring(0, 10),
          'p_start_time': startTime,
          'p_end_time': endTime,
          'p_employee_id': employeeId,
          'p_reason': reason,
          'p_is_all_day': isAllDay,
        },
      );

      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return success(data['block_id'] as String);
      }
      return failure(
        ConflictFailure(
          message: data['message'] as String? ?? 'Failed to create time block.',
        ),
      );
    } catch (e, st) {
      AppLogger.error('createTimeBlock failed', tag: 'TimeBlockRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> updateTimeBlock({
    required String blockId,
    String? title,
    DateTime? blockDate,
    String? startTime,
    String? endTime,
    String? reason,
    bool? isAllDay,
  }) async {
    try {
      final response = await _client.rpc(
        'update_time_block',
        params: {
          'p_block_id': blockId,
          'p_title': title,
          'p_block_date': blockDate?.toIso8601String().substring(0, 10),
          'p_start_time': startTime,
          'p_end_time': endTime,
          'p_reason': reason,
          'p_is_all_day': isAllDay,
        },
      );

      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return success(null);
      }
      return failure(
        ConflictFailure(
          message: data['message'] as String? ?? 'Failed to update time block.',
        ),
      );
    } catch (e, st) {
      AppLogger.error('updateTimeBlock failed', tag: 'TimeBlockRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> deleteTimeBlock(String blockId) async {
    try {
      final response = await _client.rpc(
        'delete_time_block',
        params: {'p_block_id': blockId},
      );

      final data = response as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return success(null);
      }
      return failure(
        ConflictFailure(
          message: data['message'] as String? ?? 'Failed to delete time block.',
        ),
      );
    } catch (e, st) {
      AppLogger.error('deleteTimeBlock failed', tag: 'TimeBlockRepo', error: e);
      return failure(ServerFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  void dispose() {}
}
