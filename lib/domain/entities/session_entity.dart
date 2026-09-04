enum SessionType { personalTraining, ownWorkout }
enum SessionStatus { requested, confirmed, inProgress, completed, cancelled, rejected }

class SessionEntity {
  final String id;
  final String clientId;
  final String? trainerId;
  final String? clientPackageId;
  final SessionType sessionType;
  final DateTime scheduledStart;
  final SessionStatus status;
  final bool isRecurring;
  final bool creditConsumed;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String? rejectionReason;
  final String? notes;

  const SessionEntity({
    required this.id,
    required this.clientId,
    this.trainerId,
    this.clientPackageId,
    this.sessionType = SessionType.personalTraining,
    required this.scheduledStart,
    this.status = SessionStatus.requested,
    this.isRecurring = false,
    this.creditConsumed = false,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.rejectionReason,
    this.notes,
  });

  SessionEntity copyWith({
    SessionStatus? status,
    bool? creditConsumed,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelReason,
    String? rejectionReason,
    DateTime? scheduledStart,
  }) {
    return SessionEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId,
      clientPackageId: clientPackageId,
      sessionType: sessionType,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      status: status ?? this.status,
      isRecurring: isRecurring,
      creditConsumed: creditConsumed ?? this.creditConsumed,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes,
    );
  }
}
