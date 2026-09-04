import '../../domain/entities/trainer_entity.dart';
import '../../domain/entities/cancellation_policy_entity.dart';

class TrainerModel {
  final String id;
  final String userId;
  final String name;
  final String trainerCode;
  final String bio;
  final int yearsExperience;
  final double rating;
  final int reviewCount;
  final VerificationStatus verificationStatus;
  final double hourlyRate;
  final int trialDaysRemaining;
  final List<String> specializations;
  final List<String> certifications;
  final List<String> services;
  final CancellationPolicyEntity cancellationPolicy;

  TrainerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.trainerCode,
    required this.bio,
    required this.yearsExperience,
    required this.rating,
    required this.reviewCount,
    required this.verificationStatus,
    this.hourlyRate = 60.0,
    this.trialDaysRemaining = 14,
    this.specializations = const [],
    this.certifications = const [],
    this.services = const [],
    required this.cancellationPolicy,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] is Map<String, dynamic> ? json['users'] as Map<String, dynamic> : <String, dynamic>{};

    VerificationStatus vStatus;
    switch (json['verification_status']?.toString().toUpperCase()) {
      case 'VERIFIED':
        vStatus = VerificationStatus.verified;
        break;
      case 'UNVERIFIED':
      default:
        vStatus = VerificationStatus.unverified;
    }

    final specs = (json['trainer_specializations'] as List?)
            ?.map((s) => s['specialization']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final certs = (json['trainer_certifications'] as List?)
            ?.map((c) => c['title']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toList() ??
        [];

    final servs = (json['trainer_services'] as List?)
            ?.map((s) => s['service_name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final graceHours = json['cancellation_grace_hours'] != null
        ? int.tryParse(json['cancellation_grace_hours'].toString()) ?? 4
        : 4;
    final penaltyEnabled = json['late_cancellation_penalty_enabled'] ?? true;
    final penaltyCredits = json['late_cancellation_penalty_credits'] != null
        ? int.tryParse(json['late_cancellation_penalty_credits'].toString()) ?? 1
        : 1;

    return TrainerModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? json['name']?.toString() ?? 'Coach',
      trainerCode: json['trainer_code']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      yearsExperience: json['years_experience'] != null ? int.tryParse(json['years_experience'].toString()) ?? 1 : 1,
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 5.0 : 5.0,
      reviewCount: json['review_count'] != null ? int.tryParse(json['review_count'].toString()) ?? 0 : 0,
      verificationStatus: vStatus,
      hourlyRate: json['hourly_rate'] != null ? double.tryParse(json['hourly_rate'].toString()) ?? 60.0 : 60.0,
      trialDaysRemaining: json['trial_days_remaining'] != null ? int.tryParse(json['trial_days_remaining'].toString()) ?? 14 : 14,
      specializations: specs,
      certifications: certs,
      services: servs,
      cancellationPolicy: CancellationPolicyEntity(
        policyType: CancellationPolicyType.fourHourPolicy,
        penaltyEnabled: penaltyEnabled,
        gracePeriodHours: graceHours,
        creditsDeducted: penaltyCredits,
      ),
    );
  }

  TrainerEntity toEntity() {
    return TrainerEntity(
      id: userId.isNotEmpty ? userId : id,
      userId: userId.isNotEmpty ? userId : id,
      name: name,
      trainerCode: trainerCode,
      bio: bio,
      experienceYears: yearsExperience,
      rating: rating,
      reviewCount: reviewCount,
      verificationStatus: verificationStatus,
      trialDaysRemaining: trialDaysRemaining,
      specializations: specializations.isNotEmpty ? specializations : ['Biomechanics', 'Hypertrophy'],
      certifications: certifications.isNotEmpty ? certifications : ['Certified Personal Trainer'],
      services: services.isNotEmpty ? services : ['1-on-1 Personal Training', 'Nutrition Coaching'],
      location: 'IronCore Fitness Metro',
      upiId: 'alex.rivera@upi',
      mobilePaymentNumber: '+1 555 234 5678',
      cancellationPolicy: cancellationPolicy,
    );
  }
}
