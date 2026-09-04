import '../../domain/entities/exercise_entity.dart';

class ExerciseModel {
  final String id;
  final String name;
  final ExerciseCategory category;
  final String equipment;
  final String target;
  final String description;
  final String? trainerId;
  final bool isCustom;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.target,
    required this.description,
    this.trainerId,
    this.isCustom = false,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    ExerciseCategory parsedCat;
    switch (json['category']?.toString().toUpperCase()) {
      case 'CHEST':
        parsedCat = ExerciseCategory.chest;
        break;
      case 'BACK':
        parsedCat = ExerciseCategory.back;
        break;
      case 'LEGS':
        parsedCat = ExerciseCategory.legs;
        break;
      case 'SHOULDERS':
        parsedCat = ExerciseCategory.shoulders;
        break;
      case 'BICEPS':
        parsedCat = ExerciseCategory.biceps;
        break;
      case 'TRICEPS':
        parsedCat = ExerciseCategory.triceps;
        break;
      case 'FOREARMS':
        parsedCat = ExerciseCategory.forearms;
        break;
      case 'GLUTES':
        parsedCat = ExerciseCategory.glutes;
        break;
      case 'HIPS':
        parsedCat = ExerciseCategory.hips;
        break;
      case 'CORE':
        parsedCat = ExerciseCategory.core;
        break;
      case 'CALVES':
        parsedCat = ExerciseCategory.calves;
        break;
      case 'FULL_BODY':
      default:
        parsedCat = ExerciseCategory.fullBody;
    }

    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: parsedCat,
      equipment: json['equipment']?.toString() ?? 'Bodyweight',
      target: json['target_muscles']?.toString() ?? json['target']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString(),
      isCustom: json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name.toUpperCase(),
      'equipment': equipment,
      'target_muscles': target,
      'description': description,
      if (trainerId != null) 'trainer_id': trainerId,
      'is_custom': isCustom,
    };
  }

  ExerciseEntity toEntity() {
    return ExerciseEntity(
      id: id,
      name: name,
      category: category,
      equipment: equipment,
      target: target,
      description: description,
      trainerId: trainerId,
      isCustom: isCustom,
    );
  }
}
