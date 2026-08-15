import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';
import './ob_step_wrapper.dart';

/// Step 5: Employees configuration.
class ObStepEmployeesWidget extends StatefulWidget {
  const ObStepEmployeesWidget({super.key});

  @override
  State<ObStepEmployeesWidget> createState() => _ObStepEmployeesWidgetState();
}

class _ObStepEmployeesWidgetState extends State<ObStepEmployeesWidget> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return ObStepWrapper(
      title: AppStrings.obStepTitleEmployees,
      subtitle: AppStrings.obStepSubtitleEmployees,
      isLoading: provider.isLoading,
      onBack: () => provider.goToStep(OnboardingStep.services),
      onNext: () {
        provider.markEmployeesComplete();
        provider.completeStep(OnboardingStep.employees);
      },
      nextLabel: provider.employees.isEmpty
          ? AppStrings.skipForNow
          : AppStrings.continue_,
      extraAction: TextButton.icon(
        onPressed: () => _showEmployeeDialog(context, null),
        icon: const Icon(Icons.person_add_outlined, size: 16),
        label: Text(AppStrings.obAddEmployee),
        style: TextButton.styleFrom(foregroundColor: AppTheme.secondary),
      ),
      child: Column(
        children: [
          if (provider.employees.isEmpty)
            _EmptyEmployeesCard(onAdd: () => _showEmployeeDialog(context, null))
          else
            ...provider.employees.map(
              (emp) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EmployeeCard(
                  employee: emp,
                  services: provider.services,
                  onEdit: () => _showEmployeeDialog(context, emp),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEmployeeDialog(
    BuildContext context,
    OnboardingEmployeeEntity? existing,
  ) async {
    final provider = context.read<OnboardingProvider>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EmployeeDialog(
        existing: existing,
        services: provider.services,
        onSave: (emp) async {
          await provider.saveEmployee(emp);
        },
      ),
    );
  }
}

class _EmptyEmployeesCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyEmployeesCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: AppTheme.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.obNoEmployeesYet,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.obNoEmployeesSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: Text(AppStrings.obAddFirstEmployee),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final OnboardingEmployeeEntity employee;
  final List<OnboardingServiceEntity> services;
  final VoidCallback onEdit;

  const _EmployeeCard({
    required this.employee,
    required this.services,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final assignedServices = services
        .where((s) => employee.serviceIds.contains(s.id))
        .map((s) => s.name)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.secondaryContainer,
            backgroundImage: employee.avatarUrl != null
                ? NetworkImage(employee.avatarUrl!)
                : null,
            child: employee.avatarUrl == null
                ? Text(
                    employee.firstName.isNotEmpty
                        ? employee.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (assignedServices.isNotEmpty)
                  Text(
                    assignedServices.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                else
                  Text(
                    AppStrings.obNoServicesAssigned,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: employee.isActive
                  ? AppTheme.successContainer
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              employee.isActive ? AppStrings.active : AppStrings.inactive,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: employee.isActive
                    ? AppTheme.success
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

// ─── Employee Dialog ──────────────────────────────────────────────────────────

class _EmployeeDialog extends StatefulWidget {
  final OnboardingEmployeeEntity? existing;
  final List<OnboardingServiceEntity> services;
  final Future<void> Function(OnboardingEmployeeEntity) onSave;

  const _EmployeeDialog({
    this.existing,
    required this.services,
    required this.onSave,
  });

  @override
  State<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<_EmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isActive = true;
  bool _isBookable = true;
  Set<String> _selectedServiceIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _firstNameCtrl.text = e.firstName;
      _lastNameCtrl.text = e.lastName;
      _emailCtrl.text = e.email ?? '';
      _phoneCtrl.text = e.phone ?? '';
      _isActive = e.isActive;
      _isBookable = e.isBookable;
      _selectedServiceIds = Set.from(e.serviceIds);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final emp = OnboardingEmployeeEntity(
      id: widget.existing?.id,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      isActive: _isActive,
      isBookable: _isBookable,
      serviceIds: _selectedServiceIds.toList(),
    );
    await widget.onSave(emp);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.existing == null
                          ? AppStrings.obAddEmployeeTitle
                          : AppStrings.obEditEmployeeTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ObTextField(
                        label: AppStrings.obFirstName,
                        hint: AppStrings.obFirstNameHint,
                        controller: _firstNameCtrl,
                        required: true,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppStrings.obFieldRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ObTextField(
                        label: AppStrings.obLastName,
                        hint: AppStrings.obLastNameHint,
                        controller: _lastNameCtrl,
                        required: true,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppStrings.obFieldRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ObTextField(
                  label: AppStrings.email,
                  hint: AppStrings.obEmployeeEmailHint,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                      return AppStrings.obInvalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ObTextField(
                  label: AppStrings.phone,
                  hint: AppStrings.obEmployeePhoneHint,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleRow(
                        label: AppStrings.active,
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ToggleRow(
                        label: AppStrings.obBookable,
                        value: _isBookable,
                        onChanged: (v) => setState(() => _isBookable = v),
                      ),
                    ),
                  ],
                ),
                if (widget.services.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.obAssignedServices,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.services.map((svc) {
                      final selected = _selectedServiceIds.contains(svc.id);
                      return FilterChip(
                        label: Text(svc.name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedServiceIds.add(svc.id!);
                            } else {
                              _selectedServiceIds.remove(svc.id);
                            }
                          });
                        },
                        selectedColor: AppTheme.secondaryContainer,
                        checkmarkColor: AppTheme.secondary,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(AppStrings.obSaveEmployee),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
