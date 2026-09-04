import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/measurement_entity.dart';
import '../../../domain/repositories/i_progress_repository.dart';
import '../../models/measurement_model.dart';

class SupabaseProgressRepository implements IProgressRepository {
  final SupabaseClient _client;

  SupabaseProgressRepository(this._client);

  @override
  Future<List<MeasurementEntity>> getMeasurementsByClientId(String clientId) async {
    try {
      final res = await _client
          .from('progress_measurements')
          .select('*, progress_photos(*)')
          .eq('client_id', clientId)
          .order('date', ascending: false);

      return (res as List).map((json) => MeasurementModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> logMeasurement(MeasurementEntity measurement) async {
    try {
      final mRes = await _client.from('progress_measurements').insert({
        'client_id': measurement.clientId,
        'logged_by': _client.auth.currentUser?.id ?? measurement.clientId,
        'date': '${measurement.date.year}-${measurement.date.month.toString().padLeft(2, '0')}-${measurement.date.day.toString().padLeft(2, '0')}',
        'weight_kg': measurement.weightKg,
        'height_cm': measurement.heightCm,
        'body_fat_percentage': measurement.bodyFatPercentage,
        'chest_cm': measurement.chestCm,
        'waist_cm': measurement.waistCm,
        'hips_cm': measurement.hipsCm,
        'biceps_cm': measurement.bicepsCm,
        'thighs_cm': measurement.thighsCm,
        'calves_cm': measurement.calvesCm,
        'notes': measurement.notes,
        'source': measurement.source,
      }).select().single();

      if (measurement.photos != null) {
        final photos = measurement.photos!;
        if (photos.frontUrl != null) {
          await _client.from('progress_photos').insert({
            'measurement_id': mRes['id'],
            'client_id': measurement.clientId,
            'pose_type': 'FRONT',
            'storage_path': photos.frontUrl,
          });
        }
        if (photos.sideUrl != null) {
          await _client.from('progress_photos').insert({
            'measurement_id': mRes['id'],
            'client_id': measurement.clientId,
            'pose_type': 'SIDE',
            'storage_path': photos.sideUrl,
          });
        }
        if (photos.backUrl != null) {
          await _client.from('progress_photos').insert({
            'measurement_id': mRes['id'],
            'client_id': measurement.clientId,
            'pose_type': 'BACK',
            'storage_path': photos.backUrl,
          });
        }
      }
    } catch (_) {}
  }
}
