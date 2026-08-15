import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import './ob_step_wrapper.dart';

/// Step 3: Branch setup.
class ObStepBranchWidget extends StatefulWidget {
  const ObStepBranchWidget({super.key});

  @override
  State<ObStepBranchWidget> createState() => _ObStepBranchWidgetState();
}

class _ObStepBranchWidgetState extends State<ObStepBranchWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _timezone = 'UTC';

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
    final branch = provider.branch;
    if (branch != null) {
      _nameCtrl.text = branch.name;
      _addressCtrl.text = branch.address ?? '';
      _cityCtrl.text = branch.city ?? '';
      _countryCtrl.text = branch.country ?? '';
      _phoneCtrl.text = branch.phone ?? '';
      _emailCtrl.text = branch.email ?? '';
      _timezone = branch.timezone ?? 'UTC';
    } else {
      // Pre-fill from business
      final biz = provider.business;
      if (biz != null) {
        _nameCtrl.text = '${biz.name} - Main Branch';
        _timezone = biz.timezone ?? 'UTC';
      }
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

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.saveBranch(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim().isEmpty
          ? null
          : _countryCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      timezone: _timezone,
    );
    if (ok && mounted) {
      provider.completeStep(OnboardingStep.branch);
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
        title: 'Your First Location',
        subtitle:
            'Add your primary branch. You can add more locations from the dashboard later.',
        isLoading: provider.isLoading,
        onBack: () => provider.goToStep(OnboardingStep.business),
        onNext: _onNext,
        child: Column(
          children: [
            ObSectionCard(
              title: 'Branch Details',
              child: Column(
                children: [
                  ObTextField(
                    label: 'Branch Name',
                    hint: 'e.g. Main Branch, Downtown Location',
                    controller: _nameCtrl,
                    required: true,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Branch name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: 'Street Address',
                    hint: '123 Main Street',
                    controller: _addressCtrl,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ObTextField(
                          label: 'City',
                          hint: 'New York',
                          controller: _cityCtrl,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ObTextField(
                          label: 'Country',
                          hint: 'United States',
                          controller: _countryCtrl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ObSectionCard(
              title: 'Contact & Timezone',
              child: Column(
                children: [
                  ObTextField(
                    label: 'Branch Phone',
                    hint: '+1 555 000 0000',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  ObTextField(
                    label: 'Branch Email',
                    hint: 'branch@yourbusiness.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _DropdownField(
                    label: 'Branch Timezone',
                    value: _timezone,
                    items: _timezones,
                    onChanged: (v) => setState(() => _timezone = v!),
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
