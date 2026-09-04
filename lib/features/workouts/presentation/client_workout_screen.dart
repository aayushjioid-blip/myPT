import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/workout_entity.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'workout_view_model.dart';

class ClientWorkoutScreen extends StatefulWidget {
  const ClientWorkoutScreen({super.key});

  @override
  State<ClientWorkoutScreen> createState() => _ClientWorkoutScreenState();
}

class _ClientWorkoutScreenState extends State<ClientWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<WorkoutViewModel>().loadForClient(authVM.currentUser.id);
    });
  }

  void _showOwnWorkoutDialog(BuildContext context, String clientId, WorkoutViewModel workoutVM) {
    final titleCtrl = TextEditingController(text: 'Morning Cardio & Core Flow');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Independent "Own Workout"', style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Workout Routine Name',
              controller: titleCtrl,
              hint: 'e.g. 5km Run, HIIT Session, Home Core',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                '🛡️ Strict Rule: Own workouts logged independently by you deduct 0 PT credits from your active package.',
                style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Save & Log (0 Credits) 🏃',
            onPressed: () async {
              await workoutVM.logOwnWorkout(
                clientId: clientId,
                name: titleCtrl.text,
                exercises: const [
                  WorkoutExerciseItem(id: 'oe-1', exerciseId: 'ex-15', name: 'Plank with Shoulder Taps', sets: 3, repetitions: 12),
                  WorkoutExerciseItem(id: 'oe-2', exerciseId: 'ex-14', name: '90-90 Hip Mobility Flow', sets: 3, repetitions: 10),
                ],
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Own Workout logged successfully! (0 PT credits deducted).')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final workoutVM = context.watch<WorkoutViewModel>();
    final clientId = authVM.currentUser.id;
    final workouts = workoutVM.clientWorkouts;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training Studio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Workout History', style: AppTypography.heading1),
                ],
              ),
              CustomButton(
                text: '+ Own Workout',
                height: 36,
                variant: ButtonVariant.secondary,
                onPressed: () => _showOwnWorkoutDialog(context, clientId, workoutVM),
              ),
            ],
          ),

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

          const SizedBox(height: 20),

          const Text('All Logged & Completed Workouts', style: AppTypography.heading2),
          const SizedBox(height: 8),

          if (workouts.isEmpty) ...[
            FitnessCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      Icon(Icons.fitness_center_outlined, size: 32, color: AppColors.darkTextMuted),
                      SizedBox(height: 8),
                      Text('No completed workouts logged yet.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                      Text('Complete a session with your trainer or log an Own Workout above.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            ...workouts.map((w) {
              final isOwn = w.workoutType == WorkoutType.ownWorkout;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FitnessCard(
                  hasGlow: !isOwn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(w.name, style: AppTypography.heading3),
                          StatusBadge(
                            text: isOwn ? 'Own Workout (0 Credits)' : '1-on-1 PT Session',
                            type: isOwn ? BadgeType.blue : BadgeType.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Date: ${w.assignedDate.month}/${w.assignedDate.day} • ${w.exercises.length} Exercises Logged',
                        style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      ...w.exercises.map((ex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${ex.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${ex.sets} sets × ${ex.repetitions} reps @ ${ex.weightKg.toStringAsFixed(0)}kg', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOwn ? 'Credits deducted: 0 (Own Workout)' : 'Credits deducted: 1 PT Session',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOwn ? AppColors.blue : AppColors.primary,
                            ),
                          ),
                          const Text('✓ Saved in History', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
