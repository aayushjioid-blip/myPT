import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_workout_repository.dart';
import '../../domain/services/credit_ledger_service.dart';
import '../mock/mock_data_store.dart';

class MockWorkoutRepository implements IWorkoutRepository {
  final MockDataStore _dataStore;
  final CreditLedgerService _creditLedgerService;

  MockWorkoutRepository(this._dataStore, this._creditLedgerService);

  @override
  Future<List<ExerciseEntity>> getAllExercises() async {
    return List.unmodifiable(_dataStore.exercises);
  }

  @override
  Future<List<WorkoutTemplateEntity>> getTemplatesByTrainerId(String trainerId) async {
    return _dataStore.workoutTemplates.where((t) => t.trainerId == trainerId).toList();
  }

  @override
  Future<List<WorkoutEntity>> getWorkoutsForClient(String clientId) async {
    return _dataStore.workouts.where((w) => w.clientId == clientId).toList();
  }

  @override
  Future<void> createCustomExercise(ExerciseEntity exercise) async {
    _dataStore.exercises.add(exercise);
    _dataStore.notifyListeners();
  }

  @override
  Future<void> saveWorkoutTemplate(WorkoutTemplateEntity template) async {
    _dataStore.workoutTemplates.insert(0, template);
    _dataStore.notifyListeners();
  }

  @override
  Future<void> assignWorkout(String clientId, String templateId, DateTime assignedDate) async {
    final tmpl = _dataStore.workoutTemplates.firstWhere((t) => t.id == templateId);
    final workout = WorkoutEntity(
      id: 'wo-${DateTime.now().millisecondsSinceEpoch}',
      trainerId: tmpl.trainerId,
      clientId: clientId,
      name: tmpl.name,
      description: tmpl.description,
      workoutType: WorkoutType.assigned,
      assignedDate: assignedDate,
      status: WorkoutStatus.pending,
      exercises: tmpl.exercises,
    );
    _dataStore.workouts.insert(0, workout);
    _dataStore.notifyListeners();
  }

  @override
  Future<void> logOwnWorkout(WorkoutEntity ownWorkout) async {
    _dataStore.workouts.insert(0, ownWorkout);

    // Create completed session with STRICT zero credit consumption
    _dataStore.sessions.insert(0, SessionEntity(
      id: 'sess-own-${DateTime.now().millisecondsSinceEpoch}',
      clientId: ownWorkout.clientId,
      sessionType: SessionType.ownWorkout,
      scheduledStart: DateTime.now(),
      status: SessionStatus.completed,
      creditConsumed: false, // Strict: 0 PT credits consumed
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      notes: 'Independent own workout',
    ));

    _dataStore.notifyListeners();
  }

  @override
  Future<void> completeWorkoutSession(
    String sessionId,
    String workoutId,
    List<WorkoutExerciseItem> exercises,
  ) async {
    final sIdx = _dataStore.sessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final session = _dataStore.sessions[sIdx];

    // Update Workout
    final wIdx = _dataStore.workouts.indexWhere((w) => w.id == workoutId);
    if (wIdx != -1) {
      _dataStore.workouts[wIdx] = _dataStore.workouts[wIdx].copyWith(
        status: WorkoutStatus.completed,
        completedAt: DateTime.now(),
        exercises: exercises.isNotEmpty ? exercises : null,
      );
    } else {
      // If no pre-existing workout record, create one linked to this session
      final newWorkout = WorkoutEntity(
        id: workoutId,
        trainerId: session.trainerId,
        clientId: session.clientId,
        name: 'Personal Training Session Workout',
        workoutType: WorkoutType.assigned,
        assignedDate: session.scheduledStart,
        status: WorkoutStatus.completed,
        completedAt: DateTime.now(),
        exercises: exercises,
      );
      _dataStore.workouts.insert(0, newWorkout);
    }

    // Process Credit Ledger Deduction (Idempotency & Double Deduction Shield)
    if (session.sessionType == SessionType.personalTraining && !session.creditConsumed) {
      if (session.clientPackageId != null) {
        await _creditLedgerService.processSessionCompletion(
          session: session,
          clientPackageId: session.clientPackageId!,
          performedByUserId: session.trainerId ?? 'usr-trn-1',
        );
      }

      // Mark session as completed & credit consumed
      _dataStore.sessions[sIdx] = session.copyWith(
        status: SessionStatus.completed,
        creditConsumed: true,
        completedAt: DateTime.now(),
      );

      // Notify Client with updated credit balance
      _dataStore.notifications.insert(0, NotificationEntity(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: session.clientId,
        title: 'Workout Completed! 💪',
        message: 'Your trainer logged your workout. 1 PT credit was deducted.',
        type: NotificationType.workout,
        timestamp: DateTime.now(),
      ));
    } else {
      // Already completed or Own Workout
      _dataStore.sessions[sIdx] = session.copyWith(
        status: SessionStatus.completed,
        completedAt: DateTime.now(),
      );
    }

    _dataStore.notifyListeners();
  }
}
