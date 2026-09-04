class GymEntity {
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

  const GymEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.headTrainerId,
    required this.address,
    required this.phone,
    required this.operatingHours,
    this.maxFloorCapacity = 40,
    this.status = 'ACTIVE',
    this.amenities = const [],
  });
}
