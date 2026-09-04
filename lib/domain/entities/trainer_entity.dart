import 'cancellation_policy_entity.dart';

enum VerificationStatus { verified, unverified }

class WorkingShift {
  final String start;
  final String end;
  final bool active;
  final int slotCapacity;

  const WorkingShift({
    required this.start,
    required this.end,
    this.active = true,
    this.slotCapacity = 2,
  });
}

class TrainerEntity {
  final String id;
  final String userId;
  final String name;
  final VerificationStatus verificationStatus;
  final String bio;
  final int experienceYears;
  final List<String> certifications;
  final List<String> specializations;
  final List<String> skills;
  final List<String> services;
  final List<String> languages;
  final String location;
  final String trainerCode;
  final String upiId;
  final String mobilePaymentNumber;
  final CancellationPolicyEntity cancellationPolicy;
  final double rating;
  final int reviewCount;
  final int trialDaysRemaining;
  final Map<String, WorkingShift> workingHours;

  const TrainerEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.verificationStatus = VerificationStatus.verified,
    required this.bio,
    this.experienceYears = 5,
    this.certifications = const [],
    this.specializations = const [],
    this.skills = const [],
    this.services = const [],
    this.languages = const ['English'],
    required this.location,
    required this.trainerCode,
    required this.upiId,
    required this.mobilePaymentNumber,
    this.cancellationPolicy = const CancellationPolicyEntity(),
    this.rating = 5.0,
    this.reviewCount = 0,
    this.trialDaysRemaining = 365,
    this.workingHours = const {},
  });

  TrainerEntity copyWith({
    VerificationStatus? verificationStatus,
    CancellationPolicyEntity? cancellationPolicy,
    double? rating,
    int? reviewCount,
    Map<String, WorkingShift>? workingHours,
  }) {
    return TrainerEntity(
      id: id,
      userId: userId,
      name: name,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      bio: bio,
      experienceYears: experienceYears,
      certifications: certifications,
      specializations: specializations,
      skills: skills,
      services: services,
      languages: languages,
      location: location,
      trainerCode: trainerCode,
      upiId: upiId,
      mobilePaymentNumber: mobilePaymentNumber,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      trialDaysRemaining: trialDaysRemaining,
      workingHours: workingHours ?? this.workingHours,
    );
  }
}
