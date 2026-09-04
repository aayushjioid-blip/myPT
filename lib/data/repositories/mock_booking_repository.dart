import '../../domain/entities/session_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_booking_repository.dart';
import '../mock/mock_data_store.dart';

class MockBookingRepository implements IBookingRepository {
  final MockDataStore _dataStore;

  MockBookingRepository(this._dataStore);

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
  Future<List<SessionEntity>> getSessionsForUser(String userId) async {
    final eq = _resolveEquivalentIds(userId);
    return _dataStore.sessions.where((s) => eq.contains(s.clientId)).toList();
  }

  @override
  Future<List<SessionEntity>> getSessionsForTrainer(String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    return _dataStore.sessions.where((s) => eq.contains(s.trainerId)).toList();
  }

  @override
  Future<SessionEntity> requestBooking({
    required String clientId,
    required String trainerId,
    required String clientPackageId,
    required DateTime scheduledStart,
    int recurringWeeks = 1,
  }) async {
    final session = SessionEntity(
      id: 'sess-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      trainerId: trainerId,
      clientPackageId: clientPackageId,
      sessionType: SessionType.personalTraining,
      scheduledStart: scheduledStart,
      status: SessionStatus.requested,
      isRecurring: recurringWeeks > 1,
      creditConsumed: false, // Strict Rule: 0 credits deducted on booking
      createdAt: DateTime.now(),
    );

    _dataStore.sessions.insert(0, session);

    // Notify Trainer
    _dataStore.notifications.insert(0, NotificationEntity(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: trainerId,
      title: 'New Session Booking Request 📅',
      message: 'A client requested a 1-on-1 session for ${scheduledStart.month}/${scheduledStart.day}.',
      type: NotificationType.booking,
      timestamp: DateTime.now(),
    ));

    _dataStore.notifyListeners();
    return session;
  }

  @override
  Future<void> acceptBooking(String sessionId) async {
    final idx = _dataStore.sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final sess = _dataStore.sessions[idx];
      _dataStore.sessions[idx] = sess.copyWith(status: SessionStatus.confirmed);

      // Notify Client
      _dataStore.notifications.insert(0, NotificationEntity(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: sess.clientId,
        title: 'Booking Confirmed ✓',
        message: 'Your 1-on-1 session for ${sess.scheduledStart.month}/${sess.scheduledStart.day} has been confirmed.',
        type: NotificationType.booking,
        timestamp: DateTime.now(),
      ));

      _dataStore.notifyListeners();
    }
  }

  @override
  Future<void> rescheduleBooking(String sessionId, DateTime newStart) async {
    final idx = _dataStore.sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final sess = _dataStore.sessions[idx];
      _dataStore.sessions[idx] = sess.copyWith(scheduledStart: newStart);
      _dataStore.notifyListeners();
    }
  }

  @override
  Future<void> cancelBooking(String sessionId, String cancelledBy, String reason) async {
    final idx = _dataStore.sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final sess = _dataStore.sessions[idx];
      _dataStore.sessions[idx] = sess.copyWith(status: SessionStatus.cancelled);

      // Notify other party
      final notifyTarget = (cancelledBy == sess.clientId ? sess.trainerId : sess.clientId) ?? '';
      _dataStore.notifications.insert(0, NotificationEntity(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: notifyTarget,
        title: 'Session Cancelled ⚠️',
        message: 'A scheduled session was cancelled: $reason',
        type: NotificationType.warning,
        timestamp: DateTime.now(),
      ));

      _dataStore.notifyListeners();
    }
  }

  @override
  Future<void> rejectBooking(String sessionId, String reason) async {
    final idx = _dataStore.sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final sess = _dataStore.sessions[idx];
      _dataStore.sessions[idx] = sess.copyWith(status: SessionStatus.rejected);

      // Notify Client
      _dataStore.notifications.insert(0, NotificationEntity(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: sess.clientId,
        title: 'Booking Declined',
        message: 'Your booking request was declined: $reason',
        type: NotificationType.warning,
        timestamp: DateTime.now(),
      ));

      _dataStore.notifyListeners();
    }
  }
}
