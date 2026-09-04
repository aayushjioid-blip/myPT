import 'package:flutter/foundation.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/credit_transaction_entity.dart';
import '../../../domain/entities/workout_entity.dart';
import '../../../domain/entities/measurement_entity.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../../domain/repositories/i_workout_repository.dart';
import '../../../domain/repositories/i_progress_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class Client360Profile {
  final UserEntity user;
  final ClientPackageEntity? activePackage;
  final List<WorkoutEntity> workoutHistory;
  final List<MeasurementEntity> sharedMeasurements;

  const Client360Profile({
    required this.user,
    this.activePackage,
    this.workoutHistory = const [],
    this.sharedMeasurements = const [],
  });
}

class TrainerClientsViewModel extends ChangeNotifier {
  final IAuthRepository _authRepository;
  final IPackageRepository _packageRepository;
  final IWorkoutRepository _workoutRepository;
  final IProgressRepository _progressRepository;
  final MockDataStore _dataStore;

  List<Client360Profile> _clients = [];
  String _searchQuery = '';
  bool _isLoading = false;

  TrainerClientsViewModel(
    this._authRepository,
    this._packageRepository,
    this._workoutRepository,
    this._progressRepository,
    this._dataStore,
  ) {
    _dataStore.stateChanges.listen((_) => refresh());
  }

  List<Client360Profile> get clients {
    if (_searchQuery.trim().isEmpty) return _clients;
    final q = _searchQuery.toLowerCase();
    return _clients.where((c) =>
      c.user.name.toLowerCase().contains(q) ||
      c.user.email.toLowerCase().contains(q) ||
      (c.activePackage?.status.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  bool get isLoading => _isLoading;

  Future<void> loadClientsForTrainer(String trainerId) async {
    _isLoading = true;
    notifyListeners();

    final allUsers = await _authRepository.getAllUsers();
    final clientUsers = allUsers.where((u) => u.role == UserRole.client).toList();

    List<Client360Profile> profiles = [];

    for (final client in clientUsers) {
      final activePkg = await _packageRepository.getActivePackageForClient(client.id);
      final workouts = await _workoutRepository.getWorkoutsForClient(client.id);

      // Privacy Rule: Only load measurements if client explicitly opted in!
      List<MeasurementEntity> measurements = [];
      if (client.sharePersonalInfoWithTrainer) {
        measurements = await _progressRepository.getMeasurementsByClientId(client.id);
      }

      profiles.add(Client360Profile(
        user: client,
        activePackage: activePkg,
        workoutHistory: workouts,
        sharedMeasurements: measurements,
      ));
    }

    _clients = profiles;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final user = _dataStore.currentUser;
    if (user.id.isNotEmpty) {
      await loadClientsForTrainer(user.id);
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
