import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/fitness_chart_entity.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'fitness_chart_view_model.dart';

class TrainerChartBuilderScreen extends StatefulWidget {
  const TrainerChartBuilderScreen({super.key});

  @override
  State<TrainerChartBuilderScreen> createState() => _TrainerChartBuilderScreenState();
}

class _TrainerChartBuilderScreenState extends State<TrainerChartBuilderScreen> {
  String _selectedClientId = 'usr-client-1';
  String _selectedClientName = 'Sarah Jenkins';
  final TextEditingController _titleCtrl = TextEditingController(text: 'Phase 2: Hypertrophy & Macro Recomp');
  final TextEditingController _goalCtrl = TextEditingController(text: 'Fat Loss & Lean Muscle Growth');

  final List<MealItemEntity> _dietItems = [
    const MealItemEntity(
      mealName: 'Meal 1 (Breakfast)',
      foodItems: '5 Egg whites + 1 Whole egg + 70g Rolled Oats with 1 Scoop Whey',
      calories: 500,
      proteinGrams: 45,
      carbsGrams: 55,
      fatsGrams: 10,
    ),
    const MealItemEntity(
      mealName: 'Meal 2 (Lunch)',
      foodItems: '200g Grilled Chicken Breast + 180g Brown Rice + Steamed Greens',
      calories: 620,
      proteinGrams: 52,
      carbsGrams: 65,
      fatsGrams: 12,
    ),
    const MealItemEntity(
      mealName: 'Meal 3 (Post-Workout)',
      foodItems: '1 Scoop Whey Isolate + 1 Banana + 30g Almonds',
      calories: 380,
      proteinGrams: 32,
      carbsGrams: 35,
      fatsGrams: 14,
    ),
  ];

  final List<WorkoutExercisePlan> _exercises = [
    const WorkoutExercisePlan(name: 'Barbell Squat', sets: 4, reps: 10, notes: 'Full depth, pause at bottom', targetMuscle: 'Legs / Quads'),
    const WorkoutExercisePlan(name: 'Flat Barbell Bench Press', sets: 4, reps: 8, notes: 'Controlled negative, progressive overload', targetMuscle: 'Chest'),
    const WorkoutExercisePlan(name: 'Lat Pulldown', sets: 3, reps: 12, notes: 'Squeeze scapulae at contraction', targetMuscle: 'Back'),
    const WorkoutExercisePlan(name: 'Dumbbell Lateral Raise', sets: 4, reps: 15, notes: 'Strict form, no momentum', targetMuscle: 'Shoulders'),
  ];

  void _showAddMealDialog() {
    final nameCtrl = TextEditingController(text: 'Meal ${_dietItems.length + 1}');
    final foodCtrl = TextEditingController(text: '180g Salmon + Quinoa + Mixed Vegetables');
    final calCtrl = TextEditingController(text: '450');
    final proCtrl = TextEditingController(text: '35');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Meal to Diet Plan', style: AppTypography.heading3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(label: 'Meal Name / Timing', controller: nameCtrl),
              const SizedBox(height: 10),
              CustomTextField(label: 'Food Items & Portions', controller: foodCtrl, maxLines: 2),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: 'Calories (kcal)', controller: calCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: CustomTextField(label: 'Protein (g)', controller: proCtrl, keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          CustomButton(
            text: 'Add Meal ✓',
            onPressed: () {
              if (foodCtrl.text.isNotEmpty) {
                setState(() {
                  _dietItems.add(
                    MealItemEntity(
                      mealName: nameCtrl.text.trim(),
                      foodItems: foodCtrl.text.trim(),
                      calories: int.tryParse(calCtrl.text) ?? 400,
                      proteinGrams: int.tryParse(proCtrl.text) ?? 30,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog() {
    final nameCtrl = TextEditingController(text: 'Romanian Deadlift');
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '12');
    final muscleCtrl = TextEditingController(text: 'Hamstrings & Glutes');
    final notesCtrl = TextEditingController(text: 'Hinge at hips, keep flat back');

  showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Exercise to Workout Routine', style: AppTypography.heading3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(label: 'Exercise Name', controller: nameCtrl),
              const SizedBox(height: 10),
              CustomTextField(label: 'Target Muscle Group', controller: muscleCtrl),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: 'Sets', controller: setsCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: CustomTextField(label: 'Reps', controller: repsCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(label: 'Form Guidance Notes', controller: notesCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          CustomButton(
            text: 'Add Exercise ✓',
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _exercises.add(
                    WorkoutExercisePlan(
                      name: nameCtrl.text.trim(),
                      sets: int.tryParse(setsCtrl.text) ?? 3,
                      reps: int.tryParse(repsCtrl.text) ?? 10,
                      targetMuscle: muscleCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartVM = context.watch<FitnessChartViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCals = _dietItems.fold(0, (sum, m) => sum + m.calories);
    final totalPro = _dietItems.fold(0, (sum, m) => sum + m.proteinGrams);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrition & Workout Dispatcher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Build & Send Chart 📋', style: AppTypography.heading1),
                ],
              ),
              StatusBadge(text: 'Live Builder', type: BadgeType.primary),
            ],
          ),

          const SizedBox(height: 16),

          // Client Selector & Header Info
          FitnessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. ASSIGN TO CLIENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'usr-client-1', child: Text('Sarah Jenkins (Active Client)')),
                    DropdownMenuItem(value: 'usr-client-2', child: Text('David Kim (Active Client)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedClientId = val;
                        _selectedClientName = val == 'usr-client-1' ? 'Sarah Jenkins' : 'David Kim';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(label: 'Chart Title', controller: _titleCtrl),
                const SizedBox(height: 10),
                CustomTextField(label: 'Goal & Category', controller: _goalCtrl),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 2: Diet Plan
          FitnessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.restaurant, size: 18, color: AppColors.amber),
                        SizedBox(width: 8),
                        Text('2. NUTRITIONAL DIET PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
                    InkWell(
                      onTap: _showAddMealDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add, size: 14, color: AppColors.amber),
                            SizedBox(width: 2),
                            Text('Add Meal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amber)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Total Macros Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkInput : AppColors.lightInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🔥 Total Calories: $totalCals kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amber)),
                      Text('💪 Total Protein: ${totalPro}g', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                ..._dietItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final meal = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal.mealName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.amber)),
                              const SizedBox(height: 2),
                              Text(meal.foodItems, style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${meal.calories} kcal • ${meal.proteinGrams}g Protein', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.rose),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _dietItems.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 3: Workout Routine Split
          FitnessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.fitness_center, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('3. WORKOUT ROUTINE SPLIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
                    InkWell(
                      onTap: _showAddExerciseDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add, size: 14, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text('Add Exercise', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ..._exercises.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ex = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${idx + 1}. ${ex.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('${ex.targetMuscle} • ${ex.notes}', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${ex.sets} × ${ex.reps}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.rose),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _exercises.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Dispatch Button
          CustomButton(
            text: 'Dispatch Chart to $_selectedClientName 🚀',
            isFullWidth: true,
            height: 50,
            onPressed: () async {
              await chartVM.dispatchChart(
                trainerId: 'trn-alex',
                trainerName: 'Alex Rivera',
                clientId: _selectedClientId,
                clientName: _selectedClientName,
                title: _titleCtrl.text.trim(),
                goalCategory: _goalCtrl.text.trim(),
                dietPlan: _dietItems,
                workoutPlan: _exercises,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Fitness & Nutrition Chart dispatched to $_selectedClientName!'),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
