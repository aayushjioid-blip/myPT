import '../entities/trainer_entity.dart';
import '../entities/cancellation_policy_entity.dart';
import '../entities/review_entity.dart';

abstract class ITrainerRepository {
  Future<List<TrainerEntity>> getVerifiedTrainers();
  Future<List<TrainerEntity>> getAllTrainers();
  Future<TrainerEntity?> getTrainerById(String id);
  Future<TrainerEntity?> getTrainerByCode(String code);
  Future<void> updateCancellationPolicy(String trainerId, CancellationPolicyEntity policy);
  Future<void> updateWorkingHours(String trainerId, Map<String, WorkingShift> hours);
  Future<List<ReviewEntity>> getReviewsForTrainer(String trainerId);
  Future<void> addReview(ReviewEntity review);
}
