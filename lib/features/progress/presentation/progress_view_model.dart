import 'package:flutter/foundation.dart';
import '../../../domain/entities/measurement_entity.dart';
import '../../../domain/repositories/i_progress_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/mock/mock_data_store.dart';

enum ProgressTimeRange { oneMonth, threeMonths, sixMonths, allTime }

class ProgressViewModel extends ChangeNotifier {
  final IProgressRepository _progressRepository;
  final MockDataStore _dataStore;

  List<MeasurementEntity> _allMeasurements = [];
  ProgressTimeRange _selectedRange = ProgressTimeRange.threeMonths;
  bool _isLoading = false;

  ProgressViewModel(this._progressRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
  }

  List<MeasurementEntity> get allMeasurements => _allMeasurements;
  ProgressTimeRange get selectedRange => _selectedRange;
  bool get isLoading => _isLoading;

  MeasurementEntity? get latestMeasurement => _allMeasurements.isNotEmpty ? _allMeasurements.first : null;
  MeasurementEntity? get initialMeasurement => _allMeasurements.isNotEmpty ? _allMeasurements.last : null;

  double get totalWeightLost {
    if (_allMeasurements.length < 2) return 0.0;
    final initial = initialMeasurement!.weightKg;
    final latest = latestMeasurement!.weightKg;
    return double.parse((initial - latest).toStringAsFixed(1));
  }

  List<MeasurementEntity> get filteredMeasurements {
    if (_selectedRange == ProgressTimeRange.allTime) return _allMeasurements;

    final now = DateTime.now();
    int days;
    switch (_selectedRange) {
      case ProgressTimeRange.oneMonth:
        days = 30;
        break;
      case ProgressTimeRange.threeMonths:
        days = 90;
        break;
      case ProgressTimeRange.sixMonths:
        days = 180;
        break;
      case ProgressTimeRange.allTime:
        days = 9999;
        break;
    }

    final cutoff = now.subtract(Duration(days: days));
    return _allMeasurements.where((m) => m.date.isAfter(cutoff)).toList();
  }

  void setTimeRange(ProgressTimeRange range) {
    _selectedRange = range;
    notifyListeners();
  }

  Future<void> loadForClient(String clientId) async {
    _isLoading = true;
    notifyListeners();

    _allMeasurements = await _progressRepository.getMeasurementsByClientId(clientId);
    // Sort descending by date
    _allMeasurements.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final user = _dataStore.currentUser;
    if (user.id.isNotEmpty) {
      await loadForClient(user.id);
    }
  }

  Future<void> logMeasurement({
    required String clientId,
    required double weightKg,
    required double heightCm,
    double bodyFat = 22.0,
    double chest = 90.0,
    double waist = 72.0,
    double hips = 95.0,
    double biceps = 29.0,
    double thighs = 55.0,
    double calves = 36.5,
    ProgressPhotos? photos,
    String? notes,
    String source = 'CLIENT',
  }) async {
    final bmi = Formatters.calculateBmi(weightKg, heightCm);

    final m = MeasurementEntity(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      date: DateTime.now(),
      weightKg: weightKg,
      heightCm: heightCm,
      bmi: bmi,
      bodyFatPercentage: bodyFat,
      chestCm: chest,
      waistCm: waist,
      hipsCm: hips,
      bicepsCm: biceps,
      thighsCm: thighs,
      calvesCm: calves,
      photos: photos,
      notes: notes,
      source: source,
    );

    await _progressRepository.logMeasurement(m);
    await refresh();
  }
}
