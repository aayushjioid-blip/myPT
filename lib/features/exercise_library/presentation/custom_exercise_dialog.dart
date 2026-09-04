import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/repositories/i_workout_repository.dart';

class CustomExerciseDialog extends StatefulWidget {
  final String trainerId;
  final IWorkoutRepository workoutRepo;

  const CustomExerciseDialog({
    super.key,
    required this.trainerId,
    required this.workoutRepo,
  });

  @override
  State<CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<CustomExerciseDialog> {
  final _nameCtrl = TextEditingController(text: 'Deficit Bulgarian Split Squat');
  final _targetCtrl = TextEditingController(text: 'Gluteus Maximus, Quadriceps');
  final _equipmentCtrl = TextEditingController(text: 'Dumbbells + Step Platform');
  final _descCtrl = TextEditingController(text: 'Elevate front foot on a 4-inch plate for deep hip flexion stretch.');
  ExerciseCategory _selectedCategory = ExerciseCategory.legs;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Custom Exercise', style: AppTypography.heading3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Exercise Name',
              controller: _nameCtrl,
              hint: 'e.g. Landmine Press, Deficit Deadlift',
            ),
            const SizedBox(height: 10),
            const Text('Category (12 Standard Categories)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<ExerciseCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: ExerciseCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(ExerciseEntity.getCategoryName(c), style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val ?? ExerciseCategory.legs),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Target Muscles',
              controller: _targetCtrl,
              hint: 'e.g. Upper Chest, Lats, Calves',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Equipment',
              controller: _equipmentCtrl,
              hint: 'e.g. Barbell, Dumbbell, Cable, Machine',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Execution Cues & Notes',
              controller: _descCtrl,
              maxLines: 2,
              hint: 'Form cues, tempo, range of motion tips',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Save Custom Exercise ✓',
          onPressed: () async {
            final exercise = ExerciseEntity(
              id: 'ex-custom-${DateTime.now().millisecondsSinceEpoch}',
              name: _nameCtrl.text,
              category: _selectedCategory,
              equipment: _equipmentCtrl.text,
              target: _targetCtrl.text,
              description: _descCtrl.text,
              trainerId: widget.trainerId,
              isCustom: true,
            );

            await widget.workoutRepo.createCustomExercise(exercise);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Custom exercise "${_nameCtrl.text}" created!')),
            );
          },
        ),
      ],
    );
  }
}
