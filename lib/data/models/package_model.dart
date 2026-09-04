import '../../domain/entities/package_entity.dart';

class PackageModel {
  final String id;
  final String trainerId;
  final String? gymId;
  final String name;
  final String description;
  final int sessions;
  final double price;
  final String currency;
  final int validityDays;
  final ValidityMode validityMode;
  final bool isActive;

  PackageModel({
    required this.id,
    required this.trainerId,
    this.gymId,
    required this.name,
    required this.description,
    required this.sessions,
    required this.price,
    this.currency = 'USD',
    required this.validityDays,
    this.validityMode = ValidityMode.custom,
    this.isActive = true,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString() ?? '',
      gymId: json['gym_id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sessions: json['sessions'] != null ? int.tryParse(json['sessions'].toString()) ?? 10 : 10,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      validityDays: json['validity_days'] != null ? int.tryParse(json['validity_days'].toString()) ?? 45 : 45,
      validityMode: ValidityMode.custom,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      if (gymId != null) 'gym_id': gymId,
      'name': name,
      'description': description,
      'sessions': sessions,
      'price': price,
      'currency': currency,
      'validity_days': validityDays,
      'is_active': isActive,
    };
  }

  PackageEntity toEntity() {
    return PackageEntity(
      id: id,
      trainerId: trainerId,
      name: name,
      description: description,
      sessions: sessions,
      price: price,
      validityDays: validityDays,
      validityMode: validityMode,
    );
  }
}
