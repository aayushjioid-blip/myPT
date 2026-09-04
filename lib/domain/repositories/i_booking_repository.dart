import '../entities/session_entity.dart';

abstract class IBookingRepository {
  Future<List<SessionEntity>> getSessionsForUser(String userId);
  Future<List<SessionEntity>> getSessionsForTrainer(String trainerId);
  Future<SessionEntity> requestBooking({
    required String clientId,
    required String trainerId,
    required String clientPackageId,
    required DateTime scheduledStart,
    int recurringWeeks = 1,
  });
  Future<void> acceptBooking(String sessionId);
  Future<void> rejectBooking(String sessionId, String reason);
  Future<void> rescheduleBooking(String sessionId, DateTime newStart);
  Future<void> cancelBooking(String sessionId, String cancelledBy, String reason);
}
