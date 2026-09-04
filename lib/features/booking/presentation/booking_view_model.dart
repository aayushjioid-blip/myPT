import 'package:flutter/foundation.dart';
import '../../../domain/entities/session_entity.dart';
import '../../../domain/repositories/i_booking_repository.dart';
import '../../../data/mock/mock_data_store.dart';

class BookingViewModel extends ChangeNotifier {
  final IBookingRepository _bookingRepository;
  final MockDataStore _dataStore;

  List<SessionEntity> _clientSessions = [];
  List<SessionEntity> _trainerSessions = [];
  bool _isLoading = false;

  BookingViewModel(this._bookingRepository, this._dataStore) {
    _dataStore.stateChanges.listen((_) => refresh());
  }

  List<SessionEntity> get clientSessions => _clientSessions;
  List<SessionEntity> get trainerSessions => _trainerSessions;
  bool get isLoading => _isLoading;

  Future<void> loadClientSessions(String clientId) async {
    _isLoading = true;
    notifyListeners();

    _clientSessions = await _bookingRepository.getSessionsForUser(clientId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTrainerSessions(String trainerId) async {
    _isLoading = true;
    notifyListeners();

    _trainerSessions = await _bookingRepository.getSessionsForTrainer(trainerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final user = _dataStore.currentUser;
    if (user.id.isNotEmpty) {
      await loadClientSessions(user.id);
      await loadTrainerSessions(user.id);
    }
  }

  Future<SessionEntity> requestBooking({
    required String clientId,
    required String trainerId,
    required String clientPackageId,
    required DateTime scheduledStart,
    int recurringWeeks = 1,
  }) async {
    final session = await _bookingRepository.requestBooking(
      clientId: clientId,
      trainerId: trainerId,
      clientPackageId: clientPackageId,
      scheduledStart: scheduledStart,
      recurringWeeks: recurringWeeks,
    );
    await refresh();
    return session;
  }

  Future<void> acceptBooking(String sessionId) async {
    await _bookingRepository.acceptBooking(sessionId);
    await refresh();
  }

  Future<void> rejectBooking(String sessionId, String reason) async {
    await _bookingRepository.rejectBooking(sessionId, reason);
    await refresh();
  }
}
