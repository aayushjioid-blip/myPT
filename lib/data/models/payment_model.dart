import '../../domain/entities/payment_entity.dart';

class PaymentModel {
  final String id;
  final String clientId;
  final String trainerId;
  final String packageId;
  final String? clientPackageId;
  final double amount;
  final String paymentMethod;
  final String transactionRef;
  final PaymentStatus status;
  final String? receiptUrl;
  final String? notes;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.packageId,
    this.clientPackageId,
    required this.amount,
    this.paymentMethod = 'UPI',
    required this.transactionRef,
    this.status = PaymentStatus.pendingVerification,
    this.receiptUrl,
    this.notes,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    PaymentStatus pStatus;
    switch (json['status']?.toString().toUpperCase()) {
      case 'VERIFIED':
        pStatus = PaymentStatus.paid;
        break;
      case 'REJECTED':
        pStatus = PaymentStatus.rejected;
        break;
      case 'PENDING_VERIFICATION':
      default:
        pStatus = PaymentStatus.pendingVerification;
    }

    return PaymentModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString() ?? '',
      packageId: json['package_id']?.toString() ?? '',
      clientPackageId: json['client_package_id']?.toString(),
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'UPI',
      transactionRef: json['transaction_ref']?.toString() ?? '',
      status: pStatus,
      receiptUrl: json['receipt_url']?.toString(),
      notes: json['notes']?.toString(),
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'].toString()).toLocal() : null,
      verifiedBy: json['verified_by']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'trainer_id': trainerId,
      'package_id': packageId,
      if (clientPackageId != null) 'client_package_id': clientPackageId,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_ref': transactionRef,
      'status': status == PaymentStatus.paid ? 'VERIFIED' : (status == PaymentStatus.rejected ? 'REJECTED' : 'PENDING_VERIFICATION'),
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (notes != null) 'notes': notes,
      if (verifiedAt != null) 'verified_at': verifiedAt!.toUtc().toIso8601String(),
    };
  }

  PaymentEntity toEntity() {
    return PaymentEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId,
      packageId: packageId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionRef: transactionRef,
      status: status,
      createdAt: createdAt,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      rejectionReason: rejectionReason,
    );
  }
}
