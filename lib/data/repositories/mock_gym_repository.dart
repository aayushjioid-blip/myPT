import '../../domain/entities/gym_entity.dart';
import '../../domain/entities/trainer_entity.dart';
import '../../domain/repositories/i_gym_repository.dart';
import '../mock/mock_data_store.dart';

class MockGymRepository implements IGymRepository {
  final MockDataStore _dataStore;

  MockGymRepository(this._dataStore);

  @override
  Future<GymEntity?> getGymById(String gymId) async {
    try {
      return _dataStore.gyms.firstWhere((g) => g.id == gymId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TrainerEntity>> getStaffTrainersForGym(String gymId) async {
    return _dataStore.trainers;
  }

  @override
  Future<void> reassignClient({
    required String relationshipId,
    required String fromTrainerId,
    required String toTrainerId,
    required String reason,
  }) async {
    final index = _dataStore.relationships.indexWhere((r) => r.id == relationshipId);
    if (index != -1) {
      _dataStore.relationships[index] = _dataStore.relationships[index].copyWith(
        trainerId: toTrainerId,
        reassignedAt: DateTime.now(),
        reassignmentReason: reason,
      );
    }

    // Preserves 100% of client packages and credit balances
    for (int i = 0; i < _dataStore.clientPackages.length; i++) {
      if (_dataStore.clientPackages[i].clientId == _dataStore.relationships[index != -1 ? index : 0].clientId &&
          _dataStore.clientPackages[i].trainerId == fromTrainerId) {
        _dataStore.clientPackages[i] = _dataStore.clientPackages[i].copyWith(trainerId: toTrainerId);
      }
    }
  }
}
