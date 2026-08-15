import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/route_names.dart';
import '../../shared/utils/responsive_builder.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_form_widget.dart';
import './widgets/onboarding_hero_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
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
      backgroundColor: AppTheme.backgroundLight,
      body: ResponsiveBuilder(
        builder: (context, size) {
          if (size == ScreenSize.desktop) return _buildDesktopLayout();
          if (size == ScreenSize.tablet) return _buildTabletLayout();
          return _buildPhoneLayout();
        },
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        const OnboardingHeroWidget(),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildAuthCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: SizedBox(
        width: 480,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildBrandHeader(),
                const SizedBox(height: 32),
                _buildAuthCard(isRounded: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel — brand / hero
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.primary,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(38),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ReserveHub',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    Text(
                      'Where businesses\nmanage time better.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'The all-in-one booking platform for modern businesses.\nManage appointments, customers, and your team — all in one place.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withAlpha(200),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildFeaturePill(
                      Icons.calendar_month_rounded,
                      'Smart Scheduling',
                    ),
                    const SizedBox(height: 12),
                    _buildFeaturePill(
                      Icons.people_rounded,
                      'Customer Management',
                    ),
                    const SizedBox(height: 12),
                    _buildFeaturePill(
                      Icons.bar_chart_rounded,
                      'Business Analytics',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right panel — auth form
        Expanded(
          flex: 4,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to your business portal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AuthFormWidget(
                          onAuthSuccess: () => context.go(RouteNames.dashboard),
                        ),
                      ),
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

  Widget _buildFeaturePill(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha(220),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ReserveHub',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Where businesses manage time better.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard({bool isRounded = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(28),
          topRight: const Radius.circular(28),
          bottomLeft: Radius.circular(isRounded ? 28 : 0),
          bottomRight: Radius.circular(isRounded ? 28 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AuthFormWidget(
        onAuthSuccess: () => context.go(RouteNames.dashboard),
      ),
    );
  }
}
