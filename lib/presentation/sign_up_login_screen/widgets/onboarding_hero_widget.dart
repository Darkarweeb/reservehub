import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../localization/app_strings.dart';
import '../../../widgets/brand/reserve_hub_logo.dart';
import '../../../widgets/brand/rh_background_painter.dart';

/// Mobile hero widget — replaces generic stock photography
/// with the ReserveHub brand identity on a futuristic background.
class OnboardingHeroWidget extends StatelessWidget {
  const OnboardingHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.42,
      width: double.infinity,
      child: Stack(
        children: [
          // Futuristic brand background
          const Positioned.fill(child: RHFuturisticBackground()),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ReserveHubBrand(
                    logoSize: 40,
                    wordmarkSize: 20,
                    showGlow: true,
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.heroBrandHeadline,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: RHBrandTokens.textOnDark,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appSubheadline,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: RHBrandTokens.textOnDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
