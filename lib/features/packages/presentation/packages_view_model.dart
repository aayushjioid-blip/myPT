import 'package:flutter/foundation.dart';
import '../../../domain/entities/credit_transaction_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class PackagesViewModel extends ChangeNotifier {
  final IPackageRepository _packageRepository;
  final MockDataStore _dataStore;

  List<ClientPackageEntity> _clientPackages = [];
  ClientPackageEntity? _activePackage;
  bool _isLoading = false;

  PackagesViewModel(this._packageRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
  }

  List<ClientPackageEntity> get clientPackages => _clientPackages;
  ClientPackageEntity? get activePackage => _activePackage;
  int get activeRemainingCredits => _activePackage?.remainingSessions ?? 0;
  bool get isLoading => _isLoading;

  Future<void> loadPackagesForClient(String clientId) async {
    _isLoading = true;
    notifyListeners();

    _clientPackages = await _packageRepository.getClientPackages(clientId);
    _activePackage = await _packageRepository.getActivePackageForClient(clientId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_dataStore.currentUser.id.isNotEmpty) {
      await loadPackagesForClient(_dataStore.currentUser.id);
    }
  }

  Future<void> purchasePackage({
    required String clientId,
    required String packageId,
    required String transactionRef,
  }) async {
    await _packageRepository.requestPackagePurchase(clientId, packageId, transactionRef);
    await loadPackagesForClient(clientId);
  }
}
