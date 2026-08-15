import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ReserveHub brand design tokens for authentication surfaces.
class RHBrandTokens {
  RHBrandTokens._();

  // Core brand palette
  static const Color deepNavy = Color(0xFF0A0F1E);
  static const Color navyMid = Color(0xFF0D1530);
  static const Color navyLight = Color(0xFF1A2547);
  static const Color professionalBlue = Color(0xFF1E3A8A);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color electricBlueLight = Color(0xFF60A5FA);
  static const Color electricBlueFaint = Color(0xFF93C5FD);
  static const Color glowBlue = Color(0xFF2563EB);

  // Glass surface tokens
  static const Color glassSurface = Color(0xF5FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassInner = Color(0x0AFFFFFF);

  // Auth card tokens
  static const Color authCardBg = Color(0xFFFFFFFF);
  static const Color authCardBorder = Color(0xFFE2E8F0);
  static const Color authCardShadow = Color(0x1A1E3A8A);

  // Glow
  static const Color glowColor = Color(0x403B82F6);
  static const Color glowColorStrong = Color(0x603B82F6);

  // Typography on dark
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xB3FFFFFF);
  static const Color textOnDarkSubtle = Color(0x80FFFFFF);

  // Spacing
  static const double brandPanelPadding = 56.0;
  static const double authCardPadding = 32.0;
  static const double authCardRadius = 24.0;
  static const double logoMarkSize = 52.0;
  static const double logoMarkRadius = 16.0;
}

/// The ReserveHub logomark — a stylised calendar/hub icon.
/// Reusable across all brand surfaces.
class ReserveHubLogoMark extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showGlow;

  const ReserveHubLogoMark({
    super.key,
    this.size = 52.0,
    this.backgroundColor,
    this.iconColor,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? RHBrandTokens.electricBlue;
    final ic = iconColor ?? Colors.white;
    final radius = size * 0.3;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RHBrandTokens.electricBlue, RHBrandTokens.professionalBlue],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: RHBrandTokens.glowColorStrong,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: RHBrandTokens.glowColor,
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: RHBrandTokens.authCardShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: CustomPaint(painter: _LogoMarkPainter(color: ic)),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  final Color color;
  const _LogoMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;

    // Outer circle (hub ring)
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), r * 0.18, fillPaint);

    // 4 spokes (scheduling lines)
    final spokeLen = r * 0.55;
    for (int i = 0; i < 4; i++) {
      final angle = (i * 3.14159 / 2) - 3.14159 / 4;
      final dx = cx + (r * 0.28) * _cos(angle);
      final dy = cy + (r * 0.28) * _sin(angle);
      final ex = cx + (r * 0.28 + spokeLen) * _cos(angle);
      final ey = cy + (r * 0.28 + spokeLen) * _sin(angle);
      canvas.drawLine(Offset(dx, dy), Offset(ex, ey), paint);
    }

    // Calendar top bar
    final barPaint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Small tick marks at top (calendar header)
    final tickY = cy - r * 1.15;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(cx + i * r * 0.4, tickY - 2),
        Offset(cx + i * r * 0.4, tickY + 2),
        barPaint,
      );
    }
  }

  double _cos(double angle) => (angle == 0)
      ? 1.0
      : (angle == 3.14159 / 2)
      ? 0.0
      : (angle == 3.14159)
      ? -1.0
      : (angle == 3 * 3.14159 / 2)
      ? 0.0
      : _approxCos(angle);

  double _sin(double angle) => _approxSin(angle);

  double _approxCos(double a) {
    // Simple Taylor approximation for small angles
    return 1 - (a * a) / 2 + (a * a * a * a) / 24;
  }

  double _approxSin(double a) {
    return a - (a * a * a) / 6 + (a * a * a * a * a) / 120;
  }

  @override
  bool shouldRepaint(_LogoMarkPainter old) => old.color != color;
}

/// ReserveHub wordmark — the text portion of the logo.
class ReserveHubWordmark extends StatelessWidget {
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  const ReserveHubWordmark({
    super.key,
    this.fontSize = 24.0,
    this.color = Colors.white,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Reserve',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Hub',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: RHBrandTokens.electricBlueLight,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Combined ReserveHub brand lockup: logomark + wordmark.
class ReserveHubBrand extends StatelessWidget {
  final double logoSize;
  final double wordmarkSize;
  final Color wordmarkColor;
  final bool showGlow;
  final Axis direction;
  final double spacing;

  const ReserveHubBrand({
    super.key,
    this.logoSize = 44.0,
    this.wordmarkSize = 22.0,
    this.wordmarkColor = Colors.white,
    this.showGlow = false,
    this.direction = Axis.horizontal,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final mark = ReserveHubLogoMark(size: logoSize, showGlow: showGlow);
    final word = ReserveHubWordmark(
      fontSize: wordmarkSize,
      color: wordmarkColor,
    );

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: spacing),
          word,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: spacing),
        word,
      ],
    );
  }
}
