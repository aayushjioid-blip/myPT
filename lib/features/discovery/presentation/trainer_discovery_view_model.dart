import 'package:flutter/foundation.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/repositories/i_trainer_repository.dart';
import '../../admin/presentation/admin_view_model.dart';
import '../../../data/mock/mock_data_store.dart';

class TrainerDiscoveryViewModel extends ChangeNotifier {
  final ITrainerRepository _trainerRepository;
  final AdminViewModel _adminViewModel;
  final MockDataStore _dataStore;

  List<TrainerEntity> _verifiedTrainers = [];
  List<TrainerEntity> _filteredTrainers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  TrainerDiscoveryViewModel(this._trainerRepository, this._adminViewModel, this._dataStore) {
    _dataStore.stateChanges.listen((_) => loadTrainers());
    loadTrainers();
  }

  List<TrainerEntity> get trainers => _filteredTrainers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isAdvancedSearchEnabled => _adminViewModel.isAdvancedTrainerSearchEnabled;

  Future<void> loadTrainers() async {
    _isLoading = true;
    notifyListeners();
    
    // Strict Rule: Only verified trainers appear in public discovery!
    _verifiedTrainers = await _trainerRepository.getVerifiedTrainers();
    _applyFilter();
    
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  Future<TrainerEntity?> findByCode(String code) async {
    return await _trainerRepository.getTrainerByCode(code);
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredTrainers = List.from(_verifiedTrainers);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredTrainers = _verifiedTrainers.where((t) {
        return t.name.toLowerCase().contains(q) ||
            t.specializations.any((s) => s.toLowerCase().contains(q)) ||
            t.location.toLowerCase().contains(q);
      }).toList();
    }
  }
}
