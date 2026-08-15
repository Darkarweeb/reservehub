/// Route name constants for the entire ReserveHub application.
/// Organized by: Public Experience | Authenticated Business Portal
class RouteNames {
  RouteNames._();

  // ─── Root ──────────────────────────────────────────────────────────────────
  static const String root = '/';

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';

  // ─── Business Portal (authenticated) ──────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String calendar = '/calendar';
  static const String newAppointment = '/appointments/new';
  static const String customers = '/customers';
  static const String businessSettings = '/settings';
  static const String onboarding = '/onboarding';

  // ─── Public Experience ─────────────────────────────────────────────────────
  static const String publicSearch = '/search';
  static const String publicBusiness = '/b/:slug';
  static const String publicBooking = '/b/:slug/book';
  static const String appointmentManage = '/appointments/:token';
  static const String appointmentCancel = '/appointments/:token/cancel';

  // ─── Legacy aliases (keep existing routes working) ─────────────────────────
  static const String signUpLogin = '/sign-up-login-screen';
  static const String dashboardLegacy = '/dashboard-screen';
  static const String calendarLegacy = '/calendar-screen';
  static const String newAppointmentLegacy = '/new-appointment-screen';
  static const String customersLegacy = '/customers-screen';
  static const String businessSettingsLegacy = '/business-settings-screen';
}
