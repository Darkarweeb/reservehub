import './app_config.dart';

/// Production environment configuration.
/// All values MUST be provided via --dart-define at build time.
/// Missing values will cause [AppConfig.initialize] to throw at runtime.
class ProdConfig {
  ProdConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static void apply() {
    assert(
      supabaseUrl.isNotEmpty,
      'SUPABASE_URL must be set for production builds.',
    );
    assert(
      supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY must be set for production builds.',
    );

    AppConfig.initialize(
      environment: AppEnvironment.production,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }
}
