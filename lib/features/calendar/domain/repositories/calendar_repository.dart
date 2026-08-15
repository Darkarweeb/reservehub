import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/calendar_entities.dart';

/// Contract for calendar data operations.
abstract interface class CalendarRepository implements BaseRepository {
  /// Fetches calendar day metadata for a given month.
  Future<Result<List<CalendarDayEntity>>> getCalendarMonth({
    required int year,
    required int month,
    String? organizationId,
  });
}
