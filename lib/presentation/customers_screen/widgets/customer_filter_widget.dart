import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../localization/app_strings.dart';
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
    {'key': 'All', 'icon': Icons.people_outline_rounded},
    {'key': 'Active', 'icon': Icons.check_circle_outline_rounded},
    {'key': 'VIP', 'icon': Icons.star_outline_rounded},
    {'key': 'New', 'icon': Icons.fiber_new_outlined},
    {'key': 'At-Risk', 'icon': Icons.warning_amber_outlined},
  ];

  String _labelFor(String key) {
    switch (key) {
      case 'All':
        return AppStrings.customerFilterAll;
      case 'Active':
        return AppStrings.customerFilterActive;
      case 'VIP':
        return AppStrings.customerFilterVip;
      case 'New':
        return AppStrings.customerFilterNew;
      case 'At-Risk':
        return AppStrings.customerFilterAtRisk;
      default:
        return key;
    }
  }

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
          final key = filter['key'] as String;
          final icon = filter['icon'] as IconData;
          final isActive = selected == key;
          final label = _labelFor(key);
          return GestureDetector(
            onTap: () => onSelected(key),
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
