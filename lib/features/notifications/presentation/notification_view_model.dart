import 'package:flutter/foundation.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/repositories/i_notification_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class NotificationViewModel extends ChangeNotifier {
  final INotificationRepository _notificationRepository;
  final MockDataStore _dataStore;

  List<NotificationEntity> _notifications = [];
  bool _isLoading = false;

  NotificationViewModel(this._notificationRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
    refresh();
  }

  List<NotificationEntity> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get isLoading => _isLoading;

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    _notifications = await _notificationRepository.getNotificationsForUser(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final user = _dataStore.currentUser;
    if (user.id.isNotEmpty) {
      await loadForUser(user.id);
    }
  }

  Future<void> markAsRead(String id) async {
    await _notificationRepository.markAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    final user = _dataStore.currentUser;
    await _notificationRepository.markAllAsRead(user.id);
    await refresh();
  }
}
