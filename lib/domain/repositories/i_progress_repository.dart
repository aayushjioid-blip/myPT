import '../entities/measurement_entity.dart';

abstract class IProgressRepository {
  Future<List<MeasurementEntity>> getMeasurementsByClientId(String clientId);
  Future<void> logMeasurement(MeasurementEntity measurement);
}
