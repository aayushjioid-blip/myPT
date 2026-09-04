import '../entities/fitness_chart_entity.dart';

abstract class IFitnessChartRepository {
  Future<List<FitnessChartEntity>> getChartsForClient(String clientId);
  Future<List<FitnessChartEntity>> getChartsForTrainer(String trainerId);
  Future<List<FitnessChartEntity>> getAllCharts();
  Future<void> dispatchChart(FitnessChartEntity chart);
  Future<void> deleteChart(String chartId);
}
