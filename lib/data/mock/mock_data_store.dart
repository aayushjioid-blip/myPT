import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/trainer_entity.dart';
import '../../domain/entities/cancellation_policy_entity.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/exercise_catalog.dart';
import '../../domain/entities/measurement_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/gym_entity.dart';
import '../../domain/entities/credit_transaction_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/relationship_entity.dart';
import '../../domain/entities/fitness_chart_entity.dart';

class MockDataStore {
  static final MockDataStore _instance = MockDataStore._internal();
  factory MockDataStore() => _instance;
  MockDataStore._internal() {
    _initSeedData();
  }

  // Reactive State Stream
  final StreamController<UserEntity> _currentUserController = StreamController<UserEntity>.broadcast();
  Stream<UserEntity> get currentUserStream => _currentUserController.stream;
  late UserEntity _currentUser;
  UserEntity get currentUser => _currentUser;

  // Change notification stream for global state listeners
  final StreamController<void> _stateChangeController = StreamController<void>.broadcast();
  Stream<void> get stateChanges => _stateChangeController.stream;

  void notifyListeners() {
    _stateChangeController.add(null);
  }

  // Data Collections
  final List<UserEntity> users = [];
  final List<TrainerEntity> trainers = [];
  final List<GymEntity> gyms = [];
  final List<PackageEntity> packages = [];
  final List<RelationshipEntity> relationships = [];
  final List<ClientPackageEntity> clientPackages = [];
  final List<PaymentEntity> payments = [];
  final List<SessionEntity> sessions = [];
  final List<ExerciseEntity> exercises = [];
  final List<WorkoutTemplateEntity> workoutTemplates = [];
  final List<WorkoutEntity> workouts = [];
  final List<FitnessChartEntity> charts = [];
  final List<MeasurementEntity> measurements = [];
  final List<ReviewEntity> reviews = [];
  final List<CreditTransactionEntity> creditTransactions = [];
  final List<NotificationEntity> notifications = [];
  final Map<String, bool> featureFlags = {
    'advanced_trainer_search': false,
    'client_personal_information': true,
    'online_payments': false,
    'trainer_reviews': true,
    'whatsapp_notifications': false,
  };

  void setCurrentUser(UserEntity user) {
    _currentUser = user;
    _currentUserController.add(_currentUser);
    notifyListeners();
  }

  void _initSeedData() {
    // 1. Users for all 5 roles
    users.addAll([
      const UserEntity(
        id: 'usr_master',
        name: 'Master Admin',
        email: 'master@mypt.com',
        role: UserRole.superAdmin,
        avatar: '⚡',
      ),
      const UserEntity(
        id: 'usr-admin-1',
        name: 'Super Admin',
        email: 'admin@test.local',
        role: UserRole.superAdmin,
        avatar: '🛡️',
      ),
      const UserEntity(
        id: 'usr-gymmgr-1',
        name: 'Elena Rostova',
        email: 'gymmanager@test.local',
        role: UserRole.gymManager,
        avatar: '🏢',
        gymId: 'gym-ironcore',
      ),
      const UserEntity(
        id: 'usr-headtrn-1',
        name: 'Marcus Vance',
        email: 'headtrainer@test.local',
        role: UserRole.headTrainer,
        avatar: '👑',
        gymId: 'gym-ironcore',
      ),
      const UserEntity(
        id: 'usr-trn-1',
        name: 'Alex Rivera',
        email: 'trainer@test.local',
        role: UserRole.trainer,
        avatar: '🏋️',
        gymId: 'gym-ironcore',
      ),
      const UserEntity(
        id: 'usr-trn-2',
        name: 'Maya Lin',
        email: 'maya.trainer@test.local',
        role: UserRole.trainer,
        avatar: '🤸‍♀️',
        gymId: 'gym-ironcore',
      ),
      const UserEntity(
        id: 'usr-trn-unverified',
        name: 'Leo Novak',
        email: 'leo.unverified@test.local',
        role: UserRole.trainer,
        avatar: '🥊',
      ),
      const UserEntity(
        id: 'usr-client-1',
        name: 'Sarah Jenkins',
        email: 'client@test.local',
        role: UserRole.client,
        avatar: '🏃‍♀️',
        sharePersonalInfoWithTrainer: false,
        age: 28,
        heightCm: 168,
        weightKg: 64.5,
        fitnessGoal: 'Fat Loss & Athletic Conditioning',
        fitnessLevel: 'Intermediate',
        injuries: 'Past minor rotator cuff strain (left shoulder)',
        medicalInfo: 'No chronic conditions',
        emergencyContact: '+1-555-0199 (Mike Jenkins)',
      ),
      const UserEntity(
        id: 'usr-client-2',
        name: 'David Kim',
        email: 'david.client@test.local',
        role: UserRole.client,
        avatar: '🧗',
        sharePersonalInfoWithTrainer: true,
        age: 34,
        heightCm: 178,
        weightKg: 82.0,
        fitnessGoal: 'Hypertrophy & Strength',
        fitnessLevel: 'Advanced',
      ),
    ]);

    _currentUser = users.firstWhere((u) => u.id == 'usr-client-1');

    // 2. Trainers
    trainers.addAll([
      TrainerEntity(
        id: 'trn-alex',
        userId: 'usr-trn-1',
        name: 'Alex Rivera',
        verificationStatus: VerificationStatus.verified,
        bio: 'NASM-certified Elite Performance Coach specializing in hypertrophy, mobility, and fat loss.',
        experienceYears: 8,
        certifications: const ['NASM-CPT', 'CSCS', 'Precision Nutrition L1'],
        specializations: const ['Hypertrophy', 'Fat Loss', 'Mobility', 'Strength'],
        skills: const ['Barbell Mastery', 'Postural Restoration', 'Kettlebell Flow'],
        services: const ['1-on-1 PT', 'Nutrition Consulting', 'Custom Programming'],
        languages: const ['English', 'Spanish'],
        location: 'Downtown Athletic Club / Hybrid Online',
        trainerCode: 'TRN001',
        upiId: 'alex.rivera@upi',
        mobilePaymentNumber: '+1-555-8822',
        cancellationPolicy: const CancellationPolicyEntity(
          policyType: CancellationPolicyType.fourHourPolicy,
          gracePeriodHours: 4,
          creditsDeducted: 1,
        ),
        rating: 4.9,
        reviewCount: 38,
      ),
      TrainerEntity(
        id: 'trn-maya',
        userId: 'usr-trn-2',
        name: 'Maya Lin',
        verificationStatus: VerificationStatus.verified,
        bio: 'Yoga, Calisthenics, and Athletic Functional Conditioning Coach with Olympic lifting background.',
        experienceYears: 6,
        certifications: const ['ACE-CPT', 'RYT-500 Yoga', 'USAW L1'],
        specializations: const ['Mobility', 'Functional Training', 'Calisthenics'],
        skills: const ['Bodyweight Acrobatics', 'Flexibility Training', 'Breathwork'],
        services: const ['Movement Screen', 'Small Group Calisthenics', '1-on-1 PT'],
        languages: const ['English', 'Mandarin'],
        location: 'IronCore Fitness Center',
        trainerCode: 'MAYA02',
        upiId: 'maya.lin@upi',
        mobilePaymentNumber: '+1-555-7733',
        rating: 4.95,
        reviewCount: 24,
      ),
      TrainerEntity(
        id: 'trn-leo',
        userId: 'usr-trn-unverified',
        name: 'Leo Novak',
        verificationStatus: VerificationStatus.unverified, // Hidden from public discovery
        bio: 'Independent boxing and HIIT coach.',
        experienceYears: 3,
        certifications: const ['Boxing Fundamentals'],
        specializations: const ['Boxing', 'Conditioning'],
        skills: const ['Pad Work', 'Heavy Bag Conditioning'],
        services: const ['Boxing 1-on-1', 'HIIT Cardio'],
        languages: const ['English'],
        location: 'Metro Boxing Studio',
        trainerCode: 'LEO007',
        upiId: 'leo.boxing@upi',
        mobilePaymentNumber: '+1-555-3344',
        cancellationPolicy: const CancellationPolicyEntity(
          policyType: CancellationPolicyType.noPenalty,
          penaltyEnabled: false,
          gracePeriodHours: 0,
          creditsDeducted: 0,
        ),
        rating: 5.0,
        reviewCount: 2,
      ),
    ]);

    // 3. Gyms
    gyms.add(const GymEntity(
      id: 'gym-ironcore',
      name: 'IronCore Fitness Center',
      ownerId: 'usr-gymmgr-1',
      headTrainerId: 'usr-headtrn-1',
      address: '742 Evergreen Blvd, Metro City',
      phone: '+1-555-0900',
      operatingHours: '06:00 - 22:00 Daily',
      maxFloorCapacity: 40,
      amenities: ['Olympic Platforms', 'Sauna & Ice Bath', 'Turf Sprint Track'],
    ));

    // 4. Packages
    packages.addAll([
      const PackageEntity(
        id: 'pkg-10pt',
        trainerId: 'trn-alex',
        name: '10 PT Sessions Starter Pack',
        description: 'Comprehensive 1-on-1 coaching with nutrition & programming.',
        sessions: 10,
        price: 499.00,
        validityDays: 40,
      ),
      const PackageEntity(
        id: 'pkg-20pt',
        trainerId: 'trn-alex',
        name: '20 PT Sessions Transformation',
        description: 'Full body transformation with bi-weekly body scans.',
        sessions: 20,
        price: 899.00,
        validityDays: 80,
      ),
      const PackageEntity(
        id: 'pkg-10maya',
        trainerId: 'trn-maya',
        name: '10 Mobility & Calisthenics Sessions',
        description: 'Bodyweight strength, core endurance, and joint mobility.',
        sessions: 10,
        price: 479.00,
        validityDays: 45,
        validityMode: ValidityMode.custom,
      ),
    ]);

    // 5. Exercises across 12 categories
    exercises.addAll(ExerciseCatalog.defaultExercises);

    // 6. Workout Templates
    workoutTemplates.add(const WorkoutTemplateEntity(
      id: 'tmpl-upper-hypertrophy',
      trainerId: 'trn-alex',
      name: 'Upper Body Hypertrophy Focus',
      description: 'High intensity upper body power sequence.',
      exercises: [
        WorkoutExerciseItem(id: 'te-1', exerciseId: 'ex-1', name: 'Barbell Bench Press', sets: 3, repetitions: 10, weightKg: 60),
        WorkoutExerciseItem(id: 'te-2', exerciseId: 'ex-5', name: 'Lat Pulldown', sets: 3, repetitions: 12, weightKg: 50),
        WorkoutExerciseItem(id: 'te-3', exerciseId: 'ex-9', name: 'Dumbbell Lateral Raise', sets: 3, repetitions: 15, weightKg: 10),
        WorkoutExerciseItem(id: 'te-4', exerciseId: 'ex-11', name: 'Triceps Rope Pushdown', sets: 3, repetitions: 12, weightKg: 25),
      ],
    ));

    // 7. Measurements
    measurements.addAll([
      MeasurementEntity(
        id: 'm-1',
        clientId: 'usr-client-1',
        date: DateTime.now().subtract(const Duration(days: 60)),
        weightKg: 68.0,
        heightCm: 168.0,
        bmi: 24.1,
        bodyFatPercentage: 24.5,
        chestCm: 94.0,
        waistCm: 76.0,
        hipsCm: 99.0,
      ),
      MeasurementEntity(
        id: 'm-2',
        clientId: 'usr-client-1',
        date: DateTime.now().subtract(const Duration(days: 30)),
        weightKg: 66.2,
        heightCm: 168.0,
        bmi: 23.5,
        bodyFatPercentage: 23.0,
        chestCm: 92.5,
        waistCm: 74.0,
        hipsCm: 97.5,
      ),
      MeasurementEntity(
        id: 'm-3',
        clientId: 'usr-client-1',
        date: DateTime.now(),
        weightKg: 64.5,
        heightCm: 168.0,
        bmi: 22.9,
        bodyFatPercentage: 21.8,
        chestCm: 91.0,
        waistCm: 72.0,
        hipsCm: 96.0,
      ),
    ]);

    // 8. Reviews
    reviews.addAll([
      ReviewEntity(
        id: 'rev-1',
        trainerId: 'trn-alex',
        clientId: 'usr-client-2',
        clientName: 'David Kim',
        rating: 5,
        comment: 'Alex is phenomenal! He corrected my squat mechanics and programmed a tailored hypertrophy routine.',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      ReviewEntity(
        id: 'rev-2',
        trainerId: 'trn-alex',
        clientId: 'usr-client-1',
        clientName: 'Sarah Jenkins',
        rating: 5,
        comment: 'Super structured workouts and attentive coaching. Down 3.5kg and feeling stronger than ever!',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    // 9. Notifications
    notifications.add(NotificationEntity(
      id: 'notif-1',
      userId: 'usr-client-1',
      title: 'Welcome to FitTrainer',
      message: 'Explore verified trainers to start your fitness journey!',
      timestamp: DateTime.now(),
    ));

    // 10. Relationships
    relationships.addAll([
      RelationshipEntity(
        id: 'rel-seed-sarah',
        clientId: 'usr-client-1',
        trainerId: 'trn-alex',
        status: RelationshipStatus.requested,
        goals: 'Fat loss, hypertrophy and posture alignment.',
        notes: 'Available weekday mornings 8-10 AM.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RelationshipEntity(
        id: 'rel-seed-david',
        clientId: 'usr-client-2',
        trainerId: 'trn-alex',
        status: RelationshipStatus.accepted,
        goals: 'Hypertrophy & Strength',
        notes: 'Preparing for powerlifting meet.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ]);

    // 11. Payments & Packages
    payments.addAll([
      PaymentEntity(
        id: 'pay-seed-1',
        clientId: 'usr-client-2',
        trainerId: 'trn-alex',
        packageId: 'pkg-10pt',
        amount: 499.00,
        transactionRef: 'UPI-984712093481',
        status: PaymentStatus.pendingVerification,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      PaymentEntity(
        id: 'pay-seed-sarah',
        clientId: 'usr-client-1',
        trainerId: 'trn-alex',
        packageId: 'pkg-10pt',
        amount: 499.00,
        transactionRef: 'UPI-112233445566',
        status: PaymentStatus.paid,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        verifiedAt: DateTime.now().subtract(const Duration(days: 10)),
        verifiedBy: 'trn-alex',
      ),
    ]);

    clientPackages.addAll([
      ClientPackageEntity(
        id: 'cpkg-seed-david',
        clientId: 'usr-client-2',
        trainerId: 'trn-alex',
        packageId: 'pkg-10pt',
        totalSessions: 10,
        completedSessions: 0,
        remainingSessions: 0,
        validityDays: 40,
        purchaseDate: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'PENDING_PAYMENT',
        paymentId: 'pay-seed-1',
      ),
      ClientPackageEntity(
        id: 'cpkg-seed-sarah',
        clientId: 'usr-client-1',
        trainerId: 'trn-alex',
        packageId: 'pkg-10pt',
        totalSessions: 10,
        completedSessions: 1,
        remainingSessions: 9,
        validityDays: 40,
        purchaseDate: DateTime.now().subtract(const Duration(days: 10)),
        status: 'ACTIVE',
        activationDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        paymentId: 'pay-seed-sarah',
      ),
    ]);

    // 12. Sessions
    sessions.addAll([
      SessionEntity(
        id: 'sess-today-sarah',
        clientId: 'usr-client-1',
        trainerId: 'trn-alex',
        clientPackageId: 'cpkg-seed-sarah',
        sessionType: SessionType.personalTraining,
        scheduledStart: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 10, 0),
        status: SessionStatus.confirmed,
        isRecurring: false,
        creditConsumed: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    // 13. Completed Past Workouts (for Progressive Overload Previous Session Comparison)
    workouts.addAll([
      WorkoutEntity(
        id: 'wo-prev-sarah-1',
        trainerId: 'trn-alex',
        clientId: 'usr-client-1',
        name: 'Upper Body Power & Hypertrophy',
        description: 'Previous upper body training session',
        workoutType: WorkoutType.assigned,
        assignedDate: DateTime.now().subtract(const Duration(days: 3)),
        status: WorkoutStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
        exercises: const [
          WorkoutExerciseItem(
            id: 'pe-1',
            exerciseId: 'ex-chest-1',
            name: 'Flat Barbell Bench Press',
            sets: 3,
            repetitions: 10,
            weightKg: 55,
            setDetails: [
              WorkoutSetDetail(setNumber: 1, reps: 10, weightKg: 55),
              WorkoutSetDetail(setNumber: 2, reps: 10, weightKg: 55),
              WorkoutSetDetail(setNumber: 3, reps: 10, weightKg: 55),
            ],
          ),
          WorkoutExerciseItem(
            id: 'pe-2',
            exerciseId: 'ex-back-2',
            name: 'Lat Pulldown',
            sets: 3,
            repetitions: 12,
            weightKg: 45,
            setDetails: [
              WorkoutSetDetail(setNumber: 1, reps: 12, weightKg: 45),
              WorkoutSetDetail(setNumber: 2, reps: 12, weightKg: 45),
              WorkoutSetDetail(setNumber: 3, reps: 12, weightKg: 45),
            ],
          ),
          WorkoutExerciseItem(
            id: 'pe-3',
            exerciseId: 'ex-sh-3',
            name: 'Dumbbell Lateral Raise',
            sets: 3,
            repetitions: 12,
            weightKg: 10,
            setDetails: [
              WorkoutSetDetail(setNumber: 1, reps: 12, weightKg: 10),
              WorkoutSetDetail(setNumber: 2, reps: 12, weightKg: 10),
              WorkoutSetDetail(setNumber: 3, reps: 12, weightKg: 10),
            ],
          ),
          WorkoutExerciseItem(
            id: 'pe-4',
            exerciseId: 'ex-tri-1',
            name: 'Triceps Rope Pushdown',
            sets: 3,
            repetitions: 12,
            weightKg: 20,
            setDetails: [
              WorkoutSetDetail(setNumber: 1, reps: 12, weightKg: 20),
              WorkoutSetDetail(setNumber: 2, reps: 12, weightKg: 20),
              WorkoutSetDetail(setNumber: 3, reps: 12, weightKg: 20),
            ],
          ),
        ],
      ),
    ]);

    // 14. Fitness & Diet Charts
    charts.addAll([
      FitnessChartEntity(
        id: 'chart-seed-1',
        trainerId: 'trn-alex',
        trainerName: 'Alex Rivera',
        clientId: 'usr-client-1',
        clientName: 'Sarah Jenkins',
        title: 'Phase 1: Foundation Hypertrophy & Fat Loss',
        goalCategory: 'Body Recomposition & Lean Mass',
        dietPlan: const [
          MealItemEntity(
            mealName: 'Meal 1 (Breakfast)',
            foodItems: '4 Egg whites + 1 Whole egg + 60g Oats with blueberries + 1 scoop Whey Protein',
            calories: 480,
            proteinGrams: 42,
            carbsGrams: 55,
            fatsGrams: 10,
          ),
          MealItemEntity(
            mealName: 'Meal 2 (Lunch)',
            foodItems: '180g Grilled Chicken Breast + 150g Jasmine Rice + Steamed Broccoli & Zucchini',
            calories: 580,
            proteinGrams: 48,
            carbsGrams: 62,
            fatsGrams: 12,
          ),
          MealItemEntity(
            mealName: 'Meal 3 (Post-Workout)',
            foodItems: '1 Scoop Whey Isolate + 1 Medium Banana + 2 Rice Cakes with 15g Peanut Butter',
            calories: 340,
            proteinGrams: 30,
            carbsGrams: 40,
            fatsGrams: 8,
          ),
          MealItemEntity(
            mealName: 'Meal 4 (Dinner)',
            foodItems: '160g Baked Salmon Fillet + Quinoa & Mixed Leaf Salad with Olive Oil Dressing',
            calories: 510,
            proteinGrams: 40,
            carbsGrams: 35,
            fatsGrams: 22,
          ),
        ],
        workoutPlan: const [
          WorkoutExercisePlan(name: 'Barbell Bench Press', sets: 3, reps: 10, notes: 'Focus on explosive concentric, controlled 2-sec eccentric.', targetMuscle: 'Chest'),
          WorkoutExercisePlan(name: 'Lat Pulldown', sets: 3, reps: 12, notes: 'Drive elbows down and back, pause at full contraction.', targetMuscle: 'Back'),
          WorkoutExercisePlan(name: 'Dumbbell Lateral Raise', sets: 3, reps: 15, notes: 'Maintain slight torso lean, lead with elbows.', targetMuscle: 'Shoulders'),
          WorkoutExercisePlan(name: 'Triceps Rope Pushdown', sets: 3, reps: 12, notes: 'Spread rope handles at the bottom for peak triceps squeeze.', targetMuscle: 'Triceps'),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }
}
