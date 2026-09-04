import 'package:flutter/foundation.dart';
import '../../../domain/entities/fitness_chart_entity.dart';
import '../../../domain/repositories/i_fitness_chart_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class FitnessChartViewModel extends ChangeNotifier {
  final IFitnessChartRepository _chartRepository;
  final MockDataStore _dataStore;

  List<FitnessChartEntity> _clientCharts = [];
  List<FitnessChartEntity> _trainerCharts = [];
  List<FitnessChartEntity> _allCharts = [];
  bool _isLoading = false;

  FitnessChartViewModel(this._chartRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
  }

  List<FitnessChartEntity> get clientCharts => _clientCharts;
  List<FitnessChartEntity> get trainerCharts => _trainerCharts;
  List<FitnessChartEntity> get allCharts => _allCharts;
  bool get isLoading => _isLoading;

  Future<void> loadChartsForClient(String clientId) async {
    _isLoading = true;
    notifyListeners();

    _clientCharts = await _chartRepository.getChartsForClient(clientId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChartsForTrainer(String trainerId) async {
    _isLoading = true;
    notifyListeners();

    _trainerCharts = await _chartRepository.getChartsForTrainer(trainerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllCharts() async {
    _isLoading = true;
    notifyListeners();

    _allCharts = await _chartRepository.getAllCharts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final user = _dataStore.currentUser;
    if (user.id.isNotEmpty) {
      await loadChartsForClient(user.id);
      await loadChartsForTrainer(user.id);
      await loadAllCharts();
    }
  }

  Future<void> dispatchChart({
    required String trainerId,
    required String trainerName,
    required String clientId,
    required String clientName,
    required String title,
    required String goalCategory,
    required List<MealItemEntity> dietPlan,
    required List<WorkoutExercisePlan> workoutPlan,
  }) async {
    final chart = FitnessChartEntity(
      id: 'chart-${DateTime.now().millisecondsSinceEpoch}',
      trainerId: trainerId,
      trainerName: trainerName,
      clientId: clientId,
      clientName: clientName,
      title: title,
      goalCategory: goalCategory,
      dietPlan: dietPlan,
      workoutPlan: workoutPlan,
      createdAt: DateTime.now(),
    );

    await _chartRepository.dispatchChart(chart);
    await refresh();
  }

  Future<void> deleteChart(String chartId) async {
    await _chartRepository.deleteChart(chartId);
    await refresh();
  }
}
