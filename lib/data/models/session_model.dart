import '../../domain/entities/session_entity.dart';

class SessionModel {
  final String id;
  final String clientId;
  final String? trainerId;
  final String? clientPackageId;
  final SessionType sessionType;
  final SessionStatus status;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final bool creditConsumed;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? notes;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.clientId,
    this.trainerId,
    this.clientPackageId,
    this.sessionType = SessionType.personalTraining,
    this.status = SessionStatus.requested,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.creditConsumed = false,
    this.isRecurring = false,
    this.recurrenceRule,
    this.notes,
    this.cancellationReason,
    this.rejectionReason,
    this.cancelledBy,
    this.cancelledAt,
    required this.createdAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    SessionType sType;
    switch (json['session_type']?.toString().toUpperCase()) {
      case 'OWN_WORKOUT':
        sType = SessionType.ownWorkout;
        break;
      case 'PERSONAL_TRAINING':
      default:
        sType = SessionType.personalTraining;
    }

    SessionStatus sStatus;
    switch (json['status']?.toString().toUpperCase()) {
      case 'CONFIRMED':
        sStatus = SessionStatus.confirmed;
        break;
      case 'IN_PROGRESS':
        sStatus = SessionStatus.inProgress;
        break;
      case 'COMPLETED':
        sStatus = SessionStatus.completed;
        break;
      case 'CANCELLED':
        sStatus = SessionStatus.cancelled;
        break;
      case 'DECLINED':
      case 'REJECTED':
        sStatus = SessionStatus.rejected;
        break;
      case 'REQUESTED':
      default:
        sStatus = SessionStatus.requested;
    }

    final start = json['scheduled_start'] != null
        ? DateTime.parse(json['scheduled_start'].toString()).toLocal()
        : DateTime.now();
    final end = json['scheduled_end'] != null
        ? DateTime.parse(json['scheduled_end'].toString()).toLocal()
        : start.add(const Duration(hours: 1));

    return SessionModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString(),
      clientPackageId: json['client_package_id']?.toString(),
      sessionType: sType,
      status: sStatus,
      scheduledStart: start,
      scheduledEnd: end,
      actualStart: json['actual_start'] != null ? DateTime.parse(json['actual_start'].toString()).toLocal() : null,
      actualEnd: json['actual_end'] != null ? DateTime.parse(json['actual_end'].toString()).toLocal() : null,
      creditConsumed: json['credit_consumed'] ?? false,
      isRecurring: json['is_recurring'] ?? false,
      recurrenceRule: json['recurrence_rule']?.toString(),
      notes: json['notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      cancelledBy: json['cancelled_by']?.toString(),
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'].toString()).toLocal() : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  SessionEntity toEntity() {
    return SessionEntity(
      id: id,
      clientId: clientId,
      trainerId: trainerId,
      clientPackageId: clientPackageId,
      sessionType: sessionType,
      scheduledStart: scheduledStart,
      status: status,
      isRecurring: isRecurring,
      creditConsumed: creditConsumed,
      createdAt: createdAt,
      completedAt: actualEnd,
      cancelledAt: cancelledAt,
      cancelReason: cancellationReason,
      rejectionReason: rejectionReason,
      notes: notes,
    );
  }
}
