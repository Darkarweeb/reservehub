import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/business/data/repositories/business_repository_impl.dart';
import '../../features/business/domain/repositories/business_repository.dart';
import '../../features/business_settings/data/repositories/business_settings_repository_impl.dart';
import '../../features/business_settings/data/repositories/organization_repository_impl.dart';
import '../../features/business_settings/domain/repositories/business_settings_repository.dart';
import '../../features/business_settings/domain/repositories/organization_repository.dart';
import '../../features/media/data/repositories/media_repository_impl.dart';
import '../../features/media/domain/repositories/media_repository.dart';
import '../../features/public_discovery/data/repositories/public_discovery_repository_impl.dart';
import '../../features/public_discovery/domain/repositories/public_discovery_repository.dart';
import '../../features/public_booking/data/repositories/public_booking_repository_impl.dart';
import '../../features/public_booking/domain/repositories/public_booking_repository.dart';
import '../../features/scheduling/data/repositories/appointment_repository_impl.dart';
import '../../features/scheduling/data/repositories/availability_repository_impl.dart';
import '../../features/scheduling/data/repositories/time_block_repository_impl.dart';
import '../../features/scheduling/domain/repositories/appointment_repository.dart';
import '../../features/scheduling/domain/repositories/availability_repository.dart';
import '../../features/scheduling/domain/repositories/time_block_repository.dart';

/// Dependency Injection registry for ReserveHub.
///
/// This is the composition root. All repository and service bindings
/// are registered here.
///
/// Usage:
/// ```dart
/// // In main.dart, after Supabase.initialize():
/// ServiceLocator.setup();
///
/// // In any class:
/// final authRepo = ServiceLocator.get<AuthRepository>();
/// ```
class ServiceLocator {
  ServiceLocator._();

  static final Map<Type, Object> _registry = {};

  /// Registers all application dependencies.
  /// Call once in [main] after Supabase is initialized.
  static void setup() {
    // ─── Supabase Client ────────────────────────────────────────────────────
    final supabaseClient = Supabase.instance.client;
    register<SupabaseClient>(supabaseClient);

    // ─── Repositories ───────────────────────────────────────────────────────
    register<AuthRepository>(AuthRepositoryImpl(client: supabaseClient));

    register<OrganizationRepository>(
      OrganizationRepositoryImpl(client: supabaseClient),
    );

    register<BusinessRepository>(
      BusinessRepositoryImpl(client: supabaseClient),
    );

    register<BusinessSettingsRepository>(
      BusinessSettingsRepositoryImpl(client: supabaseClient),
    );

    // ─── Scheduling / Availability Engine ───────────────────────────────────
    register<AppointmentRepository>(
      AppointmentRepositoryImpl(client: supabaseClient),
    );

    final availabilityRepo = AvailabilityRepositoryImpl(client: supabaseClient);
    register<AvailabilityRepository>(availabilityRepo);

    register<TimeBlockRepository>(
      TimeBlockRepositoryImpl(client: supabaseClient),
    );

    // ─── Public Discovery & Booking ─────────────────────────────────────────
    register<PublicDiscoveryRepository>(
      PublicDiscoveryRepositoryImpl(client: supabaseClient),
    );

    register<PublicBookingRepository>(
      PublicBookingRepositoryImpl(
        client: supabaseClient,
        availabilityRepo: availabilityRepo,
      ),
    );

    // ─── Media ──────────────────────────────────────────────────────────────
    register<MediaRepository>(MediaRepositoryImpl(client: supabaseClient));
  }

  /// Registers a singleton instance.
  static void register<T extends Object>(T instance) {
    _registry[T] = instance;
  }

  /// Retrieves a registered instance.
  /// Throws [StateError] if the type is not registered.
  static T get<T extends Object>() {
    final instance = _registry[T];
    if (instance == null) {
      throw StateError(
        'ServiceLocator: No instance registered for type $T. '
        'Did you call ServiceLocator.setup()?',
      );
    }
    return instance as T;
  }

  /// Returns null if the type is not registered.
  static T? tryGet<T extends Object>() {
    return _registry[T] as T?;
  }

  /// Removes all registrations (useful in tests).
  static void reset() {
    _registry.clear();
  }
}
