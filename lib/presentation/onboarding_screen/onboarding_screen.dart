import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';
import './widgets/ob_step_booking_settings_widget.dart';
import './widgets/ob_step_branch_widget.dart';
import './widgets/ob_step_business_widget.dart';
import './widgets/ob_step_employees_widget.dart';
import './widgets/ob_step_hours_widget.dart';
import './widgets/ob_step_organization_widget.dart';
import './widgets/ob_step_review_widget.dart';
import './widgets/ob_step_services_widget.dart';

/// Main onboarding screen — multi-step wizard for new business owners.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              final isTablet = constraints.maxWidth >= 600;

              if (isDesktop) {
                return _DesktopLayout(provider: provider);
              } else if (isTablet) {
                return _TabletLayout(provider: provider);
              } else {
                return _MobileLayout(provider: provider);
              }
            },
          ),
        );
      },
    );
  }
}

// ─── Desktop Layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final OnboardingProvider provider;
  const _DesktopLayout({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left sidebar — step list
        Container(
          width: 280,
          color: AppTheme.primary,
          child: _StepSidebar(provider: provider),
        ),
        // Right content
        Expanded(
          child: Column(
            children: [
              _OnboardingAppBar(provider: provider),
              Expanded(child: _StepContent(provider: provider)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tablet Layout ────────────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final OnboardingProvider provider;
  const _TabletLayout({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OnboardingAppBar(provider: provider),
        _StepProgressBar(provider: provider),
        Expanded(child: _StepContent(provider: provider)),
      ],
    );
  }
}

// ─── Mobile Layout ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final OnboardingProvider provider;
  const _MobileLayout({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OnboardingAppBar(provider: provider),
        _StepProgressBar(provider: provider),
        Expanded(child: _StepContent(provider: provider)),
      ],
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _OnboardingAppBar extends StatelessWidget {
  final OnboardingProvider provider;
  const _OnboardingAppBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final step = provider.currentStep;
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ReserveHub',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                'Business Setup',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const Spacer(),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step ${step.index + 1} of ${OnboardingStep.values.length}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final OnboardingProvider provider;
  const _StepProgressBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.progressPercent,
              backgroundColor: AppTheme.outlineLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.secondary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: OnboardingStep.values.map((step) {
              final isCompleted = provider.progress.isStepCompleted(step);
              final isCurrent = provider.currentStep == step;
              return Expanded(
                child: GestureDetector(
                  onTap: isCompleted ? () => provider.goToStep(step) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.secondary
                          : isCurrent
                          ? AppTheme.secondary.withAlpha(128)
                          : AppTheme.outlineLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step Sidebar (Desktop) ───────────────────────────────────────────────────

class _StepSidebar extends StatelessWidget {
  final OnboardingProvider provider;
  const _StepSidebar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ReserveHub',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Business Setup',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: OnboardingStep.values.length,
              itemBuilder: (context, i) {
                final step = OnboardingStep.values[i];
                final isCompleted = provider.progress.isStepCompleted(step);
                final isCurrent = provider.currentStep == step;

                return _SidebarStepTile(
                  step: step,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  onTap: isCompleted ? () => provider.goToStep(step) : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: provider.progressPercent,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accent,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(provider.progressPercent * 100).round()}% complete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarStepTile extends StatelessWidget {
  final OnboardingStep step;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _SidebarStepTile({
    required this.step,
    required this.isCompleted,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.white.withAlpha(38) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.accent
                    : isCurrent
                    ? Colors.white
                    : Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppTheme.primary)
                    : Text(
                        '${step.index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? AppTheme.primary
                              : Colors.white.withAlpha(179),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isCurrent
                      ? Colors.white
                      : isCompleted
                      ? Colors.white.withAlpha(230)
                      : Colors.white.withAlpha(128),
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step Content Router ──────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  final OnboardingProvider provider;
  const _StepContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.organization == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey(provider.currentStep),
        child: _buildStep(context, provider.currentStep),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingStep step) {
    switch (step) {
      case OnboardingStep.organization:
        return const ObStepOrganizationWidget();
      case OnboardingStep.business:
        return const ObStepBusinessWidget();
      case OnboardingStep.branch:
        return const ObStepBranchWidget();
      case OnboardingStep.services:
        return const ObStepServicesWidget();
      case OnboardingStep.employees:
        return const ObStepEmployeesWidget();
      case OnboardingStep.businessHours:
        return const ObStepHoursWidget();
      case OnboardingStep.bookingSettings:
        return const ObStepBookingSettingsWidget();
      case OnboardingStep.review:
        return const ObStepReviewWidget();
    }
  }
}
