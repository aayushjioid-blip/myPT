import '../entities/credit_transaction_entity.dart';

abstract class ICreditLedgerRepository {
  Future<List<CreditTransactionEntity>> getTransactionsForClient(String clientId);
  Future<int> getCurrentBalance(String clientPackageId);
  Future<void> recordTransaction(CreditTransactionEntity transaction);
}
