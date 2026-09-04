class MealItemEntity {
  final String mealName; // e.g. Breakfast, Lunch, Dinner, Post-Workout
  final String foodItems;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatsGrams;

  const MealItemEntity({
    required this.mealName,
    required this.foodItems,
    required this.calories,
    required this.proteinGrams,
    this.carbsGrams = 0,
    this.fatsGrams = 0,
  });
}

class WorkoutExercisePlan {
  final String name;
  final int sets;
  final int reps;
  final String notes;
  final String targetMuscle;

  const WorkoutExercisePlan({
    required this.name,
    required this.sets,
    required this.reps,
    required this.notes,
    this.targetMuscle = 'General',
  });
}

class FitnessChartEntity {
  final String id;
  final String trainerId;
  final String trainerName;
  final String clientId;
  final String clientName;
  final String title;
  final String goalCategory;
  final List<MealItemEntity> dietPlan;
  final List<WorkoutExercisePlan> workoutPlan;
  final DateTime createdAt;

  const FitnessChartEntity({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.goalCategory,
    required this.dietPlan,
    required this.workoutPlan,
    required this.createdAt,
  });

  int get totalCalories => dietPlan.fold(0, (sum, m) => sum + m.calories);
  int get totalProtein => dietPlan.fold(0, (sum, m) => sum + m.proteinGrams);
}
