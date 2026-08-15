import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/route_names.dart';
import '../presentation/business_settings_screen/business_settings_screen.dart';
import '../presentation/calendar_screen/calendar_screen.dart';
import '../presentation/customers_screen/customers_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/new_appointment_screen/new_appointment_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/public_search_screen/public_search_screen.dart';
import '../presentation/business_profile_screen/business_profile_screen.dart';
import '../presentation/booking_flow_screen/booking_flow_screen.dart';
import '../presentation/booking_confirmation_screen/booking_confirmation_screen.dart';
import '../presentation/appointment_management_screen/appointment_management_screen.dart';
import '../widgets/app_scaffold.dart';

// ─── Route guard ─────────────────────────────────────────────────────────────

/// Returns the redirect path if the user should be redirected, or null.
Future<String?> _authGuardAsync(
  BuildContext context,
  GoRouterState state,
) async {
  final session = Supabase.instance.client.auth.currentSession;
  final isAuthenticated = session != null;
  final loc = state.matchedLocation;

  final isAuthRoute =
      loc == RouteNames.login ||
      loc == RouteNames.signUpLogin ||
      loc == RouteNames.root;

  final isOnboardingRoute = loc == RouteNames.onboarding;

  // Public routes — no auth required
  final isPublicRoute =
      loc.startsWith('/b/') ||
      loc == RouteNames.publicSearch ||
      loc.startsWith('/appointments/');

  if (isPublicRoute) return null;

  // Not authenticated → send to login
  if (!isAuthenticated && !isAuthRoute) {
    return RouteNames.login;
  }

  // Authenticated on auth route → check onboarding status
  if (isAuthenticated && isAuthRoute) {
    return await _resolveAuthenticatedDestination();
  }

  // Authenticated on dashboard/calendar/etc → check if onboarding needed
  if (isAuthenticated && !isOnboardingRoute && !isAuthRoute) {
    final needsOnboarding = await _needsOnboarding();
    if (needsOnboarding) {
      return RouteNames.onboarding;
    }
  }

  return null;
}

/// Checks if the authenticated user still needs to complete onboarding.
Future<bool> _needsOnboarding() async {
  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    // Check if user has an organization
    final orgMember = await client
        .from('organization_members')
        .select('organization_id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (orgMember == null) return true;

    final orgId = orgMember['organization_id'] as String;

    // Check if org has a published business
    final business = await client
        .from('businesses')
        .select('id, publication_status')
        .eq('organization_id', orgId)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (business == null) return true;

    // Has a business (even draft) → onboarding was started, go to dashboard
    return false;
  } catch (_) {
    return false;
  }
}

/// Resolves where an authenticated user should go after login.
Future<String> _resolveAuthenticatedDestination() async {
  final needsOnboarding = await _needsOnboarding();
  return needsOnboarding ? RouteNames.onboarding : RouteNames.dashboard;
}

// ─── Router ───────────────────────────────────────────────────────────────────

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.root,
  redirect: _authGuardAsync,
  refreshListenable: _AuthChangeNotifier(),
  routes: [
    // ─── Auth routes ────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.root,
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return RouteNames.login;
        return await _resolveAuthenticatedDestination();
      },
    ),
    GoRoute(
      path: RouteNames.login,
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
    // Legacy alias
    GoRoute(
      path: RouteNames.signUpLogin,
      redirect: (context, state) => RouteNames.login,
    ),

    // ─── Public Experience (no auth required) ────────────────────────────────
    GoRoute(
      path: RouteNames.publicSearch,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BusinessSearchScreen(),
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
      path: RouteNames.publicBusiness,
      pageBuilder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: BusinessProfileScreen(slug: slug),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: RouteNames.publicBooking,
      pageBuilder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: BookingFlowScreen(slug: slug),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: '/b/:slug/appointment/:token',
      pageBuilder: (context, state) {
        final slug = state.pathParameters['slug']!;
        final token = state.pathParameters['token']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: BookingConfirmationScreen(slug: slug, token: token),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: RouteNames.appointmentManage,
      pageBuilder: (context, state) {
        final token = state.pathParameters['token']!;
        final cancelToken = state.uri.queryParameters['ct'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: AppointmentManagementScreen(
            token: token,
            cancelToken: cancelToken,
          ),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),

    // ─── Onboarding ──────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.onboarding,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
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

    // ─── New appointment (outside shell) ────────────────────────────────────
    GoRoute(
      path: RouteNames.newAppointment,
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
    // Legacy alias
    GoRoute(
      path: RouteNames.newAppointmentLegacy,
      redirect: (context, state) => RouteNames.newAppointment,
    ),

    // ─── Authenticated shell (bottom nav / side rail) ────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.dashboard,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            // Legacy alias
            GoRoute(
              path: RouteNames.dashboardLegacy,
              redirect: (context, state) => RouteNames.dashboard,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.calendar,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
            // Legacy alias
            GoRoute(
              path: RouteNames.calendarLegacy,
              redirect: (context, state) => RouteNames.calendar,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.customers,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomersScreen()),
            ),
            // Legacy alias
            GoRoute(
              path: RouteNames.customersLegacy,
              redirect: (context, state) => RouteNames.customers,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.businessSettings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BusinessSettingsScreen()),
            ),
            // Legacy alias
            GoRoute(
              path: RouteNames.businessSettingsLegacy,
              redirect: (context, state) => RouteNames.businessSettings,
            ),
          ],
        ),
      ],
    ),
  ],
);

// ─── Auth change notifier for GoRouter refresh ────────────────────────────────

/// Bridges Supabase auth state changes to GoRouter's refreshListenable.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

// ─── Legacy AppRoutes class (kept for backward compatibility) ─────────────────

class AppRoutes {
  static const String initial = RouteNames.root;
  static const String signUpLogin = RouteNames.login;
  static const String dashboard = RouteNames.dashboard;
  static const String calendar = RouteNames.calendar;
  static const String newAppointment = RouteNames.newAppointment;
  static const String customers = RouteNames.customers;
  static const String businessSettings = RouteNames.businessSettings;
  static const String onboarding = RouteNames.onboarding;
}
