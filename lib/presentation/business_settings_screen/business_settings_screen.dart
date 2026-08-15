import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../features/management/domain/entities/management_entities.dart';
import '../../../features/management/presentation/providers/management_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../shared/utils/responsive_builder.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../features/media/domain/entities/media_asset_entity.dart';
import '../../features/media/presentation/providers/media_provider.dart';
import '../../widgets/media_image_widget.dart';
import '../../widgets/media_upload_widget.dart';
import './widgets/settings_branding_widget.dart';
import './widgets/settings_business_profile_widget.dart';
import './widgets/settings_danger_zone_widget.dart';
import './widgets/settings_notifications_widget.dart';
import './widgets/settings_subscription_widget.dart';

/// Business Settings screen — hub for all post-onboarding management.
class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  int _selectedSection = 0;

  static List<_SectionSpec> get _sections => [
    _SectionSpec(
      icon: Icons.store_outlined,
      label: AppStrings.settingsSectionBusinessProfile,
      index: 0,
    ),
    _SectionSpec(
      icon: Icons.location_on_outlined,
      label: AppStrings.settingsSectionBranches,
      index: 1,
    ),
    _SectionSpec(
      icon: Icons.design_services_outlined,
      label: AppStrings.settingsSectionServices,
      index: 2,
    ),
    _SectionSpec(
      icon: Icons.people_outline_rounded,
      label: AppStrings.settingsSectionEmployees,
      index: 3,
    ),
    _SectionSpec(
      icon: Icons.schedule_outlined,
      label: AppStrings.settingsSectionBusinessHours,
      index: 4,
    ),
    _SectionSpec(
      icon: Icons.tune_outlined,
      label: AppStrings.settingsSectionBookingSettings,
      index: 5,
    ),
    _SectionSpec(
      icon: Icons.event_busy_outlined,
      label: AppStrings.settingsSectionHolidaysExceptions,
      index: 6,
    ),
    _SectionSpec(
      icon: Icons.notifications_outlined,
      label: AppStrings.settingsSectionNotifications,
      index: 7,
    ),
    _SectionSpec(
      icon: Icons.workspace_premium_outlined,
      label: AppStrings.settingsSectionSubscription,
      index: 8,
    ),
    _SectionSpec(
      icon: Icons.palette_outlined,
      label: AppStrings.settingsSectionBranding,
      index: 9,
    ),
    _SectionSpec(
      icon: Icons.workspace_premium_outlined,
      label: AppStrings.settingsSectionSubscription,
      index: 10,
    ),
    _SectionSpec(
      icon: Icons.warning_amber_outlined,
      label: AppStrings.settingsSectionDangerZone,
      index: 11,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size == ScreenSize.desktop) return _buildDesktopLayout();
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: AppTheme.surfaceLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    AppStrings.settingsSidebarTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    itemCount: _sections.length,
                    itemBuilder: (context, i) {
                      final s = _sections[i];
                      final isActive = _selectedSection == s.index;
                      return _SidebarItem(
                        spec: s,
                        isActive: isActive,
                        onTap: () => setState(() => _selectedSection = s.index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Content
          Expanded(child: _buildSectionContent()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBarWidget(title: _sections[_selectedSection].label),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primary),
              child: Text(
                AppStrings.settingsSidebarTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: _sections.length,
                itemBuilder: (context, i) {
                  final s = _sections[i];
                  final isActive = _selectedSection == s.index;
                  return _SidebarItem(
                    spec: s,
                    isActive: isActive,
                    onTap: () {
                      setState(() => _selectedSection = s.index);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    return switch (_selectedSection) {
      0 => const _SettingsContentWrapper(
        child: SettingsBusinessProfileWidget(),
      ),
      1 => const _BranchManagerSection(),
      2 => const _ServicesManagerSection(),
      3 => const _EmployeesManagerSection(),
      4 => const _BusinessHoursSection(),
      5 => const _BookingSettingsSection(),
      6 => const _ScheduleExceptionsSection(),
      7 => const _SettingsContentWrapper(child: SettingsNotificationsWidget()),
      8 => const _SettingsContentWrapper(child: SettingsSubscriptionWidget()),
      9 => const _SettingsContentWrapper(child: SettingsBrandingWidget()),
      10 => const _SettingsContentWrapper(child: SettingsSubscriptionWidget()),
      11 => const _SettingsContentWrapper(child: SettingsDangerZoneWidget()),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Content wrapper ─────────────────────────────────────────────────────────

class _SettingsContentWrapper extends StatelessWidget {
  final Widget child;
  const _SettingsContentWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: child,
    );
  }
}

// ─── Sidebar item ─────────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final _SectionSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                spec.icon,
                size: 18,
                color: isActive ? AppTheme.secondary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  spec.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppTheme.secondary
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSpec {
  final IconData icon;
  final String label;
  final int index;
  const _SectionSpec({
    required this.icon,
    required this.label,
    required this.index,
  });
}

// ─── Branch Manager Section ───────────────────────────────────────────────────

class _BranchManagerSection extends StatefulWidget {
  const _BranchManagerSection();

  @override
  State<_BranchManagerSection> createState() => _BranchManagerSectionState();
}

class _BranchManagerSectionState extends State<_BranchManagerSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mgmt = context.read<ManagementProvider>();
      mgmt.loadBranches().then((_) {
        // Load branch media for all branches
        final media = context.read<MediaProvider>();
        for (final branch in mgmt.branches) {
          media.loadBranchMedia(branch.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
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
                          AppStrings.settingsBranchManagerTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          AppStrings.settingsBranchManagerSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showBranchDialog(context, provider),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.settingsAddBranch),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (provider.branchesLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.branches.isEmpty)
                _EmptyState(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.settingsNoBranchesTitle,
                  subtitle: AppStrings.settingsNoBranchesSubtitle,
                )
              else
                ...provider.branches.map(
                  (branch) => _BranchCard(
                    branch: branch,
                    onEdit: () =>
                        _showBranchDialog(context, provider, branch: branch),
                    onToggle: (v) => provider.toggleBranchActive(branch.id, v),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBranchDialog(
    BuildContext context,
    ManagementProvider provider, {
    dynamic branch,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _BranchDialog(
        branch: branch,
        onSave: (data) async {
          final result = await provider.saveBranch(
            branchId: branch?.id,
            name: data['name'] as String,
            address: data['address'] as String?,
            city: data['city'] as String?,
            country: data['country'] as String?,
            phone: data['phone'] as String?,
            email: data['email'] as String?,
            timezone: data['timezone'] as String?,
          );
          result.fold(
            onSuccess: (_) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.settingsBranchSaved),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? AppStrings.settingsBranchSaveFailed),
                backgroundColor: AppTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Services Manager Section ─────────────────────────────────────────────────

class _ServicesManagerSection extends StatefulWidget {
  const _ServicesManagerSection();

  @override
  State<_ServicesManagerSection> createState() =>
      _ServicesManagerSectionState();
}

class _ServicesManagerSectionState extends State<_ServicesManagerSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mgmt = context.read<ManagementProvider>();
      mgmt.loadServices().then((_) {
        // Load service media for all services
        final media = context.read<MediaProvider>();
        for (final svc in mgmt.services) {
          media.loadServiceMedia(svc.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
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
                          AppStrings.settingsServicesManagerTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          AppStrings.settingsServicesManagerSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showServiceDialog(context, provider),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.settingsAddService),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (provider.servicesLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.services.isEmpty)
                _EmptyState(
                  icon: Icons.design_services_outlined,
                  title: AppStrings.settingsNoServicesTitle,
                  subtitle: AppStrings.settingsNoServicesSubtitle,
                )
              else
                ...provider.services.map(
                  (svc) => _ServiceCard(
                    service: svc,
                    onEdit: () =>
                        _showServiceDialog(context, provider, service: svc),
                    onToggle: (v) => provider.toggleServiceActive(svc.id, v),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showServiceDialog(
    BuildContext context,
    ManagementProvider provider, {
    dynamic service,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _ServiceDialog(
        service: service,
        onSave: (data) async {
          final result = await provider.saveService(
            serviceId: service?.id,
            name: data['name'] as String,
            description: data['description'] as String?,
            durationMinutes: data['duration'] as int,
            price: data['price'] as double,
            bufferBefore: data['buffer_before'] as int,
            bufferAfter: data['buffer_after'] as int,
            isActive: data['is_active'] as bool,
            category: data['category'] as String?,
          );
          result.fold(
            onSuccess: (_) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.settingsServiceSaved),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  f.message ?? AppStrings.settingsServiceSaveFailed,
                ),
                backgroundColor: AppTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Employees Manager Section ────────────────────────────────────────────────

class _EmployeesManagerSection extends StatefulWidget {
  const _EmployeesManagerSection();

  @override
  State<_EmployeesManagerSection> createState() =>
      _EmployeesManagerSectionState();
}

class _EmployeesManagerSectionState extends State<_EmployeesManagerSection> {
  String? _expandedEmployeeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
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
                          AppStrings.settingsEmployeesManagerTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          AppStrings.settingsEmployeesManagerSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showEmployeeDialog(context, provider),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.settingsAddEmployee),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (provider.employeesLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.employees.isEmpty)
                _EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: AppStrings.settingsNoEmployeesTitle,
                  subtitle: AppStrings.settingsNoEmployeesSubtitle,
                )
              else
                ...provider.employees.map(
                  (emp) => _EmployeeExpandableCard(
                    employee: emp,
                    isExpanded: _expandedEmployeeId == emp.id,
                    onToggleExpand: () {
                      setState(() {
                        _expandedEmployeeId = _expandedEmployeeId == emp.id
                            ? null
                            : emp.id;
                      });
                      if (_expandedEmployeeId == emp.id) {
                        provider.loadEmployeeWorkingHours(emp.id);
                        provider.loadEmployeeBreaks(emp.id);
                        provider.loadEmployeeTimeOff(emp.id);
                      }
                    },
                    onEdit: () =>
                        _showEmployeeDialog(context, provider, employee: emp),
                    onToggleStatus: (active) => provider.toggleEmployeeStatus(
                      emp.id,
                      active ? 'active' : 'inactive',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEmployeeDialog(
    BuildContext context,
    ManagementProvider provider, {
    dynamic employee,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _EmployeeDialog(
        employee: employee,
        onSave: (data) async {
          final result = await provider.saveEmployee(
            employeeId: employee?.id,
            firstName: data['first_name'] as String,
            lastName: data['last_name'] as String,
            email: data['email'] as String?,
            phone: data['phone'] as String?,
            title: data['title'] as String?,
            isBookable: data['is_bookable'] as bool,
            status: data['status'] as String,
          );
          result.fold(
            onSuccess: (_) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.settingsEmployeeSaved),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  f.message ?? AppStrings.settingsEmployeeSaveFailed,
                ),
                backgroundColor: AppTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Business Hours Section ───────────────────────────────────────────────────

class _BusinessHoursSection extends StatefulWidget {
  const _BusinessHoursSection();

  @override
  State<_BusinessHoursSection> createState() => _BusinessHoursSectionState();
}

class _BusinessHoursSectionState extends State<_BusinessHoursSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadBusinessHours();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.settingsBusinessHoursTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                AppStrings.settingsBusinessHoursSubtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              if (provider.hoursLoading)
                const Center(child: CircularProgressIndicator())
              else
                _BusinessHoursEditor(
                  hours: provider.businessHours,
                  onHourChanged: (index, updated) =>
                      provider.updateLocalBusinessHour(index, updated),
                  onSave: () async {
                    final result = await provider.saveBusinessHours(
                      provider.businessHours,
                    );
                    result.fold(
                      onSuccess: (_) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.settingsBusinessHoursSaved,
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          ),
                      onFailure: (f) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                f.message ?? AppStrings.dialogFailed,
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          ),
                    );
                  },
                  isSaving: provider.isSaving,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Booking Settings Section ─────────────────────────────────────────────────

class _BookingSettingsSection extends StatefulWidget {
  const _BookingSettingsSection();

  @override
  State<_BookingSettingsSection> createState() =>
      _BookingSettingsSectionState();
}

class _BookingSettingsSectionState extends State<_BookingSettingsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadBookingSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.settingsBookingTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                AppStrings.settingsBookingSubtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              if (provider.settingsLoading)
                const Center(child: CircularProgressIndicator())
              else
                _BookingSettingsEditor(
                  settings: provider.bookingSettings,
                  onSave: (settings) async {
                    final result = await provider.saveBookingSettings(settings);
                    result.fold(
                      onSuccess: (_) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.settingsBookingSettingsSaved,
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          ),
                      onFailure: (f) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                f.message ?? AppStrings.dialogFailed,
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          ),
                    );
                  },
                  isSaving: provider.isSaving,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Schedule Exceptions Section ──────────────────────────────────────────────

class _ScheduleExceptionsSection extends StatefulWidget {
  const _ScheduleExceptionsSection();

  @override
  State<_ScheduleExceptionsSection> createState() =>
      _ScheduleExceptionsSectionState();
}

class _ScheduleExceptionsSectionState
    extends State<_ScheduleExceptionsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadScheduleExceptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
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
                          AppStrings.settingsHolidaysTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          AppStrings.settingsHolidaysSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showExceptionDialog(context, provider),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.settingsAddException),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (provider.exceptionsLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.scheduleExceptions.isEmpty)
                _EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: AppStrings.settingsNoExceptionsTitle,
                  subtitle: AppStrings.settingsNoExceptionsSubtitle,
                )
              else
                ...provider.scheduleExceptions.map(
                  (exc) => _ExceptionCard(
                    exception: exc,
                    onDelete: () async {
                      final result = await provider.deleteScheduleException(
                        exc.id,
                      );
                      result.fold(
                        onSuccess: (_) =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.settingsExceptionRemoved,
                                ),
                                backgroundColor: AppTheme.success,
                              ),
                            ),
                        onFailure: (f) =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  f.message ?? AppStrings.dialogFailed,
                                ),
                                backgroundColor: AppTheme.error,
                              ),
                            ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showExceptionDialog(BuildContext context, ManagementProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _ExceptionDialog(
        onSave: (data) async {
          final result = await provider.addScheduleException(
            date: data['date'] as DateTime,
            isClosed: data['is_closed'] as bool,
            openTime: data['open_time'] as String?,
            closeTime: data['close_time'] as String?,
            reason: data['reason'] as String?,
            exceptionType: data['type'] as String,
          );
          result.fold(
            onSuccess: (_) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.settingsExceptionAdded),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? AppStrings.dialogFailed),
                backgroundColor: AppTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Reusable Cards & Dialogs ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Branch Card ──────────────────────────────────────────────────────────────

class _BranchCard extends StatefulWidget {
  final dynamic branch;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _showMedia = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagementProvider, MediaProvider>(
      builder: (context, mgmt, media, _) {
        final branchId = widget.branch.id as String;
        final orgId = mgmt.organizationId;
        final bizId = mgmt.businessId;
        final branchCover = media.getBranchCover(branchId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Branch cover thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MediaImageWidget(
                        imageUrl: branchCover?.publicUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        fallback: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.secondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.branch.name as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          if ((widget.branch.city as String?) != null ||
                              (widget.branch.country as String?) != null)
                            Text(
                              [
                                widget.branch.city,
                                widget.branch.country,
                              ].where((e) => e != null).join(', '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _showMedia = !_showMedia);
                        if (!_showMedia && orgId != null) {
                          media.loadBranchMedia(branchId);
                        }
                      },
                      icon: Icon(
                        Icons.photo_outlined,
                        size: 18,
                        color: _showMedia
                            ? AppTheme.secondary
                            : const Color(0xFF64748B),
                      ),
                      tooltip: AppStrings.settingsBranchImageTooltip,
                    ),
                    Switch(
                      value: widget.branch.isActive as bool,
                      onChanged: widget.onToggle,
                      activeThumbColor: AppTheme.success,
                    ),
                    IconButton(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
              if (_showMedia && orgId != null && bizId != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.settingsBranchCoverImage,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleMediaUploadWidget(
                        currentImageUrl: branchCover?.publicUrl,
                        currentAssetId: branchCover?.id,
                        mediaType: MediaAssetType.branchCover,
                        label: 'Branch Cover',
                        previewSize: 64,
                        aspectRatio: 16 / 9,
                        organizationId: orgId,
                        businessId: bizId,
                        branchId: branchId,
                        onUploaded: () => media.loadBranchMedia(branchId),
                        onDeleted: () => media.loadBranchMedia(branchId),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatefulWidget {
  final dynamic service;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _showMedia = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagementProvider, MediaProvider>(
      builder: (context, mgmt, media, _) {
        final serviceId = widget.service.id as String;
        final orgId = mgmt.organizationId;
        final bizId = mgmt.businessId;
        final serviceImage = media.getServiceImage(serviceId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Service image thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MediaImageWidget(
                        imageUrl: serviceImage?.publicUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        fallback: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.service.isActive as bool
                                ? AppTheme.secondaryContainer
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.design_services_outlined,
                            color: widget.service.isActive as bool
                                ? AppTheme.secondary
                                : const Color(0xFFCBD5E1),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            '${widget.service.durationMinutes} min · \$${(widget.service.price as double).toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _showMedia = !_showMedia);
                        if (!_showMedia) {
                          media.loadServiceMedia(serviceId);
                        }
                      },
                      icon: Icon(
                        Icons.photo_outlined,
                        size: 18,
                        color: _showMedia
                            ? AppTheme.secondary
                            : const Color(0xFF64748B),
                      ),
                      tooltip: AppStrings.settingsServiceImageTooltip,
                    ),
                    Switch(
                      value: widget.service.isActive as bool,
                      onChanged: widget.onToggle,
                      activeThumbColor: AppTheme.success,
                    ),
                    IconButton(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
              if (_showMedia && orgId != null && bizId != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.settingsServiceImageLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.settingsServiceImageSubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleMediaUploadWidget(
                        currentImageUrl: serviceImage?.publicUrl,
                        currentAssetId: serviceImage?.id,
                        mediaType: MediaAssetType.serviceImage,
                        label: 'Service Image',
                        previewSize: 64,
                        organizationId: orgId,
                        businessId: bizId,
                        serviceId: serviceId,
                        onUploaded: () => media.loadServiceMedia(serviceId),
                        onDeleted: () => media.loadServiceMedia(serviceId),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Employee Expandable Card ─────────────────────────────────────────────────

class _EmployeeExpandableCard extends StatelessWidget {
  final dynamic employee;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleStatus;

  const _EmployeeExpandableCard({
    required this.employee,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();
    final empId = employee.id as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppTheme.secondary.withAlpha(100)
              : AppTheme.outlineLight,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  EmployeeAvatarUploadWidget(
                    employeeId: empId,
                    employeeName: employee.displayName as String,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.displayName as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          employee.title as String? ??
                              (employee.isBookable as bool
                                  ? AppStrings.settingsEmployeeBookable
                                  : AppStrings.inactive),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: employee.isActive as bool,
                    onChanged: onToggleStatus,
                    activeThumbColor: AppTheme.success,
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: const Color(0xFF64748B),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            _EmployeeSchedulePanel(employeeId: empId, provider: provider),
          ],
        ],
      ),
    );
  }
}

// ─── Employee Schedule Panel ──────────────────────────────────────────────────

class _EmployeeSchedulePanel extends StatefulWidget {
  final String employeeId;
  final ManagementProvider provider;

  const _EmployeeSchedulePanel({
    required this.employeeId,
    required this.provider,
  });

  @override
  State<_EmployeeSchedulePanel> createState() => _EmployeeSchedulePanelState();
}

class _EmployeeSchedulePanelState extends State<_EmployeeSchedulePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final empId = widget.employeeId;
    final hours = provider.employeeHours(empId);
    final breaks = provider.employeeBreaks(empId);
    final timeOff = provider.employeeTimeOff(empId);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.secondary,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppTheme.secondary,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: AppStrings.settingsTabWorkingHours),
              Tab(text: AppStrings.settingsTabBreaks),
              Tab(text: AppStrings.settingsTabTimeOff),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Working Hours Tab
                _WorkingHoursTab(
                  hours: hours,
                  onHourChanged: (i, updated) =>
                      provider.updateLocalEmployeeHour(empId, i, updated),
                  onSave: () async {
                    final result = await provider.saveEmployeeWorkingHours(
                      empId,
                      hours,
                    );
                    result.fold(
                      onSuccess: (_) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.settingsWorkingHoursSaved,
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          ),
                      onFailure: (f) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                f.message ?? AppStrings.dialogFailed,
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          ),
                    );
                  },
                  isSaving: provider.isSaving,
                ),
                // Breaks Tab
                _BreaksTab(
                  breaks: breaks,
                  onAdd: () => _showAddBreakDialog(context, provider, empId),
                  onDelete: (breakId) =>
                      provider.deleteEmployeeBreak(empId, breakId),
                ),
                // Time Off Tab
                _TimeOffTab(
                  timeOff: timeOff,
                  onAdd: () => _showAddTimeOffDialog(context, provider, empId),
                  onDelete: (toId) =>
                      provider.deleteEmployeeTimeOff(empId, toId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBreakDialog(
    BuildContext context,
    ManagementProvider provider,
    String empId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AddBreakDialog(
        onSave: (data) async {
          final result = await provider.addEmployeeBreak(
            employeeId: empId,
            breakName: data['name'] as String,
            dayOfWeek: data['day'] as String?,
            startTime: data['start'] as String,
            endTime: data['end'] as String,
          );
          result.fold(
            onSuccess: (_) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.settingsBreakAdded),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? AppStrings.dialogFailed),
                backgroundColor: AppTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddTimeOffDialog(
    BuildContext context,
    ManagementProvider provider,
    String empId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AddTimeOffDialog(
        onSave: (data) async {
          final result = await provider.addEmployeeTimeOff(
            employeeId: empId,
            startDatetime: data['start'] as DateTime,
            endDatetime: data['end'] as DateTime,
            reason: data['reason'] as String?,
            timeOffType: data['type'] as String,
          );
          result.fold(
            onSuccess: (_) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.settingsTimeOffAdded),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? AppStrings.dialogFailed),
                backgroundColor: AppTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Working Hours Tab ────────────────────────────────────────────────────────

class _WorkingHoursTab extends StatelessWidget {
  final List<dynamic> hours;
  final Function(int, dynamic) onHourChanged;
  final VoidCallback onSave;
  final bool isSaving;

  const _WorkingHoursTab({
    required this.hours,
    required this.onHourChanged,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) {
      return Center(child: Text(AppStrings.settingsNoWorkingHours));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: hours.length,
            itemBuilder: (context, i) {
              final h = hours[i];
              return _DayHourRow(
                dayOfWeek: h.dayOfWeek as String,
                isWorking: h.isWorking as bool,
                startTime: h.startTime as String? ?? '09:00',
                endTime: h.endTime as String? ?? '17:00',
                onIsWorkingChanged: (v) =>
                    onHourChanged(i, (h as dynamic).copyWith(isWorking: v)),
                onStartChanged: (v) =>
                    onHourChanged(i, h.copyWith(startTime: v)),
                onEndChanged: (v) => onHourChanged(i, h.copyWith(endTime: v)),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(AppStrings.settingsSaveWorkingHours),
          ),
        ),
      ],
    );
  }
}

// ─── Breaks Tab ───────────────────────────────────────────────────────────────

class _BreaksTab extends StatelessWidget {
  final List<dynamic> breaks;
  final VoidCallback onAdd;
  final Function(String) onDelete;

  const _BreaksTab({
    required this.breaks,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: Text(AppStrings.settingsAddBreak),
          ),
        ),
        Expanded(
          child: breaks.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.settingsNoBreaks,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  itemCount: breaks.length,
                  itemBuilder: (context, i) {
                    final b = breaks[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.coffee_outlined, size: 18),
                      title: Text(
                        b.breakName as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${b.startTime} – ${b.endTime}${b.dayOfWeek != null ? ' (${b.dayOfWeek})' : ' (${AppStrings.settingsAllDays})'}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.error,
                        ),
                        onPressed: () => onDelete(b.id as String),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Time Off Tab ─────────────────────────────────────────────────────────────

class _TimeOffTab extends StatelessWidget {
  final List<dynamic> timeOff;
  final VoidCallback onAdd;
  final Function(String) onDelete;

  const _TimeOffTab({
    required this.timeOff,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: Text(AppStrings.settingsAddTimeOff),
          ),
        ),
        Expanded(
          child: timeOff.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.settingsNoTimeOff,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  itemCount: timeOff.length,
                  itemBuilder: (context, i) {
                    final t = timeOff[i];
                    final start = t.startDatetime as DateTime;
                    final end = t.endDatetime as DateTime;
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.beach_access_outlined,
                        size: 18,
                      ),
                      title: Text(
                        t.reason as String? ?? t.timeOffType as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${_fmtDate(start)} – ${_fmtDate(end)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.error,
                        ),
                        onPressed: () => onDelete(t.id as String),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Business Hours Editor ────────────────────────────────────────────────────

class _BusinessHoursEditor extends StatelessWidget {
  final List<dynamic> hours;
  final Function(int, dynamic) onHourChanged;
  final VoidCallback onSave;
  final bool isSaving;

  const _BusinessHoursEditor({
    required this.hours,
    required this.onHourChanged,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hours.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final h = hours[i];
              return _DayHourRow(
                dayOfWeek: h.dayOfWeek as String,
                isWorking: h.isOpen as bool,
                startTime: h.openTime as String? ?? '09:00',
                endTime: h.closeTime as String? ?? '18:00',
                workingLabel: 'Open',
                closedLabel: 'Closed',
                onIsWorkingChanged: (v) =>
                    onHourChanged(i, h.copyWith(isOpen: v)),
                onStartChanged: (v) =>
                    onHourChanged(i, h.copyWith(openTime: v)),
                onEndChanged: (v) => onHourChanged(i, h.copyWith(closeTime: v)),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(AppStrings.settingsSaveBusinessHours),
          ),
        ),
      ],
    );
  }
}

// ─── Day Hour Row ─────────────────────────────────────────────────────────────

class _DayHourRow extends StatelessWidget {
  final String dayOfWeek;
  final bool isWorking;
  final String startTime;
  final String endTime;
  final String workingLabel;
  final String closedLabel;
  final ValueChanged<bool> onIsWorkingChanged;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  const _DayHourRow({
    required this.dayOfWeek,
    required this.isWorking,
    required this.startTime,
    required this.endTime,
    this.workingLabel = 'Working',
    this.closedLabel = 'Off',
    required this.onIsWorkingChanged,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  static const _times = [
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
  ];

  @override
  Widget build(BuildContext context) {
    final dayLabel = dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1, 3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              dayLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isWorking,
            onChanged: onIsWorkingChanged,
            activeThumbColor: AppTheme.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 44,
            child: Text(
              isWorking ? workingLabel : closedLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isWorking ? AppTheme.success : const Color(0xFF94A3B8),
              ),
            ),
          ),
          if (isWorking) ...[
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _times.contains(startTime)
                    ? startTime
                    : _times.first,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.primary,
                ),
                items: _times
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => v != null ? onStartChanged(v) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '–',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _times.contains(endTime) ? endTime : _times.last,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.primary,
                ),
                items: _times
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => v != null ? onEndChanged(v) : null,
              ),
            ),
          ] else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

// ─── Booking Settings Editor ──────────────────────────────────────────────────

class _BookingSettingsEditor extends StatefulWidget {
  final dynamic settings;
  final Function(dynamic) onSave;
  final bool isSaving;

  const _BookingSettingsEditor({
    required this.settings,
    required this.onSave,
    required this.isSaving,
  });

  @override
  State<_BookingSettingsEditor> createState() => _BookingSettingsEditorState();
}

class _BookingSettingsEditorState extends State<_BookingSettingsEditor> {
  late bool _onlineBooking;
  late bool _guestBooking;
  late bool _autoConfirm;
  late int _minNotice;
  late int _maxHorizon;
  late int _slotDuration;
  late bool _allowReschedule;
  late int _rescheduleNotice;
  late int _maxReschedules;
  late bool _cancellationAllowed;
  late int _cancellationNotice;
  late double _cancellationFee;
  late double _noShowFee;

  @override
  void initState() {
    super.initState();
    _loadFromSettings();
  }

  void _loadFromSettings() {
    final s = widget.settings;
    if (s != null) {
      _onlineBooking = s.onlineBookingEnabled as bool;
      _guestBooking = s.guestBookingEnabled as bool;
      _autoConfirm = s.autoConfirm as bool;
      _minNotice = s.minBookingNoticeHours as int;
      _maxHorizon = s.maxBookingHorizonDays as int;
      _slotDuration = s.slotDurationMinutes as int;
      _allowReschedule = s.allowRescheduling as bool;
      _rescheduleNotice = s.rescheduleNoticeHours as int;
      _maxReschedules = s.maxReschedules as int;
      _cancellationAllowed = s.cancellationAllowed as bool;
      _cancellationNotice = s.cancellationNoticeHours as int;
      _cancellationFee = s.cancellationFee as double;
      _noShowFee = s.noShowFee as double;
    } else {
      _onlineBooking = true;
      _guestBooking = true;
      _autoConfirm = false;
      _minNotice = 1;
      _maxHorizon = 60;
      _slotDuration = 30;
      _allowReschedule = true;
      _rescheduleNotice = 24;
      _maxReschedules = 2;
      _cancellationAllowed = true;
      _cancellationNotice = 24;
      _cancellationFee = 0;
      _noShowFee = 0;
    }
  }

  @override
  void didUpdateWidget(_BookingSettingsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && widget.settings != null) {
      _loadFromSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsCard(
          title: AppStrings.settingsOnlineBookingSection,
          children: [
            _ToggleRow(
              label: AppStrings.settingsEnablePublicBooking,
              subtitle: AppStrings.settingsEnablePublicBookingSubtitle,
              value: _onlineBooking,
              onChanged: (v) => setState(() => _onlineBooking = v),
            ),
            _ToggleRow(
              label: AppStrings.settingsAllowGuestBooking,
              subtitle: AppStrings.settingsAllowGuestBookingSubtitle,
              value: _guestBooking,
              onChanged: (v) => setState(() => _guestBooking = v),
            ),
            _ToggleRow(
              label: AppStrings.settingsAutoConfirm,
              subtitle: AppStrings.settingsAutoConfirmSubtitle,
              value: _autoConfirm,
              onChanged: (v) => setState(() => _autoConfirm = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: AppStrings.settingsBookingTitle,
          children: [
            _StepperRow(
              label: AppStrings.settingsMinNoticeLabel,
              value: _minNotice,
              min: 0,
              max: 72,
              onChanged: (v) => setState(() => _minNotice = v),
            ),
            _StepperRow(
              label: AppStrings.settingsMaxHorizonLabel,
              value: _maxHorizon,
              min: 1,
              max: 365,
              onChanged: (v) => setState(() => _maxHorizon = v),
            ),
            _StepperRow(
              label: AppStrings.settingsSlotDurationLabel,
              value: _slotDuration,
              min: 15,
              max: 120,
              step: 15,
              onChanged: (v) => setState(() => _slotDuration = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: AppStrings.settingsAllowReschedule,
          children: [
            _ToggleRow(
              label: AppStrings.settingsAllowReschedule,
              value: _allowReschedule,
              onChanged: (v) => setState(() => _allowReschedule = v),
            ),
            if (_allowReschedule) ...[
              _StepperRow(
                label: AppStrings.settingsRescheduleNoticeLabel,
                value: _rescheduleNotice,
                min: 0,
                max: 72,
                onChanged: (v) => setState(() => _rescheduleNotice = v),
              ),
              _StepperRow(
                label: AppStrings.settingsMaxReschedulesLabel,
                value: _maxReschedules,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _maxReschedules = v),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: AppStrings.settingsCancellationSection,
          children: [
            _ToggleRow(
              label: AppStrings.settingsAllowCancellations,
              value: _cancellationAllowed,
              onChanged: (v) => setState(() => _cancellationAllowed = v),
            ),
            if (_cancellationAllowed)
              _StepperRow(
                label: AppStrings.settingsCancellationNoticeLabel,
                value: _cancellationNotice,
                min: 0,
                max: 72,
                onChanged: (v) => setState(() => _cancellationNotice = v),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.isSaving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: widget.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(AppStrings.settingsSaveBookingSettings),
          ),
        ),
      ],
    );
  }

  void _save() {
    final settings = BookingSettingsEntity(
      onlineBookingEnabled: _onlineBooking,
      guestBookingEnabled: _guestBooking,
      autoConfirm: _autoConfirm,
      minBookingNoticeHours: _minNotice,
      maxBookingHorizonDays: _maxHorizon,
      slotDurationMinutes: _slotDuration,
      allowRescheduling: _allowReschedule,
      rescheduleNoticeHours: _rescheduleNotice,
      maxReschedules: _maxReschedules,
      cancellationAllowed: _cancellationAllowed,
      cancellationNoticeHours: _cancellationNotice,
      cancellationFee: _cancellationFee,
      noShowFee: _noShowFee,
    );
    widget.onSave(settings);
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.success,
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - step) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppTheme.secondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + step) : null,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppTheme.secondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Exception Card ───────────────────────────────────────────────────────────

class _ExceptionCard extends StatelessWidget {
  final dynamic exception;
  final VoidCallback onDelete;

  const _ExceptionCard({required this.exception, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = exception.exceptionDate as DateTime;
    final isClosed = exception.isClosed as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isClosed ? AppTheme.errorContainer : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClosed
              ? AppTheme.error.withAlpha(80)
              : AppTheme.outlineLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isClosed ? Icons.block_outlined : Icons.schedule_outlined,
            color: isClosed ? AppTheme.error : AppTheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  isClosed
                      ? AppStrings.settingsExceptionClosedLabel
                      : '${exception.openTime} – ${exception.closeTime}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if ((exception.reason as String?) != null)
                  Text(
                    exception.reason as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

class _BranchDialog extends StatefulWidget {
  final dynamic branch;
  final Function(Map<String, dynamic>) onSave;

  const _BranchDialog({this.branch, required this.onSave});

  @override
  State<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends State<_BranchDialog> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _nameCtrl.text = widget.branch.name as String? ?? '';
      _addressCtrl.text = widget.branch.address as String? ?? '';
      _cityCtrl.text = widget.branch.city as String? ?? '';
      _countryCtrl.text = widget.branch.country as String? ?? '';
      _phoneCtrl.text = widget.branch.phone as String? ?? '';
      _emailCtrl.text = widget.branch.email as String? ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.branch != null
            ? AppStrings.settingsBranchDialogEdit
            : AppStrings.settingsBranchDialogAdd,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: _nameCtrl,
                label: AppStrings.settingsBranchNameField,
              ),
              _DialogField(
                controller: _addressCtrl,
                label: AppStrings.settingsBranchAddressField,
              ),
              _DialogField(
                controller: _cityCtrl,
                label: AppStrings.settingsBranchCityField,
              ),
              _DialogField(
                controller: _countryCtrl,
                label: AppStrings.settingsBranchCountryField,
              ),
              _DialogField(
                controller: _phoneCtrl,
                label: AppStrings.settingsBranchPhoneField,
              ),
              _DialogField(
                controller: _emailCtrl,
                label: AppStrings.settingsBranchEmailField,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.dialogCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await widget.onSave({
                    'name': _nameCtrl.text.trim(),
                    'address': _addressCtrl.text.trim().isEmpty
                        ? null
                        : _addressCtrl.text.trim(),
                    'city': _cityCtrl.text.trim().isEmpty
                        ? null
                        : _cityCtrl.text.trim(),
                    'country': _countryCtrl.text.trim().isEmpty
                        ? null
                        : _countryCtrl.text.trim(),
                    'phone': _phoneCtrl.text.trim().isEmpty
                        ? null
                        : _phoneCtrl.text.trim(),
                    'email': _emailCtrl.text.trim().isEmpty
                        ? null
                        : _emailCtrl.text.trim(),
                    'timezone': null,
                  });
                  setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppStrings.dialogSave),
        ),
      ],
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final dynamic service;
  final Function(Map<String, dynamic>) onSave;

  const _ServiceDialog({this.service, required this.onSave});

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int _duration = 60;
  int _bufferBefore = 0;
  int _bufferAfter = 0;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameCtrl.text = widget.service.name as String? ?? '';
      _descCtrl.text = widget.service.description as String? ?? '';
      _priceCtrl.text = (widget.service.price as double).toStringAsFixed(0);
      _duration = widget.service.durationMinutes as int;
      _bufferBefore = widget.service.bufferBeforeMinutes as int;
      _bufferAfter = widget.service.bufferAfterMinutes as int;
      _isActive = widget.service.isActive as bool;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.service != null
            ? AppStrings.settingsServiceDialogEdit
            : AppStrings.settingsServiceDialogAdd,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: _nameCtrl,
                label: AppStrings.settingsServiceNameField,
              ),
              _DialogField(
                controller: _descCtrl,
                label: AppStrings.settingsServiceDescField,
                maxLines: 2,
              ),
              _DialogField(
                controller: _priceCtrl,
                label: AppStrings.settingsServicePriceField,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _StepperRow(
                label: AppStrings.settingsServiceDurationField,
                value: _duration,
                min: 15,
                max: 480,
                step: 15,
                onChanged: (v) => setState(() => _duration = v),
              ),
              _StepperRow(
                label: AppStrings.settingsServiceBufferBeforeField,
                value: _bufferBefore,
                min: 0,
                max: 60,
                step: 5,
                onChanged: (v) => setState(() => _bufferBefore = v),
              ),
              _StepperRow(
                label: AppStrings.settingsServiceBufferAfterField,
                value: _bufferAfter,
                min: 0,
                max: 60,
                step: 5,
                onChanged: (v) => setState(() => _bufferAfter = v),
              ),
              _ToggleRow(
                label: AppStrings.settingsServiceActiveLabel,
                subtitle: AppStrings.settingsServiceActiveSubtitle,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.dialogCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await widget.onSave({
                    'name': _nameCtrl.text.trim(),
                    'description': _descCtrl.text.trim().isEmpty
                        ? null
                        : _descCtrl.text.trim(),
                    'duration': _duration,
                    'price': double.tryParse(_priceCtrl.text) ?? 0.0,
                    'buffer_before': _bufferBefore,
                    'buffer_after': _bufferAfter,
                    'is_active': _isActive,
                    'category': null,
                  });
                  setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppStrings.dialogSave),
        ),
      ],
    );
  }
}

class _EmployeeDialog extends StatefulWidget {
  final dynamic employee;
  final Function(Map<String, dynamic>) onSave;

  const _EmployeeDialog({this.employee, required this.onSave});

  @override
  State<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<_EmployeeDialog> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  bool _isBookable = true;
  String _status = 'active';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _firstNameCtrl.text = widget.employee.firstName as String? ?? '';
      _lastNameCtrl.text = widget.employee.lastName as String? ?? '';
      _emailCtrl.text = widget.employee.email as String? ?? '';
      _phoneCtrl.text = widget.employee.phone as String? ?? '';
      _titleCtrl.text = widget.employee.title as String? ?? '';
      _isBookable = widget.employee.isBookable as bool;
      _status = widget.employee.status as String;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.employee != null
            ? AppStrings.settingsEmployeeDialogEdit
            : AppStrings.settingsEmployeeDialogAdd,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: _firstNameCtrl,
                label: AppStrings.settingsEmployeeFirstNameField,
              ),
              _DialogField(
                controller: _lastNameCtrl,
                label: AppStrings.settingsEmployeeLastNameField,
              ),
              _DialogField(
                controller: _emailCtrl,
                label: AppStrings.settingsEmployeeEmailField,
              ),
              _DialogField(
                controller: _phoneCtrl,
                label: AppStrings.settingsEmployeePhoneField,
              ),
              _DialogField(
                controller: _titleCtrl,
                label: AppStrings.settingsEmployeeTitleField,
              ),
              _ToggleRow(
                label: AppStrings.settingsEmployeeBookable,
                subtitle: AppStrings.settingsEmployeeBookableSubtitle,
                value: _isBookable,
                onChanged: (v) => setState(() => _isBookable = v),
              ),
              _ToggleRow(
                label: AppStrings.settingsEmployeeActiveLabel,
                subtitle: AppStrings.settingsEmployeeActiveSubtitle,
                value: _status == 'active',
                onChanged: (v) =>
                    setState(() => _status = v ? 'active' : 'inactive'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.dialogCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_firstNameCtrl.text.trim().isEmpty ||
                      _lastNameCtrl.text.trim().isEmpty) {
                    return;
                  }
                  setState(() => _saving = true);
                  await widget.onSave({
                    'first_name': _firstNameCtrl.text.trim(),
                    'last_name': _lastNameCtrl.text.trim(),
                    'email': _emailCtrl.text.trim().isEmpty
                        ? null
                        : _emailCtrl.text.trim(),
                    'phone': _phoneCtrl.text.trim().isEmpty
                        ? null
                        : _phoneCtrl.text.trim(),
                    'title': _titleCtrl.text.trim().isEmpty
                        ? null
                        : _titleCtrl.text.trim(),
                    'is_bookable': _isBookable,
                    'status': _status,
                  });
                  setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppStrings.dialogSave),
        ),
      ],
    );
  }
}

class _AddBreakDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  const _AddBreakDialog({required this.onSave});

  @override
  State<_AddBreakDialog> createState() => _AddBreakDialogState();
}

class _AddBreakDialogState extends State<_AddBreakDialog> {
  final _nameCtrl = TextEditingController(text: 'Lunch Break');
  String _startTime = '12:00';
  String _endTime = '13:00';
  String? _dayOfWeek;
  bool _saving = false;

  static const _times = [
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
  ];

  static const _days = [
    null,
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.settingsBreakDialogTitle,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              controller: _nameCtrl,
              label: AppStrings.settingsBreakNameField,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _dayOfWeek,
              decoration: InputDecoration(
                labelText: AppStrings.settingsBreakDayField,
                border: const OutlineInputBorder(),
              ),
              items: _days
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(d ?? AppStrings.settingsAllDays),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _dayOfWeek = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _startTime,
                    decoration: InputDecoration(
                      labelText: AppStrings.settingsBreakStartField,
                      border: const OutlineInputBorder(),
                    ),
                    items: _times
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        v != null ? setState(() => _startTime = v) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _endTime,
                    decoration: InputDecoration(
                      labelText: AppStrings.settingsBreakEndField,
                      border: const OutlineInputBorder(),
                    ),
                    items: _times
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        v != null ? setState(() => _endTime = v) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.dialogCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave({
                    'name': _nameCtrl.text.trim(),
                    'day': _dayOfWeek,
                    'start': _startTime,
                    'end': _endTime,
                  });
                  setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          child: Text(AppStrings.settingsBreakAddButton),
        ),
      ],
    );
  }
}

class _AddTimeOffDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  const _AddTimeOffDialog({required this.onSave});

  @override
  State<_AddTimeOffDialog> createState() => _AddTimeOffDialogState();
}

class _AddTimeOffDialogState extends State<_AddTimeOffDialog> {
  final _reasonCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _type = 'unavailable';
  bool _saving = false;

  static const _types = [
    'unavailable',
    'vacation',
    'illness',
    'personal',
    'training',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.settingsTimeOffDialogTitle,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: AppStrings.settingsTimeOffTypeField,
                border: const OutlineInputBorder(),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => _type = v) : null,
            ),
            const SizedBox(height: 12),
            _DialogField(
              controller: _reasonCtrl,
              label: AppStrings.settingsTimeOffReasonField,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _fmtDate(_startDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _endDate = d);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _fmtDate(_endDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.dialogCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave({
                    'start': DateTime(
                      _startDate.year,
                      _startDate.month,
                      _startDate.day,
                      0,
                      0,
                    ),
                    'end': DateTime(
                      _endDate.year,
                      _endDate.month,
                      _endDate.day,
                      23,
                      59,
                    ),
                    'reason': _reasonCtrl.text.trim().isEmpty
                        ? null
                        : _reasonCtrl.text.trim(),
                    'type': _type,
                  });
                  setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          child: Text(AppStrings.settingsTimeOffAddButton),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ExceptionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  const _ExceptionDialog({required this.onSave});

  @override
  State<_ExceptionDialog> createState() => _ExceptionDialogState();
}

class _ExceptionDialogState extends State<_ExceptionDialog> {
  final _reasonCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _isClosed = true;
  String _openTime = '09:00';
  String _closeTime = '13:00';
  String _type = 'holiday';
  bool _saving = false;

  static const _times = [
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.settingsExceptionDialogTitle,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (d != null) setState(() => _date = d);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: AppStrings.settingsExceptionTypeField,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'holiday',
                  child: Text(AppStrings.settingsExceptionTypeHoliday),
                ),
                DropdownMenuItem(
                  value: 'closed',
                  child: Text(AppStrings.settingsExceptionTypeClosed),
                ),
                DropdownMenuItem(
                  value: 'modified_hours',
                  child: Text(AppStrings.settingsExceptionTypeModified),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _type = v;
                    if (v == 'modified_hours') _isClosed = false;
                    if (v == 'holiday' || v == 'closed') _isClosed = true;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            _ToggleRow(
              label: AppStrings.settingsExceptionClosedAllDay,
              value: _isClosed,
              onChanged: (v) => setState(() => _isClosed = v),
            ),
            if (!_isClosed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _openTime,
                      decoration: InputDecoration(
                        labelText: AppStrings.settingsExceptionOpenField,
                        border: const OutlineInputBorder(),
                      ),
                      items: _times
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          v != null ? setState(() => _openTime = v) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _closeTime,
                      decoration: InputDecoration(
                        labelText: AppStrings.settingsExceptionCloseField,
                        border: const OutlineInputBorder(),
                      ),
                      items: _times
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          v != null ? setState(() => _closeTime = v) : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _DialogField(
              controller: _reasonCtrl,
              label: AppStrings.settingsExceptionReasonField,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.dialogCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave({
                    'date': _date,
                    'is_closed': _isClosed,
                    'open_time': _isClosed ? null : _openTime,
                    'close_time': _isClosed ? null : _closeTime,
                    'reason': _reasonCtrl.text.trim().isEmpty
                        ? null
                        : _reasonCtrl.text.trim(),
                    'type': _type,
                  });
                  setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          child: Text(AppStrings.settingsExceptionAddButton),
        ),
      ],
    );
  }
}

// ─── Shared dialog field ──────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: GoogleFonts.plusJakartaSans(fontSize: 14),
      ),
    );
  }
}
