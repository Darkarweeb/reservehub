/// Global application constants.
/// Feature-specific constants belong in their respective feature/domain layer.
class AppConstants {
  AppConstants._();

  // ─── App identity ──────────────────────────────────────────────────────────
  static const String appName = 'ReserveHub';
  static const String appTagline = 'Where businesses manage time better.';
  static const String appTaglineEs =
      'La forma inteligente de gestionar reservas.';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ─── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ─── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ─── Cache ─────────────────────────────────────────────────────────────────
  static const Duration defaultCacheTtl = Duration(minutes: 5);
  static const Duration longCacheTtl = Duration(hours: 1);
  static const Duration shortCacheTtl = Duration(minutes: 1);

  // ─── Animation ─────────────────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Duration animEnter = Duration(milliseconds: 280);

  // ─── Layout ────────────────────────────────────────────────────────────────
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;
  static const double maxContentWidth = 1200.0;
  static const double defaultPadding = 20.0;
  static const double cardRadius = 16.0;
  static const double pillRadius = 50.0;
  static const double inputRadius = 12.0;
  static const double chipRadius = 20.0;

  // ─── Navigation ────────────────────────────────────────────────────────────
  static const double navBarHeight = 64.0;
  static const double navBarBottomPadding = 12.0;

  // ─── Subscription tiers ────────────────────────────────────────────────────
  static const String tierFree = 'free';
  static const String tierStarter = 'starter';
  static const String tierProfessional = 'professional';
  static const String tierEnterprise = 'enterprise';

  // ─── Loyalty tiers ─────────────────────────────────────────────────────────
  static const String loyaltyBronze = 'Bronze';
  static const String loyaltySilver = 'Silver';
  static const String loyaltyGold = 'Gold';
  static const String loyaltyVip = 'VIP';

  // ─── Appointment statuses ──────────────────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCheckedIn = 'checked_in';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusNoShow = 'no_show';

  // ─── Storage keys ──────────────────────────────────────────────────────────
  static const String storageKeyThemeMode = 'theme_mode';
  static const String storageKeyLocale = 'locale';
  static const String storageKeyOnboardingDone = 'onboarding_done';
  static const String storageKeyAuthToken = 'auth_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyCurrentOrgId = 'current_org_id';
}
