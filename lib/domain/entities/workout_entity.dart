enum WorkoutType { assigned, ownWorkout }
enum WorkoutStatus { pending, inProgress, completed }

class WorkoutSetDetail {
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool isCompleted;

  const WorkoutSetDetail({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isCompleted = true,
  });

  WorkoutSetDetail copyWith({
    int? reps,
    double? weightKg,
    bool? isCompleted,
  }) {
    return WorkoutSetDetail(
      setNumber: setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class WorkoutExerciseItem {
  final String id;
  final String exerciseId;
  final String name;
  final int sets;
  final int repetitions;
  final double weightKg;
  final int restSeconds;
  final bool isCompleted;
  final List<WorkoutSetDetail>? setDetails;

  const WorkoutExerciseItem({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.sets = 3,
    this.repetitions = 10,
    this.weightKg = 40.0,
    this.restSeconds = 60,
    this.isCompleted = false,
    this.setDetails,
  });

  WorkoutExerciseItem copyWith({
    int? sets,
    int? repetitions,
    double? weightKg,
    bool? isCompleted,
    List<WorkoutSetDetail>? setDetails,
  }) {
    return WorkoutExerciseItem(
      id: id,
      exerciseId: exerciseId,
      name: name,
      sets: sets ?? this.sets,
      repetitions: repetitions ?? this.repetitions,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      setDetails: setDetails ?? this.setDetails,
    );
  }
}

class WorkoutTemplateEntity {
  final String id;
  final String trainerId;
  final String name;
  final String description;
  final List<WorkoutExerciseItem> exercises;

  const WorkoutTemplateEntity({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.description,
    required this.exercises,
  });
}

class WorkoutEntity {
  final String id;
  final String? trainerId;
  final String clientId;
  final String name;
  final String description;
  final WorkoutType workoutType;
  final DateTime assignedDate;
  final WorkoutStatus status;
  final DateTime? completedAt;
  final List<WorkoutExerciseItem> exercises;

  const WorkoutEntity({
    required this.id,
    this.trainerId,
    required this.clientId,
    required this.name,
    this.description = '',
    this.workoutType = WorkoutType.assigned,
    required this.assignedDate,
    this.status = WorkoutStatus.pending,
    this.completedAt,
    required this.exercises,
  });

  WorkoutEntity copyWith({
    WorkoutStatus? status,
    DateTime? completedAt,
    List<WorkoutExerciseItem>? exercises,
  }) {
    return WorkoutEntity(
      id: id,
      trainerId: trainerId,
      clientId: clientId,
      name: name,
      description: description,
      workoutType: workoutType,
      assignedDate: assignedDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      exercises: exercises ?? this.exercises,
    );
  }
}
