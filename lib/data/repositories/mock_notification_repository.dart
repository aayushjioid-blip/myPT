import 'dart:async';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../mock/mock_data_store.dart';

class MockNotificationRepository implements INotificationRepository {
  final MockDataStore _dataStore;
  final StreamController<List<NotificationEntity>> _streamController = StreamController<List<NotificationEntity>>.broadcast();

  MockNotificationRepository(this._dataStore);

  Set<String> _resolveEquivalentIds(String id) {
    final set = <String>{id};
    for (final t in _dataStore.trainers) {
      if (t.id == id || t.userId == id) {
        set.add(t.id);
        set.add(t.userId);
      }
    }
    for (final u in _dataStore.users) {
      if (u.id == id) {
        set.add(u.id);
      }
    }
    return set;
  }

  @override
  Stream<List<NotificationEntity>> getNotificationStream(String userId) {
    return _streamController.stream;
  }

  @override
  Future<List<NotificationEntity>> getNotificationsForUser(String userId) async {
    final eq = _resolveEquivalentIds(userId);
    return _dataStore.notifications.where((n) => eq.contains(n.userId)).toList();
  }

  @override
  Future<void> triggerNotification(NotificationEntity notification) async {
    _dataStore.notifications.insert(0, notification);
    final eq = _resolveEquivalentIds(notification.userId);
    _streamController.add(_dataStore.notifications.where((n) => eq.contains(n.userId)).toList());
    _dataStore.notifyListeners();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = _dataStore.notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _dataStore.notifications[idx] = _dataStore.notifications[idx].copyWith(read: true);
      _dataStore.notifyListeners();
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final eq = _resolveEquivalentIds(userId);
    for (int i = 0; i < _dataStore.notifications.length; i++) {
      if (eq.contains(_dataStore.notifications[i].userId)) {
        _dataStore.notifications[i] = _dataStore.notifications[i].copyWith(read: true);
      }
    }
    _dataStore.notifyListeners();
  }
}
