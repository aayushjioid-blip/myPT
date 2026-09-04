import '../../domain/entities/fitness_chart_entity.dart';
import '../../domain/repositories/i_fitness_chart_repository.dart';
import '../mock/mock_data_store.dart';

class MockFitnessChartRepository implements IFitnessChartRepository {
  final MockDataStore _dataStore;

  MockFitnessChartRepository(this._dataStore);

  List<String> _resolveEquivalentIds(String id) {
    if (id == 'trn-alex' || id == 'usr-trn-1') return ['trn-alex', 'usr-trn-1'];
    if (id == 'usr-client-1') return ['usr-client-1'];
    if (id == 'usr-client-2') return ['usr-client-2'];
    return [id];
  }

  @override
  Future<List<FitnessChartEntity>> getChartsForClient(String clientId) async {
    final eq = _resolveEquivalentIds(clientId);
    final list = _dataStore.charts.where((c) => eq.contains(c.clientId)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<FitnessChartEntity>> getChartsForTrainer(String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    final list = _dataStore.charts.where((c) => eq.contains(c.trainerId)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<FitnessChartEntity>> getAllCharts() async {
    final list = List<FitnessChartEntity>.from(_dataStore.charts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> dispatchChart(FitnessChartEntity chart) async {
    _dataStore.charts.insert(0, chart);
    _dataStore.notifyListeners();
  }

  @override
  Future<void> deleteChart(String chartId) async {
    _dataStore.charts.removeWhere((c) => c.id == chartId);
    _dataStore.notifyListeners();
  }
}
