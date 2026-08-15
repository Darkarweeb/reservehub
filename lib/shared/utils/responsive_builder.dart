import 'package:flutter/material.dart';

/// Breakpoint constants for ReserveHub responsive layout.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 560.0;
  static const double maxCardWidth = 400.0;
}

/// Current screen size class.
enum ScreenSize { mobile, tablet, desktop }

/// Extension on BuildContext for responsive helpers.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenSize get screenSize {
    final w = screenWidth;
    if (w < Breakpoints.mobile) return ScreenSize.mobile;
    if (w < Breakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet {
    final w = screenWidth;
    return w >= Breakpoints.mobile && w < Breakpoints.tablet;
  }

  bool get isDesktop => screenWidth >= Breakpoints.tablet;
  bool get isTabletOrLarger => screenWidth >= Breakpoints.mobile;

  /// Returns value based on current screen size.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    final size = screenSize;
    if (size == ScreenSize.desktop && desktop != null) return desktop;
    if (size == ScreenSize.tablet && tablet != null) return tablet;
    if (size != ScreenSize.mobile && tablet != null) return tablet;
    return mobile;
  }

  /// Horizontal padding appropriate for screen width.
  double get horizontalPadding =>
      responsive(mobile: 16.0, tablet: 32.0, desktop: 48.0);

  /// Number of grid columns for screen width.
  int gridColumns({int mobile = 1, int tablet = 2, int desktop = 3}) =>
      responsive(mobile: mobile, tablet: tablet, desktop: desktop);
}

/// Responsive builder widget — rebuilds when screen size class changes.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size) builder;

  const ResponsiveBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return builder(context, context.screenSize);
  }
}

/// Constrains content to [maxWidth] and centers it — used for desktop layouts.
class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentConstraint({
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Responsive grid that adapts columns to screen size.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCols;
  final int tabletCols;
  final int desktopCols;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    required this.children,
    this.mobileCols = 1,
    this.tabletCols = 2,
    this.desktopCols = 3,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cols = context.gridColumns(
      mobile: mobileCols,
      tablet: tabletCols,
      desktop: desktopCols,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

/// Responsive two-column layout: side panel + main content.
/// On mobile, stacks vertically.
class ResponsiveSideLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;
  final double spacing;

  const ResponsiveSideLayout({
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 280.0,
    this.spacing = 24.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebar,
          SizedBox(height: spacing),
          content,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: sidebarWidth, child: sidebar),
        SizedBox(width: spacing),
        Expanded(child: content),
      ],
    );
  }
}

/// Adaptive navigation scaffold — side rail on desktop, bottom bar on mobile.
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? navigationRail;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    required this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.navigationRail,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    if (isDesktop && navigationRail != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            navigationRail!,
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: body,
      bottomNavigationBar: isDesktop ? null : bottomNavigationBar,
      drawer: drawer,
    );
  }
}
