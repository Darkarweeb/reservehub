import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/business_settings_screen/business_settings_screen.dart';
import '../presentation/calendar_screen/calendar_screen.dart';
import '../presentation/customers_screen/customers_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/new_appointment_screen/new_appointment_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signUpLogin = '/sign-up-login-screen';
  static const String dashboard = '/dashboard-screen';
  static const String calendar = '/calendar-screen';
  static const String newAppointment = '/new-appointment-screen';
  static const String customers = '/customers-screen';
  static const String businessSettings = '/business-settings-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.signUpLogin,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.newAppointment,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NewAppointmentScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.customers,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomersScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.businessSettings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BusinessSettingsScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
