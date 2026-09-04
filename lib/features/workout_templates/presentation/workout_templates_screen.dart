import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/repositories/i_workout_repository.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../workouts/presentation/workout_view_model.dart';
import 'template_builder_dialog.dart';

class WorkoutTemplatesScreen extends StatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  State<WorkoutTemplatesScreen> createState() => _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends State<WorkoutTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<WorkoutViewModel>().loadForTrainer(authVM.currentUser.id);
    });
  }

  void _showAssignDialog(BuildContext context, String templateId, WorkoutViewModel workoutVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Assign Template to Client', style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Assigning to active client: Sarah Jenkins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 6),
            Text('Workout will appear in Sarah\'s Workout Studio as an assigned routine.', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Assign Workout 🚀',
            onPressed: () async {
              await workoutVM.assignWorkout(
                clientId: 'usr-client-1',
                templateId: templateId,
                assignedDate: DateTime.now(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template assigned to Sarah Jenkins!')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutVM = context.watch<WorkoutViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final workoutRepo = context.read<IWorkoutRepository>();
    final trainerId = authVM.currentUser.id;
    final templates = workoutVM.templates;
    final exercises = workoutVM.allExercises;

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
                  Text('Program Architecture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Workout Templates', style: AppTypography.heading1),
                ],
              ),
              CustomButton(
                text: '+ New Template',
                height: 36,
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => TemplateBuilderDialog(
                      trainerId: trainerId,
                      workoutRepo: workoutRepo,
                      availableExercises: exercises,
                    ),
                  );
                  if (context.mounted) {
                    await workoutVM.loadForTrainer(trainerId);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (templates.isEmpty) ...[
            FitnessCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      Icon(Icons.library_books_outlined, size: 32, color: AppColors.darkTextMuted),
                      SizedBox(height: 8),
                      Text('No templates created yet.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            ...templates.map((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FitnessCard(
                  hasGlow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.name, style: AppTypography.heading3),
                          StatusBadge(text: '${t.exercises.length} Movements', type: BadgeType.primary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.description, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                      const SizedBox(height: 10),
                      ...t.exercises.map((ex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${ex.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${ex.sets} sets × ${ex.repetitions} reps', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomButton(
                            text: 'Assign to Client 🚀',
                            height: 36,
                            onPressed: () => _showAssignDialog(context, t.id, workoutVM),
                          ),
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
