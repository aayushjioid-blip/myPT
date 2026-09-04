import '../entities/notification_entity.dart';

abstract class INotificationRepository {
  Stream<List<NotificationEntity>> getNotificationStream(String userId);
  Future<List<NotificationEntity>> getNotificationsForUser(String userId);
  Future<void> triggerNotification(NotificationEntity notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
