import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../localization/app_strings.dart';
import '../../navigation/route_names.dart';
import '../../shared/utils/responsive_builder.dart';
import '../../theme/app_theme.dart';
import './widgets/dashboard_app_bar_widget.dart';
import './widgets/dashboard_chart_widget.dart';
import './widgets/dashboard_kpi_widget.dart';
import './widgets/featured_appointment_card_widget.dart';
import './widgets/service_filter_widget.dart';
import './widgets/todays_appointments_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String _selectedFilter = AppStrings.filterAll;

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: ResponsiveBuilder(
          builder: (context, size) {
            if (size == ScreenSize.desktop) return _buildDesktopLayout();
            if (size == ScreenSize.tablet) return _buildTabletLayout();
            return _buildPhoneLayout();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.newAppointment),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          AppStrings.nuevaCita,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.secondary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: DashboardAppBarWidget()),
          SliverToBoxAdapter(child: DashboardKpiWidget()),
          SliverToBoxAdapter(child: FeaturedAppointmentCardWidget()),
          SliverToBoxAdapter(
            child: ServiceFilterWidget(
              selected: _selectedFilter,
              onSelected: (v) => setState(() => _selectedFilter = v),
            ),
          ),
          SliverToBoxAdapter(child: DashboardChartWidget()),
          SliverToBoxAdapter(child: TodaysAppointmentsWidget()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.secondary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: DashboardAppBarWidget()),
                SliverToBoxAdapter(child: DashboardKpiWidget()),
                SliverToBoxAdapter(child: DashboardChartWidget()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: Column(
              children: [
                FeaturedAppointmentCardWidget(),
                const SizedBox(height: 16),
                TodaysAppointmentsWidget(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.secondary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: DashboardAppBarWidget()),
                SliverToBoxAdapter(child: DashboardKpiWidget()),
                SliverToBoxAdapter(
                  child: ServiceFilterWidget(
                    selected: _selectedFilter,
                    onSelected: (v) => setState(() => _selectedFilter = v),
                  ),
                ),
                SliverToBoxAdapter(child: DashboardChartWidget()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 340,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, right: 24),
            child: Column(
              children: [
                FeaturedAppointmentCardWidget(),
                const SizedBox(height: 16),
                TodaysAppointmentsWidget(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
