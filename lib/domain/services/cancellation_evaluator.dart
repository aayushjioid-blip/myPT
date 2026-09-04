import '../entities/cancellation_policy_entity.dart';
import '../entities/session_entity.dart';

class CancellationEvaluationResult {
  final bool isPenaltyApplied;
  final int creditsToDeduct;
  final String reason;

  const CancellationEvaluationResult({
    required this.isPenaltyApplied,
    required this.creditsToDeduct,
    required this.reason,
  });
}

class CancellationEvaluator {
  static CancellationEvaluationResult evaluate({
    required SessionEntity session,
    required CancellationPolicyEntity policy,
    required DateTime cancellationTimestamp,
  }) {
    if (session.sessionType == SessionType.ownWorkout) {
      return const CancellationEvaluationResult(
        isPenaltyApplied: false,
        creditsToDeduct: 0,
        reason: 'Own workouts never incur cancellation penalties.',
      );
    }

    if (!policy.penaltyEnabled) {
      return const CancellationEvaluationResult(
        isPenaltyApplied: false,
        creditsToDeduct: 0,
        reason: 'No-penalty cancellation policy is active.',
      );
    }

    final hoursDifference = session.scheduledStart.difference(cancellationTimestamp).inMinutes / 60.0;

    if (hoursDifference < policy.gracePeriodHours) {
      return CancellationEvaluationResult(
        isPenaltyApplied: true,
        creditsToDeduct: policy.creditsDeducted,
        reason: 'Cancelled with less than ${policy.gracePeriodHours} hours notice (${hoursDifference.toStringAsFixed(1)}h remaining).',
      );
    }

    return CancellationEvaluationResult(
      isPenaltyApplied: false,
      creditsToDeduct: 0,
      reason: 'Cancelled outside penalty grace window (${hoursDifference.toStringAsFixed(1)}h before start).',
    );
  }
}
