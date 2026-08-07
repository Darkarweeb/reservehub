import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class OnboardingHeroWidget extends StatelessWidget {
  const OnboardingHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.62,
      width: double.infinity,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8EAF6),
                  Color(0xFFF0F4FF),
                  Color(0xFFE8F4FD),
                ],
              ),
            ),
          ),
          // Hero image
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.75,
            child: CustomImageWidget(
              imageUrl:
                  'https://images.pexels.com/photos/3985163/pexels-photo-3985163.jpeg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              semanticLabel:
                  'Professional woman in business attire smiling confidently at camera in modern office setting',
            ),
          ),
          // Gradient fade bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.backgroundLight.withAlpha(242),
                  ],
                ),
              ),
            ),
          ),
          // Text overlay
          Positioned(
            bottom: 40,
            left: 28,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Manage Time\n',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Better.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.primary.withAlpha(166),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The all-in-one booking platform for\nservice businesses of every size.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
