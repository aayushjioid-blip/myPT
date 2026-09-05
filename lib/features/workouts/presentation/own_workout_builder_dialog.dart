import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/entities/exercise_catalog.dart';
import '../../../domain/entities/workout_entity.dart';
import 'workout_view_model.dart';

class OwnWorkoutBuilderDialog extends StatefulWidget {
  final String clientId;
  final WorkoutViewModel workoutVM;

  const OwnWorkoutBuilderDialog({
    super.key,
    required this.clientId,
    required this.workoutVM,
  });

  @override
  State<OwnWorkoutBuilderDialog> createState() => _OwnWorkoutBuilderDialogState();
}

class _OwnWorkoutBuilderDialogState extends State<OwnWorkoutBuilderDialog> {
  final _titleCtrl = TextEditingController(text: 'Full Body Circuit & Core Flow');
  late List<WorkoutExerciseItem> _selectedExercises;

  // Selected Muscle Category for filtering
  ExerciseCategory _selectedCategory = ExerciseCategory.chest;

  final Map<ExerciseCategory, String> _categoryEmojis = {
    ExerciseCategory.chest: '🏋️',
    ExerciseCategory.back: '🚣',
    ExerciseCategory.legs: '🦵',
    ExerciseCategory.shoulders: '🥥',
    ExerciseCategory.biceps: '💪',
    ExerciseCategory.triceps: '⚡',
    ExerciseCategory.core: '🧘',
    ExerciseCategory.glutes: '🍑',
    ExerciseCategory.forearms: '🥋',
    ExerciseCategory.calves: '🏃',
    ExerciseCategory.hips: '🤸',
    ExerciseCategory.fullBody: '🔥',
  };

  @override
  void initState() {
    super.initState();
    _selectedExercises = [
      const WorkoutExerciseItem(id: 'oe-1', exerciseId: 'ex-core-1', name: 'Plank with Shoulder Taps', sets: 3, repetitions: 12, weightKg: 0),
      const WorkoutExerciseItem(id: 'oe-2', exerciseId: 'ex-legs-1', name: 'Barbell Back Squat', sets: 3, repetitions: 10, weightKg: 40),
      const WorkoutExerciseItem(id: 'oe-3', exerciseId: 'ex-bi-1', name: 'Incline Dumbbell Curl', sets: 3, repetitions: 12, weightKg: 10),
    ];
  }

  void _addExercise(ExerciseEntity ex, {int sets = 3, int reps = 10, double weightKg = 20}) {
    setState(() {
      _selectedExercises.add(WorkoutExerciseItem(
        id: 'oe-${DateTime.now().millisecondsSinceEpoch}',
        exerciseId: ex.id,
        name: ex.name,
        sets: sets,
        repetitions: reps,
        weightKg: weightKg,
      ));
    });
  }

  void _showExercisePicker() {
    final allEx = widget.workoutVM.allExercises.isNotEmpty
        ? widget.workoutVM.allExercises
        : ExerciseCatalog.defaultExercises;
    ExerciseCategory activeCat = _selectedCategory;
    int sets = 3;
    int reps = 10;
    double weightKg = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = allEx.where((e) => e.category == activeCat).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Exercise by Muscle', style: AppTypography.heading3),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),

                // Muscle Group Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ExerciseCategory.values.map((cat) {
                      final isSelected = cat == activeCat;
                      final emoji = _categoryEmojis[cat] ?? '🏋️';
                      final name = ExerciseEntity.getCategoryName(cat);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('$emoji $name', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.darkBorder),
                          onSelected: (_) {
                            setSheetState(() => activeCat = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Exercise List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No exercises found in this category.'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (c, i) {
                            final ex = filtered[i];
                            return ListTile(
                              title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${ex.target} • ${ex.equipment}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                              trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              onTap: () {
                                _addExercise(ex, sets: sets, reps: reps, weightKg: weightKg);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Build "Own Workout"', style: AppTypography.heading3),
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
              label: 'Workout Name',
              controller: _titleCtrl,
              hint: 'e.g. Legs & Abs, 5km Run, Upper Body Circuit',
            ),

            const SizedBox(height: 14),

            // Zero Credit Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('🛡️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Zero-Credit Guarantee: "Own Workouts" are independent client routines and strictly deduct 0 PT credits.',
                      style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Workout Exercises', style: AppTypography.heading2),
                CustomButton(
                  text: '+ Add by Muscle',
                  height: 34,
                  variant: ButtonVariant.secondary,
                  onPressed: _showExercisePicker,
                ),
              ],
            ),

            const SizedBox(height: 10),

            ..._selectedExercises.asMap().entries.map((entry) {
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
                        backgroundColor: AppColors.blue.withOpacity(0.2),
                        child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${item.sets} sets × ${item.repetitions} reps @ ${item.weightKg.toStringAsFixed(0)}kg', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                        onPressed: () => setState(() => _selectedExercises.removeAt(idx)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Save & Log Own Workout (0 PT Credits) 🏃',
              isFullWidth: true,
              height: 50,
              onPressed: () async {
                if (_selectedExercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add at least 1 exercise.')),
                  );
                  return;
                }

                await widget.workoutVM.logOwnWorkout(
                  clientId: widget.clientId,
                  name: _titleCtrl.text,
                  exercises: _selectedExercises,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Own Workout logged! 0 PT credits deducted.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
