import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.isRead = false,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType nType;
    switch (json['type']?.toString().toUpperCase()) {
      case 'BOOKING':
        nType = NotificationType.booking;
        break;
      case 'PAYMENT':
        nType = NotificationType.payment;
        break;
      case 'WORKOUT':
        nType = NotificationType.workout;
        break;
      case 'REVIEW':
        nType = NotificationType.review;
        break;
      case 'WARNING':
      case 'LOW_CREDIT':
        nType = NotificationType.warning;
        break;
      case 'MANAGEMENT':
      case 'REASSIGNMENT':
        nType = NotificationType.management;
        break;
      case 'ADMIN':
        nType = NotificationType.admin;
        break;
      case 'INFO':
      default:
        nType = NotificationType.info;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: nType,
      isRead: json['is_read'] ?? false,
      referenceId: json['reference_id']?.toString(),
      referenceType: json['reference_type']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      read: isRead,
      timestamp: createdAt,
    );
  }
}
