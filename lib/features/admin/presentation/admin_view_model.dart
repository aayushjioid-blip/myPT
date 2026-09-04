import 'package:flutter/foundation.dart';
import '../../../domain/repositories/i_admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final IAdminRepository _adminRepository;
  Map<String, bool> _featureFlags = {};
  bool _isLoading = false;

  AdminViewModel(this._adminRepository) {
    loadFeatureFlags();
  }

  Map<String, bool> get featureFlags => _featureFlags;
  bool get isLoading => _isLoading;
  bool get isAdvancedTrainerSearchEnabled => _featureFlags['advanced_trainer_search'] ?? false;

  Future<void> loadFeatureFlags() async {
    _isLoading = true;
    notifyListeners();
    _featureFlags = await _adminRepository.getFeatureFlags();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFeatureFlag(String key, bool value) async {
    await _adminRepository.setFeatureFlag(key, value);
    _featureFlags = Map.from(_featureFlags)..[key] = value;
    notifyListeners();
  }

  Future<void> setTrainerVerification(String trainerId, bool isVerified) async {
    await _adminRepository.setTrainerVerification(trainerId, isVerified);
    notifyListeners();
  }
}
