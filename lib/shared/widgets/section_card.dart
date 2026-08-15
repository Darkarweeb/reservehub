import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable section wrapper used across settings and form screens.
/// Renders a titled card container with optional trailing action.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
          ),
          Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
