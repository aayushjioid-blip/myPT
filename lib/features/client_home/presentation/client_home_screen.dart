import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/user_entity.dart';
import '../../packages/presentation/packages_view_model.dart';
import '../../packages/presentation/package_selection_dialog.dart';
import '../../workouts/presentation/workout_view_model.dart';
import '../../progress/presentation/progress_view_model.dart';

class ClientHomeScreen extends StatefulWidget {
  final UserEntity user;
  final VoidCallback? onNavigateToDiscovery;
  final VoidCallback? onNavigateToCalendar;
  final VoidCallback? onNavigateToWorkouts;
  final VoidCallback? onNavigateToProgress;

  const ClientHomeScreen({
    super.key,
    required this.user,
    this.onNavigateToDiscovery,
    this.onNavigateToCalendar,
    this.onNavigateToWorkouts,
    this.onNavigateToProgress,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressViewModel>().loadForClient(widget.user.id);
    });
  }

  void _openWeightLogDialog(BuildContext context, ProgressViewModel progressVM) {
    final currentVal = progressVM.latestMeasurement?.weightKg ?? 64.5;
    final weightCtrl = TextEditingController(text: currentVal.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Today's Weight", style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track your daily weight to automatically update your progress charts and BMI analytics.',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Weight (kg)',
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hint: 'e.g. 64.2',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Save Weight Entry ✓',
            onPressed: () async {
              final newWeight = double.tryParse(weightCtrl.text);
              if (newWeight != null && newWeight > 20 && newWeight < 300) {
                final height = progressVM.latestMeasurement?.heightCm ?? 168.0;
                await progressVM.logMeasurement(
                  clientId: widget.user.id,
                  weightKg: newWeight,
                  heightCm: height,
                  notes: 'Daily weight check-in',
                );
                Navigator.pop(ctx);
                final totalLost = progressVM.totalWeightLost;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Weight logged: ${newWeight.toStringAsFixed(1)} kg! Total progress: $totalLost kg lost.'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pkgVM = context.watch<PackagesViewModel>();
    final workoutVM = context.watch<WorkoutViewModel>();
    final progressVM = context.watch<ProgressViewModel>();

    final remainingCredits = pkgVM.activeRemainingCredits;
    final activePkg = pkgVM.activePackage;
    final latestWorkout = workoutVM.latestWorkout;
    final hasActivePackage = activePkg != null;

    final latestWeight = progressVM.latestMeasurement?.weightKg ?? 64.5;
    final weightLost = progressVM.totalWeightLost;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Welcome Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  widget.user.name.split(' ').first,
                  style: AppTypography.heading1,
                ),
              ],
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Center(
                child: Text(widget.user.avatar, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Primary Metrics Grid
        Row(
          children: [
            // REMAINING CREDITS (CLICKABLE TO OPEN PACKAGES)
            Expanded(
              child: InkWell(
                onTap: () {
                  PackageSelectionDialog.show(
                    context,
                    clientId: widget.user.id,
                    onNavigateToDiscovery: widget.onNavigateToDiscovery,
                    onNavigateToWorkouts: widget.onNavigateToWorkouts,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: MetricTile(
                  label: 'Remaining Credits',
                  value: '$remainingCredits',
                  unit: 'PT Sessions',
                  subtitle: hasActivePackage ? '${activePkg.totalSessions} Pack (${activePkg.status})' : 'Tap to select pack (0)',
                  valueColor: remainingCredits > 0 ? AppColors.primary : AppColors.rose,
                  icon: Icons.fitness_center,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // CURRENT WEIGHT (CLICKABLE TO LOG TODAY'S WEIGHT)
            Expanded(
              child: InkWell(
                onTap: () => _openWeightLogDialog(context, progressVM),
                borderRadius: BorderRadius.circular(16),
                child: MetricTile(
                  label: 'Current Weight',
                  value: latestWeight.toStringAsFixed(1),
                  unit: 'kg',
                  subtitle: '↓ ${weightLost.toStringAsFixed(1)} kg total lost (Tap to log)',
                  valueColor: AppColors.blue,
                  icon: Icons.edit_note,
                ),
              ),
            ),
          ],
        ),

        if (remainingCredits == 0) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              PackageSelectionDialog.show(
                context,
                clientId: widget.user.id,
                onNavigateToDiscovery: widget.onNavigateToDiscovery,
                onNavigateToWorkouts: widget.onNavigateToWorkouts,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Text('⚡', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '0 PT credits remaining. Tap to select a package, talk to coach, or switch coaches.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Dynamic Today's Workout Card
        if (latestWorkout != null) ...[
          FitnessCard(
            hasGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      text: latestWorkout.status.name.toUpperCase(),
                      type: latestWorkout.status.name == 'completed' ? BadgeType.primary : BadgeType.amber,
                    ),
                    Text(
                      '${latestWorkout.assignedDate.month}/${latestWorkout.assignedDate.day}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(latestWorkout.name, style: AppTypography.heading3),
                const SizedBox(height: 4),
                Text(
                  '${latestWorkout.exercises.length} exercises logged • Bench press, lat pulldown, lateral raises, pushdowns',
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'View Workout Studio ➔',
                  isFullWidth: true,
                  onPressed: widget.onNavigateToWorkouts,
                ),
              ],
            ),
          ),
        ] else ...[
          FitnessCard(
            hasGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(text: 'Ready to Train', type: BadgeType.primary),
                    Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Start Your Training Journey', style: AppTypography.heading3),
                const SizedBox(height: 4),
                const Text(
                  'Explore verified coaches, book a session, or log an independent Own Workout.',
                  style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'Discover Coaches 🚀',
                  isFullWidth: true,
                  onPressed: widget.onNavigateToDiscovery,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Zero-Credit Own Workout Guarantee Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Text('🛡️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Zero-Credit Guarantee: "Own Workouts" created and logged by you never deduct PT session credits.',
                  style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Actions Row
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: '+ Own Workout 🏃',
                variant: ButtonVariant.secondary,
                onPressed: widget.onNavigateToWorkouts,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Book Session 📅',
                variant: ButtonVariant.secondary,
                onPressed: widget.onNavigateToCalendar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
