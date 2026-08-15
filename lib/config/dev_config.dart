import './app_config.dart';

/// Development environment configuration.
/// Reads values from compile-time --dart-define flags.
class DevConfig {
  DevConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dummy.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'dummykey.updateyourkkey.here',
  );

  static void apply() {
    AppConfig.initialize(
      environment: AppEnvironment.development,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }
}
