import 'package:flutter/foundation.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/i_auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final IAuthRepository _authRepository;
  UserEntity _currentUser;

  AuthViewModel(this._authRepository) : _currentUser = _authRepository.getCurrentUser() {
    _authRepository.currentUserStream.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  UserEntity get currentUser => _currentUser;
  UserRole get currentRole => _currentUser.role;
  bool get isClient => _currentUser.role == UserRole.client;
  bool get isTrainer => _currentUser.role == UserRole.trainer;
  bool get isHeadTrainer => _currentUser.role == UserRole.headTrainer;
  bool get isGymManager => _currentUser.role == UserRole.gymManager;
  bool get isSuperAdmin => _currentUser.role == UserRole.superAdmin;

  Future<void> switchDemoRole(String userId) async {
    await _authRepository.switchDemoUser(userId);
    notifyListeners();
  }

  Future<void> togglePersonalInfoSharing(bool isShared) async {
    await _authRepository.togglePersonalInfoSharing(isShared);
    notifyListeners();
  }

  Future<void> updateUserProfile(UserEntity updatedUser) async {
    await _authRepository.updateUserProfile(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<List<UserEntity>> getAllUsers() => _authRepository.getAllUsers();
}
