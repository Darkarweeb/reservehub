/// API endpoint constants.
/// All paths are relative to the base URL defined in [AppConfig].
class ApiConstants {
  ApiConstants._();

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static const String authSignIn = '/auth/v1/token?grant_type=password';
  static const String authSignUp = '/auth/v1/signup';
  static const String authSignOut = '/auth/v1/logout';
  static const String authRefresh = '/auth/v1/token?grant_type=refresh_token';
  static const String authUser = '/auth/v1/user';

  // ─── REST base ─────────────────────────────────────────────────────────────
  static const String restBase = '/rest/v1';

  // ─── Tables ────────────────────────────────────────────────────────────────
  static const String tableOrganizations = '$restBase/organizations';
  static const String tableBranches = '$restBase/branches';
  static const String tableEmployees = '$restBase/employees';
  static const String tableServices = '$restBase/services';
  static const String tableCustomers = '$restBase/customers';
  static const String tableAppointments = '$restBase/appointments';
  static const String tableSchedules = '$restBase/schedules';
  static const String tableNotifications = '$restBase/notifications';
  static const String tablePayments = '$restBase/payments';
  static const String tableSubscriptions = '$restBase/subscriptions';
  static const String tableAuditLogs = '$restBase/audit_logs';

  // ─── Headers ───────────────────────────────────────────────────────────────
  static const String headerApiKey = 'apikey';
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerPrefer = 'Prefer';
  static const String headerContentRange = 'Content-Range';

  // ─── Header values ─────────────────────────────────────────────────────────
  static const String contentTypeJson = 'application/json';
  static const String preferReturn = 'return=representation';
  static const String preferCount = 'count=exact';
}
