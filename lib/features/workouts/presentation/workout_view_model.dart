import 'package:flutter/foundation.dart';
import '../../../domain/entities/workout_entity.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/repositories/i_workout_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class WorkoutViewModel extends ChangeNotifier {
  final IWorkoutRepository _workoutRepository;
  final MockDataStore _dataStore;

  List<WorkoutEntity> _clientWorkouts = [];
  List<ExerciseEntity> _allExercises = [];
  List<WorkoutTemplateEntity> _templates = [];
  bool _isLoading = false;

  WorkoutViewModel(this._workoutRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
  }

  List<WorkoutEntity> get clientWorkouts => _clientWorkouts;
  List<ExerciseEntity> get allExercises => _allExercises;
  List<WorkoutTemplateEntity> get templates => _templates;
  bool get isLoading => _isLoading;

  WorkoutEntity? get latestWorkout => _clientWorkouts.isNotEmpty ? _clientWorkouts.first : null;

  Future<void> loadForClient(String clientId) async {
    _isLoading = true;
    notifyListeners();

    _clientWorkouts = await _workoutRepository.getWorkoutsForClient(clientId);
    _allExercises = await _workoutRepository.getAllExercises();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadForTrainer(String trainerId) async {
    _isLoading = true;
    notifyListeners();

    _allExercises = await _workoutRepository.getAllExercises();
    _templates = await _workoutRepository.getTemplatesByTrainerId(trainerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final user = _dataStore.currentUser;
    if (user.id.isNotEmpty) {
      await loadForClient(user.id);
      await loadForTrainer(user.id);
    }
  }

  Future<void> assignWorkout({
    required String clientId,
    required String templateId,
    required DateTime assignedDate,
  }) async {
    await _workoutRepository.assignWorkout(clientId, templateId, assignedDate);
    await refresh();
  }

  Future<void> completeSession({
    required String sessionId,
    required String workoutId,
    required List<WorkoutExerciseItem> exercises,
  }) async {
    await _workoutRepository.completeWorkoutSession(sessionId, workoutId, exercises);
    await refresh();
  }

  Future<void> logOwnWorkout({
    required String clientId,
    required String name,
    required List<WorkoutExerciseItem> exercises,
  }) async {
    final ownWorkout = WorkoutEntity(
      id: 'wo-own-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      name: name,
      workoutType: WorkoutType.ownWorkout,
      assignedDate: DateTime.now(),
      status: WorkoutStatus.completed,
      completedAt: DateTime.now(),
      exercises: exercises,
    );

    // Strict Rule: Own workouts never deduct credits!
    await _workoutRepository.logOwnWorkout(ownWorkout);
    await refresh();
  }
}
