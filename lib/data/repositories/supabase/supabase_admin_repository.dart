import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/repositories/i_admin_repository.dart';

class SupabaseAdminRepository implements IAdminRepository {
  final SupabaseClient _client;

  SupabaseAdminRepository(this._client);

  @override
  Future<Map<String, bool>> getFeatureFlags() async {
    try {
      final res = await _client.from('feature_flags').select('key, is_enabled');
      final Map<String, bool> flags = {};
      for (final item in (res as List)) {
        flags[item['key'].toString()] = item['is_enabled'] ?? false;
      }
      return flags;
    } catch (_) {
      return {
        'advanced_trainer_search': false,
        'client_personal_information': true,
        'online_payments': false,
        'trainer_reviews': true,
        'client_upcoming_workout_visibility': true,
      };
    }
  }

  @override
  Future<void> setFeatureFlag(String key, bool value) async {
    try {
      await _client
          .from('feature_flags')
          .upsert({'key': key, 'is_enabled': value, 'updated_at': DateTime.now().toUtc().toIso8601String()});
    } catch (_) {}
  }

  @override
  Future<void> setTrainerVerification(String trainerId, bool isVerified) async {
    try {
      await _client.from('trainer_profiles').update({
        'verification_status': isVerified ? 'VERIFIED' : 'UNVERIFIED',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).or('id.eq.$trainerId,user_id.eq.$trainerId');
    } catch (_) {}
  }

  @override
  Future<void> setUserStatus(String userId, String status) async {
    try {
      await _client.from('users').update({
        'is_active': status == 'ACTIVE',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (_) {}
  }
}
