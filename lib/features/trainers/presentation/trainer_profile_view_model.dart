import 'package:flutter/foundation.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/entities/relationship_entity.dart';
import '../../../domain/repositories/i_trainer_repository.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class TrainerProfileViewModel extends ChangeNotifier {
  final ITrainerRepository _trainerRepository;
  final IPackageRepository _packageRepository;

  TrainerEntity? _trainer;
  List<PackageEntity> _packages = [];
  List<ReviewEntity> _reviews = [];
  RelationshipEntity? _relationship;
  bool _isLoading = false;

  TrainerProfileViewModel(this._trainerRepository, this._packageRepository, [MockDataStore? dataStore]);

  TrainerEntity? get trainer => _trainer;
  List<PackageEntity> get packages => _packages;
  List<ReviewEntity> get reviews => _reviews;
  RelationshipEntity? get relationship => _relationship;
  bool get isLoading => _isLoading;
  bool get isApprovedForPackages => _relationship?.status == RelationshipStatus.accepted;

  Future<void> loadProfile(String trainerId, String clientId) async {
    _isLoading = true;
    notifyListeners();

    _trainer = await _trainerRepository.getTrainerById(trainerId);
    _packages = await _packageRepository.getPackagesByTrainerId(trainerId);
    _reviews = await _trainerRepository.getReviewsForTrainer(trainerId);
    _relationship = await _packageRepository.getRelationship(clientId, trainerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestConsultation({
    required String clientId,
    required String trainerId,
    required String goals,
    required String notes,
  }) async {
    await _packageRepository.requestConsultation(
      clientId: clientId,
      trainerId: trainerId,
      goals: goals,
      notes: notes,
    );
    _relationship = await _packageRepository.getRelationship(clientId, trainerId);
    notifyListeners();
  }
}
