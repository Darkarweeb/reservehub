import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class StepSelectStaffWidget extends StatelessWidget {
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final String? serviceId;

  const StepSelectStaffWidget({
    required this.selected,
    required this.onSelected,
    this.serviceId,
    super.key,
  });

  static final List<Map<String, dynamic>> _staff = [
    {
      'id': 'emp001',
      'name': 'Sofia Mendes',
      'role': 'Senior Stylist',
      'rating': 4.9,
      'reviews': 142,
      'experience': '8 years',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_10a356c8d-1774955369730.png',
      'avatarLabel':
          'Professional female hair stylist with dark curly hair smiling in salon',
      'available': true,
      'specialties': ['Color', 'Balayage', 'Cuts'],
    },
    {
      'id': 'emp002',
      'name': 'Ana Lima',
      'role': 'Nail Technician',
      'rating': 4.7,
      'reviews': 98,
      'experience': '5 years',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_13e028e74-1773212057508.png',
      'avatarLabel':
          'Friendly nail technician with straight dark hair in professional apron',
      'available': true,
      'specialties': ['Gel Nails', 'Acrylics', 'Nail Art'],
    },
    {
      'id': 'emp003',
      'name': 'Rafael Souza',
      'role': 'Barber',
      'rating': 4.8,
      'reviews': 211,
      'experience': '10 years',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15a69797c-1763294693658.png',
      'avatarLabel':
          'Male barber with short beard and professional attire in barbershop',
      'available': false,
      'specialties': ['Fades', 'Beard Trim', 'Classic Cuts'],
    },
    {
      'id': 'emp004',
      'name': 'Camila Rocha',
      'role': 'Esthetician',
      'rating': 4.6,
      'reviews': 67,
      'experience': '4 years',
      'avatarUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16b1c87f9-1772073694138.png',
      'avatarLabel': 'Esthetician with natural hair wearing white spa uniform',
      'available': true,
      'specialties': ['Facials', 'Waxing', 'Skincare'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your staff member',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All staff are qualified for your selected service',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_staff.length, (i) {
            final member = _staff[i];
            final isSelected = selected?['id'] == member['id'];
            final isAvailable = member['available'] as bool;
            return _StaffCard(
              member: member,
              isSelected: isSelected,
              onTap: isAvailable ? () => onSelected(member) : null,
            );
          }),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StaffCard({
    required this.member,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = member['available'] as bool;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryContainer
              : isAvailable
              ? AppTheme.surfaceLight
              : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondary
                : AppTheme.outlineVariantLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Opacity(
                    opacity: isAvailable ? 1.0 : 0.5,
                    child: CustomImageWidget(
                      imageUrl: member['avatarUrl'] as String,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      semanticLabel: member['avatarLabel'] as String,
                    ),
                  ),
                ),
                if (!isAvailable)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Busy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isAvailable
                              ? AppTheme.primary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${member['rating']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        ' (${member['reviews']})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${member['role']} · ${member['experience']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: (member['specialties'] as List<String>)
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
