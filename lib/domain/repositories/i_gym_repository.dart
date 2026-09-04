import '../entities/gym_entity.dart';
import '../entities/trainer_entity.dart';

abstract class IGymRepository {
  Future<GymEntity?> getGymById(String gymId);
  Future<List<TrainerEntity>> getStaffTrainersForGym(String gymId);
  Future<void> reassignClient({
    required String relationshipId,
    required String fromTrainerId,
    required String toTrainerId,
    required String reason,
  });
}
