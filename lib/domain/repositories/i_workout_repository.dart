import '../entities/workout_entity.dart';
import '../entities/exercise_entity.dart';

abstract class IWorkoutRepository {
  Future<List<ExerciseEntity>> getAllExercises();
  Future<List<WorkoutTemplateEntity>> getTemplatesByTrainerId(String trainerId);
  Future<List<WorkoutEntity>> getWorkoutsForClient(String clientId);
  Future<void> createCustomExercise(ExerciseEntity exercise);
  Future<void> saveWorkoutTemplate(WorkoutTemplateEntity template);
  Future<void> assignWorkout(String clientId, String templateId, DateTime assignedDate);
  Future<void> logOwnWorkout(WorkoutEntity ownWorkout);
  Future<void> completeWorkoutSession(String sessionId, String workoutId, List<WorkoutExerciseItem> exercises);
}
