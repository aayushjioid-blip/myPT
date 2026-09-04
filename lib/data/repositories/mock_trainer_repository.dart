import '../../domain/entities/trainer_entity.dart';
import '../../domain/entities/cancellation_policy_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/i_trainer_repository.dart';
import '../mock/mock_data_store.dart';

class MockTrainerRepository implements ITrainerRepository {
  final MockDataStore _dataStore;

  MockTrainerRepository(this._dataStore);

  @override
  Future<List<TrainerEntity>> getVerifiedTrainers() async {
    // RULE ADHERENCE: Only verified trainers appear in public discovery search!
    return _dataStore.trainers
        .where((t) => t.verificationStatus == VerificationStatus.verified)
        .toList();
  }

  @override
  Future<List<TrainerEntity>> getAllTrainers() async {
    return List.unmodifiable(_dataStore.trainers);
  }

  @override
  Future<TrainerEntity?> getTrainerById(String id) async {
    try {
      return _dataStore.trainers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TrainerEntity?> getTrainerByCode(String code) async {
    try {
      return _dataStore.trainers.firstWhere(
        (t) => t.trainerCode.toUpperCase() == code.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateCancellationPolicy(String trainerId, CancellationPolicyEntity policy) async {
    final idx = _dataStore.trainers.indexWhere((t) => t.id == trainerId);
    if (idx != -1) {
      _dataStore.trainers[idx] = _dataStore.trainers[idx].copyWith(cancellationPolicy: policy);
    }
  }

  @override
  Future<void> updateWorkingHours(String trainerId, Map<String, WorkingShift> hours) async {
    final idx = _dataStore.trainers.indexWhere((t) => t.id == trainerId);
    if (idx != -1) {
      _dataStore.trainers[idx] = _dataStore.trainers[idx].copyWith(workingHours: hours);
    }
  }

  @override
  Future<List<ReviewEntity>> getReviewsForTrainer(String trainerId) async {
    return _dataStore.reviews.where((r) => r.trainerId == trainerId).toList();
  }

  @override
  Future<void> addReview(ReviewEntity review) async {
    _dataStore.reviews.insert(0, review);
    final trainerReviews = _dataStore.reviews.where((r) => r.trainerId == review.trainerId).toList();
    final avgRating = trainerReviews.fold<double>(0.0, (sum, r) => sum + r.rating) / trainerReviews.length;
    
    final idx = _dataStore.trainers.indexWhere((t) => t.id == review.trainerId);
    if (idx != -1) {
      _dataStore.trainers[idx] = _dataStore.trainers[idx].copyWith(
        rating: double.parse(avgRating.toStringAsFixed(1)),
        reviewCount: trainerReviews.length,
      );
    }
  }
}
