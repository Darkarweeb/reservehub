import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';
import './ob_step_wrapper.dart';

/// Step 2: Business creation.
class ObStepBusinessWidget extends StatefulWidget {
  const ObStepBusinessWidget({super.key});

  @override
  State<ObStepBusinessWidget> createState() => _ObStepBusinessWidgetState();
}

class _ObStepBusinessWidgetState extends State<ObStepBusinessWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _timezone = 'UTC';
  String? _slugError;
  bool _checkingSlug = false;

  static const _timezones = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Toronto',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<OnboardingProvider>();
    final biz = provider.business;
    if (biz != null) {
      _nameCtrl.text = biz.name;
      _slugCtrl.text = biz.slug ?? '';
      _descCtrl.text = biz.description ?? '';
      _phoneCtrl.text = biz.phone ?? '';
      _emailCtrl.text = biz.email ?? '';
      _websiteCtrl.text = biz.website ?? '';
      _timezone = biz.timezone ?? 'UTC';
    }

    _nameCtrl.addListener(_autoSlug);
  }

  void _autoSlug() {
    if (_slugCtrl.text.isEmpty || _slugCtrl.text == _slugify(_nameCtrl.text)) {
      _slugCtrl.text = _slugify(_nameCtrl.text);
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_autoSlug);
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSlug() async {
    final slug = _slugCtrl.text.trim();
    if (slug.isEmpty) return;
    setState(() {
      _checkingSlug = true;
      _slugError = null;
    });
    final provider = context.read<OnboardingProvider>();
    final available = await provider.isSlugAvailable(slug);
    if (mounted) {
      setState(() {
        _checkingSlug = false;
        _slugError = available ? null : AppStrings.obSlugTaken;
      });
    }
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slugError != null) return;

    final provider = context.read<OnboardingProvider>();
    final ok = await provider.saveBusiness(
      name: _nameCtrl.text.trim(),
      slug: _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      timezone: _timezone,
    );
    if (ok && mounted) {
      provider.completeStep(OnboardingStep.business);
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
    return Form(
      key: _formKey,
      child: ObStepWrapper(
        title: AppStrings.obStepTitleBusiness,
        subtitle: AppStrings.obStepSubtitleBusiness,
        isLoading: provider.isLoading,
        onBack: () => provider.goToStep(OnboardingStep.organization),
        onNext: _onNext,
        child: Column(
          children: [
            ObSectionCard(
              title: AppStrings.obBusinessProfile,
              child: Column(
                children: [
                  ObTextField(
                    label: AppStrings.obBusinessNameLabel,
                    hint: AppStrings.obBusinessNameHint,
                    controller: _nameCtrl,
                    required: true,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.obBusinessNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: AppStrings.obPublicUrlSlug,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: const Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppTheme.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _slugCtrl,
                        onEditingComplete: _checkSlug,
                        onChanged: (_) => setState(() => _slugError = null),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return AppStrings.obSlugRequired;
                          }
                          if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                            return AppStrings.obSlugInvalidChars;
                          }
                          if (_slugError != null) return _slugError;
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: AppStrings.obPublicUrlSlugHint,
                          prefixText: 'reservehub.com/b/',
                          prefixStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          suffixIcon: _checkingSlug
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _slugError == null && _slugCtrl.text.isNotEmpty
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.success,
                                  size: 20,
                                )
                              : null,
                          errorText: _slugError,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.obSlugHelperText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: AppStrings.businessDescription,
                    hint: AppStrings.obDescriptionHint,
                    controller: _descCtrl,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ObSectionCard(
              title: AppStrings.obContactInformation,
              child: Column(
                children: [
                  ObTextField(
                    label: AppStrings.businessPhone,
                    hint: AppStrings.obBusinessPhoneHint,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: AppStrings.businessEmail,
                    hint: AppStrings.obBusinessEmailHint,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: AppStrings.obWebsite,
                    hint: AppStrings.obWebsiteHint,
                    controller: _websiteCtrl,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ObSectionCard(
              title: AppStrings.obRegionalSettings,
              child: _DropdownField(
                label: AppStrings.obBusinessTimezone,
                value: _timezone,
                items: _timezones,
                onChanged: (v) => setState(() => _timezone = v!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(),
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
