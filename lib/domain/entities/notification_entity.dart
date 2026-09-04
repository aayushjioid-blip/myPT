enum NotificationType { info, booking, payment, workout, review, warning, management, admin }

class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool read;
  final DateTime timestamp;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.read = false,
    required this.timestamp,
  });

  NotificationEntity copyWith({bool? read}) {
    return NotificationEntity(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      read: read ?? this.read,
      timestamp: timestamp,
    );
  }
}
