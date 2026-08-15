import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';
import './ob_step_wrapper.dart';

/// Step 7: Booking settings configuration.
class ObStepBookingSettingsWidget extends StatefulWidget {
  const ObStepBookingSettingsWidget({super.key});

  @override
  State<ObStepBookingSettingsWidget> createState() =>
      _ObStepBookingSettingsWidgetState();
}

class _ObStepBookingSettingsWidgetState
    extends State<ObStepBookingSettingsWidget> {
  late OnboardingBookingSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<OnboardingProvider>().bookingSettings;
  }

  void _update(OnboardingBookingSettings updated) {
    setState(() => _settings = updated);
    context.read<OnboardingProvider>().updateBookingSettings(updated);
  }

  Future<void> _onNext() async {
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.saveBookingSettings();
    if (ok && mounted) {
      provider.completeStep(OnboardingStep.bookingSettings);
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return ObStepWrapper(
      title: AppStrings.obStepTitleBookingSettings,
      subtitle: AppStrings.obStepSubtitleBookingSettings,
      isLoading: provider.isLoading,
      onBack: () => provider.goToStep(OnboardingStep.businessHours),
      onNext: _onNext,
      child: Column(
        children: [
          // Reservas en línea
          ObSectionCard(
            title: AppStrings.obOnlineBookingSection,
            child: Column(
              children: [
                _ToggleRow(
                  label: AppStrings.obEnableOnlineBooking,
                  subtitle: AppStrings.obEnableOnlineBookingSubtitle,
                  value: _settings.onlineBookingEnabled,
                  onChanged: (v) =>
                      _update(_settings.copyWith(onlineBookingEnabled: v)),
                ),
                const Divider(height: 24),
                _ToggleRow(
                  label: AppStrings.obAllowGuestBooking,
                  subtitle: AppStrings.obAllowGuestBookingSubtitle,
                  value: _settings.allowGuestBooking,
                  onChanged: (v) =>
                      _update(_settings.copyWith(allowGuestBooking: v)),
                ),
                const Divider(height: 24),
                _ToggleRow(
                  label: AppStrings.obShowEmployeeSelection,
                  subtitle: AppStrings.obShowEmployeeSelectionSubtitle,
                  value: _settings.showEmployeeSelection,
                  onChanged: (v) =>
                      _update(_settings.copyWith(showEmployeeSelection: v)),
                ),
                const Divider(height: 24),
                _ToggleRow(
                  label: AppStrings.obShowServicePrices,
                  subtitle: AppStrings.obShowServicePricesSubtitle,
                  value: _settings.showPrice,
                  onChanged: (v) => _update(_settings.copyWith(showPrice: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirmación
          ObSectionCard(
            title: AppStrings.obConfirmationSection,
            child: _ToggleRow(
              label: AppStrings.obAutoConfirm,
              subtitle: AppStrings.obAutoConfirmSubtitle,
              value: _settings.autoConfirm,
              onChanged: (v) => _update(_settings.copyWith(autoConfirm: v)),
            ),
          ),
          const SizedBox(height: 16),

          // Ventana de reservas
          ObSectionCard(
            title: AppStrings.obBookingWindowSection,
            child: Column(
              children: [
                _NumberRow(
                  label: AppStrings.obMinimumNotice,
                  subtitle: AppStrings.obMinimumNoticeSubtitle,
                  value: _settings.minAdvanceBookingHours,
                  unit: AppStrings.obUnitHours,
                  min: 0,
                  max: 168,
                  onChanged: (v) =>
                      _update(_settings.copyWith(minAdvanceBookingHours: v)),
                ),
                const Divider(height: 24),
                _NumberRow(
                  label: AppStrings.obMaximumHorizon,
                  subtitle: AppStrings.obMaximumHorizonSubtitle,
                  value: _settings.maxAdvanceBookingDays,
                  unit: AppStrings.obUnitDays,
                  min: 1,
                  max: 365,
                  onChanged: (v) =>
                      _update(_settings.copyWith(maxAdvanceBookingDays: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Política de cancelación
          ObSectionCard(
            title: AppStrings.obCancellationPolicySection,
            child: Column(
              children: [
                _ToggleRow(
                  label: AppStrings.obAllowCancellations,
                  subtitle: AppStrings.obAllowCancellationsSubtitle,
                  value: _settings.cancellationEnabled,
                  onChanged: (v) =>
                      _update(_settings.copyWith(cancellationEnabled: v)),
                ),
                if (_settings.cancellationEnabled) ...[
                  const Divider(height: 24),
                  _NumberRow(
                    label: AppStrings.obCancellationNotice,
                    subtitle: AppStrings.obCancellationNoticeSubtitle,
                    value: _settings.minCancellationNoticeHours,
                    unit: AppStrings.obUnitHours,
                    min: 0,
                    max: 168,
                    onChanged: (v) => _update(
                      _settings.copyWith(minCancellationNoticeHours: v),
                    ),
                  ),
                  const Divider(height: 24),
                  _ToggleRow(
                    label: AppStrings.obAllowRescheduling,
                    subtitle: AppStrings.obAllowReschedulingSubtitle,
                    value: _settings.reschedulingEnabled,
                    onChanged: (v) =>
                        _update(_settings.copyWith(reschedulingEnabled: v)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _NumberRow extends StatefulWidget {
  final String label;
  final String subtitle;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

class _NumberRowState extends State<_NumberRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            IconButton(
              onPressed: widget.value > widget.min
                  ? () {
                      final v = widget.value - 1;
                      _ctrl.text = v.toString();
                      widget.onChanged(v);
                    }
                  : null,
              icon: const Icon(Icons.remove, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceVariantLight,
                minimumSize: const Size(32, 32),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= widget.min && n <= widget.max) {
                    widget.onChanged(n);
                  }
                },
              ),
            ),
            IconButton(
              onPressed: widget.value < widget.max
                  ? () {
                      final v = widget.value + 1;
                      _ctrl.text = v.toString();
                      widget.onChanged(v);
                    }
                  : null,
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceVariantLight,
                minimumSize: const Size(32, 32),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.unit,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }
}
