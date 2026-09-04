import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/gym_entity.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/repositories/i_gym_repository.dart';
import '../../models/gym_model.dart';
import '../../models/trainer_model.dart';

class SupabaseGymRepository implements IGymRepository {
  final SupabaseClient _client;

  SupabaseGymRepository(this._client);

  @override
  Future<GymEntity?> getGymById(String gymId) async {
    try {
      final res = await _client.from('gyms').select('*').eq('id', gymId).maybeSingle();
      if (res != null) {
        return GymModel.fromJson(res).toEntity();
      }
    } catch (_) {}

    return const GymEntity(
      id: '10000000-0000-0000-0000-000000000001',
      name: 'IronCore Fitness Center',
      ownerId: '00000000-0000-0000-0000-000000000006',
      headTrainerId: '00000000-0000-0000-0000-000000000005',
      address: '742 Evergreen Blvd, Metro City',
      phone: '+1-555-IRON-CORE',
      operatingHours: '06:00 - 22:00 Daily',
      maxFloorCapacity: 40,
      status: 'ACTIVE',
      amenities: ['Olympic Platforms', 'Sauna & Ice Bath', 'Turf Sprint Track'],
    );
  }

  @override
  Future<List<TrainerEntity>> getStaffTrainersForGym(String gymId) async {
    try {
      final res = await _client
          .from('gym_memberships')
          .select('*, users(*, trainer_profiles(*, trainer_specializations(*), trainer_certifications(*), trainer_services(*)))')
          .eq('gym_id', gymId)
          .eq('is_active', true);

      final List<TrainerEntity> list = [];
      for (final m in (res as List)) {
        final u = m['users'] as Map<String, dynamic>?;
        final tpList = u?['trainer_profiles'] as List?;
        if (tpList != null && tpList.isNotEmpty) {
          final tp = tpList.first as Map<String, dynamic>;
          tp['users'] = u;
          list.add(TrainerModel.fromJson(tp).toEntity());
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> reassignClient({
    required String relationshipId,
    required String fromTrainerId,
    required String toTrainerId,
    required String reason,
  }) async {
    try {
      await _client.rpc('reassign_client', params: {
        'p_relationship_id': relationshipId,
        'p_from_trainer_id': fromTrainerId,
        'p_to_trainer_id': toTrainerId,
        'p_reason': reason,
        'p_reassigned_by': _client.auth.currentUser?.id,
      });
    } catch (_) {}
  }
}
