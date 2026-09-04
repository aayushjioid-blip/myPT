import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/session_entity.dart';
import '../../trainer_requests/presentation/trainer_requests_view_model.dart';
import '../../trainer_requests/presentation/trainer_requests_screen.dart';
import '../../workouts/presentation/live_workout_logger_dialog.dart';

class TrainerDashboardScreen extends StatelessWidget {
  final UserEntity user;
  final VoidCallback? onNavigateToRequests;
  final VoidCallback? onNavigateToCalendar;
  final VoidCallback? onNavigateToClients;
  final VoidCallback? onNavigateToCharts;
  final VoidCallback? onNavigateToLibrary;
  final VoidCallback? onNavigateToTemplates;
  final VoidCallback? onNavigateToPackages;

  const TrainerDashboardScreen({
    super.key,
    required this.user,
    this.onNavigateToRequests,
    this.onNavigateToCalendar,
    this.onNavigateToClients,
    this.onNavigateToCharts,
    this.onNavigateToLibrary,
    this.onNavigateToTemplates,
    this.onNavigateToPackages,
  });

  @override
  Widget build(BuildContext context) {
    final requestsVM = context.watch<TrainerRequestsViewModel>();
    final pendingConsults = requestsVM.pendingConsultations.length;
    final pendingPays = requestsVM.pendingPayments.length;
    final totalPending = requestsVM.totalPendingCount;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trainer Command Center', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                Text(user.name, style: AppTypography.heading1),
              ],
            ),
            const StatusBadge(text: 'Code: TRN001', type: BadgeType.primary),
          ],
        ),

        const SizedBox(height: 16),

        // Business KPIs - 3 Distinct Cards
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onNavigateToClients,
                borderRadius: BorderRadius.circular(12),
                child: const MetricTile(
                  label: 'Active Clients',
                  value: '4',
                  subtitle: '100% attendance',
                  valueColor: AppColors.primary,
                  icon: Icons.people_outline,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: MetricTile(
                label: 'Monthly Revenue',
                value: '\$1,398',
                subtitle: '+14% this month',
                valueColor: AppColors.accentGreen,
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: onNavigateToPackages,
                borderRadius: BorderRadius.circular(12),
                child: const MetricTile(
                  label: 'Active Packages',
                  value: '3',
                  subtitle: 'View catalog ➔',
                  valueColor: AppColors.blue,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action Required Banner
        FitnessCard(
          hasGlow: totalPending > 0,
          borderColor: totalPending > 0 ? AppColors.amber.withOpacity(0.5) : AppColors.darkBorder,
          backgroundColor: totalPending > 0 ? AppColors.amber.withOpacity(0.08) : Theme.of(context).cardTheme.color,
          child: Row(
            children: [
              const Text('📥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalPending > 0 ? 'Pending Review Items' : 'Queue All Clear 🎉',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: totalPending > 0 ? AppColors.amber : AppColors.accentGreen,
                      ),
                    ),
                    Text(
                      totalPending > 0
                          ? '$pendingConsults Inbound Consultation${pendingConsults == 1 ? '' : 's'} • $pendingPays Offline Payment${pendingPays == 1 ? '' : 's'}'
                          : 'No pending requests or payments.',
                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: 'Review ➔',
                height: 36,
                onPressed: () {
                  if (onNavigateToRequests != null) {
                    onNavigateToRequests!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrainerRequestsScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Chart Builder Action
        FitnessCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text('🥗', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client Diet & Workout Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Build and dispatch nutrition & workout routines', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                    ],
                  ),
                ],
              ),
              CustomButton(
                text: 'Build Chart ➔',
                height: 34,
                variant: ButtonVariant.secondary,
                onPressed: onNavigateToCharts,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Today's Scheduled Session Card
        FitnessCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("TODAY'S SESSIONS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  StatusBadge(text: 'Confirmed', type: BadgeType.primary),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text('S', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sarah Jenkins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('10:00 AM - 11:00 AM • Upper Body Hypertrophy', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Start Session & Log Sets ⏱️',
                isFullWidth: true,
                onPressed: () {
                  final session = SessionEntity(
                    id: 'sess-today-sarah',
                    clientId: 'usr-client-1',
                    trainerId: 'trn-alex',
                    clientPackageId: 'cpkg-seed-sarah',
                    sessionType: SessionType.personalTraining,
                    scheduledStart: DateTime.now(),
                    status: SessionStatus.confirmed,
                    createdAt: DateTime.now(),
                  );
                  showDialog(
                    context: context,
                    builder: (_) => LiveWorkoutLoggerDialog(
                      session: session,
                      clientName: 'Sarah Jenkins',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
