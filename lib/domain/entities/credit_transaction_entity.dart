enum CreditTransactionType {
  packageActivation,
  sessionCompleted,
  lateCancellationPenalty,
  refundAdjustment,
  expiration,
  transfer
}

class ClientPackageEntity {
  final String id;
  final String clientId;
  final String trainerId;
  final String packageId;
  final int totalSessions;
  final int completedSessions;
  final int remainingSessions;
  final int validityDays;
  final DateTime purchaseDate;
  final DateTime? activationDate;
  final DateTime? expiryDate;
  final String status;
  final String? paymentId;

  const ClientPackageEntity({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.packageId,
    required this.totalSessions,
    this.completedSessions = 0,
    required this.remainingSessions,
    required this.validityDays,
    required this.purchaseDate,
    this.activationDate,
    this.expiryDate,
    this.status = 'PENDING_PAYMENT',
    this.paymentId,
  });

  ClientPackageEntity copyWith({
    int? remainingSessions,
    int? completedSessions,
    String? status,
    String? trainerId,
    DateTime? activationDate,
    DateTime? expiryDate,
  }) {
    return ClientPackageEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId ?? this.trainerId,
      packageId: packageId,
      totalSessions: totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      validityDays: validityDays,
      purchaseDate: purchaseDate,
      activationDate: activationDate ?? this.activationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      paymentId: paymentId,
    );
  }
}

class CreditTransactionEntity {
  final String id;
  final String clientId;
  final String clientPackageId;
  final String? sessionId;
  final CreditTransactionType transactionType;
  final int deltaCredits;
  final int balanceAfter;
  final DateTime createdAt;
  final String createdBy;

  const CreditTransactionEntity({
    required this.id,
    required this.clientId,
    required this.clientPackageId,
    this.sessionId,
    required this.transactionType,
    required this.deltaCredits,
    required this.balanceAfter,
    required this.createdAt,
    required this.createdBy,
  });
}
