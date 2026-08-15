import 'package:flutter/material.dart';

/// Responsive utility helpers for ReserveHub.
/// Provides breakpoint detection and adaptive layout helpers.
class ResponsiveUtils {
  ResponsiveUtils._();

  // ─── Breakpoints ───────────────────────────────────────────────────────────
  static const double _tabletBreakpoint = 600.0;
  static const double _desktopBreakpoint = 1024.0;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _tabletBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _tabletBreakpoint && w < _desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

  // ─── Adaptive values ───────────────────────────────────────────────────────

  /// Returns [phone] on phones, [tablet] on tablets/desktops.
  static T adaptive<T>(
    BuildContext context, {
    required T phone,
    required T tablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _desktopBreakpoint && desktop != null) return desktop;
    if (w >= _tabletBreakpoint) return tablet;
    return phone;
  }

  /// Returns the number of grid columns appropriate for the screen width.
  static int gridColumns(
    BuildContext context, {
    int phone = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return adaptive(context, phone: phone, tablet: tablet, desktop: desktop);
  }

  /// Returns horizontal padding appropriate for the screen width.
  static double horizontalPadding(BuildContext context) =>
      adaptive(context, phone: 20.0, tablet: 32.0, desktop: 48.0);

  /// Constrains content to a max width on large screens.
  static Widget constrained(Widget child, {double maxWidth = 1200.0}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
