import '../../domain/entities/credit_transaction_entity.dart';
import '../../domain/repositories/i_credit_ledger_repository.dart';
import '../mock/mock_data_store.dart';

class MockCreditLedgerRepository implements ICreditLedgerRepository {
  final MockDataStore _dataStore;

  MockCreditLedgerRepository(this._dataStore);

  @override
  Future<List<CreditTransactionEntity>> getTransactionsForClient(String clientId) async {
    return _dataStore.creditTransactions.where((t) => t.clientId == clientId).toList();
  }

  @override
  Future<int> getCurrentBalance(String clientPackageId) async {
    final clientPkg = _dataStore.clientPackages.firstWhere(
      (cp) => cp.id == clientPackageId,
      orElse: () => throw Exception('Package not found: $clientPackageId'),
    );
    return clientPkg.remainingSessions;
  }

  @override
  Future<void> recordTransaction(CreditTransactionEntity transaction) async {
    _dataStore.creditTransactions.insert(0, transaction);

    // Synchronize package entity remaining count
    final idx = _dataStore.clientPackages.indexWhere((cp) => cp.id == transaction.clientPackageId);
    if (idx != -1) {
      final existing = _dataStore.clientPackages[idx];
      _dataStore.clientPackages[idx] = existing.copyWith(
        remainingSessions: transaction.balanceAfter,
        completedSessions: transaction.transactionType == CreditTransactionType.sessionCompleted
            ? existing.completedSessions + 1
            : existing.completedSessions,
      );
    }
  }
}
