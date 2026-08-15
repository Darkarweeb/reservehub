import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';

/// Domain entity for an administrative time block.
class TimeBlockEntity {
  final String id;
  final String organizationId;
  final String businessId;
  final String? branchId;
  final String? employeeId;
  final String title;
  final String? reason;
  final DateTime blockDate;
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final bool isAllDay;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeBlockEntity({
    required this.id,
    required this.organizationId,
    required this.businessId,
    this.branchId,
    this.employeeId,
    required this.title,
    this.reason,
    required this.blockDate,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimeBlockEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Contract for time block data operations.
abstract interface class TimeBlockRepository implements BaseRepository {
  /// Creates an administrative time block via RPC.
  Future<Result<String>> createTimeBlock({
    required String branchId,
    required String title,
    required DateTime blockDate,
    required String startTime,
    required String endTime,
    String? employeeId,
    String? reason,
    bool isAllDay = false,
  });

  /// Updates an existing time block via RPC.
  Future<Result<void>> updateTimeBlock({
    required String blockId,
    String? title,
    DateTime? blockDate,
    String? startTime,
    String? endTime,
    String? reason,
    bool? isAllDay,
  });

  /// Soft-deletes a future time block via RPC.
  Future<Result<void>> deleteTimeBlock(String blockId);
}
