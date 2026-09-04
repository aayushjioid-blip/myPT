import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/app_config.dart';

// Data - Mock
import 'data/mock/mock_data_store.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/mock_trainer_repository.dart';
import 'data/repositories/mock_package_repository.dart';
import 'data/repositories/mock_booking_repository.dart';
import 'data/repositories/mock_workout_repository.dart';
import 'data/repositories/mock_progress_repository.dart';
import 'data/repositories/mock_credit_ledger_repository.dart';
import 'data/repositories/mock_notification_repository.dart';
import 'data/repositories/mock_gym_repository.dart';
import 'data/repositories/mock_admin_repository.dart';
import 'data/repositories/mock_fitness_chart_repository.dart';

// Data - Supabase Production
import 'data/repositories/supabase/supabase_auth_repository.dart';
import 'data/repositories/supabase/supabase_trainer_repository.dart';
import 'data/repositories/supabase/supabase_package_repository.dart';
import 'data/repositories/supabase/supabase_booking_repository.dart';
import 'data/repositories/supabase/supabase_workout_repository.dart';
import 'data/repositories/supabase/supabase_progress_repository.dart';
import 'data/repositories/supabase/supabase_credit_ledger_repository.dart';
import 'data/repositories/supabase/supabase_notification_repository.dart';
import 'data/repositories/supabase/supabase_gym_repository.dart';
import 'data/repositories/supabase/supabase_admin_repository.dart';

// Domain
import 'domain/repositories/i_auth_repository.dart';
import 'domain/repositories/i_trainer_repository.dart';
import 'domain/repositories/i_package_repository.dart';
import 'domain/repositories/i_booking_repository.dart';
import 'domain/repositories/i_workout_repository.dart';
import 'domain/repositories/i_progress_repository.dart';
import 'domain/repositories/i_credit_ledger_repository.dart';
import 'domain/repositories/i_notification_repository.dart';
import 'domain/repositories/i_gym_repository.dart';
import 'domain/repositories/i_admin_repository.dart';
import 'domain/repositories/i_fitness_chart_repository.dart';
import 'domain/services/credit_ledger_service.dart';

// Features & ViewModels
import 'features/auth/presentation/auth_view_model.dart';
import 'features/theme/theme_view_model.dart';
import 'features/admin/presentation/admin_view_model.dart';
import 'features/discovery/presentation/trainer_discovery_view_model.dart';
import 'features/trainers/presentation/trainer_profile_view_model.dart';
import 'features/packages/presentation/packages_view_model.dart';
import 'features/trainer_requests/presentation/trainer_requests_view_model.dart';
import 'features/booking/presentation/booking_view_model.dart';
import 'features/workouts/presentation/workout_view_model.dart';
import 'features/progress/presentation/progress_view_model.dart';
import 'features/notifications/presentation/notification_view_model.dart';
import 'features/trainer_clients/presentation/trainer_clients_view_model.dart';
import 'features/charts/presentation/fitness_chart_view_model.dart';
import 'features/home/presentation/home_shell_screen.dart';

class FitTrainerApp extends StatelessWidget {
  final MockDataStore dataStore;
  final bool useSupabase;
  final SupabaseClient? supabaseClient;

  const FitTrainerApp({
    super.key,
    required this.dataStore,
    this.useSupabase = false,
    this.supabaseClient,
  });

  @override
  Widget build(BuildContext context) {
    SupabaseClient? client = supabaseClient;
    if (client == null && useSupabase && AppConfig.isLiveBackendAvailable) {
      try {
        client = Supabase.instance.client;
      } catch (_) {}
    }
    final bool isLive = useSupabase && client != null;
    final SupabaseClient? liveClient = isLive ? client : null;

    return MultiProvider(
      providers: [
        // 1. Abstract Repositories (Conditionally injected: Supabase in Live Prod, Mock in Dev/Test)
        if (liveClient != null) ...[
          Provider<IAuthRepository>(create: (_) => SupabaseAuthRepository(liveClient)),
          Provider<ITrainerRepository>(create: (_) => SupabaseTrainerRepository(liveClient)),
          Provider<IPackageRepository>(create: (_) => SupabasePackageRepository(liveClient)),
          Provider<IBookingRepository>(create: (_) => SupabaseBookingRepository(liveClient)),
          Provider<ICreditLedgerRepository>(create: (_) => SupabaseCreditLedgerRepository(liveClient)),
          Provider<IProgressRepository>(create: (_) => SupabaseProgressRepository(liveClient)),
          Provider<INotificationRepository>(create: (_) => SupabaseNotificationRepository(liveClient)),
          Provider<IGymRepository>(create: (_) => SupabaseGymRepository(liveClient)),
          Provider<IAdminRepository>(create: (_) => SupabaseAdminRepository(liveClient)),
          ProxyProvider<ICreditLedgerRepository, CreditLedgerService>(
            update: (_, repo, __) => CreditLedgerService(repo),
          ),
          ProxyProvider<CreditLedgerService, IWorkoutRepository>(
            update: (_, creditService, __) => SupabaseWorkoutRepository(liveClient, creditService),
          ),
        ] else ...[
          Provider<IAuthRepository>(create: (_) => MockAuthRepository(dataStore)),
          Provider<ITrainerRepository>(create: (_) => MockTrainerRepository(dataStore)),
          Provider<IPackageRepository>(create: (_) => MockPackageRepository(dataStore)),
          Provider<IBookingRepository>(create: (_) => MockBookingRepository(dataStore)),
          Provider<ICreditLedgerRepository>(create: (_) => MockCreditLedgerRepository(dataStore)),
          ProxyProvider<ICreditLedgerRepository, CreditLedgerService>(
            update: (_, repo, __) => CreditLedgerService(repo),
          ),
          ProxyProvider<CreditLedgerService, IWorkoutRepository>(
            update: (_, creditService, __) => MockWorkoutRepository(dataStore, creditService),
          ),
          Provider<IProgressRepository>(create: (_) => MockProgressRepository(dataStore)),
          Provider<INotificationRepository>(create: (_) => MockNotificationRepository(dataStore)),
          Provider<IGymRepository>(create: (_) => MockGymRepository(dataStore)),
          Provider<IAdminRepository>(create: (_) => MockAdminRepository(dataStore)),
        ],
        Provider<IFitnessChartRepository>(create: (_) => MockFitnessChartRepository(dataStore)),

        // 2. ViewModels (ChangeNotifiers depend ONLY on abstract interfaces)
        ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel()),
        ChangeNotifierProxyProvider<IAuthRepository, AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<IAuthRepository>()),
          update: (_, repo, vm) => vm ?? AuthViewModel(repo),
        ),
        ChangeNotifierProxyProvider<IAdminRepository, AdminViewModel>(
          create: (ctx) => AdminViewModel(ctx.read<IAdminRepository>()),
          update: (_, repo, vm) => vm ?? AdminViewModel(repo),
        ),
        ChangeNotifierProxyProvider2<ITrainerRepository, AdminViewModel, TrainerDiscoveryViewModel>(
          create: (ctx) => TrainerDiscoveryViewModel(
            ctx.read<ITrainerRepository>(),
            ctx.read<AdminViewModel>(),
            dataStore,
          ),
          update: (_, trainerRepo, adminVM, vm) => vm ?? TrainerDiscoveryViewModel(trainerRepo, adminVM, dataStore),
        ),
        ChangeNotifierProxyProvider2<ITrainerRepository, IPackageRepository, TrainerProfileViewModel>(
          create: (ctx) => TrainerProfileViewModel(
            ctx.read<ITrainerRepository>(),
            ctx.read<IPackageRepository>(),
            dataStore,
          ),
          update: (_, trainerRepo, pkgRepo, vm) => vm ?? TrainerProfileViewModel(trainerRepo, pkgRepo, dataStore),
        ),
        ChangeNotifierProxyProvider<IPackageRepository, PackagesViewModel>(
          create: (ctx) => PackagesViewModel(ctx.read<IPackageRepository>(), dataStore),
          update: (_, pkgRepo, vm) => vm ?? PackagesViewModel(pkgRepo, dataStore),
        ),
        ChangeNotifierProxyProvider2<IPackageRepository, IAuthRepository, TrainerRequestsViewModel>(
          create: (ctx) => TrainerRequestsViewModel(
            ctx.read<IPackageRepository>(),
            ctx.read<IAuthRepository>(),
            dataStore,
          ),
          update: (_, pkgRepo, authRepo, vm) => vm ?? TrainerRequestsViewModel(pkgRepo, authRepo, dataStore),
        ),
        ChangeNotifierProxyProvider<IBookingRepository, BookingViewModel>(
          create: (ctx) => BookingViewModel(ctx.read<IBookingRepository>(), dataStore),
          update: (_, bookingRepo, vm) => vm ?? BookingViewModel(bookingRepo, dataStore),
        ),
        ChangeNotifierProxyProvider<IWorkoutRepository, WorkoutViewModel>(
          create: (ctx) => WorkoutViewModel(ctx.read<IWorkoutRepository>(), dataStore),
          update: (_, workoutRepo, vm) => vm ?? WorkoutViewModel(workoutRepo, dataStore),
        ),
        ChangeNotifierProxyProvider<IProgressRepository, ProgressViewModel>(
          create: (ctx) => ProgressViewModel(ctx.read<IProgressRepository>(), dataStore),
          update: (_, progRepo, vm) => vm ?? ProgressViewModel(progRepo, dataStore),
        ),
        ChangeNotifierProxyProvider<INotificationRepository, NotificationViewModel>(
          create: (ctx) => NotificationViewModel(ctx.read<INotificationRepository>(), dataStore),
          update: (_, notifRepo, vm) => vm ?? NotificationViewModel(notifRepo, dataStore),
        ),
        ChangeNotifierProxyProvider4<IAuthRepository, IPackageRepository, IWorkoutRepository, IProgressRepository, TrainerClientsViewModel>(
          create: (ctx) => TrainerClientsViewModel(
            ctx.read<IAuthRepository>(),
            ctx.read<IPackageRepository>(),
            ctx.read<IWorkoutRepository>(),
            ctx.read<IProgressRepository>(),
            dataStore,
          ),
          update: (_, authRepo, pkgRepo, workoutRepo, progRepo, vm) => vm ?? TrainerClientsViewModel(
            authRepo,
            pkgRepo,
            workoutRepo,
            progRepo,
            dataStore,
          ),
        ),
        ChangeNotifierProxyProvider<IFitnessChartRepository, FitnessChartViewModel>(
          create: (ctx) => FitnessChartViewModel(ctx.read<IFitnessChartRepository>(), dataStore),
          update: (_, chartRepo, vm) => vm ?? FitnessChartViewModel(chartRepo, dataStore),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVM.themeMode,
            home: const HomeShellScreen(),
          );
        },
      ),
    );
  }
}
