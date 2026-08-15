import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Shared wrapper for all onboarding step content.
/// Provides consistent padding, title, subtitle, and action buttons.
class ObStepWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isLoading;
  final bool canGoNext;
  final Widget? extraAction;

  const ObStepWrapper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Continue',
    this.isLoading = false,
    this.canGoNext = true,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final contentWidth = isWide ? 640.0 : double.infinity;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 20,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Content
                  child,

                  const SizedBox(height: 40),

                  // Actions
                  Row(
                    children: [
                      if (onBack != null) ...[
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : onBack,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(
                              color: AppTheme.outlineLight,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (extraAction != null) ...[
                        extraAction!,
                        const SizedBox(width: 12),
                      ],
                      const Spacer(),
                      if (onNext != null)
                        FilledButton(
                          onPressed: (isLoading || !canGoNext) ? null : onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(nextLabel),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 16),
                                  ],
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reusable labeled text field for onboarding forms.
class ObTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final Widget? suffix;
  final VoidCallback? onEditingComplete;
  final bool enabled;

  const ObTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.suffix,
    this.onEditingComplete,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
            children: required
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}

/// Reusable section card for onboarding forms.
class ObSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets? padding;

  const ObSectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 24),
          ],
          Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}
