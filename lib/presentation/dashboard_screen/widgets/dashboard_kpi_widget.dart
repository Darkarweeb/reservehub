import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../features/management/presentation/providers/management_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';

class DashboardKpiWidget extends StatefulWidget {
  const DashboardKpiWidget({super.key});

  @override
  State<DashboardKpiWidget> createState() => _DashboardKpiWidgetState();
}

class _DashboardKpiWidgetState extends State<DashboardKpiWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagementProvider>();
      if (provider.kpis == null && !provider.kpisLoading) {
        provider.initialize().then((_) => provider.loadDashboardKpis());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        final kpis = provider.kpis;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.resumen,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          _formattedDate(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (provider.kpisLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      onPressed: () => provider.loadDashboardKpis(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: const Color(0xFF94A3B8),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (provider.kpisLoading && kpis == null)
                _buildSkeletonGrid()
              else if (provider.kpisError != null && kpis == null)
                _buildErrorState(provider.kpisError!)
              else
                _buildKpiGrid(kpis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(dynamic kpis) {
    final todayCount = kpis?.todayCount ?? 0;
    final yesterdayCount = kpis?.yesterdayCount ?? 0;
    final upcomingCount = kpis?.upcomingCount ?? 0;
    final completedCount = kpis?.completedCount ?? 0;
    final cancelledCount = kpis?.cancelledCount ?? 0;
    final customerCount = kpis?.customerCount ?? 0;
    final appointmentValue = kpis?.appointmentValue ?? 0.0;
    final todayDelta = todayCount - yesterdayCount;

    final kpiList = [
      _KpiData(
        label: AppStrings.kpiTodayAppts,
        value: '$todayCount',
        change: todayDelta >= 0
            ? '+$todayDelta ${AppStrings.kpiVsYesterday}'
            : '$todayDelta ${AppStrings.kpiVsYesterday}',
        isPositive: todayDelta >= 0,
        isAlert: false,
        icon: Icons.calendar_today_rounded,
        color: AppTheme.secondary,
        bgColor: AppTheme.secondaryContainer,
      ),
      _KpiData(
        label: AppStrings.kpiApptValue,
        value: '\$${appointmentValue.toStringAsFixed(0)}',
        change: AppStrings.kpiInformationalOnly,
        isPositive: true,
        isAlert: false,
        icon: Icons.attach_money_rounded,
        color: AppTheme.success,
        bgColor: AppTheme.successContainer,
      ),
      _KpiData(
        label: AppStrings.kpiCancelled,
        value: '$cancelledCount',
        change: cancelledCount > 0 ? AppStrings.today : AppStrings.kpiNoneToday,
        isPositive: cancelledCount == 0,
        isAlert: cancelledCount > 2,
        icon: Icons.person_off_outlined,
        color: AppTheme.error,
        bgColor: AppTheme.errorContainer,
      ),
      _KpiData(
        label: AppStrings.kpiCustomers,
        value: '$customerCount',
        change: '$upcomingCount ${AppStrings.kpiUpcoming}',
        isPositive: true,
        isAlert: false,
        icon: Icons.people_outline_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF3E8FF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: kpiList.length,
      itemBuilder: (context, i) => _KpiCard(data: kpiList[i]),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: 4,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariantLight),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.dashboardDataUnavailable,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      AppStrings.monthJan,
      AppStrings.monthFeb,
      AppStrings.monthMar,
      AppStrings.monthApr,
      AppStrings.monthMay,
      AppStrings.monthJun,
      AppStrings.monthJul,
      AppStrings.monthAug,
      AppStrings.monthSep,
      AppStrings.monthOct,
      AppStrings.monthNov,
      AppStrings.monthDec,
    ];
    const weekdays = [
      AppStrings.weekdayMon,
      AppStrings.weekdayTue,
      AppStrings.weekdayWed,
      AppStrings.weekdayThu,
      AppStrings.weekdayFri,
      AppStrings.weekdaySat,
      AppStrings.weekdaySun,
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _KpiData {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final bool isAlert;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiData({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.isAlert,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.isAlert ? data.bgColor : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: data.isAlert
            ? Border.all(color: data.color.withAlpha(77), width: 1.5)
            : Border.all(color: AppTheme.outlineVariantLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
              if (data.isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppStrings.kpiAlert,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: data.isAlert ? data.color : AppTheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                data.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.change,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: data.isPositive ? AppTheme.success : data.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
