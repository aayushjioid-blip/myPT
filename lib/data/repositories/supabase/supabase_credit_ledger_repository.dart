import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/credit_transaction_entity.dart';
import '../../../domain/repositories/i_credit_ledger_repository.dart';
import '../../models/credit_transaction_model.dart';

class SupabaseCreditLedgerRepository implements ICreditLedgerRepository {
  final SupabaseClient _client;

  SupabaseCreditLedgerRepository(this._client);

  @override
  Future<List<CreditTransactionEntity>> getTransactionsForClient(String clientId) async {
    try {
      final res = await _client
          .from('credit_ledger_transactions')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => CreditTransactionModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> getCurrentBalance(String clientPackageId) async {
    try {
      final res = await _client
          .from('client_packages')
          .select('remaining_sessions')
          .eq('id', clientPackageId)
          .maybeSingle();

      if (res != null) {
        return int.tryParse(res['remaining_sessions'].toString()) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Future<void> recordTransaction(CreditTransactionEntity transaction) async {
    try {
      await _client.from('credit_ledger_transactions').insert({
        'client_package_id': transaction.clientPackageId,
        'client_id': transaction.clientId,
        'session_id': transaction.sessionId,
        'transaction_type': transaction.transactionType.name.toUpperCase(),
        'delta_credits': transaction.deltaCredits,
        'balance_after': transaction.balanceAfter,
        'reason': 'Transaction recorded',
        'created_by': transaction.createdBy,
      });
    } catch (_) {}
  }
}
