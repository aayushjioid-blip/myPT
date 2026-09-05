import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/workout_entity.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/repositories/i_workout_repository.dart';

class TemplateBuilderDialog extends StatefulWidget {
  final String trainerId;
  final IWorkoutRepository workoutRepo;
  final List<ExerciseEntity> availableExercises;

  const TemplateBuilderDialog({
    super.key,
    required this.trainerId,
    required this.workoutRepo,
    required this.availableExercises,
  });

  @override
  State<TemplateBuilderDialog> createState() => _TemplateBuilderDialogState();
}

class _TemplateBuilderDialogState extends State<TemplateBuilderDialog> {
  final _nameCtrl = TextEditingController(text: 'Lower Body & Posterior Chain Power');
  final _descCtrl = TextEditingController(text: 'Heavy squats, deadlifts, and hip thrusts for athletic drive.');
  late List<WorkoutExerciseItem> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = [
      const WorkoutExerciseItem(id: 'te-1', exerciseId: 'ex-6', name: 'Barbell Back Squat', sets: 4, repetitions: 8, weightKg: 80),
      const WorkoutExerciseItem(id: 'te-2', exerciseId: 'ex-4', name: 'Barbell Deadlift', sets: 3, repetitions: 6, weightKg: 100),
      const WorkoutExerciseItem(id: 'te-3', exerciseId: 'ex-13', name: 'Barbell Hip Thrust', sets: 3, repetitions: 12, weightKg: 70),
    ];
  }

  void _showAddExercise() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Exercise to Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.availableExercises.length,
              itemBuilder: (c, i) {
                final ex = widget.availableExercises[i];
                return ListTile(
                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${ExerciseEntity.getCategoryName(ex.category)} • ${ex.equipment}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                  trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onTap: () {
                    setState(() {
                      _exercises.add(WorkoutExerciseItem(
                        id: 'te-${DateTime.now().millisecondsSinceEpoch}',
                        exerciseId: ex.id,
                        name: ex.name,
                        sets: 3,
                        repetitions: 10,
                        weightKg: 40,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Workout Template', style: AppTypography.heading3),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              label: 'Template Name',
              controller: _nameCtrl,
              hint: 'e.g. Push Day Hypertrophy, Leg Strength',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Description & Focus',
              controller: _descCtrl,
              maxLines: 2,
              hint: 'Target intensity, recommended rest intervals',
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Template Exercises', style: AppTypography.heading2),
                CustomButton(
                  text: '+ Add Movement',
                  height: 34,
                  variant: ButtonVariant.secondary,
                  onPressed: _showAddExercise,
                ),
              ],
            ),

            const SizedBox(height: 10),

            ..._exercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FitnessCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${item.sets} sets × ${item.repetitions} reps @ ${item.weightKg}kg', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                        onPressed: () => setState(() => _exercises.removeAt(idx)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Save Workout Template ✓',
              isFullWidth: true,
              height: 50,
              onPressed: () async {
                if (_exercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add at least 1 exercise.')),
                  );
                  return;
                }

                final template = WorkoutTemplateEntity(
                  id: 'tmpl-${DateTime.now().millisecondsSinceEpoch}',
                  trainerId: widget.trainerId,
                  name: _nameCtrl.text,
                  description: _descCtrl.text,
                  exercises: _exercises,
                );

                await widget.workoutRepo.saveWorkoutTemplate(template);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template "${_nameCtrl.text}" saved!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
