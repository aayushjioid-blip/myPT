import '../../domain/entities/gym_entity.dart';

class GymModel {
  final String id;
  final String name;
  final String ownerId;
  final String headTrainerId;
  final String address;
  final String phone;
  final String operatingHours;
  final int maxFloorCapacity;
  final String status;
  final List<String> amenities;

  GymModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.headTrainerId,
    required this.address,
    required this.phone,
    this.operatingHours = '06:00 - 22:00 Daily',
    this.maxFloorCapacity = 40,
    this.status = 'ACTIVE',
    this.amenities = const [],
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    final amList = (json['amenities'] as List?)?.map((a) => a.toString()).toList() ?? [];

    return GymModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '00000000-0000-0000-0000-000000000006',
      headTrainerId: json['head_trainer_id']?.toString() ?? '00000000-0000-0000-0000-000000000005',
      address: json['location_address']?.toString() ?? json['address']?.toString() ?? '',
      phone: json['contact_phone']?.toString() ?? json['phone']?.toString() ?? '',
      operatingHours: json['operating_hours']?.toString() ?? '06:00 - 22:00 Daily',
      maxFloorCapacity: json['floor_capacity'] != null ? int.tryParse(json['floor_capacity'].toString()) ?? 40 : 40,
      status: (json['is_active'] ?? true) ? 'ACTIVE' : 'INACTIVE',
      amenities: amList,
    );
  }

  GymEntity toEntity() {
    return GymEntity(
      id: id,
      name: name,
      ownerId: ownerId,
      headTrainerId: headTrainerId,
      address: address,
      phone: phone,
      operatingHours: operatingHours,
      maxFloorCapacity: maxFloorCapacity,
      status: status,
      amenities: amenities.isNotEmpty ? amenities : ['Olympic Platforms', 'Sauna & Ice Bath', 'Turf Sprint Track'],
    );
  }
}
