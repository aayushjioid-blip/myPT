import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/entities/cancellation_policy_entity.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/repositories/i_trainer_repository.dart';
import '../../models/trainer_model.dart';
import '../../models/review_model.dart';

class SupabaseTrainerRepository implements ITrainerRepository {
  final SupabaseClient _client;

  SupabaseTrainerRepository(this._client);

  @override
  Future<List<TrainerEntity>> getVerifiedTrainers() async {
    try {
      final res = await _client
          .from('trainer_profiles')
          .select('*, users(*), trainer_specializations(*), trainer_certifications(*), trainer_services(*)')
          .eq('verification_status', 'VERIFIED');

      return (res as List).map((json) => TrainerModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [
        const TrainerEntity(
          id: '00000000-0000-0000-0000-000000000002',
          userId: '00000000-0000-0000-0000-000000000002',
          name: 'Alex Rivera',
          trainerCode: 'TRN001',
          bio: 'NASM Certified Master Trainer specializing in biomechanics, hypertrophy, and sustainable body recomposition.',
          experienceYears: 8,
          rating: 4.90,
          reviewCount: 24,
          verificationStatus: VerificationStatus.verified,
          location: 'IronCore Fitness Metro',
          upiId: 'alex.rivera@upi',
          mobilePaymentNumber: '+1 555 234 5678',
        ),
        const TrainerEntity(
          id: '00000000-0000-0000-0000-000000000003',
          userId: '00000000-0000-0000-0000-000000000003',
          name: 'Maya Lin',
          trainerCode: 'MAYA02',
          bio: 'ACE Certified & Yoga Alliance RYT-500. Functional movement patterns, calisthenics, and core stabilization.',
          experienceYears: 6,
          rating: 4.95,
          reviewCount: 19,
          verificationStatus: VerificationStatus.verified,
          location: 'IronCore Fitness Metro',
          upiId: 'maya.lin@upi',
          mobilePaymentNumber: '+1 555 345 6789',
        ),
      ];
    }
  }

  @override
  Future<List<TrainerEntity>> getAllTrainers() async {
    try {
      final res = await _client
          .from('trainer_profiles')
          .select('*, users(*), trainer_specializations(*), trainer_certifications(*), trainer_services(*)');

      return (res as List).map((json) => TrainerModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      final verified = await getVerifiedTrainers();
      return [
        ...verified,
        const TrainerEntity(
          id: '00000000-0000-0000-0000-000000000004',
          userId: '00000000-0000-0000-0000-000000000004',
          name: 'Leo Novak',
          trainerCode: 'LEO007',
          bio: 'Boxing coach and high-intensity interval conditioning specialist.',
          experienceYears: 3,
          rating: 4.70,
          reviewCount: 5,
          verificationStatus: VerificationStatus.unverified,
          location: 'Independent',
          upiId: 'leo.novak@upi',
          mobilePaymentNumber: '+1 555 456 7890',
        ),
      ];
    }
  }

  @override
  Future<TrainerEntity?> getTrainerById(String id) async {
    try {
      final res = await _client
          .from('trainer_profiles')
          .select('*, users(*), trainer_specializations(*), trainer_certifications(*), trainer_services(*)')
          .or('id.eq.$id,user_id.eq.$id')
          .maybeSingle();

      if (res != null) {
        return TrainerModel.fromJson(res).toEntity();
      }
    } catch (_) {}

    final all = await getAllTrainers();
    return all.firstWhere((t) => t.id == id || t.trainerCode == id, orElse: () => all.first);
  }

  @override
  Future<TrainerEntity?> getTrainerByCode(String code) async {
    try {
      final res = await _client
          .from('trainer_profiles')
          .select('*, users(*), trainer_specializations(*), trainer_certifications(*), trainer_services(*)')
          .ilike('trainer_code', code.trim())
          .maybeSingle();

      if (res != null) {
        return TrainerModel.fromJson(res).toEntity();
      }
    } catch (_) {}

    final all = await getAllTrainers();
    try {
      return all.firstWhere((t) => t.trainerCode.toLowerCase() == code.trim().toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateCancellationPolicy(String trainerId, CancellationPolicyEntity policy) async {
    try {
      await _client.from('trainer_profiles').update({
        'cancellation_grace_hours': policy.gracePeriodHours,
        'late_cancellation_penalty_enabled': policy.penaltyEnabled,
        'late_cancellation_penalty_credits': policy.creditsDeducted,
      }).or('id.eq.$trainerId,user_id.eq.$trainerId');
    } catch (_) {}
  }

  @override
  Future<void> updateWorkingHours(String trainerId, Map<String, WorkingShift> hours) async {
    try {
      for (final entry in hours.entries) {
        final shift = entry.value;
        await _client.from('trainer_working_hours').upsert({
          'trainer_id': trainerId,
          'day_of_week': int.tryParse(entry.key) ?? 1,
          'start_time': shift.start,
          'end_time': shift.end,
          'slot_capacity': shift.slotCapacity,
          'is_active': shift.active,
        });
      }
    } catch (_) {}
  }

  @override
  Future<List<ReviewEntity>> getReviewsForTrainer(String trainerId) async {
    try {
      final res = await _client
          .from('reviews')
          .select('*, users(*)')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => ReviewModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [
        ReviewEntity(
          id: 'rev-1',
          trainerId: trainerId,
          clientId: '00000000-0000-0000-0000-000000000001',
          clientName: 'Sarah Jenkins',
          rating: 5,
          comment: 'Incredible coach! Very knowledgeable about hypertrophy and form correction.',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];
    }
  }

  @override
  Future<void> addReview(ReviewEntity review) async {
    try {
      await _client.from('reviews').insert({
        'trainer_id': review.trainerId,
        'client_id': review.clientId,
        'rating': review.rating,
        'comment': review.comment,
      });
    } catch (_) {}
  }
}
