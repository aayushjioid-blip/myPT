import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/session_entity.dart';
import '../../../domain/repositories/i_booking_repository.dart';
import '../../models/session_model.dart';

class SupabaseBookingRepository implements IBookingRepository {
  final SupabaseClient _client;

  SupabaseBookingRepository(this._client);

  @override
  Future<List<SessionEntity>> getSessionsForUser(String userId) async {
    try {
      final res = await _client
          .from('sessions')
          .select('*')
          .or('client_id.eq.$userId,trainer_id.eq.$userId')
          .order('scheduled_start', ascending: true);

      return (res as List).map((json) => SessionModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SessionEntity>> getSessionsForTrainer(String trainerId) async {
    try {
      final res = await _client
          .from('sessions')
          .select('*')
          .eq('trainer_id', trainerId)
          .order('scheduled_start', ascending: true);

      return (res as List).map((json) => SessionModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<SessionEntity> requestBooking({
    required String clientId,
    required String trainerId,
    required String clientPackageId,
    required DateTime scheduledStart,
    int recurringWeeks = 1,
  }) async {
    final scheduledEnd = scheduledStart.add(const Duration(hours: 1));

    try {
      final res = await _client.from('sessions').insert({
        'client_id': clientId,
        'trainer_id': trainerId,
        'client_package_id': clientPackageId,
        'session_type': 'PERSONAL_TRAINING',
        'status': 'REQUESTED',
        'scheduled_start': scheduledStart.toUtc().toIso8601String(),
        'scheduled_end': scheduledEnd.toUtc().toIso8601String(),
        'credit_consumed': false, // 0 CREDITS ON BOOKING REQUEST
        'is_recurring': recurringWeeks > 1,
      }).select().single();

      return SessionModel.fromJson(res).toEntity();
    } catch (_) {
      return SessionEntity(
        id: 'sess-${DateTime.now().millisecondsSinceEpoch}',
        clientId: clientId,
        trainerId: trainerId,
        clientPackageId: clientPackageId,
        scheduledStart: scheduledStart,
        status: SessionStatus.requested,
        creditConsumed: false,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> acceptBooking(String sessionId) async {
    try {
      await _client.from('sessions').update({
        'status': 'CONFIRMED',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (_) {}
  }

  @override
  Future<void> rejectBooking(String sessionId, String reason) async {
    try {
      await _client.from('sessions').update({
        'status': 'DECLINED',
        'cancellation_reason': reason,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (_) {}
  }

  @override
  Future<void> cancelBooking(String sessionId, String cancelledBy, String reason) async {
    try {
      await _client.rpc('apply_cancellation_policy', params: {
        'p_session_id': sessionId,
        'p_cancelled_by': cancelledBy,
        'p_reason': reason,
      });
    } catch (_) {}
  }

  @override
  Future<void> rescheduleBooking(String sessionId, DateTime newStart) async {
    try {
      final newEnd = newStart.add(const Duration(hours: 1));
      await _client.from('sessions').update({
        'status': 'RESCHEDULED',
        'scheduled_start': newStart.toUtc().toIso8601String(),
        'scheduled_end': newEnd.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (_) {}
  }
}
