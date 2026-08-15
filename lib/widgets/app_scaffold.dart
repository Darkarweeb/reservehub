import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_navigation.dart';
import '../shared/utils/responsive_builder.dart';
import '../theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size == ScreenSize.desktop) {
          return _DesktopScaffold(navigationShell: navigationShell);
        }
        return _MobileScaffold(navigationShell: navigationShell);
      },
    );
  }
}

// ─── Mobile / Tablet scaffold (bottom pill nav) ───────────────────────────────

class _MobileScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _MobileScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.backgroundLight,
      body: navigationShell,
      bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
    );
  }
}

// ─── Desktop scaffold (side rail) ────────────────────────────────────────────

class _DesktopScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _DesktopScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          _DesktopSideRail(navigationShell: navigationShell),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ─── Desktop side rail ────────────────────────────────────────────────────────

class _DesktopSideRail extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _DesktopSideRail({required this.navigationShell});

  static const _tabs = [
    _TabSpec(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      index: 0,
    ),
    _TabSpec(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Calendar',
      index: 1,
    ),
    _TabSpec(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Customers',
      index: 2,
    ),
    _TabSpec(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      index: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      width: 220,
      color: AppTheme.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ReserveHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _tabs.length,
                itemBuilder: (context, i) {
                  final tab = _tabs[i];
                  final isActive = currentIndex == tab.index;
                  return _SideNavItem(
                    tab: tab,
                    isActive: isActive,
                    onTap: () => navigationShell.goBranch(
                      tab.index,
                      initialLocation: tab.index == currentIndex,
                    ),
                  );
                },
              ),
            ),
            // Bottom spacer
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _TabSpec tab;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withAlpha(38) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                isActive ? tab.activeIcon : tab.icon,
                color: isActive ? Colors.white : Colors.white.withAlpha(160),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                tab.label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withAlpha(160),
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}
