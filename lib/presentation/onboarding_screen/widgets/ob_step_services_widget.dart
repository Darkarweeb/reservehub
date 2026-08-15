import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../features/onboarding/domain/entities/onboarding_entities.dart';
import '../../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../theme/app_theme.dart';
import './ob_step_wrapper.dart';

/// Step 4: Services configuration.
class ObStepServicesWidget extends StatefulWidget {
  const ObStepServicesWidget({super.key});

  @override
  State<ObStepServicesWidget> createState() => _ObStepServicesWidgetState();
}

class _ObStepServicesWidgetState extends State<ObStepServicesWidget> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return ObStepWrapper(
      title: 'Your Services',
      subtitle:
          'Add the services your business offers. You can edit these later.',
      isLoading: provider.isLoading,
      onBack: () => provider.goToStep(OnboardingStep.branch),
      onNext: () {
        provider.markServicesComplete();
        provider.completeStep(OnboardingStep.services);
      },
      nextLabel: provider.services.isEmpty ? 'Skip for now' : 'Continue',
      extraAction: TextButton.icon(
        onPressed: () => _showServiceDialog(context, null),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Service'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.secondary),
      ),
      child: Column(
        children: [
          if (provider.services.isEmpty)
            _EmptyServicesCard(onAdd: () => _showServiceDialog(context, null))
          else
            ...provider.services.map(
              (svc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceCard(
                  service: svc,
                  onEdit: () => _showServiceDialog(context, svc),
                  onDelete: () => _confirmDelete(context, svc),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showServiceDialog(
    BuildContext context,
    OnboardingServiceEntity? existing,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ServiceDialog(
        existing: existing,
        onSave: (svc) async {
          final provider = context.read<OnboardingProvider>();
          await provider.saveService(svc);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OnboardingServiceEntity svc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Remove "${svc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted && svc.id != null) {
      await context.read<OnboardingProvider>().deleteService(svc.id!);
    }
  }
}

class _EmptyServicesCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyServicesCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineLight,
          style: BorderStyle.solid,
        ),
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
              Icons.spa_outlined,
              color: AppTheme.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No services yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the services you offer to customers',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Your First Service'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final OnboardingServiceEntity service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: AppTheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.timer_outlined,
                      label: '${service.durationMins} min',
                    ),
                    const SizedBox(width: 8),
                    if (service.price > 0)
                      _Chip(
                        icon: Icons.attach_money,
                        label:
                            '${service.currency} ${service.price.toStringAsFixed(2)}',
                      ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: service.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      label: service.isActive ? 'Active' : 'Inactive',
                      color: service.isActive
                          ? AppTheme.success
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: const Color(0xFF64748B),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF64748B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
        ),
      ],
    );
  }
}

// ─── Service Dialog ───────────────────────────────────────────────────────────

class _ServiceDialog extends StatefulWidget {
  final OnboardingServiceEntity? existing;
  final Future<void> Function(OnboardingServiceEntity) onSave;

  const _ServiceDialog({this.existing, required this.onSave});

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _bufferBeforeCtrl = TextEditingController(text: '0');
  final _bufferAfterCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController(text: '0.00');
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description ?? '';
      _durationCtrl.text = e.durationMins.toString();
      _bufferBeforeCtrl.text = e.bufferBeforeMins.toString();
      _bufferAfterCtrl.text = e.bufferAfterMins.toString();
      _priceCtrl.text = e.price.toStringAsFixed(2);
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _bufferBeforeCtrl.dispose();
    _bufferAfterCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = OnboardingServiceEntity(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      durationMins: int.tryParse(_durationCtrl.text) ?? 60,
      bufferBeforeMins: int.tryParse(_bufferBeforeCtrl.text) ?? 0,
      bufferAfterMins: int.tryParse(_bufferAfterCtrl.text) ?? 0,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      isActive: _isActive,
    );
    await widget.onSave(svc);
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
                      widget.existing == null ? 'Add Service' : 'Edit Service',
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
                ObTextField(
                  label: 'Service Name',
                  hint: 'e.g. Haircut, Massage, Consultation',
                  controller: _nameCtrl,
                  required: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Service name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                ObTextField(
                  label: 'Description',
                  hint: 'Brief description of this service...',
                  controller: _descCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: 'Duration (min)',
                        controller: _durationCtrl,
                        required: true,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label: 'Buffer Before (min)',
                        controller: _bufferBeforeCtrl,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label: 'Buffer After (min)',
                        controller: _bufferAfterCtrl,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ObTextField(
                        label: 'Display Price',
                        hint: '0.00',
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: const Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Switch(
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isActive ? 'Active' : 'Inactive',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
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
                          : const Text('Save Service'),
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

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool required;

  const _NumField({
    required this.label,
    required this.controller,
    this.validator,
    this.required = false,
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
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
