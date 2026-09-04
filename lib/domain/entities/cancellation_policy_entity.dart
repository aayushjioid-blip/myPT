enum CancellationPolicyType { noPenalty, fourHourPolicy, custom }

class CancellationPolicyEntity {
  final CancellationPolicyType policyType;
  final bool penaltyEnabled;
  final int gracePeriodHours;
  final int creditsDeducted;

  const CancellationPolicyEntity({
    this.policyType = CancellationPolicyType.fourHourPolicy,
    this.penaltyEnabled = true,
    this.gracePeriodHours = 4,
    this.creditsDeducted = 1,
  });

  CancellationPolicyEntity copyWith({
    CancellationPolicyType? policyType,
    bool? penaltyEnabled,
    int? gracePeriodHours,
    int? creditsDeducted,
  }) {
    return CancellationPolicyEntity(
      policyType: policyType ?? this.policyType,
      penaltyEnabled: penaltyEnabled ?? this.penaltyEnabled,
      gracePeriodHours: gracePeriodHours ?? this.gracePeriodHours,
      creditsDeducted: creditsDeducted ?? this.creditsDeducted,
    );
  }
}
