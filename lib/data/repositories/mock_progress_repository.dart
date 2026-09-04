import '../../domain/entities/measurement_entity.dart';
import '../../domain/repositories/i_progress_repository.dart';
import '../mock/mock_data_store.dart';

class MockProgressRepository implements IProgressRepository {
  final MockDataStore _dataStore;

  MockProgressRepository(this._dataStore);

  @override
  Future<List<MeasurementEntity>> getMeasurementsByClientId(String clientId) async {
    return _dataStore.measurements.where((m) => m.clientId == clientId).toList();
  }

  @override
  Future<void> logMeasurement(MeasurementEntity measurement) async {
    _dataStore.measurements.insert(0, measurement);
    _dataStore.notifyListeners();
  }
}
