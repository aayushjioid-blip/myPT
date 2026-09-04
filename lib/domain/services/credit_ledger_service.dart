import '../entities/credit_transaction_entity.dart';
import '../entities/session_entity.dart';
import '../repositories/i_credit_ledger_repository.dart';

class CreditLedgerService {
  final ICreditLedgerRepository _ledgerRepo;

  CreditLedgerService(this._ledgerRepo);

  /// Deducts credit for a completed PT session.
  /// Strict Rule: Own workouts never consume credits!
  Future<int> processSessionCompletion({
    required SessionEntity session,
    required String clientPackageId,
    required String performedByUserId,
  }) async {
    if (session.sessionType == SessionType.ownWorkout) {
      // Zero credit consumption for Own Workouts
      return await _ledgerRepo.getCurrentBalance(clientPackageId);
    }

    final currentBalance = await _ledgerRepo.getCurrentBalance(clientPackageId);
    if (currentBalance <= 0) {
      throw Exception('Cannot complete PT session: Zero remaining credits in package.');
    }

    final newBalance = currentBalance - 1;
    final transaction = CreditTransactionEntity(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      clientId: session.clientId,
      clientPackageId: clientPackageId,
      sessionId: session.id,
      transactionType: CreditTransactionType.sessionCompleted,
      deltaCredits: -1,
      balanceAfter: newBalance,
      createdAt: DateTime.now(),
      createdBy: performedByUserId,
    );

    await _ledgerRepo.recordTransaction(transaction);
    return newBalance;
  }

  /// Processes penalty deduction for late cancellation.
  Future<int> processCancellationPenalty({
    required String clientId,
    required String clientPackageId,
    required String sessionId,
    required int penaltyCredits,
    required String cancelledByUserId,
  }) async {
    if (penaltyCredits <= 0) {
      return await _ledgerRepo.getCurrentBalance(clientPackageId);
    }

    final currentBalance = await _ledgerRepo.getCurrentBalance(clientPackageId);
    final newBalance = (currentBalance - penaltyCredits).clamp(0, 999);

    final transaction = CreditTransactionEntity(
      id: 'tx-pen-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      clientPackageId: clientPackageId,
      sessionId: sessionId,
      transactionType: CreditTransactionType.lateCancellationPenalty,
      deltaCredits: -penaltyCredits,
      balanceAfter: newBalance,
      createdAt: DateTime.now(),
      createdBy: cancelledByUserId,
    );

    await _ledgerRepo.recordTransaction(transaction);
    return newBalance;
  }
}
