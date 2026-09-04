import '../../domain/entities/credit_transaction_entity.dart';

class CreditTransactionModel {
  final String id;
  final String clientPackageId;
  final String clientId;
  final String trainerId;
  final String? sessionId;
  final CreditTransactionType transactionType;
  final int deltaCredits;
  final int balanceAfter;
  final String reason;
  final String createdBy;
  final DateTime createdAt;

  CreditTransactionModel({
    required this.id,
    required this.clientPackageId,
    required this.clientId,
    required this.trainerId,
    this.sessionId,
    required this.transactionType,
    required this.deltaCredits,
    required this.balanceAfter,
    required this.reason,
    this.createdBy = 'SYSTEM',
    required this.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    CreditTransactionType parsedType;
    switch (json['transaction_type']?.toString().toUpperCase()) {
      case 'PACKAGE_ACTIVATION':
        parsedType = CreditTransactionType.packageActivation;
        break;
      case 'CANCELLATION_PENALTY':
        parsedType = CreditTransactionType.lateCancellationPenalty;
        break;
      case 'CLIENT_TRANSFER':
        parsedType = CreditTransactionType.transfer;
        break;
      case 'PACKAGE_EXPIRY':
        parsedType = CreditTransactionType.expiration;
        break;
      case 'REFUND':
        parsedType = CreditTransactionType.refundAdjustment;
        break;
      case 'SESSION_COMPLETION':
      default:
        parsedType = CreditTransactionType.sessionCompleted;
    }

    return CreditTransactionModel(
      id: json['id']?.toString() ?? '',
      clientPackageId: json['client_package_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString(),
      transactionType: parsedType,
      deltaCredits: json['delta_credits'] != null ? int.tryParse(json['delta_credits'].toString()) ?? 0 : 0,
      balanceAfter: json['balance_after'] != null ? int.tryParse(json['balance_after'].toString()) ?? 0 : 0,
      reason: json['reason']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? 'SYSTEM',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  CreditTransactionEntity toEntity() {
    return CreditTransactionEntity(
      id: id,
      clientId: clientId,
      clientPackageId: clientPackageId,
      sessionId: sessionId,
      transactionType: transactionType,
      deltaCredits: deltaCredits,
      balanceAfter: balanceAfter,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
