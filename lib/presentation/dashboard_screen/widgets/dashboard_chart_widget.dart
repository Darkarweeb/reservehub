import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';

class DashboardChartWidget extends StatefulWidget {
  const DashboardChartWidget({super.key});

  @override
  State<DashboardChartWidget> createState() => _DashboardChartWidgetState();
}

class _DashboardChartWidgetState extends State<DashboardChartWidget> {
  int _selectedRange = 0; // 0=7d, 1=30d, 2=90d

  List<String> get _ranges => [
    AppStrings.chartRange7d,
    AppStrings.chartRange30d,
    AppStrings.chartRange90d,
  ];

  // Mock revenue data — realistic variance with dip on Wednesday
  final List<FlSpot> _revenueData7d = const [
    FlSpot(0, 1420),
    FlSpot(1, 1850),
    FlSpot(2, 1340),
    FlSpot(3, 2100),
    FlSpot(4, 1780),
    FlSpot(5, 980),
    FlSpot(6, 1840),
  ];

  List<String> get _dayLabels7d => [
    AppStrings.weekdayShortMon,
    AppStrings.weekdayShortTue,
    AppStrings.weekdayShortWed,
    AppStrings.weekdayShortThu,
    AppStrings.weekdayShortFri,
    AppStrings.weekdayShortSat,
    AppStrings.weekdayShortSun,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.revenueTrend,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.lastUpdatedJustNow,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                // Range selector
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: List.generate(
                      _ranges.length,
                      (i) => GestureDetector(
                        onTap: () => setState(() => _selectedRange = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRange == i
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _ranges[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _selectedRange == i
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.outlineVariantLight,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: 1000,
                        getTitlesWidget: (v, _) => Text(
                          '\$${(v / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          final labels = _dayLabels7d;
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            labels[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _revenueData7d,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppTheme.secondary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.secondary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondary.withAlpha(51),
                            AppTheme.secondary.withAlpha(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      tooltipBgColor: AppTheme.primary,
                      getTooltipItems: (spots) => spots
                          .map(
                            (s) => LineTooltipItem(
                              '\$${s.y.toStringAsFixed(0)}',
                              GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  minY: 0,
                  maxY: 2500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
