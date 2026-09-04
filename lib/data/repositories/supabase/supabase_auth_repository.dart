import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../models/user_model.dart';

class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient _client;
  final _userStreamController = StreamController<UserEntity>.broadcast();
  UserEntity _currentUser = const UserEntity(
    id: '00000000-0000-0000-0000-000000000001',
    name: 'Sarah Jenkins',
    email: 'sarah.jenkins@fitapp.dev',
    role: UserRole.client,
    avatar: '👩',
  );

  SupabaseAuthRepository(this._client) {
    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _fetchAndSetUserProfile(session.user.id);
      }
    });
  }

  Future<void> _fetchAndSetUserProfile(String authId) async {
    try {
      final res = await _client
          .from('users')
          .select('*, client_health_profiles(*)')
          .eq('auth_id', authId)
          .maybeSingle();

      if (res != null) {
        final model = UserModel.fromJson(res);
        _currentUser = model.toEntity();
        _userStreamController.add(_currentUser);
      }
    } catch (_) {
      // Fallback
    }
  }

  @override
  UserEntity getCurrentUser() => _currentUser;

  @override
  Stream<UserEntity> get currentUserStream => _userStreamController.stream;

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchAndSetUserProfile(response.user!.id);
        return _currentUser;
      }
    } catch (e) {
      // Fallback in dev/mock mode
    }
    return _currentUser;
  }

  // Real Supabase Phone OTP Authentication
  Future<void> signInWithPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<UserEntity?> verifyPhoneOtp(String phone, String token) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
    if (response.user != null) {
      await _fetchAndSetUserProfile(response.user!.id);
      return _currentUser;
    }
    return null;
  }

  // Real Supabase OAuth (Google & Apple)
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> togglePersonalInfoSharing(bool enabled) async {
    _currentUser = _currentUser.copyWith(sharePersonalInfoWithTrainer: enabled);
    _userStreamController.add(_currentUser);

    try {
      await _client
          .from('client_health_profiles')
          .update({'share_personal_info_with_trainer': enabled})
          .eq('user_id', _currentUser.id);
    } catch (_) {}
  }

  @override
  Future<void> switchDemoUser(String userId) async {
    try {
      final res = await _client
          .from('users')
          .select('*, client_health_profiles(*)')
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        _currentUser = UserModel.fromJson(res).toEntity();
        _userStreamController.add(_currentUser);
        return;
      }
    } catch (_) {}

    // Fallback in offline/demo mode
    if (userId.contains('client')) {
      _currentUser = const UserEntity(
        id: '00000000-0000-0000-0000-000000000001',
        name: 'Sarah Jenkins',
        email: 'sarah.jenkins@fitapp.dev',
        role: UserRole.client,
        avatar: '👩',
      );
    } else if (userId.contains('trn-1')) {
      _currentUser = const UserEntity(
        id: '00000000-0000-0000-0000-000000000002',
        name: 'Alex Rivera',
        email: 'alex.rivera@fitapp.dev',
        role: UserRole.trainer,
        avatar: '🏋️',
      );
    } else if (userId.contains('headtrn')) {
      _currentUser = const UserEntity(
        id: '00000000-0000-0000-0000-000000000005',
        name: 'Marcus Vance',
        email: 'marcus.vance@fitapp.dev',
        role: UserRole.headTrainer,
        avatar: '👑',
      );
    } else if (userId.contains('gymmgr')) {
      _currentUser = const UserEntity(
        id: '00000000-0000-0000-0000-000000000006',
        name: 'Elena Rostova',
        email: 'elena.rostova@fitapp.dev',
        role: UserRole.gymManager,
        avatar: '🏢',
      );
    } else if (userId.contains('admin')) {
      _currentUser = const UserEntity(
        id: '00000000-0000-0000-0000-000000000007',
        name: 'Demo Super Admin',
        email: 'admin@fitapp.dev',
        role: UserRole.superAdmin,
        avatar: '🛡️',
      );
    }
    _userStreamController.add(_currentUser);
  }

  @override
  Future<void> updateUserProfile(UserEntity updatedUser) async {
    try {
      await _client.from('users').update({
        'name': updatedUser.name,
        'email': updatedUser.email,
        'avatar': updatedUser.avatar,
        'phone': updatedUser.emergencyContact,
      }).eq('id', updatedUser.id);
    } catch (_) {}
    _currentUser = updatedUser;
    _userStreamController.add(_currentUser);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    try {
      final res = await _client
          .from('users')
          .select('*, client_health_profiles(*)');
      return (res as List).map((json) => UserModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [
        const UserEntity(id: '00000000-0000-0000-0000-000000000001', name: 'Sarah Jenkins', email: 'sarah.jenkins@fitapp.dev', role: UserRole.client, avatar: '👩'),
        const UserEntity(id: '00000000-0000-0000-0000-000000000002', name: 'Alex Rivera', email: 'alex.rivera@fitapp.dev', role: UserRole.trainer, avatar: '🏋️'),
        const UserEntity(id: '00000000-0000-0000-0000-000000000003', name: 'Maya Lin', email: 'maya.lin@fitapp.dev', role: UserRole.trainer, avatar: '🧘'),
        const UserEntity(id: '00000000-0000-0000-0000-000000000004', name: 'Leo Novak', email: 'leo.novak@fitapp.dev', role: UserRole.trainer, avatar: '🥊'),
        const UserEntity(id: '00000000-0000-0000-0000-000000000005', name: 'Marcus Vance', email: 'marcus.vance@fitapp.dev', role: UserRole.headTrainer, avatar: '👑'),
        const UserEntity(id: '00000000-0000-0000-0000-000000000006', name: 'Elena Rostova', email: 'elena.rostova@fitapp.dev', role: UserRole.gymManager, avatar: '🏢'),
        const UserEntity(id: '00000000-0000-0000-0000-000000000007', name: 'Demo Super Admin', email: 'admin@fitapp.dev', role: UserRole.superAdmin, avatar: '🛡️'),
      ];
    }
  }
}
