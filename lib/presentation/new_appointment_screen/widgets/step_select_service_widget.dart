import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class StepSelectServiceWidget extends StatelessWidget {
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const StepSelectServiceWidget({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static final List<Map<String, dynamic>> _services = [
    {
      'id': 'svc001',
      'name': 'Haircut & Style',
      'duration': '45 min',
      'price': 65,
      'category': 'Hair',
      'imageUrl':
          'https://images.unsplash.com/photo-1581404788767-726320400cea',
      'imageLabel': 'Stylist cutting and styling hair in modern salon',
    },
    {
      'id': 'svc002',
      'name': 'Balayage + Cut',
      'duration': '90 min',
      'price': 185,
      'category': 'Color',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1caca9d86-1772995193374.png',
      'imageLabel': 'Hair colorist applying balayage technique to long hair',
    },
    {
      'id': 'svc003',
      'name': 'Gel Manicure',
      'duration': '45 min',
      'price': 65,
      'category': 'Nails',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1bd0f3871-1770241959658.png',
      'imageLabel': 'Nail technician applying gel polish to client fingernails',
    },
    {
      'id': 'svc004',
      'name': 'Deep Tissue Massage',
      'duration': '90 min',
      'price': 140,
      'category': 'Massage',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16bfe256c-1772238479088.png',
      'imageLabel':
          'Massage therapist performing deep tissue massage on client back',
    },
    {
      'id': 'svc005',
      'name': 'Classic Facial',
      'duration': '60 min',
      'price': 110,
      'category': 'Skin',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_132df1612-1772074995270.png',
      'imageLabel':
          'Esthetician performing facial treatment on client in spa setting',
    },
    {
      'id': 'svc006',
      'name': 'Full Highlights',
      'duration': '120 min',
      'price': 220,
      'category': 'Color',
      'imageUrl':
          'https://images.unsplash.com/photo-1612379172887-070d61c2c9c2',
      'imageLabel':
          'Hair stylist applying full highlights with foils to client hair',
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
            'What service do you need?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select one service to continue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          // Service list — image 40% left + info 60% right (locked anatomy from reference)
          ...List.generate(_services.length, (i) {
            final svc = _services[i];
            final isSelected = selected?['id'] == svc['id'];
            return _ServiceListCard(
              service: svc,
              isSelected: isSelected,
              onTap: () => onSelected(svc),
            );
          }),
        ],
      ),
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceListCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryContainer
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondary
                : AppTheme.outlineVariantLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Anatomy locked: image 40% left + info 60% right + price + pill button
        child: Row(
          children: [
            // Image — 40% of card width
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 40) * 0.4,
                height: 110,
                child: CustomImageWidget(
                  imageUrl: service['imageUrl'] as String,
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                  semanticLabel: service['imageLabel'] as String,
                ),
              ),
            ),
            // Info — 60% right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service['category'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${service['price']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        // Pill "Book Now" button — locked anatomy
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.secondary
                                : AppTheme.primary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            isSelected ? 'Selected' : 'Select',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
