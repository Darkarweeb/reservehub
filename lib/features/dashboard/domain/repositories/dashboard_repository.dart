import '../../../../core/errors/result.dart';
import '../../../../core/repositories/base_repository.dart';
import '../entities/dashboard_entities.dart';

/// Contract for dashboard analytics data operations.
abstract interface class DashboardRepository implements BaseRepository {
  /// Fetches KPI metrics for the given date range.
  Future<Result<List<DashboardMetricEntity>>> getMetrics({
    required DateTime from,
    required DateTime to,
    String? organizationId,
  });

  /// Fetches revenue data points for the chart.
  Future<Result<List<RevenueDataPointEntity>>> getRevenueData({
    required DateTime from,
    required DateTime to,
    String? organizationId,
  });
}
