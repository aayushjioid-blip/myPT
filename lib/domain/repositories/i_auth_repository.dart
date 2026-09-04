import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Stream<UserEntity> get currentUserStream;
  UserEntity getCurrentUser();
  Future<UserEntity?> signIn(String email, String password);
  Future<void> signOut();
  Future<void> switchDemoUser(String userId);
  Future<void> togglePersonalInfoSharing(bool isShared);
  Future<void> updateUserProfile(UserEntity updatedUser);
  Future<List<UserEntity>> getAllUsers();
}
