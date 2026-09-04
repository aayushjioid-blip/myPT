import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/repositories/i_workout_repository.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../workouts/presentation/workout_view_model.dart';
import 'custom_exercise_dialog.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  ExerciseCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final workoutVM = context.watch<WorkoutViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final workoutRepo = context.read<IWorkoutRepository>();
    final trainerId = authVM.currentUser.id;
    final allExercises = workoutVM.allExercises;

    final filtered = allExercises.where((ex) {
      final matchesCat = _selectedCategory == null || ex.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.target.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.equipment.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();

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
                  Text('Biomechanical Directory', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('12-Category Library', style: AppTypography.heading1),
                ],
              ),
              CustomButton(
                text: '+ Custom Movement',
                height: 36,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CustomExerciseDialog(trainerId: trainerId, workoutRepo: workoutRepo),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: '🔍 Search by name, target muscle, or equipment...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          // 12-Category Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All (12)', null),
                ...ExerciseCategory.values.map((c) {
                  return _buildCategoryChip(ExerciseEntity.getCategoryName(c), c);
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ...filtered.map((ex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FitnessCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: const Icon(Icons.fitness_center, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if (ex.isCustom) ...[
                                const SizedBox(width: 6),
                                const StatusBadge(text: 'Custom', type: BadgeType.blue),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ExerciseEntity.getCategoryName(ex.category)} • ${ex.equipment} • Target: ${ex.target}',
                            style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                          ),
                          if (ex.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(ex.description, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, ExerciseCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.darkBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : AppColors.darkTextMuted,
            ),
          ),
        ),
      ),
    );
  }
}
