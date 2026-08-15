import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../navigation/route_names.dart';
import '../../../theme/app_theme.dart';
import './ob_step_wrapper.dart';

/// Step 8: Review & Publish.
class ObStepReviewWidget extends StatefulWidget {
  const ObStepReviewWidget({super.key});

  @override
  State<ObStepReviewWidget> createState() => _ObStepReviewWidgetState();
}

class _ObStepReviewWidgetState extends State<ObStepReviewWidget> {
  bool _publishing = false;

  Future<void> _publish() async {
    setState(() => _publishing = true);
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.publishBusiness();
    if (!mounted) return;
    setState(() => _publishing = false);
    if (ok) {
      _showSuccessDialog();
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.obBusinessPublishedTitle,
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.obBusinessPublishedSubtitle,
              style: Theme.of(
                ctx,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  context.go(RouteNames.dashboard);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(AppStrings.goToDashboard),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final biz = provider.business;
    final org = provider.organization;
    final branch = provider.branch;
    final isPublished = biz?.isPublished ?? false;

    return ObStepWrapper(
      title: AppStrings.obStepTitleReview,
      subtitle: AppStrings.obStepSubtitleReview,
      isLoading: provider.isLoading,
      onBack: () => provider.goToStep(OnboardingStep.bookingSettings),
      onNext: isPublished ? null : _publish,
      nextLabel: AppStrings.obPublishBusiness,
      canGoNext: !_publishing,
      child: Column(
        children: [
          // Publication status banner
          if (isPublished)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.obBusinessIsLive,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppTheme.success),
                        ),
                        Text(
                          AppStrings.obBusinessIsLiveSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.obDraftMode,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Organization
          if (org != null)
            _ReviewSection(
              title: AppStrings.obReviewOrganization,
              icon: Icons.business_outlined,
              onEdit: () => provider.goToStep(OnboardingStep.organization),
              children: [
                _ReviewRow(AppStrings.obReviewName, org.name),
                if (org.email != null)
                  _ReviewRow(AppStrings.obReviewEmail, org.email!),
                if (org.timezone != null)
                  _ReviewRow(AppStrings.obReviewTimezone, org.timezone!),
                if (org.currency != null)
                  _ReviewRow(AppStrings.obReviewCurrency, org.currency!),
              ],
            ),
          const SizedBox(height: 12),

          // Business
          if (biz != null)
            _ReviewSection(
              title: AppStrings.obReviewBusiness,
              icon: Icons.store_outlined,
              onEdit: () => provider.goToStep(OnboardingStep.business),
              children: [
                _ReviewRow(AppStrings.obReviewName, biz.name),
                if (biz.slug != null)
                  _ReviewRow(
                    AppStrings.obReviewUrl,
                    'reservehub.com/b/${biz.slug}',
                  ),
                if (biz.email != null)
                  _ReviewRow(AppStrings.obReviewEmail, biz.email!),
                if (biz.phone != null)
                  _ReviewRow(AppStrings.obReviewPhone, biz.phone!),
                if (biz.timezone != null)
                  _ReviewRow(AppStrings.obReviewTimezone, biz.timezone!),
              ],
            ),
          const SizedBox(height: 12),

          // Branch
          if (branch != null)
            _ReviewSection(
              title: AppStrings.obReviewBranch,
              icon: Icons.location_on_outlined,
              onEdit: () => provider.goToStep(OnboardingStep.branch),
              children: [
                _ReviewRow(AppStrings.obReviewName, branch.name),
                if (branch.address != null)
                  _ReviewRow(AppStrings.obReviewAddress, branch.address!),
                if (branch.city != null)
                  _ReviewRow(AppStrings.obReviewCity, branch.city!),
                if (branch.country != null)
                  _ReviewRow(AppStrings.obReviewCountry, branch.country!),
              ],
            ),
          const SizedBox(height: 12),

          // Services
          _ReviewSection(
            title: AppStrings.obReviewServices,
            icon: Icons.spa_outlined,
            onEdit: () => provider.goToStep(OnboardingStep.services),
            children: provider.services.isEmpty
                ? [
                    _ReviewRow(
                      AppStrings.obReviewStatus,
                      AppStrings.obReviewNoServicesYet,
                      isWarning: true,
                    ),
                  ]
                : provider.services
                      .map(
                        (s) => _ReviewRow(
                          s.name,
                          '${s.durationMins} min · ${s.currency} ${s.price.toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 12),

          // Employees
          _ReviewSection(
            title: AppStrings.obReviewEmployees,
            icon: Icons.people_outline,
            onEdit: () => provider.goToStep(OnboardingStep.employees),
            children: provider.employees.isEmpty
                ? [
                    _ReviewRow(
                      AppStrings.obReviewStatus,
                      AppStrings.obReviewNoEmployeesYet,
                      isWarning: true,
                    ),
                  ]
                : provider.employees
                      .map(
                        (e) => _ReviewRow(
                          e.displayName,
                          '${e.serviceIds.length} ${AppStrings.obServicesAssigned}',
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 12),

          // Business Hours
          _ReviewSection(
            title: AppStrings.obReviewHours,
            icon: Icons.access_time_outlined,
            onEdit: () => provider.goToStep(OnboardingStep.businessHours),
            children: _buildHoursRows(provider.businessHours),
          ),
          const SizedBox(height: 12),

          // Booking Settings
          _ReviewSection(
            title: AppStrings.obReviewBookingSettings,
            icon: Icons.settings_outlined,
            onEdit: () => provider.goToStep(OnboardingStep.bookingSettings),
            children: [
              _ReviewRow(
                AppStrings.obReviewOnlineBooking,
                provider.bookingSettings.onlineBookingEnabled
                    ? AppStrings.obReviewEnabled
                    : AppStrings.obReviewDisabled,
              ),
              _ReviewRow(
                AppStrings.obReviewConfirmation,
                provider.bookingSettings.autoConfirm
                    ? AppStrings.obReviewAutoConfirm
                    : AppStrings.obReviewManualApproval,
              ),
              _ReviewRow(
                AppStrings.obReviewMinNotice,
                '${provider.bookingSettings.minAdvanceBookingHours} ${AppStrings.obUnitHours}',
              ),
              _ReviewRow(
                AppStrings.obReviewMaxHorizon,
                '${provider.bookingSettings.maxAdvanceBookingDays} ${AppStrings.obUnitDays}',
              ),
              _ReviewRow(
                AppStrings.obReviewCancellations,
                provider.bookingSettings.cancellationEnabled
                    ? AppStrings.obReviewAllowed
                    : AppStrings.obReviewNotAllowed,
              ),
            ],
          ),

          if (!isPublished) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondary.withAlpha(20),
                    AppTheme.secondary.withAlpha(10),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.secondary.withAlpha(51)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.rocket_launch_outlined,
                    color: AppTheme.secondary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.obReadyToGoLive,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.obReadyToGoLiveSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildHoursRows(List<OnboardingDayHours> hours) {
    const dayNames = [
      AppStrings.daySunday,
      AppStrings.dayMonday,
      AppStrings.dayTuesday,
      AppStrings.dayWednesday,
      AppStrings.dayThursday,
      AppStrings.dayFriday,
      AppStrings.daySaturday,
    ];

    String abbr(int dow) {
      final name = dayNames[dow % 7];
      return name.length >= 3 ? name.substring(0, 3) : name;
    }

    final openDays = hours
        .where((d) => d.isOpen)
        .map(
          (d) =>
              _ReviewRow(abbr(d.dayOfWeek), '${d.openTime} – ${d.closeTime}'),
        );
    final closedDays = hours
        .where((d) => !d.isOpen)
        .map(
          (d) => _ReviewRow(
            abbr(d.dayOfWeek),
            AppStrings.closed,
            isSecondary: true,
          ),
        );
    return [...openDays, ...closedDays];
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.secondary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text(AppStrings.edit),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  final bool isSecondary;

  const _ReviewRow(
    this.label,
    this.value, {
    this.isWarning = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isWarning
                    ? AppTheme.warning
                    : isSecondary
                    ? const Color(0xFF94A3B8)
                    : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
