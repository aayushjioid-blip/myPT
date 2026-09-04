import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../mock/mock_data_store.dart';

class MockAuthRepository implements IAuthRepository {
  final MockDataStore _dataStore;

  MockAuthRepository(this._dataStore);

  @override
  Stream<UserEntity> get currentUserStream => _dataStore.currentUserStream;

  @override
  UserEntity getCurrentUser() => _dataStore.currentUser;

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final user = _dataStore.users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => _dataStore.users.first,
    );
    _dataStore.setCurrentUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _dataStore.setCurrentUser(_dataStore.users.first);
  }

  @override
  Future<void> switchDemoUser(String userId) async {
    final user = _dataStore.users.firstWhere(
      (u) => u.id == userId,
      orElse: () => _dataStore.users.first,
    );
    _dataStore.setCurrentUser(user);
  }

  @override
  Future<void> togglePersonalInfoSharing(bool isShared) async {
    final user = _dataStore.currentUser;
    final updated = user.copyWith(sharePersonalInfoWithTrainer: isShared);
    final idx = _dataStore.users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _dataStore.users[idx] = updated;
    }
    _dataStore.setCurrentUser(updated);
  }

  @override
  Future<void> updateUserProfile(UserEntity updatedUser) async {
    final idx = _dataStore.users.indexWhere((u) => u.id == updatedUser.id);
    if (idx != -1) {
      _dataStore.users[idx] = updatedUser;
    }
    _dataStore.setCurrentUser(updatedUser);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    return List.unmodifiable(_dataStore.users);
  }
}
