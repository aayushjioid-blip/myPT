import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/workout_entity.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/repositories/i_workout_repository.dart';
import '../../../domain/services/credit_ledger_service.dart';
import '../../models/workout_model.dart';
import '../../models/exercise_model.dart';

class SupabaseWorkoutRepository implements IWorkoutRepository {
  final SupabaseClient _client;
  final CreditLedgerService? creditLedgerService;

  SupabaseWorkoutRepository(this._client, [this.creditLedgerService]);

  @override
  Future<List<ExerciseEntity>> getAllExercises() async {
    try {
      final res = await _client
          .from('exercises')
          .select('*')
          .order('name', ascending: true);

      return (res as List).map((json) => ExerciseModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WorkoutTemplateEntity>> getTemplatesByTrainerId(String trainerId) async {
    try {
      final res = await _client
          .from('workout_templates')
          .select('*')
          .eq('trainer_id', trainerId);

      return (res as List).map<WorkoutTemplateEntity>((t) {
        return WorkoutTemplateEntity(
          id: t['id'].toString(),
          trainerId: t['trainer_id'].toString(),
          name: t['name'].toString(),
          description: t['description']?.toString() ?? '',
          exercises: const [],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WorkoutEntity>> getWorkoutsForClient(String clientId) async {
    try {
      final res = await _client
          .from('workouts')
          .select('*, workout_exercises(*, exercises(*), workout_sets(*))')
          .eq('client_id', clientId)
          .order('assigned_date', ascending: false);

      return (res as List).map((json) => WorkoutModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> createCustomExercise(ExerciseEntity exercise) async {
    try {
      await _client.from('exercises').insert({
        'name': exercise.name,
        'category': exercise.category.name.toUpperCase(),
        'equipment': exercise.equipment,
        'target_muscles': exercise.target,
        'description': exercise.description,
        'is_custom': true,
        'trainer_id': exercise.trainerId,
      });
    } catch (_) {}
  }

  @override
  Future<void> saveWorkoutTemplate(WorkoutTemplateEntity template) async {
    try {
      await _client.from('workout_templates').insert({
        'trainer_id': template.trainerId,
        'name': template.name,
        'description': template.description,
      });
    } catch (_) {}
  }

  @override
  Future<void> assignWorkout(String clientId, String templateId, DateTime assignedDate) async {
    try {
      final tmpl = await _client.from('workout_templates').select('*').eq('id', templateId).single();

      await _client.from('workouts').insert({
        'client_id': clientId,
        'template_id': templateId,
        'name': tmpl['name'],
        'workout_type': 'PERSONAL_TRAINING',
        'assigned_date': '${assignedDate.year}-${assignedDate.month.toString().padLeft(2, '0')}-${assignedDate.day.toString().padLeft(2, '0')}',
        'status': 'SCHEDULED',
      });
    } catch (_) {}
  }

  @override
  Future<void> logOwnWorkout(WorkoutEntity ownWorkout) async {
    try {
      final wRes = await _client.from('workouts').insert({
        'client_id': ownWorkout.clientId,
        'name': ownWorkout.name,
        'workout_type': 'OWN_WORKOUT',
        'status': 'COMPLETED',
        'assigned_date': '${ownWorkout.assignedDate.year}-${ownWorkout.assignedDate.month.toString().padLeft(2, '0')}-${ownWorkout.assignedDate.day.toString().padLeft(2, '0')}',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      for (int i = 0; i < ownWorkout.exercises.length; i++) {
        final ex = ownWorkout.exercises[i];
        final weRes = await _client.from('workout_exercises').insert({
          'workout_id': wRes['id'],
          'exercise_id': ex.exerciseId,
          'sort_order': i,
        }).select().single();

        await _client.from('workout_sets').insert({
          'workout_exercise_id': weRes['id'],
          'set_number': 1,
          'repetitions': ex.repetitions,
          'weight_kg': ex.weightKg,
          'is_completed': true,
        });
      }
    } catch (_) {}
  }

  @override
  Future<void> completeWorkoutSession(String sessionId, String workoutId, List<WorkoutExerciseItem> exercises) async {
    try {
      await _client.rpc('complete_pt_session', params: {
        'p_session_id': sessionId,
        'p_completed_by': _client.auth.currentUser?.id,
      });

      await _client.from('workouts').update({
        'status': 'COMPLETED',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', workoutId);
    } catch (_) {}
  }
}
