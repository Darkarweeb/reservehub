import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/dev_config.dart';
import '../core/app_export.dart';
import '../core/di/service_locator.dart';
import '../core/logging/app_logger.dart';
import '../features/appointments/domain/repositories/appointment_lifecycle_repository.dart';
import '../features/appointments/presentation/providers/appointment_lifecycle_provider.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import '../features/business/domain/repositories/business_repository.dart';
import '../features/business/presentation/providers/business_provider.dart';
import '../features/business_settings/domain/repositories/organization_repository.dart';
import '../features/business_settings/presentation/providers/organization_provider.dart';
import '../features/management/presentation/providers/management_provider.dart';
import '../features/media/domain/repositories/media_repository.dart';
import '../features/media/presentation/providers/media_provider.dart';
import '../features/notifications/presentation/providers/notification_provider.dart';
import '../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../features/public_booking/domain/repositories/public_booking_repository.dart';
import '../features/public_booking/presentation/providers/public_booking_provider.dart';
import '../features/public_discovery/domain/repositories/public_discovery_repository.dart';
import '../features/public_discovery/presentation/providers/public_discovery_provider.dart';
import '../features/scheduling/domain/repositories/appointment_repository.dart';
import '../features/scheduling/domain/repositories/availability_repository.dart';
import '../features/scheduling/domain/repositories/time_block_repository.dart';
import '../features/scheduling/presentation/providers/appointment_provider.dart';
import '../features/scheduling/presentation/providers/availability_provider.dart';
import '../features/scheduling/presentation/providers/time_block_provider.dart';
import '../widgets/custom_error_widget.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Supabase initialization ───────────────────────────────────────────────
  try {
    await SupabaseService.initialize();
    AppLogger.info('Supabase initialized', tag: 'main');
  } catch (e) {
    AppLogger.error('Failed to initialize Supabase', tag: 'main', error: e);
  }

  // ─── Environment configuration ────────────────────────────────────────────
  DevConfig.apply();

  // ─── Dependency Injection ─────────────────────────────────────────────────
  ServiceLocator.setup();
  AppLogger.info('ServiceLocator configured', tag: 'main');

  // ─── Logging ──────────────────────────────────────────────────────────────
  AppLogger.info('ReserveHub starting', tag: 'main');

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) =>
              AuthProvider(repository: ServiceLocator.get<AuthRepository>()),
        ),
        ChangeNotifierProvider<OrganizationProvider>(
          create: (_) => OrganizationProvider(
            repository: ServiceLocator.get<OrganizationRepository>(),
          ),
        ),
        ChangeNotifierProvider<BusinessProvider>(
          create: (_) => BusinessProvider(
            repository: ServiceLocator.get<BusinessRepository>(),
          ),
        ),
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) => OnboardingProvider(
            orgRepository: ServiceLocator.get<OrganizationRepository>(),
            businessRepository: ServiceLocator.get<BusinessRepository>(),
            client: ServiceLocator.get<SupabaseClient>(),
          ),
        ),
        ChangeNotifierProvider<ManagementProvider>(
          create: (_) =>
              ManagementProvider(client: ServiceLocator.get<SupabaseClient>()),
        ),
        ChangeNotifierProvider<AppointmentProvider>(
          create: (_) => AppointmentProvider(
            repository: ServiceLocator.get<AppointmentRepository>(),
          ),
        ),
        ChangeNotifierProvider<AvailabilityProvider>(
          create: (_) => AvailabilityProvider(
            repository: ServiceLocator.get<AvailabilityRepository>(),
          ),
        ),
        ChangeNotifierProvider<TimeBlockProvider>(
          create: (_) => TimeBlockProvider(
            repository: ServiceLocator.get<TimeBlockRepository>(),
          ),
        ),
        ChangeNotifierProvider<AppointmentLifecycleProvider>(
          create: (_) => AppointmentLifecycleProvider(
            repository: ServiceLocator.get<AppointmentLifecycleRepository>(),
          ),
        ),
        // ─── Public Experience Providers ──────────────────────────────────
        ChangeNotifierProvider<PublicDiscoveryProvider>(
          create: (_) => PublicDiscoveryProvider(
            repository: ServiceLocator.get<PublicDiscoveryRepository>(),
          ),
        ),
        ChangeNotifierProvider<PublicBookingProvider>(
          create: (_) => PublicBookingProvider(
            bookingRepo: ServiceLocator.get<PublicBookingRepository>(),
            availabilityRepo: ServiceLocator.get<AvailabilityRepository>(),
            client: ServiceLocator.get<SupabaseClient>(),
          ),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            client: ServiceLocator.get<SupabaseClient>(),
          ),
        ),
        ChangeNotifierProvider<MediaProvider>(
          create: (_) =>
              MediaProvider(repository: ServiceLocator.get<MediaRepository>()),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, screenType) {
          return MaterialApp.router(
            title: 'ReserveHub',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
            // 🚨 END CRITICAL SECTION
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
