import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/demo_role_hud.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../theme/theme_view_model.dart';
import '../../notifications/presentation/notification_view_model.dart';
import '../../notifications/presentation/notification_center_dialog.dart';
import '../../client_home/presentation/client_home_screen.dart';
import '../../discovery/presentation/trainer_discovery_screen.dart';
import '../../workouts/presentation/client_workout_screen.dart';
import '../../booking/presentation/client_calendar_screen.dart';
import '../../progress/presentation/client_progress_screen.dart';
import '../../charts/presentation/client_charts_screen.dart';
import '../../charts/presentation/trainer_chart_builder_screen.dart';
import '../../trainer_dashboard/presentation/trainer_dashboard_screen.dart';
import '../../trainer_requests/presentation/trainer_requests_screen.dart';
import '../../booking/presentation/trainer_calendar_screen.dart';
import '../../trainer_clients/presentation/trainer_clients_screen.dart';
import '../../exercise_library/presentation/exercise_library_screen.dart';
import '../../workout_templates/presentation/workout_templates_screen.dart';
import '../../trainer_packages/presentation/trainer_packages_screen.dart';
import '../../gym/presentation/gym_dashboard_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../../domain/entities/user_entity.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final notifVM = context.watch<NotificationViewModel>();
    final currentUser = authVM.currentUser;
    final role = currentUser.role;

    Widget bodyContent;
    List<BottomNavigationBarItem> navItems;

    if (role == UserRole.client) {
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Workouts'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: 'Charts'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up_outlined), activeIcon: Icon(Icons.trending_up), label: 'Progress'),
      ];

      switch (_currentTabIndex.clamp(0, 5)) {
        case 0:
          bodyContent = ClientHomeScreen(
            user: currentUser,
            onNavigateToDiscovery: () => setState(() => _currentTabIndex = 1),
            onNavigateToWorkouts: () => setState(() => _currentTabIndex = 2),
            onNavigateToCalendar: () => setState(() => _currentTabIndex = 4),
            onNavigateToProgress: () => setState(() => _currentTabIndex = 5),
          );
          break;
        case 1:
          bodyContent = const TrainerDiscoveryScreen();
          break;
        case 2:
          bodyContent = const ClientWorkoutScreen();
          break;
        case 3:
          bodyContent = ClientChartsScreen(
            onNavigateToWorkouts: () => setState(() => _currentTabIndex = 2),
          );
          break;
        case 4:
          bodyContent = ClientCalendarScreen(
            onNavigateToDiscovery: () => setState(() => _currentTabIndex = 1),
            onNavigateToWorkouts: () => setState(() => _currentTabIndex = 2),
          );
          break;
        case 5:
          bodyContent = const ClientProgressScreen();
          break;
        default:
          bodyContent = ClientHomeScreen(user: currentUser);
      }
    } else if (role == UserRole.trainer) {
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), activeIcon: Icon(Icons.inbox), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Clients'),
        BottomNavigationBarItem(icon: Icon(Icons.post_add_outlined), activeIcon: Icon(Icons.post_add), label: 'Build Chart'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Library'),
        BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'Templates'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Packages'),
      ];

      switch (_currentTabIndex.clamp(0, 7)) {
        case 0:
          bodyContent = TrainerDashboardScreen(
            user: currentUser,
            onNavigateToRequests: () => setState(() => _currentTabIndex = 1),
            onNavigateToCalendar: () => setState(() => _currentTabIndex = 2),
            onNavigateToClients: () => setState(() => _currentTabIndex = 3),
            onNavigateToCharts: () => setState(() => _currentTabIndex = 4),
            onNavigateToLibrary: () => setState(() => _currentTabIndex = 5),
            onNavigateToTemplates: () => setState(() => _currentTabIndex = 6),
            onNavigateToPackages: () => setState(() => _currentTabIndex = 7),
          );
          break;
        case 1:
          bodyContent = const TrainerRequestsScreen();
          break;
        case 2:
          bodyContent = const TrainerCalendarScreen();
          break;
        case 3:
          bodyContent = const TrainerClientsScreen();
          break;
        case 4:
          bodyContent = const TrainerChartBuilderScreen();
          break;
        case 5:
          bodyContent = const ExerciseLibraryScreen();
          break;
        case 6:
          bodyContent = const WorkoutTemplatesScreen();
          break;
        case 7:
          bodyContent = const TrainerPackagesScreen();
          break;
        default:
          bodyContent = TrainerDashboardScreen(user: currentUser);
      }
    } else if (role == UserRole.headTrainer || role == UserRole.gymManager) {
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.domain_outlined), activeIcon: Icon(Icons.domain), label: 'Facility'),
      ];
      bodyContent = GymDashboardScreen(user: currentUser);
    } else {
      // Super Admin
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ];
      bodyContent = const AdminDashboardScreen();
    }

    return Scaffold(
      appBar: AppHeader(
        user: currentUser,
        isDark: themeVM.isDarkMode,
        onThemeToggle: () => themeVM.toggleTheme(),
        unreadNotifications: notifVM.unreadCount,
        onNotificationTap: () {
          showDialog(
            context: context,
            builder: (_) => const NotificationCenterDialog(),
          );
        },
      ),
      body: Column(
        children: [
          // Floating Role Switcher HUD for 5-Role Demo Mode
          const DemoRoleHUD(),
          Expanded(child: bodyContent),
        ],
      ),
      bottomNavigationBar: navItems.length >= 2
          ? BottomNavigationBar(
              currentIndex: _currentTabIndex.clamp(0, navItems.length - 1),
              onTap: (index) => setState(() => _currentTabIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              items: navItems,
            )
          : null,
    );
  }
}
