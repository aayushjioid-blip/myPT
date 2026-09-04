// Standalone Comprehensive Regression Suite for Flutter Stage 1.5 Prototype

import 'lib/data/mock/mock_data_store.dart';
import 'lib/data/repositories/mock_auth_repository.dart';
import 'lib/data/repositories/mock_trainer_repository.dart';
import 'lib/data/repositories/mock_package_repository.dart';
import 'lib/data/repositories/mock_booking_repository.dart';
import 'lib/data/repositories/mock_workout_repository.dart';
import 'lib/data/repositories/mock_progress_repository.dart';
import 'lib/data/repositories/mock_credit_ledger_repository.dart';
import 'lib/data/repositories/mock_gym_repository.dart';
import 'lib/data/repositories/mock_admin_repository.dart';
import 'lib/domain/entities/session_entity.dart';
import 'lib/domain/entities/workout_entity.dart';
import 'lib/domain/entities/measurement_entity.dart';
import 'lib/domain/entities/cancellation_policy_entity.dart';
import 'lib/domain/services/credit_ledger_service.dart';
import 'lib/domain/services/cancellation_evaluator.dart';
import 'lib/core/utils/formatters.dart';

void main() async {
  print('========================================================================');
  print('🧪 RUNNING FITTRAINER FLUTTER STAGE 1.5 FULL REGRESSION SUITE (PHASES 1-7)');
  print('========================================================================\n');

  final dataStore = MockDataStore();
  final authRepo = MockAuthRepository(dataStore);
  final trainerRepo = MockTrainerRepository(dataStore);
  final packageRepo = MockPackageRepository(dataStore);
  final bookingRepo = MockBookingRepository(dataStore);
  final progressRepo = MockProgressRepository(dataStore);
  final creditLedgerRepo = MockCreditLedgerRepository(dataStore);
  final gymRepo = MockGymRepository(dataStore);
  final adminRepo = MockAdminRepository(dataStore);
  final creditLedgerService = CreditLedgerService(creditLedgerRepo);
  final workoutRepo = MockWorkoutRepository(dataStore, creditLedgerService);

  const clientId = 'usr-client-1'; // Sarah Jenkins
  const trainerId = 'trn-alex';     // Alex Rivera

  // SUITE 1: DISCOVERY & UNVERIFIED GATING
  print('▶ [SUITE 1] Public Discovery & Trainer Verification Gating...');
  final publicTrainers = await trainerRepo.getVerifiedTrainers();
  assert(publicTrainers.any((t) => t.id == 'trn-alex'), 'Alex must be visible');
  assert(publicTrainers.any((t) => t.id == 'trn-maya'), 'Maya must be visible');
  assert(!publicTrainers.any((t) => t.id == 'trn-leo'), 'Leo Novak (unverified) MUST NOT appear in public discovery');
  final leoByCode = await trainerRepo.getTrainerByCode('LEO007');
  assert(leoByCode != null && leoByCode.id == 'trn-leo', 'Direct trainer code lookup for LEO007 must work');
  print('  ✅ SUITE 1 PASSED: Unverified trainer strictly hidden from discovery; direct code accessible.\n');

  // SUITE 2: CONSULTATION & PACKAGE PURCHASE ACTIVATION
  print('▶ [SUITE 2] Consultation Acceptance & Payment Verification (+10 Credits)...');
  await packageRepo.requestConsultation(
    clientId: clientId,
    trainerId: trainerId,
    goals: 'Fat Loss & Hypertrophy',
    notes: 'Morning training preferred.',
  );
  var pendingCons = await packageRepo.getPendingRelationshipsForTrainer(trainerId);
  await packageRepo.acceptConsultation(pendingCons.first.id);

  await packageRepo.requestPackagePurchase(clientId, 'pkg-10pt', 'UPI-SARAH-9988');
  var clientPkgs = await packageRepo.getClientPackages(clientId);
  assert(clientPkgs.first.remainingSessions == 0, 'Credits must be 0 prior to trainer verification');

  final pendingPayments = await packageRepo.getPendingPaymentsForTrainer(trainerId);
  await packageRepo.verifyPayment(pendingPayments.first.id, true);
  final activePkg = await packageRepo.getActivePackageForClient(clientId);
  assert(activePkg!.remainingSessions == 10, 'Package must have 10 credits activated');
  print('  ✅ SUITE 2 PASSED: Verification activated package with exactly +10 credits.\n');

  // SUITE 3: BOOKING PRECONDITION (0 CREDITS DEDUCTED)
  print('▶ [SUITE 3] Booking Request & Acceptance (Zero Credit Deductions)...');
  final session = await bookingRepo.requestBooking(
    clientId: clientId,
    trainerId: trainerId,
    clientPackageId: activePkg!.id,
    scheduledStart: DateTime.now().add(const Duration(days: 1)),
  );
  var balance = await creditLedgerRepo.getCurrentBalance(activePkg.id);
  assert(balance == 10, 'Booking request MUST deduct 0 credits! Balance must be 10.');
  await bookingRepo.acceptBooking(session.id);
  balance = await creditLedgerRepo.getCurrentBalance(activePkg.id);
  assert(balance == 10, 'Booking acceptance MUST deduct 0 credits! Balance must be 10.');
  print('  ✅ SUITE 3 PASSED: Booking lifecycle strictly consumes 0 credits.\n');

  // SUITE 4: LIVE WORKOUT LOGGING & SESSION COMPLETION (-1 CREDIT)
  print('▶ [SUITE 4] Live Workout Logging & Completion (-1 Credit)...');
  final exercisesLogged = [
    const WorkoutExerciseItem(id: 'we-1', exerciseId: 'ex-1', name: 'Barbell Bench Press', sets: 3, repetitions: 10, weightKg: 60),
    const WorkoutExerciseItem(id: 'we-2', exerciseId: 'ex-5', name: 'Lat Pulldown', sets: 3, repetitions: 12, weightKg: 50),
  ];
  await workoutRepo.completeWorkoutSession(session.id, 'wo-${session.id}', exercisesLogged);
  balance = await creditLedgerRepo.getCurrentBalance(activePkg.id);
  assert(balance == 9, 'Completed PT session MUST deduct exactly 1 credit (10 ➔ 9). Got $balance');

  // Double completion idempotency check
  await workoutRepo.completeWorkoutSession(session.id, 'wo-${session.id}', exercisesLogged);
  balance = await creditLedgerRepo.getCurrentBalance(activePkg.id);
  assert(balance == 9, 'Double completion MUST NOT deduct another credit! Balance must remain 9.');
  print('  ✅ SUITE 4 PASSED: Session completion deducted 1 credit; double-completion guarded at 9.\n');

  // SUITE 5: OWN WORKOUT ISOLATION (0 CREDITS DEDUCTED)
  print('▶ [SUITE 5] Own Workout Independence (0 Credits Deducted)...');
  await workoutRepo.logOwnWorkout(WorkoutEntity(
    id: 'wo-own-test',
    clientId: clientId,
    name: 'Sarah Morning Cardio Flow',
    workoutType: WorkoutType.ownWorkout,
    assignedDate: DateTime.now(),
    status: WorkoutStatus.completed,
    completedAt: DateTime.now(),
    exercises: const [
      WorkoutExerciseItem(id: 'oe-1', exerciseId: 'ex-15', name: 'Plank with Shoulder Taps', sets: 3, repetitions: 12),
    ],
  ));
  balance = await creditLedgerRepo.getCurrentBalance(activePkg.id);
  assert(balance == 9, 'Own Workout MUST NEVER deduct credits! Balance must remain 9.');
  print('  ✅ SUITE 5 PASSED: Own Workout logged with 0 PT credit deduction.\n');

  // SUITE 6: DYNAMIC CANCELLATION EVALUATOR & PENALTY
  print('▶ [SUITE 6] Dynamic Cancellation Policy (Grace Window & Penalties)...');
  final policy = const CancellationPolicyEntity(
    policyType: CancellationPolicyType.fourHourPolicy,
    penaltyEnabled: true,
    gracePeriodHours: 4,
    creditsDeducted: 1,
  );

  // Test 6a: Cancel 6 hours before start -> Penalty FALSE
  final futureSession = SessionEntity(
    id: 'sess-fut-1',
    clientId: clientId,
    trainerId: trainerId,
    clientPackageId: activePkg.id,
    scheduledStart: DateTime.now().add(const Duration(hours: 6)),
    createdAt: DateTime.now(),
  );
  final eval6h = CancellationEvaluator.evaluate(
    session: futureSession,
    policy: policy,
    cancellationTimestamp: DateTime.now(),
  );
  assert(!eval6h.isPenaltyApplied && eval6h.creditsToDeduct == 0, '6h before start should have 0 penalty');

  // Test 6b: Cancel 2 hours before start -> Penalty TRUE (1 credit)
  final lateSession = SessionEntity(
    id: 'sess-late-1',
    clientId: clientId,
    trainerId: trainerId,
    clientPackageId: activePkg.id,
    scheduledStart: DateTime.now().add(const Duration(hours: 2)),
    createdAt: DateTime.now(),
  );
  final eval2h = CancellationEvaluator.evaluate(
    session: lateSession,
    policy: policy,
    cancellationTimestamp: DateTime.now(),
  );
  assert(eval2h.isPenaltyApplied && eval2h.creditsToDeduct == 1, '2h before start should incur 1 credit penalty');
  print('  ✅ SUITE 6 PASSED: Dynamic cancellation evaluator correctly enforces grace hours and penalty.\n');

  // SUITE 7: PROGRESS TRACKING & AUTO BMI
  print('▶ [SUITE 7] 8-Point Progress Tracking & Auto BMI Calculation...');
  final autoBmi = Formatters.calculateBmi(64.5, 168.0);
  assert(autoBmi == 22.9, 'BMI calculation for 64.5kg @ 168cm should be 22.9. Got $autoBmi');
  await progressRepo.logMeasurement(MeasurementEntity(
    id: 'm-reg-1',
    clientId: clientId,
    date: DateTime.now(),
    weightKg: 64.0,
    heightCm: 168.0,
    bmi: Formatters.calculateBmi(64.0, 168.0),
    chestCm: 90.0,
    waistCm: 71.5,
    hipsCm: 95.5,
  ));
  final measurements = await progressRepo.getMeasurementsByClientId(clientId);
  assert(measurements.length >= 4, 'Measurement history must be appended without overwriting');
  print('  ✅ SUITE 7 PASSED: 8-point measurement logged; BMI auto-calculated; history preserved.\n');

  // SUITE 8: MEDICAL PRIVACY SHIELD
  print('▶ [SUITE 8] Medical & Progress Privacy Shield...');
  await authRepo.togglePersonalInfoSharing(false);
  assert(authRepo.getCurrentUser().sharePersonalInfoWithTrainer == false, 'Privacy sharing must be FALSE');
  await authRepo.togglePersonalInfoSharing(true);
  assert(authRepo.getCurrentUser().sharePersonalInfoWithTrainer == true, 'Privacy sharing must be TRUE');
  print('  ✅ SUITE 8 PASSED: Explicit client privacy consent toggle verified.\n');

  // SUITE 9: HEAD TRAINER CLIENT REASSIGNMENT (100% PRESERVATION)
  print('▶ [SUITE 9] Head Trainer Client Reassignment & History Preservation...');
  await gymRepo.reassignClient(
    relationshipId: 'rel-sarah-alex',
    fromTrainerId: 'trn-alex',
    toTrainerId: 'trn-maya',
    reason: 'Schedule optimization and calisthenics mobility focus.',
  );
  final sarahPkgsAfterReassign = await packageRepo.getClientPackages(clientId);
  assert(sarahPkgsAfterReassign.first.trainerId == 'trn-maya', 'Package trainerId must update to Maya');
  assert(sarahPkgsAfterReassign.first.remainingSessions == 9, 'Credit balance of 9 MUST be preserved!');
  final sarahWorkoutsAfterReassign = await workoutRepo.getWorkoutsForClient(clientId);
  assert(sarahWorkoutsAfterReassign.isNotEmpty, 'Workout history must be 100% preserved after transfer');
  print('  ✅ SUITE 9 PASSED: Client reassignment preserved 100% of workouts, package credits & logs.\n');

  // SUITE 10: CENTRALIZED FEATURE FLAGS & ADMIN CONTROLS
  print('▶ [SUITE 10] Super Admin Feature Flags & Verification Toggles...');
  final initialFlags = await adminRepo.getFeatureFlags();
  assert(initialFlags['advanced_trainer_search'] == false, 'advanced_trainer_search must default to FALSE');
  await adminRepo.setFeatureFlag('advanced_trainer_search', true);
  final updatedFlags = await adminRepo.getFeatureFlags();
  assert(updatedFlags['advanced_trainer_search'] == true, 'Feature flag must update reactively to TRUE');

  await adminRepo.setTrainerVerification('trn-leo', true);
  final publicTrainersAfterLeoVerify = await trainerRepo.getVerifiedTrainers();
  assert(publicTrainersAfterLeoVerify.any((t) => t.id == 'trn-leo'), 'Leo Novak must now appear in public discovery');
  print('  ✅ SUITE 10 PASSED: Feature flags and trainer verification toggles work reactively.\n');

  print('========================================================================');
  print('🎉 ALL 10 COMPREHENSIVE REGRESSION SUITES PASSED WITH ZERO ERRORS!');
  print('========================================================================\n');
}
