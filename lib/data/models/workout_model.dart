import '../../domain/entities/workout_entity.dart';

class WorkoutModel {
  final String id;
  final String clientId;
  final String? trainerId;
  final String? sessionId;
  final String? templateId;
  final String name;
  final String description;
  final WorkoutType workoutType;
  final DateTime assignedDate;
  final WorkoutStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final List<WorkoutExerciseItem> exercises;

  WorkoutModel({
    required this.id,
    required this.clientId,
    this.trainerId,
    this.sessionId,
    this.templateId,
    required this.name,
    this.description = '',
    this.workoutType = WorkoutType.assigned,
    required this.assignedDate,
    this.status = WorkoutStatus.pending,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.exercises = const [],
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    WorkoutType wType;
    switch (json['workout_type']?.toString().toUpperCase()) {
      case 'OWN_WORKOUT':
        wType = WorkoutType.ownWorkout;
        break;
      case 'PERSONAL_TRAINING':
      default:
        wType = WorkoutType.assigned;
    }

    WorkoutStatus wStatus;
    switch (json['status']?.toString().toUpperCase()) {
      case 'IN_PROGRESS':
        wStatus = WorkoutStatus.inProgress;
        break;
      case 'COMPLETED':
        wStatus = WorkoutStatus.completed;
        break;
      case 'SCHEDULED':
      case 'PENDING':
      default:
        wStatus = WorkoutStatus.pending;
    }

    final rawExercises = json['workout_exercises'] as List?;
    final List<WorkoutExerciseItem> exList = [];

    if (rawExercises != null) {
      for (final we in rawExercises) {
        if (we is Map<String, dynamic>) {
          final sets = (we['workout_sets'] as List?)?.map((s) => s as Map<String, dynamic>).toList() ?? [];
          final firstSet = sets.isNotEmpty ? sets.first : <String, dynamic>{};
          final exerciseObj = we['exercises'] is Map<String, dynamic> ? we['exercises'] as Map<String, dynamic> : <String, dynamic>{};

          exList.add(WorkoutExerciseItem(
            id: we['id']?.toString() ?? '',
            exerciseId: we['exercise_id']?.toString() ?? '',
            name: exerciseObj['name']?.toString() ?? we['name']?.toString() ?? 'Exercise',
            sets: sets.isNotEmpty ? sets.length : (we['sets'] as int? ?? 3),
            repetitions: firstSet['repetitions'] as int? ?? (we['repetitions'] as int? ?? 10),
            weightKg: firstSet['weight_kg'] != null ? double.tryParse(firstSet['weight_kg'].toString()) ?? 0.0 : (we['weight_kg'] as double? ?? 0.0),
          ));
        }
      }
    }

    return WorkoutModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString(),
      sessionId: json['session_id']?.toString(),
      templateId: json['template_id']?.toString(),
      name: json['name']?.toString() ?? 'Workout',
      description: json['notes']?.toString() ?? '',
      workoutType: wType,
      assignedDate: json['assigned_date'] != null ? DateTime.parse(json['assigned_date'].toString()).toLocal() : DateTime.now(),
      status: wStatus,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'].toString()).toLocal() : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'].toString()).toLocal() : null,
      notes: json['notes']?.toString(),
      exercises: exList,
    );
  }

  WorkoutEntity toEntity() {
    return WorkoutEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId,
      name: name,
      description: description,
      workoutType: workoutType,
      assignedDate: assignedDate,
      status: status,
      completedAt: completedAt,
      exercises: exercises,
    );
  }
}
