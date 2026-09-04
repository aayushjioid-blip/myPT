import '../../domain/repositories/i_admin_repository.dart';
import '../../domain/entities/trainer_entity.dart';
import '../mock/mock_data_store.dart';

class MockAdminRepository implements IAdminRepository {
  final MockDataStore _dataStore;

  MockAdminRepository(this._dataStore);

  @override
  Future<Map<String, bool>> getFeatureFlags() async {
    return Map.unmodifiable(_dataStore.featureFlags);
  }

  @override
  Future<void> setFeatureFlag(String key, bool value) async {
    _dataStore.featureFlags[key] = value;
  }

  @override
  Future<void> setTrainerVerification(String trainerId, bool isVerified) async {
    final idx = _dataStore.trainers.indexWhere((t) => t.id == trainerId);
    if (idx != -1) {
      _dataStore.trainers[idx] = _dataStore.trainers[idx].copyWith(
        verificationStatus: isVerified ? VerificationStatus.verified : VerificationStatus.unverified,
      );
    }
  }

  @override
  Future<void> setUserStatus(String userId, String status) async {
    final idx = _dataStore.users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _dataStore.users[idx] = _dataStore.users[idx].copyWith(status: status);
    }
  }
}
