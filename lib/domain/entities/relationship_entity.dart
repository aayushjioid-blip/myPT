enum RelationshipStatus { requested, accepted, rejected, inactive, terminated }

class RelationshipEntity {
  final String id;
  final String clientId;
  final String trainerId;
  final RelationshipStatus status;
  final String goals;
  final String notes;
  final bool approvedForPackages;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? reassignedAt;
  final String? reassignmentReason;

  const RelationshipEntity({
    required this.id,
    required this.clientId,
    required this.trainerId,
    this.status = RelationshipStatus.requested,
    this.goals = '',
    this.notes = '',
    this.approvedForPackages = false,
    required this.createdAt,
    this.acceptedAt,
    this.reassignedAt,
    this.reassignmentReason,
  });

  RelationshipEntity copyWith({
    RelationshipStatus? status,
    bool? approvedForPackages,
    DateTime? acceptedAt,
    String? trainerId,
    DateTime? reassignedAt,
    String? reassignmentReason,
  }) {
    return RelationshipEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId ?? this.trainerId,
      status: status ?? this.status,
      goals: goals,
      notes: notes,
      approvedForPackages: approvedForPackages ?? this.approvedForPackages,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      reassignedAt: reassignedAt ?? this.reassignedAt,
      reassignmentReason: reassignmentReason ?? this.reassignmentReason,
    );
  }
}
