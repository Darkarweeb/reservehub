import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import './ob_step_wrapper.dart';

/// Step 1: Organization setup.
class ObStepOrganizationWidget extends StatefulWidget {
  const ObStepOrganizationWidget({super.key});

  @override
  State<ObStepOrganizationWidget> createState() =>
      _ObStepOrganizationWidgetState();
}

class _ObStepOrganizationWidgetState extends State<ObStepOrganizationWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _timezone = 'UTC';
  String _currency = 'USD';

  static const _timezones = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Toronto',
    'America/Vancouver',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Madrid',
    'Europe/Rome',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Australia/Sydney',
    'Australia/Melbourne',
    'Pacific/Auckland',
  ];

  static const _currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'NZD',
    'SGD',
    'AED',
    'INR',
    'JPY',
    'CNY',
    'BRL',
    'MXN',
    'ZAR',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<OnboardingProvider>();
    final org = provider.organization;
    if (org != null) {
      _nameCtrl.text = org.name;
      _emailCtrl.text = org.email ?? '';
      _phoneCtrl.text = org.phone ?? '';
      _timezone = org.timezone ?? 'UTC';
      _currency = org.currency ?? 'USD';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.saveOrganization(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      timezone: _timezone,
      currency: _currency,
    );
    if (ok && mounted) {
      provider.completeStep(OnboardingStep.organization);
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
        title: 'Your Organization',
        subtitle:
            'An organization is the top-level account that can contain multiple businesses.',
        isLoading: provider.isLoading,
        onNext: _onNext,
        child: Column(
          children: [
            ObSectionCard(
              title: 'Organization Details',
              child: Column(
                children: [
                  ObTextField(
                    label: 'Organization Name',
                    hint: 'e.g. Acme Corp, Smith Family Businesses',
                    controller: _nameCtrl,
                    required: true,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Organization name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: 'Contact Email',
                    hint: 'admin@yourcompany.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: 'Phone',
                    hint: '+1 555 000 0000',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ObSectionCard(
              title: 'Regional Settings',
              child: Column(
                children: [
                  _DropdownField(
                    label: 'Default Timezone',
                    value: _timezone,
                    items: _timezones,
                    onChanged: (v) => setState(() => _timezone = v!),
                  ),
                  const SizedBox(height: 16),
                  _DropdownField(
                    label: 'Currency',
                    value: _currency,
                    items: _currencies,
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ],
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
