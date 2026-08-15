/// Environment flavors supported by ReserveHub.
enum AppEnvironment { development, staging, production }

/// Central application configuration.
/// Populated at startup from compile-time environment variables.
class AppConfig {
  AppConfig._();

  static late AppEnvironment _environment;
  static late String _supabaseUrl;
  static late String _supabaseAnonKey;

  /// Must be called once in [main] before [runApp].
  static void initialize({
    required AppEnvironment environment,
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    _environment = environment;
    _supabaseUrl = supabaseUrl;
    _supabaseAnonKey = supabaseAnonKey;
  }

  // ─── Accessors ─────────────────────────────────────────────────────────────

  static AppEnvironment get environment => _environment;
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  static bool get isDevelopment => _environment == AppEnvironment.development;
  static bool get isStaging => _environment == AppEnvironment.staging;
  static bool get isProduction => _environment == AppEnvironment.production;

  /// Enables verbose logging and debug overlays in non-production builds.
  static bool get isDebugMode => !isProduction;

  @override
  String toString() => 'AppConfig(env: $_environment, url: $_supabaseUrl)';
}
