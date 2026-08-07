import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CustomerFilterWidget extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CustomerFilterWidget({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.people_outline_rounded},
    {'label': 'Active', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'VIP', 'icon': Icons.star_outline_rounded},
    {'label': 'New', 'icon': Icons.fiber_new_outlined},
    {'label': 'At-Risk', 'icon': Icons.warning_amber_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final label = filter['label'] as String;
          final icon = filter['icon'] as IconData;
          final isActive = selected == label;
          return GestureDetector(
            onTap: () => onSelected(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.primary : AppTheme.outlineLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
