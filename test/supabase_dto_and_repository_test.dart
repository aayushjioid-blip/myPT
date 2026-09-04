// Supabase DTO Serialization & Repository Contract Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrainer/data/models/user_model.dart';
import 'package:fittrainer/data/models/trainer_model.dart';
import 'package:fittrainer/data/models/session_model.dart';
import 'package:fittrainer/data/models/measurement_model.dart';
import 'package:fittrainer/data/models/credit_transaction_model.dart';
import 'package:fittrainer/domain/entities/user_entity.dart';
import 'package:fittrainer/domain/entities/trainer_entity.dart';
import 'package:fittrainer/domain/entities/session_entity.dart';
import 'package:fittrainer/domain/entities/cancellation_policy_entity.dart';
import 'package:fittrainer/domain/services/cancellation_evaluator.dart';
import 'package:fittrainer/core/utils/formatters.dart';

void main() {
  group('Supabase DTO Models Serialization Tests', () {
    test('UserModel correctly deserializes PostgreSQL snake_case payload', () {
      final json = {
        'id': '00000000-0000-0000-0000-000000000001',
        'auth_id': 'auth-uuid-1234',
        'email': 'sarah.jenkins@fitapp.dev',
        'name': 'Sarah Jenkins',
        'avatar_url': '👩',
        'role': 'CLIENT',
        'is_active': true,
        'created_at': '2026-08-31T08:00:00.000Z',
        'updated_at': '2026-08-31T08:00:00.000Z',
        'client_health_profiles': {
          'age': 28,
          'height_cm': '168.0',
          'weight_kg': '64.5',
          'fitness_goal': 'Fat Loss & Hypertrophy',
          'injuries': 'Mild left shoulder impingement',
          'medical_info': 'Asthma',
          'share_personal_info_with_trainer': false,
        }
      };

      final model = UserModel.fromJson(json);
      expect(model.id, '00000000-0000-0000-0000-000000000001');
      expect(model.role, UserRole.client);
      expect(model.sharePersonalInfoWithTrainer, false);
      expect(model.heightCm, 168.0);
      expect(model.weightKg, 64.5);

      final entity = model.toEntity();
      expect(entity.name, 'Sarah Jenkins');
      expect(entity.sharePersonalInfoWithTrainer, false);
    });

    test('TrainerModel correctly parses verification status and cancellation policy', () {
      final json = {
        'id': '00000000-0000-0000-0000-000000000002',
        'trainer_code': 'TRN001',
        'bio': 'NASM Certified Master Trainer',
        'years_experience': 8,
        'rating': '4.90',
        'review_count': 24,
        'verification_status': 'VERIFIED',
        'hourly_rate': '75.00',
        'cancellation_grace_hours': 4,
        'late_cancellation_penalty_enabled': true,
        'users': {'name': 'Alex Rivera', 'avatar_url': '🏋️'},
        'trainer_specializations': [{'specialization': 'Hypertrophy'}],
      };

      final model = TrainerModel.fromJson(json);
      expect(model.trainerCode, 'TRN001');
      expect(model.verificationStatus, VerificationStatus.verified);
      expect(model.cancellationPolicy.gracePeriodHours, 4);
      expect(model.cancellationPolicy.penaltyEnabled, true);
    });

    test('SessionModel maps PERSONAL_TRAINING and OWN_WORKOUT correctly', () {
      final ptJson = {
        'id': 'sess-1',
        'client_id': 'usr-1',
        'trainer_id': 'trn-1',
        'session_type': 'PERSONAL_TRAINING',
        'status': 'CONFIRMED',
        'scheduled_start': '2026-09-01T10:00:00.000Z',
        'scheduled_end': '2026-09-01T11:00:00.000Z',
        'credit_consumed': false,
      };

      final ptModel = SessionModel.fromJson(ptJson);
      expect(ptModel.sessionType, SessionType.personalTraining);
      expect(ptModel.status, SessionStatus.confirmed);
      expect(ptModel.creditConsumed, false);

      final ownJson = {
        'id': 'sess-2',
        'client_id': 'usr-1',
        'session_type': 'OWN_WORKOUT',
        'status': 'COMPLETED',
        'scheduled_start': '2026-09-01T07:00:00.000Z',
        'scheduled_end': '2026-09-01T07:45:00.000Z',
        'credit_consumed': false,
      };

      final ownModel = SessionModel.fromJson(ownJson);
      expect(ownModel.sessionType, SessionType.ownWorkout);
      expect(ownModel.creditConsumed, false);
    });

    test('MeasurementModel handles generated BMI and optional photo pose URLs', () {
      final json = {
        'id': 'm-1',
        'client_id': 'usr-1',
        'date': '2026-08-31',
        'weight_kg': '64.5',
        'height_cm': '168.0',
        'bmi': '22.9',
        'body_fat_percentage': '21.8',
        'chest_cm': '91.0',
        'waist_cm': '72.0',
        'hips_cm': '96.0',
        'progress_photos': [
          {'pose_type': 'FRONT', 'storage_path': 'photos/usr-1/front.jpg'},
          {'pose_type': 'SIDE', 'storage_path': 'photos/usr-1/side.jpg'},
        ],
      };

      final model = MeasurementModel.fromJson(json);
      expect(model.bmi, 22.9);
      expect(model.photos?.frontUrl, 'photos/usr-1/front.jpg');
      expect(model.photos?.sideUrl, 'photos/usr-1/side.jpg');
      expect(model.photos?.backUrl, null);
    });

    test('CreditTransactionModel maps transaction types correctly', () {
      final json = {
        'id': 'tx-1',
        'client_package_id': 'cp-1',
        'client_id': 'usr-1',
        'trainer_id': 'trn-1',
        'transaction_type': 'PACKAGE_ACTIVATION',
        'delta_credits': 10,
        'balance_after': 10,
        'reason': 'Payment verified',
        'created_at': '2026-08-31T08:00:00.000Z',
      };

      final model = CreditTransactionModel.fromJson(json);
      expect(model.deltaCredits, 10);
      expect(model.balanceAfter, 10);
    });
  });

  group('Domain Services & Business Rules Unit Tests', () {
    test('Auto BMI Formula calculates exact values', () {
      expect(Formatters.calculateBmi(64.5, 168.0), 22.9);
      expect(Formatters.calculateBmi(80.0, 180.0), 24.7);
    });

    test('CancellationEvaluator correctly enforces 4-hour grace window', () {
      const policy = CancellationPolicyEntity(
        policyType: CancellationPolicyType.fourHourPolicy,
        penaltyEnabled: true,
        gracePeriodHours: 4,
        creditsDeducted: 1,
      );

      final now = DateTime.now();

      // Session 6h away -> 0 penalty
      final futureSession = SessionEntity(
        id: 's-fut',
        clientId: 'usr-1',
        trainerId: 'trn-1',
        scheduledStart: now.add(const Duration(hours: 6)),
        createdAt: now,
      );
      final eval6h = CancellationEvaluator.evaluate(
        session: futureSession,
        policy: policy,
        cancellationTimestamp: now,
      );
      expect(eval6h.isPenaltyApplied, false);
      expect(eval6h.creditsToDeduct, 0);

      // Session 2h away -> 1 penalty
      final lateSession = SessionEntity(
        id: 's-late',
        clientId: 'usr-1',
        trainerId: 'trn-1',
        scheduledStart: now.add(const Duration(hours: 2)),
        createdAt: now,
      );
      final eval2h = CancellationEvaluator.evaluate(
        session: lateSession,
        policy: policy,
        cancellationTimestamp: now,
      );
      expect(eval2h.isPenaltyApplied, true);
      expect(eval2h.creditsToDeduct, 1);
    });
  });
}
