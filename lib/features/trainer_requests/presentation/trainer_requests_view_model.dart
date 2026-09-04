import 'package:flutter/foundation.dart';
import '../../../domain/entities/relationship_entity.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class TrainerRequestsViewModel extends ChangeNotifier {
  final IPackageRepository _packageRepository;
  final IAuthRepository _authRepository;
  final MockDataStore _dataStore;

  List<RelationshipEntity> _pendingConsultations = [];
  List<PaymentEntity> _pendingPayments = [];
  List<UserEntity> _allUsers = [];
  bool _isLoading = false;

  TrainerRequestsViewModel(this._packageRepository, this._authRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
    refresh();
  }

  List<RelationshipEntity> get pendingConsultations => _pendingConsultations;
  List<PaymentEntity> get pendingPayments => _pendingPayments;
  int get totalPendingCount => _pendingConsultations.length + _pendingPayments.length;
  bool get isLoading => _isLoading;

  UserEntity? getUserById(String userId) {
    try {
      return _allUsers.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRequestsForTrainer([String? trainerId]) async {
    final tId = trainerId ??
        (_dataStore.currentUser.role == UserRole.trainer
            ? _dataStore.currentUser.id
            : 'trn-alex');
    _isLoading = true;
    notifyListeners();

    _pendingConsultations = await _packageRepository.getPendingRelationshipsForTrainer(tId);
    _pendingPayments = await _packageRepository.getPendingPaymentsForTrainer(tId);
    _allUsers = await _authRepository.getAllUsers();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final tId = _dataStore.currentUser.role == UserRole.trainer
        ? _dataStore.currentUser.id
        : 'trn-alex';
    await loadRequestsForTrainer(tId);
  }

  Future<void> acceptConsultation(String relationshipId, [String? trainerId]) async {
    await _packageRepository.acceptConsultation(relationshipId);
    await refresh();
  }

  Future<void> verifyPayment(String paymentId, bool approve, [String? trainerId, String? reason]) async {
    await _packageRepository.verifyPayment(paymentId, approve, reason: reason);
    await refresh();
  }
}
