import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../localization/app_strings.dart';
import '../../navigation/route_names.dart';
import '../../shared/utils/responsive_builder.dart';
import '../../widgets/brand/reserve_hub_logo.dart';
import '../../widgets/brand/rh_background_painter.dart';
import './widgets/auth_form_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RHBrandTokens.deepNavy,
      body: ResponsiveBuilder(
        builder: (context, size) {
          if (size == ScreenSize.desktop) return _buildDesktopLayout();
          if (size == ScreenSize.tablet) return _buildTabletLayout();
          return _buildMobileLayout();
        },
      ),
    );
  }

  // ─── Desktop: split left brand / right auth ─────────────────────────────

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LEFT — brand panel
        Expanded(flex: 55, child: _buildBrandPanel()),
        // RIGHT — auth panel
        Expanded(flex: 45, child: _buildAuthPanel()),
      ],
    );
  }

  Widget _buildBrandPanel() {
    return Stack(
      children: [
        // Animated futuristic background
        const Positioned.fill(child: RHFuturisticBackground()),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RHBrandTokens.brandPanelPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo lockup
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const ReserveHubBrand(
                      logoSize: 48,
                      wordmarkSize: 22,
                      showGlow: true,
                    ),
                  ),
                ),
                const Spacer(),
                // Hero headline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.heroBrandHeadline,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: RHBrandTokens.textOnDark,
                          height: 1.12,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.appTagline,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: RHBrandTokens.textOnDarkMuted,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Feature pills
                      _buildFeaturePill(
                        Icons.schedule_rounded,
                        AppStrings.featureSmartScheduling,
                        AppStrings.featureSmartSchedulingSubtitle,
                      ),
                      const SizedBox(height: 14),
                      _buildFeaturePill(
                        Icons.people_alt_rounded,
                        AppStrings.featureCustomerManagement,
                        AppStrings.featureCustomerManagementSubtitle,
                      ),
                      const SizedBox(height: 14),
                      _buildFeaturePill(
                        Icons.bar_chart_rounded,
                        AppStrings.featureBusinessAnalytics,
                        AppStrings.featureBusinessAnalyticsSubtitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Bottom tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppStrings.appFooterTagline,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: RHBrandTokens.textOnDarkSubtle,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthPanel() {
    return Container(
      color: const Color(0xFFF4F5F7),
      child: SafeArea(
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Auth card header
                      Text(
                        AppStrings.welcomeBack,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A0F1E),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.signInToPortal,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Premium auth card
                      _buildPremiumAuthCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tablet layout ───────────────────────────────────────────────────────

  Widget _buildTabletLayout() {
    return Stack(
      children: [
        // Full background
        const Positioned.fill(child: RHFuturisticBackground()),
        SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: const ReserveHubBrand(
                          logoSize: 52,
                          wordmarkSize: 24,
                          showGlow: true,
                          direction: Axis.vertical,
                          spacing: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.heroBrandHeadline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: RHBrandTokens.textOnDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildPremiumAuthCard(isGlass: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile layout ───────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Top brand area with background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.38,
          child: Stack(
            children: [
              const Positioned.fill(child: RHFuturisticBackground()),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: const ReserveHubBrand(
                          logoSize: 40,
                          wordmarkSize: 20,
                          showGlow: true,
                        ),
                      ),
                      const Spacer(),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.heroBrandHeadline,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom auth card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                  ),
                ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 32,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: AuthFormWidget(
                  onAuthSuccess: () => context.go(RouteNames.dashboard),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────

  Widget _buildPremiumAuthCard({bool isGlass = false}) {
    if (isGlass) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(242),
          borderRadius: BorderRadius.circular(RHBrandTokens.authCardRadius),
          border: Border.all(color: Colors.white.withAlpha(100), width: 1),
          boxShadow: [
            BoxShadow(
              color: RHBrandTokens.authCardShadow,
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AuthFormWidget(
          onAuthSuccess: () => context.go(RouteNames.dashboard),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RHBrandTokens.authCardRadius),
        border: Border.all(color: RHBrandTokens.authCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: RHBrandTokens.authCardShadow,
            blurRadius: 48,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AuthFormWidget(
        onAuthSuccess: () => context.go(RouteNames.dashboard),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RHBrandTokens.electricBlue.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RHBrandTokens.electricBlue.withAlpha(60),
              width: 1,
            ),
          ),
          child: Icon(icon, color: RHBrandTokens.electricBlueLight, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RHBrandTokens.textOnDark,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: RHBrandTokens.textOnDarkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
