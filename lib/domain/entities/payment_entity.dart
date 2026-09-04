enum PaymentStatus { pendingVerification, paid, rejected }

class PaymentEntity {
  final String id;
  final String clientId;
  final String trainerId;
  final String packageId;
  final double amount;
  final String paymentMethod;
  final String transactionRef;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  const PaymentEntity({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.packageId,
    required this.amount,
    this.paymentMethod = 'UPI',
    required this.transactionRef,
    this.status = PaymentStatus.pendingVerification,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  PaymentEntity copyWith({
    PaymentStatus? status,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectionReason,
  }) {
    return PaymentEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId,
      packageId: packageId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionRef: transactionRef,
      status: status ?? this.status,
      createdAt: createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
