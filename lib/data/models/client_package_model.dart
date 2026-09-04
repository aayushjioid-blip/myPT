import '../../domain/entities/credit_transaction_entity.dart';

class ClientPackageModel {
  final String id;
  final String clientId;
  final String trainerId;
  final String packageId;
  final int totalSessions;
  final int completedSessions;
  final int remainingSessions;
  final int validityDays;
  final double pricePaid;
  final String status;
  final DateTime purchaseDate;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final String? paymentId;

  ClientPackageModel({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.packageId,
    required this.totalSessions,
    this.completedSessions = 0,
    required this.remainingSessions,
    this.validityDays = 45,
    required this.pricePaid,
    required this.status,
    required this.purchaseDate,
    this.activatedAt,
    this.expiresAt,
    this.paymentId,
  });

  factory ClientPackageModel.fromJson(Map<String, dynamic> json) {
    final total = json['total_sessions'] != null ? int.tryParse(json['total_sessions'].toString()) ?? 10 : 10;
    final remaining = json['remaining_sessions'] != null ? int.tryParse(json['remaining_sessions'].toString()) ?? 0 : 0;

    return ClientPackageModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString() ?? '',
      packageId: json['package_id']?.toString() ?? '',
      totalSessions: total,
      completedSessions: total - remaining > 0 ? total - remaining : 0,
      remainingSessions: remaining,
      validityDays: json['validity_days'] != null ? int.tryParse(json['validity_days'].toString()) ?? 45 : 45,
      pricePaid: json['price_paid'] != null ? double.tryParse(json['price_paid'].toString()) ?? 0.0 : 0.0,
      status: json['status']?.toString() ?? 'PENDING_PAYMENT',
      purchaseDate: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
      activatedAt: json['activated_at'] != null ? DateTime.parse(json['activated_at'].toString()).toLocal() : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'].toString()).toLocal() : null,
      paymentId: json['payment_id']?.toString(),
    );
  }

  ClientPackageEntity toEntity() {
    return ClientPackageEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId,
      packageId: packageId,
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      remainingSessions: remainingSessions,
      validityDays: validityDays,
      purchaseDate: purchaseDate,
      activationDate: activatedAt,
      expiryDate: expiresAt,
      status: status,
      paymentId: paymentId,
    );
  }
}
