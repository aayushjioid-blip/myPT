import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/repositories/i_notification_repository.dart';
import '../../models/notification_model.dart';

class SupabaseNotificationRepository implements INotificationRepository {
  final SupabaseClient _client;
  final Map<String, StreamController<List<NotificationEntity>>> _userStreams = {};

  SupabaseNotificationRepository(this._client);

  @override
  Future<List<NotificationEntity>> getNotificationsForUser(String userId) async {
    try {
      final res = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => NotificationModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> triggerNotification(NotificationEntity notification) async {
    try {
      await _client.from('notifications').insert({
        'user_id': notification.userId,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type.name.toUpperCase(),
        'is_read': notification.read,
      });
    } catch (_) {}
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
    } catch (_) {}
  }

  @override
  Stream<List<NotificationEntity>> getNotificationStream(String userId) {
    if (!_userStreams.containsKey(userId)) {
      final controller = StreamController<List<NotificationEntity>>.broadcast();
      _userStreams[userId] = controller;

      _client
          .channel('public:notifications:user_id=eq.$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) async {
              final notifs = await getNotificationsForUser(userId);
              controller.add(notifs);
            },
          )
          .subscribe();

      getNotificationsForUser(userId).then((notifs) => controller.add(notifs));
    }
    return _userStreams[userId]!.stream;
  }
}
