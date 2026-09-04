# Flutter to Supabase Readiness & Data Contract Mapping

**Project:** FitTrainer (Fitness Trainer Platform)  
**Version:** 1.0  
**Phase:** Stage 1.5 — Flutter Foundation  
**Date:** August 31, 2026  

---

## 1. Executive Summary

This document verifies that all Dart models, entities, repository contracts, and domain services in the Flutter application are structured for seamless future synchronization with the production **Supabase PostgreSQL backend**.

---

## 2. Model-to-PostgreSQL Schema Mapping

| Flutter Entity / Model | Target PostgreSQL Table | Key Foreign Keys & RLS Safeguards | Serialization Strategy |
| :--- | :--- | :--- | :--- |
| `UserEntity` / `UserModel` | `users` | `id REFERENCES auth.users(id)` | `fromJson` / `toJson` with null-safety |
| `TrainerEntity` / `TrainerModel` | `trainers` | `user_id REFERENCES users(id)` | `working_hours` serialized as `JSONB` |
| `GymEntity` / `GymModel` | `gyms` | `owner_id`, `head_trainer_id` | Array serialization for amenities |
| `PackageEntity` / `PackageModel` | `packages` | `trainer_id REFERENCES trainers(id)` | Numeric price & integer sessions |
| `RelationshipEntity` | `relationships` | `client_id`, `trainer_id` | Status string enum mapping |
| `ClientPackageEntity` | `client_packages` | `client_id`, `trainer_id`, `package_id` | Connected to `credit_ledger_transactions` |
| `PaymentEntity` | `payments` | `client_id`, `trainer_id`, `package_id` | Offline UPI & future gateway webhooks |
| `SessionEntity` | `sessions` | `client_id`, `trainer_id`, `client_package_id` | Check constraint: Own workouts 0 credit |
| `ExerciseEntity` | `exercises` | `trainer_id` (Nullable for global library) | 12 standard category enum strings |
| `WorkoutTemplateEntity` | `workout_templates` | `trainer_id REFERENCES trainers(id)` | `exercises` array mapped to `JSONB` |
| `WorkoutEntity` | `workouts` | `client_id`, `trainer_id` (Nullable) | Sets, reps, weight logs serialized |
| `MeasurementEntity` | `progress_measurements` | `client_id REFERENCES users(id)` | 8-point metrics + generated BMI |
| `ReviewEntity` | `reviews` | `trainer_id`, `client_id` | 1-5 integer rating & text comment |
| `CreditTransactionEntity` | `credit_ledger_transactions` | `client_id`, `client_package_id`, `session_id` | Append-only ledger entries |

---

## 3. Dependency Injection & Repository Swap Pattern

In Stage 1.5, the application registers mock repositories:
```dart
abstract class ITrainerRepository {
  Future<List<TrainerEntity>> getVerifiedTrainers();
  Future<TrainerEntity?> getTrainerById(String id);
  Future<void> updateWorkingHours(String trainerId, WorkingHours hours);
}

class MockTrainerRepository implements ITrainerRepository { ... }
```

In Stage 2, `SupabaseTrainerRepository` is implemented against the exact same interface:
```dart
class SupabaseTrainerRepository implements ITrainerRepository {
  final SupabaseClient _client;
  SupabaseTrainerRepository(this._client);

  @override
  Future<List<TrainerEntity>> getVerifiedTrainers() async {
    final data = await _client
        .from('trainers')
        .select('*')
        .eq('verification_status', 'VERIFIED');
    return data.map((json) => TrainerModel.fromJson(json).toEntity()).toList();
  }
}
```

This guarantees **zero architectural disruption** when transitioning from local mock state to Supabase.
