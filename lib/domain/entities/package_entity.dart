enum ValidityMode { sessionsMultipliedBy4, custom }

class PackageEntity {
  final String id;
  final String trainerId;
  final String name;
  final String description;
  final int sessions;
  final double price;
  final int validityDays;
  final ValidityMode validityMode;
  final int sessionDurationMinutes;
  final String status;

  const PackageEntity({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.description,
    required this.sessions,
    required this.price,
    required this.validityDays,
    this.validityMode = ValidityMode.sessionsMultipliedBy4,
    this.sessionDurationMinutes = 60,
    this.status = 'ACTIVE',
  });
}
