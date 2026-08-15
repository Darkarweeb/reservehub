/// Domain entity representing a KPI metric for the dashboard.
class DashboardMetricEntity {
  final String id;
  final String label;
  final double value;
  final double? previousValue;
  final String? unit;
  final MetricTrendEntity trend;

  const DashboardMetricEntity({
    required this.id,
    required this.label,
    required this.value,
    this.previousValue,
    this.unit,
    required this.trend,
  });

  double get changePercent {
    if (previousValue == null || previousValue == 0) return 0;
    return ((value - previousValue!) / previousValue!) * 100;
  }
}

enum MetricTrendEntity { up, down, neutral }

/// Domain entity representing a revenue data point for charts.
class RevenueDataPointEntity {
  final DateTime date;
  final double revenue;
  final int bookings;

  const RevenueDataPointEntity({
    required this.date,
    required this.revenue,
    required this.bookings,
  });
}
