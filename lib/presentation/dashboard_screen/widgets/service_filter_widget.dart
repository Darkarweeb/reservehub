import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';

class ServiceFilterWidget extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const ServiceFilterWidget({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static List<String> get filters => [
    AppStrings.filterAll,
    'Corte',
    'Color',
    'Uñas',
    'Masaje',
    'Facial',
    'Depilación',
  ];

  @override
  Widget build(BuildContext context) {
    final filterList = filters;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              AppStrings.servicesFilterLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = filterList[i];
                final isActive = filter == selected;
                return GestureDetector(
                  onTap: () => onSelected(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.outlineLight,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(51),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
