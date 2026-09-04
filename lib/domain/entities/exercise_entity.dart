enum ExerciseCategory {
  chest, back, legs, shoulders, biceps, triceps,
  forearms, glutes, hips, core, calves, fullBody
}

class ExerciseEntity {
  final String id;
  final String name;
  final ExerciseCategory category;
  final String equipment;
  final String target;
  final String description;
  final String? trainerId;
  final bool isCustom;

  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.target,
    this.description = '',
    this.trainerId,
    this.isCustom = false,
  });

  static String getCategoryName(ExerciseCategory cat) {
    switch (cat) {
      case ExerciseCategory.chest: return 'Chest';
      case ExerciseCategory.back: return 'Back';
      case ExerciseCategory.legs: return 'Legs';
      case ExerciseCategory.shoulders: return 'Shoulders';
      case ExerciseCategory.biceps: return 'Biceps';
      case ExerciseCategory.triceps: return 'Triceps';
      case ExerciseCategory.forearms: return 'Forearms';
      case ExerciseCategory.glutes: return 'Glutes';
      case ExerciseCategory.hips: return 'Hips';
      case ExerciseCategory.core: return 'Core';
      case ExerciseCategory.calves: return 'Calves';
      case ExerciseCategory.fullBody: return 'Full Body';
    }
  }
}
