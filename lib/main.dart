import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ============================================================================
// 1. ROLES & DATA MODELS
// ============================================================================
enum UserRole { client, coach, headCoach, gymMgr, superAdmin }
enum RequestStatus { pending, confirmed, completed, cancelled }
enum TrainerApprovalStatus { none, pending, approved, rejected }

const List<String> kStandardFitnessGoals = [
  'Fat Loss & Hypertrophy',
  'Lean Muscle & Core',
  'Strength & Power',
  'Hypertrophy & Mobility',
  'General Fitness & Muscle Gain',
  'Athletic Conditioning & Endurance',
  'Post-Rehab & Posture Correction',
];

class UserModel {
  final String id;
  String name;
  String email;
  UserRole role;
  double currentWeight;
  double startingWeight;
  int ptCredits;
  String goal;
  String phone;
  int age;
  double heightCm;
  String emergencyContact;
  String medicalInfo;
  String? headCoachId; // If Coach: ID of Head Coach managing this coach
  String? trainerId;   // If Client: ID of Trainer training this client
  TrainerApprovalStatus trainerApprovalStatus;
  List<UserRole>? dualRoles; // Dual roles (e.g. Neeli: headCoach + gymMgr, Khushboo: coach + client)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.currentWeight = 64.5,
    this.startingWeight = 68.0,
    this.ptCredits = 0,
    this.goal = 'Fat Loss & Hypertrophy',
    this.phone = '+91 98765 43210',
    this.age = 28,
    this.heightCm = 168.0,
    this.emergencyContact = '+91 98765 00000 (Emergency Contact)',
    this.medicalInfo = 'No known medical restrictions',
    this.headCoachId,
    this.trainerId,
    this.trainerApprovalStatus = TrainerApprovalStatus.none,
    this.dualRoles,
  });
}

class SessionItem {
  final String id;
  final String? clientId;
  final String clientName;
  final String? trainerId;
  final String trainerName;
  DateTime date;
  String timeSlot;
  String focusArea;
  RequestStatus status;
  String? meetingLink;

  SessionItem({
    required this.id,
    this.clientId,
    required this.clientName,
    this.trainerId,
    required this.trainerName,
    required this.date,
    required this.timeSlot,
    required this.focusArea,
    this.status = RequestStatus.pending,
    this.meetingLink = 'https://meet.mypt.pro/1on1-live-session',
  });
}

class TrainingPackage {
  final String id;
  final String? trainerId;
  final String? trainerName;
  String title;
  double priceInr;
  int sessionsCount;
  int durationWeeks;
  List<String> perks;
  String description;

  TrainingPackage({
    required this.id,
    this.trainerId,
    this.trainerName,
    required this.title,
    required this.priceInr,
    required this.sessionsCount,
    required this.durationWeeks,
    required this.perks,
    this.description = 'Personalized 1-on-1 coaching package',
  });

  double get price => priceInr;
}

class PackagePurchaseRequest {
  final String id;
  final String clientId;
  final String clientName;
  final String trainerId;
  final String trainerName;
  final String packageId;
  final String packageTitle;
  final double priceInr;
  final int sessionsCount;
  final String paymentMethod; // 'offline' or 'online'
  RequestStatus status; // pending, confirmed, cancelled
  final DateTime createdAt;

  PackagePurchaseRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.trainerId,
    required this.trainerName,
    required this.packageId,
    required this.packageTitle,
    required this.priceInr,
    required this.sessionsCount,
    this.paymentMethod = 'offline',
    this.status = RequestStatus.pending,
    required this.createdAt,
  });
}

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final double rate;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    required this.rate,
  });
}

class MovementItem {
  final String name;
  final String category;
  final String defaultSetsReps;
  final String equipment;
  final String primaryMuscle;
  final String secondaryMuscles;
  final String difficulty;
  final String movementPattern;
  final String trackingType;

  MovementItem({
    required this.name,
    String? category,
    required this.defaultSetsReps,
    required this.equipment,
    String? primaryMuscle,
    String? secondaryMuscles,
    String? difficulty,
    String? movementPattern,
    String? trackingType,
  })  : category = category ?? primaryMuscle ?? 'Strength',
        primaryMuscle = primaryMuscle ?? category ?? 'General',
        secondaryMuscles = secondaryMuscles ?? 'None',
        difficulty = difficulty ?? 'Beginner',
        movementPattern = movementPattern ?? 'Standard',
        trackingType = trackingType ?? 'Weight + Reps';
}

class SetDetail {
  int setNumber;
  double weightKg;
  int reps;
  bool isCompleted;

  SetDetail({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isCompleted = false,
  });

  double get volumeKg => weightKg * reps;
}

class WorkoutExercise {
  String name;
  String sets;
  String reps;
  String weight;
  String restSeconds;
  bool isCompleted;
  List<SetDetail>? setDetails;

  WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.restSeconds = '90s',
    this.isCompleted = false,
    this.setDetails,
  });

  double get sumProductKg {
    if (setDetails != null && setDetails!.isNotEmpty) {
      return setDetails!.where((s) => s.isCompleted).fold(0.0, (acc, s) => acc + s.volumeKg);
    }
    final s = double.tryParse(sets) ?? 1.0;
    final repsMatch = RegExp(r'(\d+)').firstMatch(reps);
    final r = repsMatch != null ? double.tryParse(repsMatch.group(1)!) ?? 10.0 : 10.0;
    final weightMatch = RegExp(r'(\d+)').firstMatch(weight);
    final w = weightMatch != null
        ? double.tryParse(weightMatch.group(1)!) ?? 0.0
        : (weight.toLowerCase().contains('bodyweight') ? 70.0 : 0.0);
    return s * r * w;
  }

  String get formattedSumProduct {
    final val = sumProductKg;
    if (val >= 1000) {
      final formatted = val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '$formatted kg';
    }
    return '${val.toStringAsFixed(0)} kg';
  }

  bool get hasTargetWeight {
    final w = weight.trim();
    if (w.isEmpty) return false;
    final lower = w.toLowerCase();
    if (lower == 'none' || lower == 'n/a' || lower == '-' || lower == '0' || lower == '0 kg' || lower == '0kg') {
      return false;
    }
    return true;
  }
}

class CustomWorkoutRoutine {
  final String id;
  String name;
  String focusArea;
  String phase;
  List<WorkoutExercise> exercises;
  String createdBy;
  bool isCustom;

  CustomWorkoutRoutine({
    required this.id,
    required this.name,
    required this.focusArea,
    this.phase = 'Phase 1 Active',
    required this.exercises,
    this.createdBy = 'You',
    this.isCustom = true,
  });

  double get totalVolumeKg => exercises.fold(0.0, (acc, ex) => acc + ex.sumProductKg);

  String get formattedTotalVolume {
    final val = totalVolumeKg;
    if (val >= 1000) {
      final formatted = val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '$formatted kg';
    }
    return '${val.toStringAsFixed(0)} kg';
  }
}

class WorkoutSessionLog {
  final String id;
  final String routineName;
  final String focusArea;
  final DateTime completedAt;
  final int durationMinutes;
  final double totalVolumeKg;
  final String loggedBy;
  final List<WorkoutExercise> exercises;

  WorkoutSessionLog({
    required this.id,
    required this.routineName,
    required this.focusArea,
    required this.completedAt,
    this.durationMinutes = 45,
    required this.totalVolumeKg,
    this.loggedBy = 'You',
    required this.exercises,
  });
}

class BodyMeasurementEntry {
  final String id;
  final DateTime date;
  final double weightKg;
  final double bodyFatPercent;
  final double chestCm;
  final double waistCm;
  final double hipsCm;
  final double armsCm;
  final double thighsCm;
  final String notes;

  BodyMeasurementEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.bodyFatPercent = 18.5,
    this.chestCm = 96.0,
    this.waistCm = 78.0,
    this.hipsCm = 92.0,
    this.armsCm = 34.0,
    this.thighsCm = 56.0,
    this.notes = 'Regular Check-in',
  });
}

class ClientRequestItem {
  final String id;
  final String? clientId;
  final String clientName;
  final String email;
  final String? trainerId;
  final String? trainerName;
  final String requestType;
  final String message;
  final DateTime date;
  RequestStatus status;
  String? declineReason;

  ClientRequestItem({
    required this.id,
    this.clientId,
    required this.clientName,
    required this.email,
    this.trainerId,
    this.trainerName,
    required this.requestType,
    required this.message,
    required this.date,
    this.status = RequestStatus.pending,
    this.declineReason,
  });
}

class MealLogAttachment {
  final String mealType; // 'Breakfast', 'Lunch', 'Snacks', 'Dinner', 'Extra Meal'
  final String description;
  final String? photoUrl;
  final DateTime mealDate;
  final int? caloriesKcal;
  final int? proteinGrams;

  MealLogAttachment({
    required this.mealType,
    required this.description,
    this.photoUrl,
    required this.mealDate,
    this.caloriesKcal,
    this.proteinGrams,
  });

  String get emoji {
    final lower = mealType.toLowerCase();
    if (lower.contains('breakfast')) return '🍳';
    if (lower.contains('lunch')) return '🥗';
    if (lower.contains('snack')) return '🥪';
    if (lower.contains('dinner')) return '🍲';
    if (lower.contains('extra')) return '🍱';
    return '🍽️';
  }
}

class ChatMessageItem {
  final String id;
  final String senderName;
  final String receiverName;
  final String text;
  final DateTime timestamp;
  final bool isFromTrainer;
  final MealLogAttachment? mealAttachment;

  ChatMessageItem({
    required this.id,
    required this.senderName,
    required this.receiverName,
    required this.text,
    required this.timestamp,
    required this.isFromTrainer,
    this.mealAttachment,
  });
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'booking', 'approval', 'chat', 'payment', 'warning', 'system'
  bool isRead;
  final String? recipientName;
  final UserRole? recipientRole;
  final String? sessionId;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.recipientName,
    this.recipientRole,
    this.sessionId,
  });
}

// ============================================================================
// 2. STATE PROVIDER WITH AUTH, HIERARCHY & PERSISTED DATA
// ============================================================================
class MyPtProvider extends ChangeNotifier {
  UserModel? currentUser; // Null when logged out
  bool isDevMode = !kReleaseMode;

  // Localization and currency (Default to India and INR)
  String userLocation = 'India';
  String selectedCountry = 'India';

  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'INR': CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳', rate: 1.0),
    'USD': CurrencyInfo(code: 'USD', symbol: '\$', name: 'United States Dollar', flag: '🇺🇸', rate: 0.012),
    'EUR': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺', rate: 0.011),
    'GBP': CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧', rate: 0.0095),
    'AED': CurrencyInfo(code: 'AED', symbol: 'AED ', name: 'UAE Dirham', flag: '🇦🇪', rate: 0.044),
    'CAD': CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '🇨🇦', rate: 0.016),
    'AUD': CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺', rate: 0.018),
    'SGD': CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬', rate: 0.016),
  };

  String selectedCurrency = 'INR';

  void setCurrency(String code) {
    if (supportedCurrencies.containsKey(code)) {
      selectedCurrency = code;
      notifyListeners();
    }
  }

  void setUserLocation(String country, {String? currencyCode}) {
    selectedCountry = country;
    userLocation = country;
    if (currencyCode != null && supportedCurrencies.containsKey(currencyCode)) {
      selectedCurrency = currencyCode;
    }
    notifyListeners();
  }

  CurrencyInfo get currentCurrencyInfo =>
      supportedCurrencies[selectedCurrency] ?? supportedCurrencies['INR']!;

  String formatPrice(double priceInr) {
    final cur = currentCurrencyInfo;
    if (cur.code == 'INR') {
      return '₹${NumberFormat('#,##0').format(priceInr.round())}';
    }
    final converted = priceInr * cur.rate;
    return '${cur.symbol}${NumberFormat('#,##0').format(converted.round())}';
  }

  // Pre-configured demo passwords map
  final Map<String, String> demoPasswords = {
    'master@mypt.com': 'master',
    'aayush@mypt.com': 'admin123',
    'himani@mypt.com': 'admin123',
    'sourabh@mypt.com': 'client123',
    'rk@mypt.com': 'client123',
    'odin@mypt.com': 'client123',
    'rincy@mypt.com': 'trainer123',
    'kumar@mypt.com': 'trainer123',
    'neeli@mypt.com': 'lead123',
    'khushboo@mypt.com': 'coachclient123',
    'sarah@mypt.com': 'client123',
    'alex@mypt.com': 'coach123',
    'marcus@mypt.com': 'head123',
    'elena@mypt.com': 'manager123',
    'admin@mypt.com': 'admin123',
  };

  // Pre-configured demo accounts
  final Map<String, UserModel> demoAccounts = {
    'master@mypt.com': UserModel(
      id: 'usr_master',
      name: 'Master Admin',
      email: 'master@mypt.com',
      role: UserRole.superAdmin,
      currentWeight: 75.0,
      startingWeight: 80.0,
      ptCredits: 99,
      goal: 'Master Control & Complete Testing',
      headCoachId: 'usr_neeli',
      trainerId: 'usr_rincy',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
      dualRoles: [
        UserRole.superAdmin,
        UserRole.headCoach,
        UserRole.gymMgr,
        UserRole.coach,
        UserRole.client,
      ],
    ),
    'aayush@mypt.com': UserModel(
      id: 'usr_aayush',
      name: 'Aayush',
      email: 'aayush@mypt.com',
      role: UserRole.superAdmin,
    ),
    'himani@mypt.com': UserModel(
      id: 'usr_himani',
      name: 'Himani',
      email: 'himani@mypt.com',
      role: UserRole.superAdmin,
    ),
    'sourabh@mypt.com': UserModel(
      id: 'usr_sourabh',
      name: 'Sourabh',
      email: 'sourabh@mypt.com',
      role: UserRole.client,
      currentWeight: 72.0,
      startingWeight: 75.0,
      ptCredits: 4,
      goal: 'Lean Muscle & Core',
      trainerId: 'usr_rincy',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    'rk@mypt.com': UserModel(
      id: 'usr_rk',
      name: 'RK',
      email: 'rk@mypt.com',
      role: UserRole.client,
      currentWeight: 78.5,
      startingWeight: 82.0,
      ptCredits: 6,
      goal: 'Hypertrophy & Mobility',
      trainerId: 'usr_kumar',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    'odin@mypt.com': UserModel(
      id: 'usr_odin',
      name: 'Odin',
      email: 'odin@mypt.com',
      role: UserRole.client,
      currentWeight: 85.0,
      startingWeight: 90.0,
      ptCredits: 8,
      goal: 'Power & Strength',
      trainerId: 'trn_alex',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    'newclient@mypt.com': UserModel(
      id: 'usr_new_client',
      name: 'New Trainee',
      email: 'newclient@mypt.com',
      role: UserRole.client,
      currentWeight: 70.0,
      startingWeight: 74.0,
      ptCredits: 4,
      goal: 'General Fitness & Muscle Gain',
      trainerId: null,
      trainerApprovalStatus: TrainerApprovalStatus.none,
    ),
    'rincy@mypt.com': UserModel(
      id: 'usr_rincy',
      name: 'Rincy',
      email: 'rincy@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
    ),
    'kumar@mypt.com': UserModel(
      id: 'usr_kumar',
      name: 'Kumar',
      email: 'kumar@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
    ),
    'neeli@mypt.com': UserModel(
      id: 'usr_neeli',
      name: 'Neeli',
      email: 'neeli@mypt.com',
      role: UserRole.headCoach,
      dualRoles: [UserRole.headCoach, UserRole.gymMgr],
    ),
    'khushboo@mypt.com': UserModel(
      id: 'usr_khushboo',
      name: 'Khushboo',
      email: 'khushboo@mypt.com',
      role: UserRole.coach,
      currentWeight: 56.0,
      startingWeight: 59.0,
      ptCredits: 5,
      goal: 'Athletic Conditioning & Hypertrophy',
      headCoachId: 'usr_neeli',
      dualRoles: [UserRole.coach, UserRole.client],
    ),
    'sarah@mypt.com': UserModel(
      id: 'usr_sarah',
      name: 'Sarah Jenkins',
      email: 'sarah@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      startingWeight: 68.0,
      ptCredits: 4,
      goal: 'Fat Loss & Hypertrophy',
      trainerId: 'trn_alex',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    'alex@mypt.com': UserModel(
      id: 'trn_alex',
      name: 'Alex Rivera',
      email: 'alex@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
    ),
    'marcus@mypt.com': UserModel(
      id: 'trn_marcus',
      name: 'Marcus Vance',
      email: 'marcus@mypt.com',
      role: UserRole.headCoach,
    ),
    'elena@mypt.com': UserModel(
      id: 'mgr_elena',
      name: 'Elena Rostova',
      email: 'elena@mypt.com',
      role: UserRole.gymMgr,
      headCoachId: 'trn_marcus',
    ),
    'admin@mypt.com': UserModel(
      id: 'adm_root',
      name: 'Elena Admin',
      email: 'admin@mypt.com',
      role: UserRole.superAdmin,
    ),
  };

  List<UserModel> allTrainers = [
    UserModel(
      id: 'usr_rincy',
      name: 'Rincy',
      email: 'rincy@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
    ),
    UserModel(
      id: 'usr_kumar',
      name: 'Kumar',
      email: 'kumar@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
    ),
    UserModel(
      id: 'usr_khushboo',
      name: 'Khushboo',
      email: 'khushboo@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
      dualRoles: [UserRole.coach, UserRole.client],
    ),
    UserModel(
      id: 'trn_alex',
      name: 'Alex Rivera',
      email: 'alex@mypt.com',
      role: UserRole.coach,
      headCoachId: 'usr_neeli',
    ),
    UserModel(
      id: 'trn_elena',
      name: 'Elena Rostova',
      email: 'elena.coach@mypt.com',
      role: UserRole.coach,
      headCoachId: 'trn_marcus',
    ),
  ];

  List<UserModel> rosterClients = [
    UserModel(
      id: 'usr_sourabh',
      name: 'Sourabh',
      email: 'sourabh@mypt.com',
      role: UserRole.client,
      currentWeight: 72.0,
      startingWeight: 75.0,
      ptCredits: 4,
      goal: 'Lean Muscle & Core',
      trainerId: 'usr_rincy',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    UserModel(
      id: 'usr_rk',
      name: 'RK',
      email: 'rk@mypt.com',
      role: UserRole.client,
      currentWeight: 78.5,
      startingWeight: 82.0,
      ptCredits: 6,
      goal: 'Hypertrophy & Mobility',
      trainerId: 'usr_kumar',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    UserModel(
      id: 'usr_odin',
      name: 'Odin',
      email: 'odin@mypt.com',
      role: UserRole.client,
      currentWeight: 85.0,
      startingWeight: 90.0,
      ptCredits: 8,
      goal: 'Power & Strength',
      trainerId: 'trn_alex',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
    UserModel(
      id: 'usr_new_client',
      name: 'New Trainee',
      email: 'newclient@mypt.com',
      role: UserRole.client,
      currentWeight: 70.0,
      startingWeight: 74.0,
      ptCredits: 4,
      goal: 'General Fitness & Muscle Gain',
      trainerId: null,
      trainerApprovalStatus: TrainerApprovalStatus.none,
    ),
    UserModel(
      id: 'usr_sarah',
      name: 'Sarah Jenkins',
      email: 'sarah@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      startingWeight: 68.0,
      ptCredits: 4,
      goal: 'Fat Loss & Hypertrophy',
      trainerId: 'trn_alex',
      trainerApprovalStatus: TrainerApprovalStatus.approved,
    ),
  ];

  List<SessionItem> sessions = [
    SessionItem(
      id: 's1',
      clientName: 'Sarah Jenkins',
      trainerName: 'Alex Rivera',
      date: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '10:00 AM - 11:00 AM',
      focusArea: 'Upper Body Hypertrophy',
      status: RequestStatus.confirmed,
    ),
    SessionItem(
      id: 's4',
      clientName: 'Sourabh',
      trainerName: 'Rincy',
      date: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '10:00 AM - 11:00 AM',
      focusArea: 'Hypertrophy & Form',
      status: RequestStatus.confirmed,
    ),
  ];

  List<ClientRequestItem> trainerRequests = [
    ClientRequestItem(
      id: 'req_1',
      clientName: 'Emma Watson',
      email: 'emma.w@example.com',
      requestType: 'Initial PT Consultation',
      message: 'Looking to start a 12-week hypertrophy program for summer preparation.',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      trainerId: 'trn_alex',
    ),
    ClientRequestItem(
      id: 'req_2',
      clientName: 'Liam Johnson',
      email: 'liam.j@example.com',
      requestType: 'Strength Coaching 1-on-1',
      message: 'Need help increasing my bench press and fixing shoulder stability.',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      trainerId: 'usr_rincy',
    ),
  ];

  // Trainer-Specific Packages
  List<TrainingPackage> packages = [
    // Trainer: Rincy
    TrainingPackage(
      id: 'pkg_rincy_4',
      trainerId: 'usr_rincy',
      trainerName: 'Rincy',
      title: 'Foundation Starter (Rincy)',
      priceInr: 3999.0,
      sessionsCount: 4,
      durationWeeks: 4,
      perks: ['4 x 1-on-1 Private Sessions', 'Personalized Macro Blueprint', 'Weekly Body Stat Scan', 'Form Correction Videos'],
      description: 'Perfect intro to biomechanics and strength foundations with Coach Rincy.',
    ),
    TrainingPackage(
      id: 'pkg_rincy_12',
      trainerId: 'usr_rincy',
      trainerName: 'Rincy',
      title: '12-Week Transformation (Rincy)',
      priceInr: 10999.0,
      sessionsCount: 12,
      durationWeeks: 12,
      perks: ['12 x 1-on-1 Private Sessions', 'Priority WhatsApp Access', '24/7 Form Guard Audits', 'Custom Nutrition & Supplementation'],
      description: 'Comprehensive transformation covering periodized hypertrophy & posture mastery.',
    ),

    // Trainer: Alex Rivera
    TrainingPackage(
      id: 'pkg_alex_4',
      trainerId: 'trn_alex',
      trainerName: 'Alex Rivera',
      title: 'Hypertrophy Kickstart (Alex)',
      priceInr: 4499.0,
      sessionsCount: 4,
      durationWeeks: 4,
      perks: ['4 x 1-on-1 Coaching Sessions', 'Custom AI Meal Plan', 'Weekly Body Composition Scan'],
      description: 'Targeted muscle activation & lifting fundamentals with Coach Alex.',
    ),
    TrainingPackage(
      id: 'pkg_alex_12',
      trainerId: 'trn_alex',
      trainerName: 'Alex Rivera',
      title: '12-Week Body Recomp (Alex)',
      priceInr: 11999.0,
      sessionsCount: 12,
      durationWeeks: 12,
      perks: ['12 x 1-on-1 Coaching Sessions', 'Direct Coach Chat', '24/7 Form Feedback', 'Full Macro Adjustments'],
      description: 'Aggressive fat loss and muscle building routine tailored to your physique.',
    ),

    // Trainer: Kumar
    TrainingPackage(
      id: 'pkg_kumar_4',
      trainerId: 'usr_kumar',
      trainerName: 'Kumar',
      title: 'Power & Form Starter (Kumar)',
      priceInr: 3499.0,
      sessionsCount: 4,
      durationWeeks: 4,
      perks: ['4 x 1-on-1 Powerlifting Sessions', 'Deadlift & Squat Form Check', 'Mobility Warmup Protocols'],
      description: 'Lifting mechanics and raw strength building with Coach Kumar.',
    ),
    TrainingPackage(
      id: 'pkg_kumar_12',
      trainerId: 'usr_kumar',
      trainerName: 'Kumar',
      title: '12-Week Heavy Strength (Kumar)',
      priceInr: 9999.0,
      sessionsCount: 12,
      durationWeeks: 12,
      perks: ['12 x 1-on-1 Powerlifting Sessions', 'Custom RPE Training Splits', 'Joint Health Protocols'],
      description: 'Overcome strength plateaus and master squat, bench, and deadlift.',
    ),

    // Trainer: Khushboo
    TrainingPackage(
      id: 'pkg_khushboo_4',
      trainerId: 'usr_khushboo',
      trainerName: 'Khushboo',
      title: 'Athletic Agility Starter (Khushboo)',
      priceInr: 3799.0,
      sessionsCount: 4,
      durationWeeks: 4,
      perks: ['4 x 1-on-1 Conditioning Sessions', 'Cardio Conditioning Plan', 'Body Fat Tracking'],
      description: 'High-energy fat burning and mobility conditioning with Coach Khushboo.',
    ),
  ];

  List<PackagePurchaseRequest> packagePurchaseRequests = [];

  List<BodyMeasurementEntry> measurementHistory = [
    BodyMeasurementEntry(
      id: 'm1',
      date: DateTime.now().subtract(const Duration(days: 35)),
      weightKg: 68.0,
      bodyFatPercent: 21.5,
      chestCm: 98.0,
      waistCm: 82.0,
      hipsCm: 94.0,
      armsCm: 33.0,
      thighsCm: 58.0,
      notes: 'Initial baseline assessment',
    ),
    BodyMeasurementEntry(
      id: 'm2',
      date: DateTime.now().subtract(const Duration(days: 28)),
      weightKg: 67.2,
      bodyFatPercent: 20.8,
      chestCm: 97.5,
      waistCm: 81.0,
      hipsCm: 93.5,
      armsCm: 33.2,
      thighsCm: 57.5,
      notes: 'Week 1 progress: clean eating on track',
    ),
    BodyMeasurementEntry(
      id: 'm3',
      date: DateTime.now().subtract(const Duration(days: 21)),
      weightKg: 66.5,
      bodyFatPercent: 20.1,
      chestCm: 97.0,
      waistCm: 80.0,
      hipsCm: 93.0,
      armsCm: 33.5,
      thighsCm: 57.0,
      notes: 'Mid-month scan: improved recovery',
    ),
    BodyMeasurementEntry(
      id: 'm4',
      date: DateTime.now().subtract(const Duration(days: 14)),
      weightKg: 65.8,
      bodyFatPercent: 19.4,
      chestCm: 96.5,
      waistCm: 79.2,
      hipsCm: 92.5,
      armsCm: 33.8,
      thighsCm: 56.5,
      notes: 'Strength increasing on compound lifts',
    ),
    BodyMeasurementEntry(
      id: 'm5',
      date: DateTime.now().subtract(const Duration(days: 7)),
      weightKg: 65.1,
      bodyFatPercent: 18.9,
      chestCm: 96.2,
      waistCm: 78.5,
      hipsCm: 92.2,
      armsCm: 34.0,
      thighsCm: 56.2,
      notes: 'Visible abdominal definition appearing',
    ),
    BodyMeasurementEntry(
      id: 'm6',
      date: DateTime.now(),
      weightKg: 64.5,
      bodyFatPercent: 18.2,
      chestCm: 96.0,
      waistCm: 78.0,
      hipsCm: 92.0,
      armsCm: 34.0,
      thighsCm: 56.0,
      notes: 'Current check-in: -3.5 kg total lost!',
    ),
  ];

  List<CustomWorkoutRoutine> customWorkouts = [
    CustomWorkoutRoutine(
      id: 'w1',
      name: 'Upper Body Hypertrophy (Push Focus)',
      focusArea: 'Chest, Shoulders & Triceps',
      phase: 'Phase 1 Active',
      createdBy: 'Coach Alex Rivera',
      isCustom: false,
      exercises: [
        WorkoutExercise(name: 'Barbell Bench Press', sets: '4', reps: '8-10', weight: '75 kg', restSeconds: '90s'),
        WorkoutExercise(name: 'Incline DB Press', sets: '3', reps: '10-12', weight: '26 kg', restSeconds: '60s'),
        WorkoutExercise(name: 'Standing Overhead Press', sets: '3', reps: '8', weight: '45 kg', restSeconds: '90s'),
        WorkoutExercise(name: 'Cable Tricep Pushdowns', sets: '4', reps: '15', weight: '30 kg', restSeconds: '45s'),
        WorkoutExercise(name: 'Hanging Leg Raises', sets: '3', reps: '15', weight: 'Bodyweight', restSeconds: '45s'),
      ],
    ),
    CustomWorkoutRoutine(
      id: 'w2',
      name: 'Lower Body & Squat Biomechanics',
      focusArea: 'Quads, Hamstrings & Glutes',
      phase: 'Phase 1 Active',
      createdBy: 'Coach Alex Rivera',
      isCustom: false,
      exercises: [
        WorkoutExercise(name: 'Barbell Back Squat', sets: '4', reps: '8', weight: '95 kg', restSeconds: '120s'),
        WorkoutExercise(name: 'Romanian Deadlift (RDL)', sets: '3', reps: '10', weight: '70 kg', restSeconds: '90s'),
        WorkoutExercise(name: 'Bulgarian Split Squats', sets: '3', reps: '12 each', weight: '18 kg', restSeconds: '60s'),
        WorkoutExercise(name: 'Standing Calf Raises', sets: '4', reps: '15', weight: '40 kg', restSeconds: '45s'),
      ],
    ),
  ];

  List<ChatMessageItem> chatMessages = [
    ChatMessageItem(
      id: 'msg_1',
      senderName: 'Sourabh',
      receiverName: 'Rincy',
      text: 'Hi Coach Rincy! Looking forward to starting the hypertrophy program.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isFromTrainer: false,
    ),
    ChatMessageItem(
      id: 'msg_2',
      senderName: 'Rincy',
      receiverName: 'Sourabh',
      text: 'Welcome Sourabh! Make sure you stay hydrated and bring lifting shoes for the form audit.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      isFromTrainer: true,
    ),
    ChatMessageItem(
      id: 'msg_3',
      senderName: 'Sarah Jenkins',
      receiverName: 'Alex Rivera',
      text: 'Hey Alex, excited for our session tomorrow at 10 AM!',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isFromTrainer: false,
    ),
    ChatMessageItem(
      id: 'msg_4',
      senderName: 'Alex Rivera',
      receiverName: 'Sarah Jenkins',
      text: 'Great work on the nutrition consistency! See you on the lifting floor.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isFromTrainer: true,
    ),
  ];

  List<AppNotificationItem> notifications = [
    AppNotificationItem(
      id: 'notif_1',
      title: '🇮🇳 Region Set to India (INR ₹)',
      message: 'Default pricing is localized to Indian Rupees (₹). Location set to India.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: 'system',
      isRead: true,
    ),
  ];

  List<MovementItem> movementLibrary = [
    MovementItem(name: 'Barbell Bench Press', primaryMuscle: 'Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Barbell, Bench', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 6-8 reps'),
    MovementItem(name: 'Dumbbell Bench Press', primaryMuscle: 'Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Dumbbells, Bench', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Incline Barbell Bench Press', primaryMuscle: 'Chest', secondaryMuscles: 'Shoulders, Triceps', equipment: 'Barbell, Incline Bench', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 6-8 reps'),
    MovementItem(name: 'Incline Dumbbell Press', primaryMuscle: 'Chest', secondaryMuscles: 'Shoulders, Triceps', equipment: 'Dumbbells, Incline Bench', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Decline Bench Press', primaryMuscle: 'Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Barbell, Decline Bench', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-10 reps'),
    MovementItem(name: 'Chest Press Machine', primaryMuscle: 'Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Machine', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Incline Chest Press Machine', primaryMuscle: 'Chest', secondaryMuscles: 'Shoulders, Triceps', equipment: 'Machine', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Dumbbell Fly', primaryMuscle: 'Chest', secondaryMuscles: 'Shoulders', equipment: 'Dumbbells, Bench', category: 'Strength', movementPattern: 'Fly', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Cable Fly', primaryMuscle: 'Chest', secondaryMuscles: 'Shoulders', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Fly', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Pec Deck Fly', primaryMuscle: 'Chest', secondaryMuscles: 'Shoulders', equipment: 'Machine', category: 'Strength', movementPattern: 'Fly', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Push-Up', primaryMuscle: 'Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Beginner', trackingType: 'Reps', defaultSetsReps: '3 sets x 12-20 reps'),
    MovementItem(name: 'Chest Dips', primaryMuscle: 'Chest', secondaryMuscles: 'Triceps, Shoulders', equipment: 'Dip Station', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Intermediate', trackingType: 'Reps / Added Weight', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Pull-Up', primaryMuscle: 'Back', secondaryMuscles: 'Biceps, Shoulders', equipment: 'Pull-Up Bar', category: 'Strength', movementPattern: 'Vertical Pull', difficulty: 'Intermediate', trackingType: 'Reps / Added Weight', defaultSetsReps: '3-4 sets x 6-10 reps'),
    MovementItem(name: 'Chin-Up', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Pull-Up Bar', category: 'Strength', movementPattern: 'Vertical Pull', difficulty: 'Intermediate', trackingType: 'Reps / Added Weight', defaultSetsReps: '3-4 sets x 6-10 reps'),
    MovementItem(name: 'Lat Pulldown', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Vertical Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Close-Grip Lat Pulldown', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Vertical Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Seated Cable Row', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Barbell Bent-Over Row', primaryMuscle: 'Back', secondaryMuscles: 'Biceps, Lower Back', equipment: 'Barbell', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 6-8 reps'),
    MovementItem(name: 'Single-Arm Dumbbell Row', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Dumbbell, Bench', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'T-Bar Row', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'T-Bar Machine', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-10 reps'),
    MovementItem(name: 'Chest-Supported Row', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Machine or Bench', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Machine Row', primaryMuscle: 'Back', secondaryMuscles: 'Biceps', equipment: 'Machine', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Straight-Arm Pulldown', primaryMuscle: 'Back', secondaryMuscles: 'Triceps', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Vertical Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Back Extension', primaryMuscle: 'Lower Back', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Back Extension Bench', category: 'Strength', movementPattern: 'Hip Extension', difficulty: 'Beginner', trackingType: 'Reps / Added Weight', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Deadlift', primaryMuscle: 'Back', secondaryMuscles: 'Glutes, Hamstrings, Core', equipment: 'Barbell', category: 'Strength', movementPattern: 'Hip Hinge', difficulty: 'Advanced', trackingType: 'Weight + Reps', defaultSetsReps: '3-5 sets x 3-5 reps @ RPE 8.5'),
    MovementItem(name: 'Rack Pull', primaryMuscle: 'Back', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Barbell, Rack', category: 'Strength', movementPattern: 'Hip Hinge', difficulty: 'Advanced', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 4-6 reps'),
    MovementItem(name: 'Barbell Overhead Press', primaryMuscle: 'Shoulders', secondaryMuscles: 'Triceps, Core', equipment: 'Barbell', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 5-8 reps'),
    MovementItem(name: 'Dumbbell Shoulder Press', primaryMuscle: 'Shoulders', secondaryMuscles: 'Triceps', equipment: 'Dumbbells, Bench', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Arnold Press', primaryMuscle: 'Shoulders', secondaryMuscles: 'Triceps', equipment: 'Dumbbells, Bench', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Machine Shoulder Press', primaryMuscle: 'Shoulders', secondaryMuscles: 'Triceps', equipment: 'Machine', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Dumbbell Lateral Raise', primaryMuscle: 'Shoulders', secondaryMuscles: 'Traps', equipment: 'Dumbbells', category: 'Strength', movementPattern: 'Isolation', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Cable Lateral Raise', primaryMuscle: 'Shoulders', secondaryMuscles: 'Traps', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Isolation', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Dumbbell Front Raise', primaryMuscle: 'Shoulders', secondaryMuscles: 'Chest', equipment: 'Dumbbells', category: 'Strength', movementPattern: 'Isolation', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Rear Delt Fly', primaryMuscle: 'Shoulders', secondaryMuscles: 'Upper Back', equipment: 'Dumbbells or Machine', category: 'Strength', movementPattern: 'Isolation', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Reverse Pec Deck', primaryMuscle: 'Shoulders', secondaryMuscles: 'Upper Back', equipment: 'Machine', category: 'Strength', movementPattern: 'Isolation', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Face Pull', primaryMuscle: 'Shoulders', secondaryMuscles: 'Upper Back, Biceps', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Horizontal Pull', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 15-20 reps'),
    MovementItem(name: 'Upright Row', primaryMuscle: 'Shoulders', secondaryMuscles: 'Traps, Biceps', equipment: 'Barbell or Cable', category: 'Strength', movementPattern: 'Vertical Pull', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Barbell Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Barbell', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-10 reps'),
    MovementItem(name: 'EZ Bar Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'EZ Bar', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Dumbbell Bicep Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Dumbbells', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Alternating Dumbbell Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Dumbbells', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Hammer Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Dumbbells', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Incline Dumbbell Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Dumbbells, Incline Bench', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Concentration Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Dumbbell', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Preacher Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'EZ Bar or Machine', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Cable Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Rope Hammer Curl', primaryMuscle: 'Biceps', secondaryMuscles: 'Forearms', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Elbow Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Tricep Pushdown', primaryMuscle: 'Triceps', secondaryMuscles: 'Forearms', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Rope Tricep Pushdown', primaryMuscle: 'Triceps', secondaryMuscles: 'Forearms', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Overhead Cable Tricep Extension', primaryMuscle: 'Triceps', secondaryMuscles: 'Shoulders', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Dumbbell Overhead Tricep Extension', primaryMuscle: 'Triceps', secondaryMuscles: 'Shoulders', equipment: 'Dumbbell', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Skull Crusher', primaryMuscle: 'Triceps', secondaryMuscles: 'Forearms', equipment: 'EZ Bar or Dumbbells', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Close-Grip Bench Press', primaryMuscle: 'Triceps', secondaryMuscles: 'Chest, Shoulders', equipment: 'Barbell, Bench', category: 'Strength', movementPattern: 'Horizontal Push', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 6-8 reps'),
    MovementItem(name: 'Bench Dip', primaryMuscle: 'Triceps', secondaryMuscles: 'Shoulders', equipment: 'Bench', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Beginner', trackingType: 'Reps', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Tricep Dip', primaryMuscle: 'Triceps', secondaryMuscles: 'Chest, Shoulders', equipment: 'Dip Station', category: 'Strength', movementPattern: 'Vertical Push', difficulty: 'Intermediate', trackingType: 'Reps / Added Weight', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Dumbbell Tricep Kickback', primaryMuscle: 'Triceps', secondaryMuscles: 'Shoulders', equipment: 'Dumbbell', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Machine Tricep Extension', primaryMuscle: 'Triceps', secondaryMuscles: 'Forearms', equipment: 'Machine', category: 'Strength', movementPattern: 'Elbow Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Barbell Back Squat', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Hamstrings, Core', equipment: 'Barbell, Rack', category: 'Strength', movementPattern: 'Squat', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 6-8 reps @ RPE 8'),
    MovementItem(name: 'Front Squat', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Core', equipment: 'Barbell', category: 'Strength', movementPattern: 'Squat', difficulty: 'Advanced', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 5-8 reps'),
    MovementItem(name: 'Goblet Squat', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Core', equipment: 'Dumbbell or Kettlebell', category: 'Strength', movementPattern: 'Squat', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Leg Press', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Machine', category: 'Strength', movementPattern: 'Squat', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Hack Squat', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes', equipment: 'Machine', category: 'Strength', movementPattern: 'Squat', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Leg Extension', primaryMuscle: 'Quadriceps', secondaryMuscles: 'None', equipment: 'Machine', category: 'Strength', movementPattern: 'Knee Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Bulgarian Split Squat', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Dumbbells, Bench', category: 'Strength', movementPattern: 'Single-Leg Squat', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 8-10 reps / leg'),
    MovementItem(name: 'Walking Lunge', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Bodyweight or Dumbbells', category: 'Strength', movementPattern: 'Lunge', difficulty: 'Beginner', trackingType: 'Reps / Weight', defaultSetsReps: '3 sets x 10-12 steps / leg'),
    MovementItem(name: 'Reverse Lunge', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Bodyweight or Dumbbells', category: 'Strength', movementPattern: 'Lunge', difficulty: 'Beginner', trackingType: 'Reps / Weight', defaultSetsReps: '3 sets x 10-12 reps / leg'),
    MovementItem(name: 'Step-Up', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes, Hamstrings', equipment: 'Bench, Dumbbells', category: 'Strength', movementPattern: 'Single-Leg', difficulty: 'Beginner', trackingType: 'Reps / Weight', defaultSetsReps: '3 sets x 10-12 reps / leg'),
    MovementItem(name: 'Smith Machine Squat', primaryMuscle: 'Quadriceps', secondaryMuscles: 'Glutes', equipment: 'Smith Machine', category: 'Strength', movementPattern: 'Squat', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-10 reps'),
    MovementItem(name: 'Romanian Deadlift', primaryMuscle: 'Hamstrings', secondaryMuscles: 'Glutes, Lower Back', equipment: 'Barbell or Dumbbells', category: 'Strength', movementPattern: 'Hip Hinge', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-10 reps'),
    MovementItem(name: 'Stiff-Leg Deadlift', primaryMuscle: 'Hamstrings', secondaryMuscles: 'Glutes, Lower Back', equipment: 'Barbell', category: 'Strength', movementPattern: 'Hip Hinge', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-10 reps'),
    MovementItem(name: 'Lying Leg Curl', primaryMuscle: 'Hamstrings', secondaryMuscles: 'Calves', equipment: 'Machine', category: 'Strength', movementPattern: 'Knee Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Seated Leg Curl', primaryMuscle: 'Hamstrings', secondaryMuscles: 'Calves', equipment: 'Machine', category: 'Strength', movementPattern: 'Knee Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 10-12 reps'),
    MovementItem(name: 'Nordic Hamstring Curl', primaryMuscle: 'Hamstrings', secondaryMuscles: 'Glutes', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Knee Flexion', difficulty: 'Advanced', trackingType: 'Reps', defaultSetsReps: '3 sets x 5-8 reps'),
    MovementItem(name: 'Good Morning', primaryMuscle: 'Hamstrings', secondaryMuscles: 'Glutes, Lower Back', equipment: 'Barbell', category: 'Strength', movementPattern: 'Hip Hinge', difficulty: 'Intermediate', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 8-10 reps'),
    MovementItem(name: 'Barbell Hip Thrust', primaryMuscle: 'Glutes', secondaryMuscles: 'Hamstrings, Quadriceps', equipment: 'Barbell, Bench', category: 'Strength', movementPattern: 'Hip Thrust', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 8-12 reps'),
    MovementItem(name: 'Glute Bridge', primaryMuscle: 'Glutes', secondaryMuscles: 'Hamstrings', equipment: 'Bodyweight or Barbell', category: 'Strength', movementPattern: 'Hip Thrust', difficulty: 'Beginner', trackingType: 'Reps / Weight', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Cable Glute Kickback', primaryMuscle: 'Glutes', secondaryMuscles: 'Hamstrings', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Hip Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3 sets x 12-15 reps / leg'),
    MovementItem(name: 'Cable Pull-Through', primaryMuscle: 'Glutes', secondaryMuscles: 'Hamstrings', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Hip Hinge', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Hip Abduction Machine', primaryMuscle: 'Glutes', secondaryMuscles: 'Hip Abductors', equipment: 'Machine', category: 'Strength', movementPattern: 'Hip Abduction', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 15-20 reps'),
    MovementItem(name: 'Standing Calf Raise', primaryMuscle: 'Calves', secondaryMuscles: 'None', equipment: 'Machine or Bodyweight', category: 'Strength', movementPattern: 'Ankle Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Seated Calf Raise', primaryMuscle: 'Calves', secondaryMuscles: 'None', equipment: 'Machine', category: 'Strength', movementPattern: 'Ankle Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 15-20 reps'),
    MovementItem(name: 'Leg Press Calf Raise', primaryMuscle: 'Calves', secondaryMuscles: 'None', equipment: 'Leg Press Machine', category: 'Strength', movementPattern: 'Ankle Extension', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Single-Leg Calf Raise', primaryMuscle: 'Calves', secondaryMuscles: 'None', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Ankle Extension', difficulty: 'Beginner', trackingType: 'Reps / Added Weight', defaultSetsReps: '3 sets x 15 reps / leg'),
    MovementItem(name: 'Crunch', primaryMuscle: 'Abdominals', secondaryMuscles: 'Hip Flexors', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Trunk Flexion', difficulty: 'Beginner', trackingType: 'Reps', defaultSetsReps: '3 sets x 15-20 reps'),
    MovementItem(name: 'Cable Crunch', primaryMuscle: 'Abdominals', secondaryMuscles: 'Hip Flexors', equipment: 'Cable Machine', category: 'Strength', movementPattern: 'Trunk Flexion', difficulty: 'Beginner', trackingType: 'Weight + Reps', defaultSetsReps: '3-4 sets x 12-15 reps'),
    MovementItem(name: 'Decline Crunch', primaryMuscle: 'Abdominals', secondaryMuscles: 'Hip Flexors', equipment: 'Decline Bench', category: 'Strength', movementPattern: 'Trunk Flexion', difficulty: 'Intermediate', trackingType: 'Reps / Added Weight', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Hanging Leg Raise', primaryMuscle: 'Abdominals', secondaryMuscles: 'Hip Flexors, Forearms', equipment: 'Pull-Up Bar', category: 'Strength', movementPattern: 'Hip Flexion', difficulty: 'Intermediate', trackingType: 'Reps', defaultSetsReps: '3-4 sets x 10-15 reps'),
    MovementItem(name: 'Lying Leg Raise', primaryMuscle: 'Abdominals', secondaryMuscles: 'Hip Flexors', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Hip Flexion', difficulty: 'Beginner', trackingType: 'Reps', defaultSetsReps: '3 sets x 12-15 reps'),
    MovementItem(name: 'Plank', primaryMuscle: 'Abdominals', secondaryMuscles: 'Shoulders, Glutes', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Anti-Extension', difficulty: 'Beginner', trackingType: 'Duration', defaultSetsReps: '3 sets x 45-60 sec'),
    MovementItem(name: 'Side Plank', primaryMuscle: 'Obliques', secondaryMuscles: 'Shoulders, Glutes', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Anti-Lateral Flexion', difficulty: 'Beginner', trackingType: 'Duration', defaultSetsReps: '3 sets x 30-45 sec / side'),
    MovementItem(name: 'Russian Twist', primaryMuscle: 'Obliques', secondaryMuscles: 'Abdominals, Hip Flexors', equipment: 'Bodyweight or Weight', category: 'Strength', movementPattern: 'Rotation', difficulty: 'Beginner', trackingType: 'Reps / Weight', defaultSetsReps: '3 sets x 20 total reps'),
    MovementItem(name: 'Bicycle Crunch', primaryMuscle: 'Abdominals', secondaryMuscles: 'Obliques, Hip Flexors', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Trunk Flexion', difficulty: 'Beginner', trackingType: 'Reps', defaultSetsReps: '3 sets x 20 total reps'),
    MovementItem(name: 'Ab Wheel Rollout', primaryMuscle: 'Abdominals', secondaryMuscles: 'Shoulders, Lats', equipment: 'Ab Wheel', category: 'Strength', movementPattern: 'Anti-Extension', difficulty: 'Intermediate', trackingType: 'Reps', defaultSetsReps: '3 sets x 8-12 reps'),
    MovementItem(name: 'Dead Bug', primaryMuscle: 'Abdominals', secondaryMuscles: 'Hip Flexors', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Core Stability', difficulty: 'Beginner', trackingType: 'Reps', defaultSetsReps: '3 sets x 10-12 reps / side'),
    MovementItem(name: 'Mountain Climber', primaryMuscle: 'Abdominals', secondaryMuscles: 'Shoulders, Hip Flexors', equipment: 'Bodyweight', category: 'Strength', movementPattern: 'Core Stability', difficulty: 'Beginner', trackingType: 'Reps / Duration', defaultSetsReps: '3 sets x 30-45 sec'),
    MovementItem(name: 'Treadmill Walk', primaryMuscle: 'Full Body', secondaryMuscles: 'Legs', equipment: 'Treadmill', category: 'Cardio', movementPattern: 'Walking', difficulty: 'Beginner', trackingType: 'Duration + Distance', defaultSetsReps: '20-30 mins @ Incline 4-8%'),
    MovementItem(name: 'Treadmill Run', primaryMuscle: 'Full Body', secondaryMuscles: 'Legs', equipment: 'Treadmill', category: 'Cardio', movementPattern: 'Running', difficulty: 'Intermediate', trackingType: 'Duration + Distance', defaultSetsReps: '15-25 mins (Intervals or Steady)'),
    MovementItem(name: 'Stationary Bike', primaryMuscle: 'Legs', secondaryMuscles: 'Glutes, Calves', equipment: 'Stationary Bike', category: 'Cardio', movementPattern: 'Cycling', difficulty: 'Beginner', trackingType: 'Duration + Distance', defaultSetsReps: '20-30 mins @ Moderate Resistance'),
    MovementItem(name: 'Elliptical', primaryMuscle: 'Full Body', secondaryMuscles: 'Legs, Arms', equipment: 'Elliptical Machine', category: 'Cardio', movementPattern: 'Cross Training', difficulty: 'Beginner', trackingType: 'Duration + Distance', defaultSetsReps: '20-30 mins @ Zone 2 Heart Rate'),
    MovementItem(name: 'Stair Climber', primaryMuscle: 'Legs', secondaryMuscles: 'Glutes, Calves', equipment: 'Stair Climber', category: 'Cardio', movementPattern: 'Climbing', difficulty: 'Intermediate', trackingType: 'Duration + Floors', defaultSetsReps: '15-20 mins (Level 5-8)'),
    MovementItem(name: 'Rowing Machine', primaryMuscle: 'Back', secondaryMuscles: 'Legs, Arms, Core', equipment: 'Rowing Machine', category: 'Cardio', movementPattern: 'Rowing', difficulty: 'Beginner', trackingType: 'Duration + Distance', defaultSetsReps: '15-20 mins (500m Splits)'),
    MovementItem(name: 'Jump Rope', primaryMuscle: 'Full Body', secondaryMuscles: 'Calves, Shoulders', equipment: 'Jump Rope', category: 'Cardio', movementPattern: 'Jumping', difficulty: 'Intermediate', trackingType: 'Duration / Reps', defaultSetsReps: '5 rounds x 1-2 mins'),
    MovementItem(name: 'Burpee', primaryMuscle: 'Full Body', secondaryMuscles: 'Chest, Legs, Shoulders', equipment: 'Bodyweight', category: 'Conditioning', movementPattern: 'Full Body', difficulty: 'Intermediate', trackingType: 'Reps', defaultSetsReps: '3-4 sets x 10-15 reps'),
    MovementItem(name: 'Battle Rope', primaryMuscle: 'Shoulders', secondaryMuscles: 'Arms, Core', equipment: 'Battle Ropes', category: 'Conditioning', movementPattern: 'Full Body', difficulty: 'Intermediate', trackingType: 'Duration', defaultSetsReps: '4-6 rounds x 30 sec work / 30 sec rest'),
  ];

  void addMovementItem(MovementItem item) {
    movementLibrary.insert(0, item);
    notifyListeners();
  }

  void updateMovementItem(int index, MovementItem item) {
    if (index >= 0 && index < movementLibrary.length) {
      movementLibrary[index] = item;
      notifyListeners();
    }
  }

  void deleteMovementItem(int index) {
    if (index >= 0 && index < movementLibrary.length) {
      movementLibrary.removeAt(index);
      notifyListeners();
    }
  }

  Map<String, bool> globalFlags = {
    'ai_fitness_copilot': true,
    'bento_analytics_grid': true,
    'strict_headcoach_hierarchy': true,
    'dynamic_currency_converter': true,
    'instant_package_checkout': true,
  };

  // --- HIERARCHY METHODS ---
  List<UserModel> get allClients => rosterClients;

  List<UserModel> getTrainersForHeadCoach(String headCoachId) {
    return allTrainers.where((t) => t.headCoachId == headCoachId).toList();
  }

  List<UserModel> getClientsForTrainer(String trainerId) {
    return rosterClients.where((c) => c.trainerId == trainerId).toList();
  }

  // --- COACH SELECTION WORKFLOW ---
  void selectPrimaryTrainer(UserModel coach) {
    if (currentUser == null) return;
    currentUser!.trainerId = coach.id;
    currentUser!.trainerApprovalStatus = TrainerApprovalStatus.approved;

    for (final c in rosterClients) {
      if (c.id == currentUser!.id || c.email.toLowerCase() == currentUser!.email.toLowerCase()) {
        c.trainerId = coach.id;
        c.trainerApprovalStatus = TrainerApprovalStatus.approved;
        break;
      }
    }

    addNotification(
      title: '🎉 Coach ${coach.name} Selected as Primary Trainer',
      message: 'You have connected with Coach ${coach.name}. You can now schedule 1-on-1 sessions, follow custom workouts, and message your coach.',
      recipientName: currentUser!.name,
      recipientRole: UserRole.client,
      type: 'approval',
    );

    addNotification(
      title: '👤 New Trainee Assigned: ${currentUser!.name}',
      message: '${currentUser!.name} selected you as their primary trainer.',
      recipientName: coach.name,
      recipientRole: UserRole.coach,
      type: 'booking',
    );

    notifyListeners();
  }

  // --- PACKAGES & PURCHASES ---
  List<TrainingPackage> getPackagesForTrainer(String? trainerId) {
    if (trainerId == null) return [];
    return packages.where((p) => p.trainerId == trainerId).toList();
  }

  void addOrUpdateTrainerPackage(TrainingPackage pkg) {
    final idx = packages.indexWhere((p) => p.id == pkg.id);
    if (idx >= 0) {
      packages[idx] = pkg;
    } else {
      packages.add(pkg);
    }
    notifyListeners();
  }

  void deleteTrainerPackage(String pkgId) {
    packages.removeWhere((p) => p.id == pkgId);
    notifyListeners();
  }

  void requestPackagePurchase(TrainingPackage pkg, String paymentMethod) {
    if (currentUser == null) return;
    final isOffline = paymentMethod == 'offline';

    final req = PackagePurchaseRequest(
      id: 'ppr_${DateTime.now().millisecondsSinceEpoch}',
      clientId: currentUser!.id,
      clientName: currentUser!.name,
      trainerId: pkg.trainerId ?? '',
      trainerName: pkg.trainerName ?? 'Coach',
      packageId: pkg.id,
      packageTitle: pkg.title,
      priceInr: pkg.priceInr,
      sessionsCount: pkg.sessionsCount,
      paymentMethod: paymentMethod,
      status: isOffline ? RequestStatus.pending : RequestStatus.confirmed,
      createdAt: DateTime.now(),
    );

    packagePurchaseRequests.add(req);

    if (isOffline) {
      addNotification(
        title: '💵 Offline Payment Request from ${currentUser!.name}',
        message: '${currentUser!.name} requested to purchase "${pkg.title}" (${formatPrice(pkg.priceInr)}). Confirm payment to credit +${pkg.sessionsCount} PT Credits.',
        recipientName: pkg.trainerName,
        recipientRole: UserRole.coach,
        type: 'payment',
      );

      addNotification(
        title: '⏳ Offline Payment Request Sent',
        message: 'Your request for "${pkg.title}" was sent to Coach ${pkg.trainerName}. Once Coach confirms receipt, +${pkg.sessionsCount} PT Credits will be added.',
        recipientName: currentUser!.name,
        recipientRole: UserRole.client,
        type: 'payment',
      );
    } else {
      currentUser!.ptCredits += pkg.sessionsCount;
      addNotification(
        title: '🎉 Package Activated (+${pkg.sessionsCount} PT Credits)',
        message: 'Online payment of ${formatPrice(pkg.priceInr)} successful for ${pkg.title}. Total balance: ${currentUser!.ptCredits} PT Credits.',
        recipientName: currentUser!.name,
        recipientRole: UserRole.client,
        type: 'payment',
      );
    }

    notifyListeners();
  }

  void approvePackagePurchase(PackagePurchaseRequest req) {
    req.status = RequestStatus.confirmed;

    UserModel? client;
    for (final c in rosterClients) {
      if (c.id == req.clientId || c.name.toLowerCase() == req.clientName.toLowerCase()) {
        client = c;
        break;
      }
    }
    if (client == null && currentUser?.id == req.clientId) {
      client = currentUser;
    }

    if (client != null) {
      client.ptCredits += req.sessionsCount;
    }

    addNotification(
      title: '🎉 Payment Confirmed (+${req.sessionsCount} PT Credits)',
      message: 'Coach ${req.trainerName} confirmed payment for "${req.packageTitle}". +${req.sessionsCount} PT Credits added to your balance!',
      recipientName: req.clientName,
      recipientRole: UserRole.client,
      type: 'payment',
    );

    notifyListeners();
  }

  void declinePackagePurchase(PackagePurchaseRequest req) {
    req.status = RequestStatus.cancelled;

    addNotification(
      title: '❌ Payment Request Declined',
      message: 'Coach ${req.trainerName} was unable to confirm payment for "${req.packageTitle}". Please contact your coach.',
      recipientName: req.clientName,
      recipientRole: UserRole.client,
      type: 'warning',
    );

    notifyListeners();
  }

  // --- MEASUREMENTS ---
  void addMeasurement(BodyMeasurementEntry entry) {
    measurementHistory.insert(0, entry);
    if (currentUser != null) {
      currentUser!.currentWeight = entry.weightKg;
    }
    notifyListeners();
  }

  // --- WORKOUTS ---
  List<WorkoutSessionLog> workoutHistory = [
    WorkoutSessionLog(
      id: 'sess_prev_1',
      routineName: 'Upper Body Hypertrophy (Push Focus)',
      focusArea: 'Chest, Shoulders & Triceps',
      completedAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      durationMinutes: 48,
      totalVolumeKg: 8520,
      loggedBy: 'You',
      exercises: [
        WorkoutExercise(
          name: 'Barbell Bench Press',
          sets: '4',
          reps: '8',
          weight: '70 kg',
          restSeconds: '90s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 70, reps: 8, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 70, reps: 8, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 70, reps: 8, isCompleted: true),
            SetDetail(setNumber: 4, weightKg: 70, reps: 8, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Incline DB Press',
          sets: '3',
          reps: '10',
          weight: '24 kg',
          restSeconds: '60s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 24, reps: 10, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 24, reps: 10, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 24, reps: 10, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Standing Overhead Press',
          sets: '3',
          reps: '8',
          weight: '42.5 kg',
          restSeconds: '90s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 42.5, reps: 8, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 42.5, reps: 8, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 42.5, reps: 8, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Cable Tricep Pushdowns',
          sets: '4',
          reps: '15',
          weight: '28 kg',
          restSeconds: '45s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 28, reps: 15, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 28, reps: 15, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 28, reps: 15, isCompleted: true),
            SetDetail(setNumber: 4, weightKg: 28, reps: 15, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Hanging Leg Raises',
          sets: '3',
          reps: '15',
          weight: 'Bodyweight',
          restSeconds: '45s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 70, reps: 15, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 70, reps: 15, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 70, reps: 15, isCompleted: true),
          ],
        ),
      ],
    ),
    WorkoutSessionLog(
      id: 'sess_prev_2',
      routineName: 'Upper Body Hypertrophy (Push Focus)',
      focusArea: 'Chest, Shoulders & Triceps',
      completedAt: DateTime.now().subtract(const Duration(days: 7, hours: 3)),
      durationMinutes: 45,
      totalVolumeKg: 7920,
      loggedBy: 'You',
      exercises: [
        WorkoutExercise(
          name: 'Barbell Bench Press',
          sets: '4',
          reps: '8',
          weight: '67.5 kg',
          restSeconds: '90s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 67.5, reps: 8, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 67.5, reps: 8, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 67.5, reps: 8, isCompleted: true),
            SetDetail(setNumber: 4, weightKg: 67.5, reps: 8, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Incline DB Press',
          sets: '3',
          reps: '10',
          weight: '22 kg',
          restSeconds: '60s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 22, reps: 10, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 22, reps: 10, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 22, reps: 10, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Standing Overhead Press',
          sets: '3',
          reps: '8',
          weight: '40 kg',
          restSeconds: '90s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 40, reps: 8, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 40, reps: 8, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 40, reps: 8, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Cable Tricep Pushdowns',
          sets: '4',
          reps: '15',
          weight: '25 kg',
          restSeconds: '45s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 25, reps: 15, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 25, reps: 15, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 25, reps: 15, isCompleted: true),
            SetDetail(setNumber: 4, weightKg: 25, reps: 15, isCompleted: true),
          ],
        ),
      ],
    ),
    WorkoutSessionLog(
      id: 'sess_prev_3',
      routineName: 'Lower Body & Squat Biomechanics',
      focusArea: 'Quads, Hamstrings & Glutes',
      completedAt: DateTime.now().subtract(const Duration(days: 5, hours: 4)),
      durationMinutes: 52,
      totalVolumeKg: 7506,
      loggedBy: 'You',
      exercises: [
        WorkoutExercise(
          name: 'Barbell Back Squat',
          sets: '4',
          reps: '8',
          weight: '90 kg',
          restSeconds: '120s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 90, reps: 8, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 90, reps: 8, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 90, reps: 8, isCompleted: true),
            SetDetail(setNumber: 4, weightKg: 90, reps: 8, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Romanian Deadlift (RDL)',
          sets: '3',
          reps: '10',
          weight: '65 kg',
          restSeconds: '90s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 65, reps: 10, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 65, reps: 10, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 65, reps: 10, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Bulgarian Split Squats',
          sets: '3',
          reps: '12',
          weight: '16 kg',
          restSeconds: '60s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 16, reps: 12, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 16, reps: 12, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 16, reps: 12, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          name: 'Standing Calf Raises',
          sets: '4',
          reps: '15',
          weight: '35 kg',
          restSeconds: '45s',
          isCompleted: true,
          setDetails: [
            SetDetail(setNumber: 1, weightKg: 35, reps: 15, isCompleted: true),
            SetDetail(setNumber: 2, weightKg: 35, reps: 15, isCompleted: true),
            SetDetail(setNumber: 3, weightKg: 35, reps: 15, isCompleted: true),
            SetDetail(setNumber: 4, weightKg: 35, reps: 15, isCompleted: true),
          ],
        ),
      ],
    ),
  ];

  void addCustomWorkout(CustomWorkoutRoutine routine) {
    customWorkouts.insert(0, routine);
    notifyListeners();
  }

  void saveCompletedWorkoutSession(WorkoutSessionLog session) {
    workoutHistory.insert(0, session);
    notifications.insert(
      0,
      AppNotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: '🔥 Workout Session Saved & Logged!',
        message: 'Great job completing "${session.routineName}"! Total Volume: ${session.totalVolumeKg.toStringAsFixed(0)} kg logged.',
        timestamp: DateTime.now(),
        type: 'system',
      ),
    );
    notifyListeners();
  }

  bool hasSeenOnboarding = false;

  void setHasSeenOnboarding(bool val) {
    hasSeenOnboarding = val;
    notifyListeners();
  }

  bool hasSeenNoTrainerPrompt = false;

  void setHasSeenNoTrainerPrompt(bool val) {
    hasSeenNoTrainerPrompt = val;
    notifyListeners();
  }

  // --- THEME & APPEARANCE ---
  bool isDarkMode = true;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void setIsDarkMode(bool val) {
    if (isDarkMode != val) {
      isDarkMode = val;
      notifyListeners();
    }
  }

  // --- FEATURE FLAGS (SUPER ADMIN) ---
  bool enableExerciseTargetWeight = true;
  bool enableMealPhotoUpload = true;

  void setEnableExerciseTargetWeight(bool val) {
    enableExerciseTargetWeight = val;
    notifyListeners();
  }

  void setEnableMealPhotoUpload(bool val) {
    enableMealPhotoUpload = val;
    notifyListeners();
  }

  // --- SESSIONS & BOOKING ---
  List<SessionItem> getSessionsForUser(UserModel user) {
    List<SessionItem> userSessions;
    if (user.role == UserRole.client) {
      userSessions = sessions.where((s) {
        if (s.clientId != null && s.clientId == user.id) return true;
        return s.clientName.trim().toLowerCase() == user.name.trim().toLowerCase();
      }).toList();
    } else {
      userSessions = sessions.where((s) {
        if (s.trainerId != null && s.trainerId == user.id) return true;
        return s.trainerName.trim().toLowerCase() == user.name.trim().toLowerCase();
      }).toList();
    }

    // Sort upcoming sessions first
    userSessions.sort((a, b) => a.date.compareTo(b.date));
    return userSessions;
  }

  List<ClientRequestItem> getRequestsForUser(UserModel user) {
    if (user.role == UserRole.client) {
      return trainerRequests.where((r) {
        if (r.clientId != null && r.clientId == user.id) return true;
        if (r.email.trim().toLowerCase() == user.email.trim().toLowerCase()) return true;
        return r.clientName.trim().toLowerCase() == user.name.trim().toLowerCase();
      }).toList();
    } else {
      return trainerRequests.where((r) => r.trainerId == user.id || r.trainerId == null).toList();
    }
  }

  void rescheduleSession(SessionItem session, DateTime newDate, String newTimeSlot) {
    session.date = newDate;
    session.timeSlot = newTimeSlot;
    session.status = RequestStatus.confirmed;

    final formatted = DateFormat('EEEE, dd MMMM yyyy').format(newDate);

    addNotification(
      title: '🔄 Session Rescheduled',
      message: 'Your session with Coach ${session.trainerName} was rescheduled to $formatted from $newTimeSlot.',
      recipientName: session.clientName,
      recipientRole: UserRole.client,
      type: 'booking',
      sessionId: session.id,
    );

    addNotification(
      title: '🔄 Session Rescheduled: ${session.clientName}',
      message: 'Session with ${session.clientName} was rescheduled to $formatted from $newTimeSlot.',
      recipientName: session.trainerName,
      recipientRole: UserRole.coach,
      type: 'booking',
      sessionId: session.id,
    );

    notifyListeners();
  }

  void scheduleSession(SessionItem session) {
    session.status = RequestStatus.pending;
    sessions.insert(0, session);

    if (currentUser?.role == UserRole.client && currentUser != null && currentUser!.ptCredits > 0) {
      currentUser!.ptCredits -= 1;
    }

    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(session.date);
    addNotification(
      title: '⏳ Session Request Sent (Pending Coach Approval)',
      message: 'Your 1-on-1 session request ("${session.focusArea}") for $formattedDate from ${session.timeSlot} was sent to Coach ${session.trainerName}. Waiting for coach approval.',
      recipientName: session.clientName,
      recipientRole: UserRole.client,
      type: 'booking',
      sessionId: session.id,
    );

    addNotification(
      title: '📅 New Session Request: ${session.clientName}',
      message: '${session.clientName} requested a 1-on-1 session for $formattedDate from ${session.timeSlot} (Focus: ${session.focusArea}). Please accept, reject, or reschedule.',
      recipientName: session.trainerName,
      recipientRole: UserRole.coach,
      type: 'booking',
      sessionId: session.id,
    );

    notifyListeners();
  }

  void approveSession(SessionItem session) {
    session.status = RequestStatus.confirmed;

    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(session.date);
    addNotification(
      title: '✓ Session Approved by Coach ${session.trainerName}',
      message: 'Coach ${session.trainerName} has accepted and confirmed your 1-on-1 session for $formattedDate from ${session.timeSlot} (Focus: ${session.focusArea})!',
      recipientName: session.clientName,
      recipientRole: UserRole.client,
      type: 'booking',
      sessionId: session.id,
    );

    addNotification(
      title: '✓ Session Confirmed with ${session.clientName}',
      message: 'You confirmed ${session.clientName}\'s 1-on-1 session for $formattedDate from ${session.timeSlot}.',
      recipientName: session.trainerName,
      recipientRole: UserRole.coach,
      type: 'booking',
      sessionId: session.id,
    );

    notifyListeners();
  }

  void rejectSession(SessionItem session, {String? reason}) {
    session.status = RequestStatus.cancelled;

    UserModel? client;
    for (final c in rosterClients) {
      if (c.id == session.clientId || c.name.toLowerCase() == session.clientName.toLowerCase()) {
        client = c;
        break;
      }
    }
    if (client != null) {
      client.ptCredits += 1;
    } else if (currentUser?.name.toLowerCase() == session.clientName.toLowerCase() || currentUser?.id == session.clientId) {
      currentUser?.ptCredits += 1;
    }

    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(session.date);
    addNotification(
      title: '❌ Session Declined by Coach ${session.trainerName} (Credit Refunded)',
      message: 'Coach ${session.trainerName} was unable to accept your booking for $formattedDate at ${session.timeSlot}${reason != null && reason.isNotEmpty ? " (Reason: $reason)" : ""}. 1 PT Credit has been refunded to your balance.',
      recipientName: session.clientName,
      recipientRole: UserRole.client,
      type: 'warning',
      sessionId: session.id,
    );

    addNotification(
      title: '❌ Session Request Declined',
      message: 'You declined ${session.clientName}\'s booking for $formattedDate at ${session.timeSlot}. 1 PT Credit was refunded to the client.',
      recipientName: session.trainerName,
      recipientRole: UserRole.coach,
      type: 'warning',
      sessionId: session.id,
    );

    notifyListeners();
  }

  void cancelSession(SessionItem session) {
    session.status = RequestStatus.cancelled;

    UserModel? client;
    for (final c in rosterClients) {
      if (c.id == session.clientId || c.name.toLowerCase() == session.clientName.toLowerCase()) {
        client = c;
        break;
      }
    }
    if (client != null) {
      client.ptCredits += 1;
    } else if (currentUser?.name.toLowerCase() == session.clientName.toLowerCase() || currentUser?.id == session.clientId) {
      currentUser?.ptCredits += 1;
    }

    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(session.date);
    addNotification(
      title: '❌ Session Cancelled (1 PT Credit Refunded)',
      message: 'Session with Coach ${session.trainerName} for $formattedDate at ${session.timeSlot} was cancelled. 1 PT Credit has been refunded.',
      recipientName: session.clientName,
      recipientRole: UserRole.client,
      type: 'warning',
      sessionId: session.id,
    );

    addNotification(
      title: '❌ Session Cancelled: ${session.clientName}',
      message: '${session.clientName} cancelled their session for $formattedDate at ${session.timeSlot}.',
      recipientName: session.trainerName,
      recipientRole: UserRole.coach,
      type: 'warning',
      sessionId: session.id,
    );

    notifyListeners();
  }

  // --- CONSULTATION REQUEST WORKFLOW ---
  void sendConsultationRequest({
    required UserModel coach,
    required String requestType,
    required String message,
  }) {
    if (currentUser == null) return;

    final req = ClientRequestItem(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      clientId: currentUser!.id,
      clientName: currentUser!.name,
      email: currentUser!.email,
      trainerId: coach.id,
      trainerName: coach.name,
      requestType: requestType,
      message: message,
      date: DateTime.now(),
      status: RequestStatus.pending,
    );

    trainerRequests.insert(0, req);

    // If client does not have an approved trainer, set trainer to pending
    if (currentUser!.trainerId == null || currentUser!.trainerApprovalStatus != TrainerApprovalStatus.approved) {
      currentUser!.trainerId = coach.id;
      currentUser!.trainerApprovalStatus = TrainerApprovalStatus.pending;
      for (final c in rosterClients) {
        if (c.id == currentUser!.id || c.email.toLowerCase() == currentUser!.email.toLowerCase()) {
          c.trainerId = coach.id;
          c.trainerApprovalStatus = TrainerApprovalStatus.pending;
          break;
        }
      }
    }

    addNotification(
      title: '🤝 Consultation Request Sent to Coach ${coach.name}',
      message: 'Your inquiry for "$requestType" was submitted. Coach ${coach.name} will review and respond shortly.',
      recipientName: currentUser!.name,
      recipientRole: UserRole.client,
      type: 'booking',
    );

    addNotification(
      title: '📩 New Consultation Request: ${currentUser!.name}',
      message: '${currentUser!.name} requested a 1-on-1 consultation for "$requestType".',
      recipientName: coach.name,
      recipientRole: UserRole.coach,
      type: 'booking',
    );

    notifyListeners();
  }

  void acceptRequest(ClientRequestItem req) {
    req.status = RequestStatus.confirmed;

    UserModel? client;
    for (final c in rosterClients) {
      if (c.id == req.clientId || c.name.toLowerCase() == req.clientName.toLowerCase() || c.email.toLowerCase() == req.email.toLowerCase()) {
        client = c;
        break;
      }
    }
    if (client == null && currentUser?.id == req.clientId) {
      client = currentUser;
    }

    if (client != null && req.trainerId != null) {
      client.trainerId = req.trainerId;
      client.trainerApprovalStatus = TrainerApprovalStatus.approved;
    }
    if (currentUser != null && (currentUser!.id == req.clientId || currentUser!.email.toLowerCase() == req.email.toLowerCase())) {
      currentUser!.trainerId = req.trainerId;
      currentUser!.trainerApprovalStatus = TrainerApprovalStatus.approved;
    }

    addNotification(
      title: '✓ Consultation Request Accepted!',
      message: 'Coach ${req.trainerName ?? 'your coach'} has accepted your consultation request! You can now book 1-on-1 sessions and message directly.',
      recipientName: req.clientName,
      recipientRole: UserRole.client,
      type: 'approval',
    );

    notifyListeners();
  }

  void declineRequest(ClientRequestItem req, {String reason = 'Coach capacity is currently full for 1-on-1 consultations'}) {
    req.status = RequestStatus.cancelled;
    req.declineReason = reason;

    UserModel? client;
    for (final c in rosterClients) {
      if (c.id == req.clientId || c.name.toLowerCase() == req.clientName.toLowerCase() || c.email.toLowerCase() == req.email.toLowerCase()) {
        client = c;
        break;
      }
    }
    if (client == null && currentUser?.id == req.clientId) {
      client = currentUser;
    }

    if (client != null && client.trainerId == req.trainerId && client.trainerApprovalStatus == TrainerApprovalStatus.pending) {
      client.trainerId = null;
      client.trainerApprovalStatus = TrainerApprovalStatus.none;
    }
    if (currentUser != null && (currentUser!.id == req.clientId || currentUser!.email.toLowerCase() == req.email.toLowerCase())) {
      if (currentUser!.trainerId == req.trainerId && currentUser!.trainerApprovalStatus == TrainerApprovalStatus.pending) {
        currentUser!.trainerId = null;
        currentUser!.trainerApprovalStatus = TrainerApprovalStatus.none;
      }
    }

    addNotification(
      title: 'Consultation Unavailable - Choose Another Coach',
      message: 'Coach ${req.trainerName ?? 'your coach'} was unable to accept your request. Reason: $reason. Tap to explore other certified coaches.',
      recipientName: req.clientName,
      recipientRole: UserRole.client,
      type: 'warning',
    );

    notifyListeners();
  }

  void cancelConsultationRequest(ClientRequestItem req) {
    req.status = RequestStatus.cancelled;
    req.declineReason = 'Cancelled by client';

    if (currentUser != null && currentUser!.trainerId == req.trainerId && currentUser!.trainerApprovalStatus == TrainerApprovalStatus.pending) {
      currentUser!.trainerId = null;
      currentUser!.trainerApprovalStatus = TrainerApprovalStatus.none;
    }

    addNotification(
      title: 'Consultation Request Cancelled',
      message: 'You have cancelled your consultation request with Coach ${req.trainerName ?? 'your coach'}.',
      recipientName: req.clientName,
      recipientRole: UserRole.client,
      type: 'system',
    );

    notifyListeners();
  }

  // --- NOTIFICATIONS ---
  int get unreadNotificationCount {
    if (currentUser == null) return 0;
    return notifications.where((n) {
      if (n.isRead) return false;
      if (n.recipientName != null && n.recipientName!.toLowerCase() != currentUser!.name.toLowerCase()) {
        return false;
      }
      return true;
    }).length;
  }

  List<AppNotificationItem> get currentNotifications {
    if (currentUser == null) return [];
    return notifications.where((n) {
      if (n.recipientName != null && n.recipientName!.toLowerCase() != currentUser!.name.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  void markAllNotificationsRead() {
    for (final n in notifications) {
      if (currentUser == null || n.recipientName == null || n.recipientName!.toLowerCase() == currentUser!.name.toLowerCase()) {
        n.isRead = true;
      }
    }
    notifyListeners();
  }

  void addNotification({
    required String title,
    required String message,
    required String type,
    String? recipientName,
    UserRole? recipientRole,
    String? sessionId,
  }) {
    notifications.insert(
      0,
      AppNotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${notifications.length}',
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
        isRead: false,
        recipientName: recipientName,
        recipientRole: recipientRole,
        sessionId: sessionId,
      ),
    );
    notifyListeners();
  }

  // --- CHAT ---
  List<ChatMessageItem> getMessagesBetween(String userA, String userB) {
    final uA = userA.toLowerCase();
    final uB = userB.toLowerCase();
    return chatMessages.where((m) {
      final s = m.senderName.toLowerCase();
      final r = m.receiverName.toLowerCase();
      return (s == uA && r == uB) || (s == uB && r == uA);
    }).toList();
  }

  void sendChatMessage({
    required String senderName,
    required String receiverName,
    required String text,
    required bool isFromTrainer,
    MealLogAttachment? mealAttachment,
  }) {
    final clean = text.trim();
    if (clean.isEmpty && mealAttachment == null) return;

    final msg = ChatMessageItem(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      receiverName: receiverName,
      text: clean.isEmpty && mealAttachment != null ? '${mealAttachment.emoji} ${mealAttachment.mealType}: ${mealAttachment.description}' : clean,
      timestamp: DateTime.now(),
      isFromTrainer: isFromTrainer,
      mealAttachment: mealAttachment,
    );
    chatMessages.add(msg);

    addNotification(
      title: mealAttachment != null ? '🍽️ Meal Log from $senderName' : '💬 New Message from $senderName',
      message: clean.isNotEmpty
          ? (clean.length > 60 ? '${clean.substring(0, 60)}...' : clean)
          : '${mealAttachment?.emoji} ${mealAttachment?.mealType} picture & log submitted',
      recipientName: receiverName,
      type: 'chat',
    );

    notifyListeners();
  }

  // --- AUTH, MASTER GOVERNANCE & SWITCHING ---
  UserModel? originalMasterUser;

  bool get isMasterUser =>
      currentUser?.email == 'master@mypt.com' ||
      (currentUser?.role == UserRole.superAdmin) ||
      originalMasterUser != null;

  bool get isImpersonating =>
      originalMasterUser != null && currentUser?.id != originalMasterUser?.id;

  List<UserModel> getAllAccounts() {
    final Map<String, UserModel> map = {};
    for (final u in demoAccounts.values) {
      map[u.id] = u;
    }
    for (final t in allTrainers) {
      map[t.id] = t;
    }
    for (final c in rosterClients) {
      map[c.id] = c;
    }
    return map.values.toList();
  }

  bool login(String email, String pass) {
    final cleanEmail = email.trim().toLowerCase();
    originalMasterUser = null;
    if (!demoAccounts.containsKey(cleanEmail)) {
      return false;
    }
    final expectedPass = demoPasswords[cleanEmail];
    if (expectedPass == null || expectedPass != pass) {
      return false;
    }
    currentUser = demoAccounts[cleanEmail];
    notifyListeners();
    return true;
  }

  void register({
    required String name,
    required String email,
    required String pass,
    required UserRole role,
    String goal = 'Fat Loss & Hypertrophy',
  }) {
    final cleanEmail = email.trim().toLowerCase();
    originalMasterUser = null;
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: cleanEmail,
      role: role,
      goal: goal,
      ptCredits: role == UserRole.client ? 4 : 0,
    );
    demoAccounts[cleanEmail] = newUser;
    demoPasswords[cleanEmail] = pass;
    if (role == UserRole.coach) {
      allTrainers.add(newUser);
    } else if (role == UserRole.client) {
      rosterClients.add(newUser);
    }
    currentUser = newUser;
    notifyListeners();
  }

  bool resetPassword(String email, String newPassword) {
    final cleanEmail = email.trim().toLowerCase();
    if (!demoAccounts.containsKey(cleanEmail)) {
      return false;
    }
    demoPasswords[cleanEmail] = newPassword;
    notifyListeners();
    return true;
  }

  void updateUserGoal(String newGoal) {
    if (currentUser != null && newGoal.isNotEmpty) {
      currentUser!.goal = newGoal;
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    originalMasterUser = null;
    notifyListeners();
  }

  void impersonateUser(UserModel targetUser) {
    if (originalMasterUser == null) {
      if (currentUser?.email == 'master@mypt.com' || currentUser?.role == UserRole.superAdmin) {
        originalMasterUser = currentUser;
      } else if (demoAccounts.containsKey('master@mypt.com')) {
        originalMasterUser = demoAccounts['master@mypt.com'];
      }
    }
    currentUser = targetUser;
    notifyListeners();
  }

  void returnToMasterAdmin() {
    if (originalMasterUser != null) {
      currentUser = originalMasterUser;
      originalMasterUser = null;
      notifyListeners();
    } else if (demoAccounts.containsKey('master@mypt.com')) {
      currentUser = demoAccounts['master@mypt.com'];
      notifyListeners();
    }
  }

  void switchUser(UserModel user) {
    if ((currentUser?.email == 'master@mypt.com' || isMasterUser) && originalMasterUser == null) {
      originalMasterUser = currentUser?.email == 'master@mypt.com' ? currentUser : (demoAccounts['master@mypt.com'] ?? currentUser);
    }
    currentUser = user;
    notifyListeners();
  }

  void switchUserByEmail(String email) {
    final clean = email.trim().toLowerCase();
    UserModel? foundUser;
    if (demoAccounts.containsKey(clean)) {
      foundUser = demoAccounts[clean];
    } else {
      for (final u in getAllAccounts()) {
        if (u.email.toLowerCase() == clean) {
          foundUser = u;
          break;
        }
      }
    }

    if (foundUser != null) {
      if ((currentUser?.email == 'master@mypt.com' || isMasterUser) && originalMasterUser == null) {
        originalMasterUser = currentUser?.email == 'master@mypt.com' ? currentUser : (demoAccounts['master@mypt.com'] ?? currentUser);
      }
      currentUser = foundUser;
      notifyListeners();
    }
  }

  void updateClientCredits(String clientId, int newCredits) {
    for (final c in rosterClients) {
      if (c.id == clientId) {
        c.ptCredits = newCredits;
        break;
      }
    }
    for (final acc in demoAccounts.values) {
      if (acc.id == clientId) {
        acc.ptCredits = newCredits;
        break;
      }
    }
    if (currentUser?.id == clientId) {
      currentUser?.ptCredits = newCredits;
    }
    notifyListeners();
  }

  void toggleFlag(String key, bool val) {
    globalFlags[key] = val;
    notifyListeners();
  }

  void logTodayWeight(double w) {
    if (currentUser != null) {
      currentUser!.currentWeight = w;
      addMeasurement(
        BodyMeasurementEntry(
          id: 'm_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          weightKg: w,
          notes: 'Daily weight check-in',
        ),
      );
      notifyListeners();
    }
  }
}

// ============================================================================
// 3. MAIN APP & THEME CONFIGURATION
// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => MyPtProvider(),
      child: const MyPtApp(),
    ),
  );
}

class MyPtApp extends StatelessWidget {
  const MyPtApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MyPtProvider>(context);
    return MaterialApp(
      title: 'myPT',
      debugShowCheckedModeBanner: false,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF5722),
          onPrimary: Colors.white,
          secondary: Color(0xFF00E676),
          onSecondary: Colors.black,
          surface: Colors.white,
          onSurface: Color(0xFF1E293B),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFFF5722),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5722),
          onPrimary: Colors.white,
          secondary: Color(0xFF00E676),
          onSecondary: Colors.black,
          surface: Color(0xFF161B22),
          onSurface: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFFF5722),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: state.currentUser == null ? const AuthScreen() : const MainShellScreen(),
    );
  }
}

// ============================================================================
// 4. AUTH SCREEN (WITH PROPER VALIDATION STATE & ZERO PREMATURE ERRORS)
// ============================================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSignUp = false;
  bool _obscurePassword = true;
  bool _submitted = false; // Prevents premature error display on initial load

  // Touch flags to prevent premature errors before user interaction
  bool _emailTouched = false;
  bool _passTouched = false;
  bool _nameTouched = false;

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _nameFocus = FocusNode();

  late final TextEditingController emailCtrl;
  late final TextEditingController passCtrl;
  final nameCtrl = TextEditingController();
  UserRole selectedRole = UserRole.client;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: kReleaseMode ? '' : 'sarah@mypt.com');
    passCtrl = TextEditingController(text: kReleaseMode ? '' : 'client123');

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && emailCtrl.text.isNotEmpty) {
        setState(() => _emailTouched = true);
      }
    });
    _passFocus.addListener(() {
      if (!_passFocus.hasFocus && passCtrl.text.isNotEmpty) {
        setState(() => _passTouched = true);
      }
    });
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && nameCtrl.text.isNotEmpty) {
        setState(() => _nameTouched = true);
      }
    });
  }

  String selectedGoal = kStandardFitnessGoals.first;
  String _personaRoleFilter = 'All';

  @override
  void dispose() {
    _emailFocus.dispose();
    _passFocus.dispose();
    _nameFocus.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MyPtProvider>(context, listen: false);

    return PopScope(
      canPop: !isSignUp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSignUp) {
          setState(() {
            isSignUp = false;
            _submitted = false;
            _emailTouched = false;
            _passTouched = false;
            _nameTouched = false;
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isSignUp)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSignUp = false;
                              _submitted = false;
                              _emailTouched = false;
                              _passTouched = false;
                              _nameTouched = false;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Back', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                        ),
                      const SizedBox(width: 10),
                      const Text('myPT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSignUp ? 'Create your personal training account' : 'Welcome back to your fitness command center',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                const SizedBox(height: 24),

                if (!kReleaseMode) ...[
                  Builder(
                    builder: (context) {
                      final allAccounts = state.demoAccounts.entries.toList();
                      final clientAccounts = allAccounts.where((e) => e.value.role == UserRole.client).toList();
                      final coachAccounts = allAccounts.where((e) => e.value.role == UserRole.coach).toList();
                      final headCoachAccounts = allAccounts.where((e) => e.value.role == UserRole.headCoach).toList();
                      final managerAccounts = allAccounts.where((e) => e.value.role == UserRole.gymMgr).toList();
                      final adminAccounts = allAccounts.where((e) => e.value.role == UserRole.superAdmin).toList();

                      final displayedAccounts = switch (_personaRoleFilter) {
                        'Clients' => clientAccounts,
                        'Coaches' => coachAccounts,
                        'Head Coaches' => headCoachAccounts,
                        'Managers' => managerAccounts,
                        'Admins' => adminAccounts,
                        _ => allAccounts,
                      };

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bolt, color: Color(0xFFFF5722), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'QUICK TEST PERSONAS (TAP TO LOGIN)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722), letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${allAccounts.length} Total Users',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Role Filter Tabs
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _loginFilterChip('All (${allAccounts.length})', 'All'),
                                  const SizedBox(width: 5),
                                  _loginFilterChip('Clients 👤 (${clientAccounts.length})', 'Clients'),
                                  const SizedBox(width: 5),
                                  _loginFilterChip('Coaches 🏋️ (${coachAccounts.length})', 'Coaches'),
                                  const SizedBox(width: 5),
                                  _loginFilterChip('Head Coaches 🥇 (${headCoachAccounts.length})', 'Head Coaches'),
                                  const SizedBox(width: 5),
                                  _loginFilterChip('Managers 🏢 (${managerAccounts.length})', 'Managers'),
                                  const SizedBox(width: 5),
                                  _loginFilterChip('Admins 👑 (${adminAccounts.length})', 'Admins'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dynamic Persona Buttons for All Users
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: displayedAccounts.map((entry) {
                                final email = entry.key;
                                final user = entry.value;
                                final pass = state.demoPasswords[email] ?? 'client123';
                                final prefix = switch (user.role) {
                                  UserRole.superAdmin => '👑',
                                  UserRole.headCoach => '🥇',
                                  UserRole.gymMgr => '🏢',
                                  UserRole.coach => '🏋️',
                                  UserRole.client => '👤',
                                };
                                final roleTag = switch (user.role) {
                                  UserRole.superAdmin => 'Admin',
                                  UserRole.headCoach => 'Head Coach',
                                  UserRole.gymMgr => 'Manager',
                                  UserRole.coach => 'Coach',
                                  UserRole.client => 'Client',
                                };
                                final shortName = user.name.split(' ').first;
                                final displayName = '$prefix $shortName ($roleTag)';
                                return _demoButton(displayName, email, pass, state, user.role);
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                if (isSignUp) ...[
                  TextFormField(
                    controller: nameCtrl,
                    focusNode: _nameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Rahul Sharma',
                      prefixIcon: Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (!_nameTouched && val.isNotEmpty) setState(() => _nameTouched = true);
                    },
                    validator: (val) {
                      if (!_submitted && !_nameTouched) return null;
                      if (val == null || val.trim().isEmpty) return 'Full name is required';
                      if (val.trim().length < 2) return 'Full name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Account Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: UserRole.client, child: Text('👤 Client')),
                      DropdownMenuItem(value: UserRole.coach, child: Text('🏋️ Coach / Trainer')),
                      DropdownMenuItem(value: UserRole.headCoach, child: Text('🥇 Head Coach')),
                      DropdownMenuItem(value: UserRole.gymMgr, child: Text('🏢 Gym Manager')),
                    ],
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: kStandardFitnessGoals.contains(selectedGoal) ? selectedGoal : kStandardFitnessGoals.first,
                    decoration: const InputDecoration(
                      labelText: 'Primary Fitness Goal',
                      prefixIcon: Icon(Icons.flag_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                    items: kStandardFitnessGoals.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedGoal = val);
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Color(0xFF161B22),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    if (!_emailTouched && val.isNotEmpty) setState(() => _emailTouched = true);
                  },
                  validator: (val) {
                    if (!_submitted && !_emailTouched) return null;
                    if (val == null || val.trim().isEmpty) return 'Email address is required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: passCtrl,
                  focusNode: _passFocus,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    if (!_passTouched && val.isNotEmpty) setState(() => _passTouched = true);
                  },
                  validator: (val) {
                    if (!_submitted && !_passTouched) return null;
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                if (!isSignUp) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _openForgotPasswordModal(context, state),
                      child: const Text(
                        'Forgot Password? 🔒',
                        style: TextStyle(color: Color(0xFFFF5722), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _submitted = true);
                      if (!_formKey.currentState!.validate()) return;
                      if (isSignUp) {
                        state.register(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          pass: passCtrl.text,
                          role: selectedRole,
                          goal: selectedGoal,
                        );
                      } else {
                        final success = state.login(emailCtrl.text.trim(), passCtrl.text);
                        if (!success) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1E242C),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.redAccent.withOpacity(0.7), width: 1.2),
                              ),
                              content: Row(
                                children: [
                                  const Icon(Icons.lock_reset, color: Colors.redAccent, size: 22),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Invalid password',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Retry or forgot password?',
                                          style: TextStyle(fontSize: 11, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFFF5722),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      _openForgotPasswordModal(context, state);
                                    },
                                    child: const Text('Forgot?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D333B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      passCtrl.clear();
                                    },
                                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      isSignUp ? 'Create Account 🚀' : 'Sign In 🔑',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isSignUp = !isSignUp;
                        _submitted = false;
                        _emailTouched = false;
                        _passTouched = false;
                        _nameTouched = false;
                      });
                    },
                    child: Text(
                      isSignUp ? 'Already have an account? Sign In' : 'New to myPT? Create Account',
                      style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _openForgotPasswordModal(BuildContext context, MyPtProvider state) {
    final resetEmailCtrl = TextEditingController(text: emailCtrl.text.trim());
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? resetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              child: Form(
                key: resetFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFFF5722), size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reset Account Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Set a new password for your myPT account', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      if (resetError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(resetError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: resetEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Registered Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Color(0xFF161B22),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email is required';
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                            onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF161B22),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'New password is required';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                            onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF161B22),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please confirm your password';
                          if (val != newPassCtrl.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Update Password & Sign In 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: () {
                            if (!resetFormKey.currentState!.validate()) return;
                            final targetEmail = resetEmailCtrl.text.trim();
                            final success = state.resetPassword(targetEmail, newPassCtrl.text);
                            if (!success) {
                              setSheetState(() => resetError = 'No account found with $targetEmail. Please check the email or sign up.');
                              return;
                            }
                            Navigator.pop(ctx);
                            // Automatically sign in with newly set credentials
                            state.login(targetEmail, newPassCtrl.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF00E676),
                                content: Text('✓ Password reset successfully for $targetEmail! Signed in.'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _loginFilterChip(String label, String value) {
    final isSelected = _personaRoleFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _personaRoleFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFFF5722) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _demoButton(String title, String email, String pass, MyPtProvider state, [UserRole? role]) {
    final borderColor = switch (role) {
      UserRole.superAdmin => const Color(0xFF00E676).withOpacity(0.4),
      UserRole.headCoach => const Color(0xFFFFD54F).withOpacity(0.4),
      UserRole.gymMgr => const Color(0xFFAB47BC).withOpacity(0.4),
      UserRole.coach => const Color(0xFFFF5722).withOpacity(0.4),
      UserRole.client => const Color(0xFF29B6F6).withOpacity(0.3),
      null => Colors.white12,
    };

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF21262D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
      ),
      onPressed: () {
        setState(() {
          emailCtrl.text = email;
          passCtrl.text = pass;
          _emailTouched = false;
          _passTouched = false;
          _submitted = false;
        });
        state.login(email, pass);
      },
      child: Text(title),
    );
  }
}

// ============================================================================
// 5. MAIN SHELL SCREEN (APPLE-STYLE LIQUID GLASS NAVIGATION)
// ============================================================================
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _tabIndex = 0;
  String _sessionFilter = 'All';
  final TextEditingController _coachSearchCtrl = TextEditingController();
  String _coachSearchQuery = '';
  String _selectedCoachSpecialty = 'All';
  final List<String> _specialtyFilters = const [
    'All',
    'Hypertrophy',
    'Strength',
    'Fat Loss',
    'Biomechanics',
    'Mobility',
    'Conditioning',
    'Powerlifting',
  ];

  // --- TRAINER GOOGLE CALENDAR SCHEDULE STATE ---
  String _calendarViewMode = 'Month'; // 'Month', 'Week', '3-Day', 'Day', 'Schedule'
  DateTime _calendarFocusedDate = DateTime.now();
  DateTime _calendarSelectedDate = DateTime.now();
  String _calendarStatusFilter = 'All'; // 'All', 'Confirmed', 'Pending'

  // --- EXERCISE MOVEMENT LIBRARY FILTER STATE ---
  String _exerciseSearchQuery = '';
  String _selectedMuscleFilter = 'All';
  final List<String> _muscleFilterCategories = const [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Quadriceps',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Abdominals',
    'Obliques',
    'Lower Back',
    'Full Body',
    'Legs',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<MyPtProvider>(context, listen: false);
      if (!state.hasSeenOnboarding && state.currentUser?.role == UserRole.client) {
        _openOnboardingTutorial(context, state);
      } else if (!state.hasSeenNoTrainerPrompt && state.currentUser?.role == UserRole.client && state.currentUser?.trainerId == null) {
        _openGetPersonalTrainerModal(context, state);
      }
    });
  }

  @override
  void dispose() {
    _coachSearchCtrl.dispose();
    super.dispose();
  }

  List<String> _getTrainerSpecialties(UserModel trainer) {
    final lower = trainer.name.toLowerCase();
    if (lower.contains('rincy')) {
      return const ['Strength & Conditioning', 'Biomechanics', 'Hypertrophy'];
    } else if (lower.contains('kumar')) {
      return const ['Powerlifting', 'Hypertrophy', 'Strength'];
    } else if (lower.contains('khushboo')) {
      return const ['Athletic Conditioning', 'Fat Loss', 'Mobility'];
    } else if (lower.contains('alex')) {
      return const ['NASM-CPT Elite', 'Hypertrophy', 'Fat Loss', 'Biomechanics'];
    } else if (lower.contains('elena')) {
      return const ['Functional Training', 'Mobility', 'Conditioning'];
    } else if (lower.contains('marcus') || lower.contains('neeli')) {
      return const ['Head Coach Oversight', 'Olympic Lifting', 'Biomechanics'];
    }
    return const ['Personal Training', 'Fitness Coaching', 'Strength'];
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MyPtProvider>(context);
    final user = state.currentUser!;

    final List<(IconData, String)> navTabs = switch (user.role) {
      UserRole.client => const [
        (Icons.dashboard_rounded, 'Dashboard'),
        (Icons.search, 'Discover'),
        (Icons.fitness_center, 'Workouts'),
        (Icons.trending_up, 'Progress'),
      ],
      UserRole.coach => const [
        (Icons.dashboard, 'Dashboard'),
        (Icons.inbox, 'Requests'),
        (Icons.calendar_month, 'Schedule'),
        (Icons.people, 'Clients'),
        (Icons.post_add, 'Build Chart'),
        (Icons.fitness_center, 'Library'),
        (Icons.inventory_2, 'Packages'),
      ],
      UserRole.headCoach => const [
        (Icons.dashboard, 'Overview'),
        (Icons.account_tree, 'Squad Tree'),
        (Icons.calendar_month, 'Schedule'),
        (Icons.menu_book, 'Protocols'),
        (Icons.domain, 'Facility'),
      ],
      UserRole.gymMgr => const [
        (Icons.storefront, 'Floor'),
        (Icons.badge, 'Members'),
        (Icons.calendar_month, 'Schedule'),
        (Icons.build, 'Equipment'),
      ],
      UserRole.superAdmin => const [
        (Icons.dashboard_rounded, 'Dashboard'),
        (Icons.admin_panel_settings, 'Accounts'),
        (Icons.toggle_on, 'Flags'),
        (Icons.dns, 'Telemetry'),
        (Icons.person, 'Profile'),
      ],
    };

    final int safeTabIndex = _tabIndex.clamp(0, navTabs.length - 1);

    return PopScope(
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tabIndex != 0) {
          setState(() => _tabIndex = 0);
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(state.isDevMode ? 116 : 65),
          child: SafeArea(
            bottom: false,
            child: Container(
              color: const Color(0xFF0D1117),
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (_tabIndex != 0)
                        GestureDetector(
                          onTap: () => setState(() => _tabIndex = 0),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Back', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                        ),
                      const SizedBox(width: 8),
                      const Text(
                        'myPT',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 8),

                    // Location Chip
                    GestureDetector(
                      onTap: () => _openLocationPromptModal(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Color(0xFFFF5722)),
                            const SizedBox(width: 4),
                            Text(
                              state.selectedCountry,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Currency Pill
                    GestureDetector(
                      onTap: () => _openCurrencySelector(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                        ),
                        child: Text(
                          '${state.currentCurrencyInfo.flag} ${state.selectedCurrency}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                        ),
                      ),
                    ),

                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white70, size: 21),
                      tooltip: 'Getting Started Guide',
                      onPressed: () => _openOnboardingTutorial(context, state),
                    ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: state.unreadNotificationCount > 0,
                        label: Text(
                          '${state.unreadNotificationCount}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFFFF5722),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                      tooltip: 'Notifications',
                      onPressed: () => _openNotificationModal(context, state),
                    ),
                    if (state.isMasterUser || state.isImpersonating || user.role == UserRole.superAdmin) ...[
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFF5722), size: 22),
                        tooltip: 'Master User Switcher',
                        onPressed: () => _openMasterUserSwitcherModal(context, state),
                      ),
                    ],
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _openProfileModal(context, state),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF5722), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFF21262D),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.isDevMode) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFFFF5722), size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'PERSONA: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _openMasterUserSwitcherModal(context, state),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF5722)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz, size: 12, color: Color(0xFFFF5722)),
                                SizedBox(width: 4),
                                Text(
                                  '🔄 Switch Any User',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _userChip('👤 Sarah (Client)', 'sarah@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👤 Sourabh (Client)', 'sourabh@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👤 New Trainee', 'newclient@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('⚡ Rincy (Coach)', 'rincy@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🏋️ Alex (Coach)', 'alex@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🏋️ Kumar (Coach)', 'kumar@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🥊 Khushboo (Coach)', 'khushboo@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👑 Neeli (Head)', 'neeli@mypt.com', state),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (state.isImpersonating) _buildImpersonationBanner(context, state),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: switch (user.role) {
                    UserRole.client => _buildClientView(state, safeTabIndex),
                    UserRole.coach => _buildCoachView(state, safeTabIndex),
                    UserRole.headCoach => _buildHeadCoachView(state, safeTabIndex),
                    UserRole.gymMgr => _buildGymMgrView(state, safeTabIndex),
                    UserRole.superAdmin => _buildAdminView(state, safeTabIndex),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAppleLiquidGlassBottomNav(navTabs, safeTabIndex),
      ),
    );
  }

  Widget _buildAppleLiquidGlassBottomNav(List<(IconData, String)> tabs, int activeIndex) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.06),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1E2430).withOpacity(0.85),
                        const Color(0xFF0F131A).withOpacity(0.92),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(tabs.length, (idx) {
                      final isSelected = activeIndex == idx;
                      final (iconData, label) = tabs[idx];

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _tabIndex = idx);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFFFF5722).withOpacity(0.28),
                                        const Color(0xFFFF5722).withOpacity(0.10),
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFFFF5722).withOpacity(0.4),
                                      width: 1.0,
                                    )
                                  : Border.all(color: Colors.transparent, width: 1.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconData,
                                  size: isSelected ? 21 : 19,
                                  color: isSelected ? const Color(0xFFFF5722) : Colors.white60,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    letterSpacing: 0.15,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFFFF5722) : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userChip(String title, String email, MyPtProvider state) {
    final sel = state.currentUser?.email.toLowerCase() == email.toLowerCase();
    return GestureDetector(
      onTap: () {
        state.switchUserByEmail(email);
        setState(() => _tabIndex = 0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF5722) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? const Color(0xFFFF5722) : Colors.white12),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.white70),
        ),
      ),
    );
  }

  // ============================================================================
  // 6. CLIENT VIEWS (4 TABS: Dashboard, Discover, Workouts, Progress)
  // ============================================================================
  Widget _buildClientView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _clientDashboardTab(state),
      1 => _clientDiscoverTab(state),
      2 => _clientWorkoutsTab(state),
      3 => _clientProgressTab(state),
      _ => _clientDashboardTab(state),
    };
  }

  // --- DASHBOARD TAB (HOME + PACKAGES BELOW PT CREDITS + SCHEDULE & INQUIRIES) ---
  Widget _clientDashboardTab(MyPtProvider state) {
    final user = state.currentUser!;
    final allUserSessions = state.getSessionsForUser(user);
    final allUserRequests = state.getRequestsForUser(user);

    // Find assigned trainer details if any
    UserModel? assignedTrainer;
    if (user.trainerId != null) {
      for (final t in state.allTrainers) {
        if (t.id == user.trainerId) {
          assignedTrainer = t;
          break;
        }
      }
    }

    final hasCoach = assignedTrainer != null && user.trainerApprovalStatus == TrainerApprovalStatus.approved;
    final isPendingCoach = user.trainerApprovalStatus == TrainerApprovalStatus.pending;
    final trainerPackages = state.getPackagesForTrainer(user.trainerId);

    // Accurate dynamic weight delta calculations
    final double weightDiff = user.startingWeight - user.currentWeight;
    final String weightSubtitle;
    final Color deltaColor;
    if (weightDiff > 0.05) {
      weightSubtitle = '↓ ${weightDiff.toStringAsFixed(1)} kg lost (Start: ${user.startingWeight} kg)';
      deltaColor = const Color(0xFF00E676);
    } else if (weightDiff < -0.05) {
      weightSubtitle = '↑ ${(-weightDiff).toStringAsFixed(1)} kg gained (Start: ${user.startingWeight} kg)';
      deltaColor = const Color(0xFFFF9800);
    } else {
      weightSubtitle = 'Maintaining baseline (${user.startingWeight} kg)';
      deltaColor = Colors.white70;
    }

    // Schedule status filters
    final confirmedSessions = allUserSessions.where((s) => s.status == RequestStatus.confirmed).toList();
    final pendingSessions = allUserSessions.where((s) => s.status == RequestStatus.pending).toList();
    final completedSessions = allUserSessions.where((s) => s.status == RequestStatus.completed).toList();
    final cancelledSessions = allUserSessions.where((s) => s.status == RequestStatus.cancelled).toList();

    List<SessionItem> filteredSessions = switch (_sessionFilter) {
      'Confirmed' => confirmedSessions,
      'Pending' => pendingSessions,
      'Completed' => completedSessions,
      'Cancelled' => cancelledSessions,
      _ => allUserSessions,
    };

    final filterOptions = [
      ('All', allUserSessions.length),
      ('Confirmed', confirmedSessions.length),
      ('Pending', pendingSessions.length),
      ('Completed', completedSessions.length),
      ('Cancelled', cancelledSessions.length),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // 1. Who am I? (Header)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Namaste / Welcome Back 🙏', style: TextStyle(color: Colors.white60, fontSize: 13)),
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),

        // 2. What is my current status? (Prominent Weight & PT Credits Bento)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openWeightLogDialog(context, state),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF29B6F6).withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CURRENT WEIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                          Icon(Icons.edit_note, size: 14, color: Color(0xFF29B6F6)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${user.currentWeight} kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(weightSubtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deltaColor)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (hasCoach && trainerPackages.isNotEmpty) {
                    _openPurchaseOptionsModal(context, state, trainerPackages.first);
                  } else {
                    setState(() => _tabIndex = 1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PT CREDITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                          Icon(Icons.token_outlined, size: 14, color: Color(0xFFFF5722)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${user.ptCredits}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
                      const SizedBox(height: 4),
                      Text(user.ptCredits > 0 ? 'Active & Ready • Top up' : 'Top up credits >', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Active Personal Trainer & Packages by Current Coaches Bento Cards
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (hasCoach) {
                    _openCoachProfileModal(context, state, assignedTrainer!);
                  } else {
                    setState(() => _tabIndex = 1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'ACTIVE PT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.verified, size: 14, color: Color(0xFF00E676)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasCoach ? 'Coach ${assignedTrainer.name.split(' ').first}' : 'None Selected',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCoach ? '1-on-1 Assigned • Profile >' : 'Find a coach >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasCoach ? const Color(0xFF00E676) : Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (hasCoach && trainerPackages.isNotEmpty) {
                    _openPurchaseOptionsModal(context, state, trainerPackages.first);
                  } else {
                    setState(() => _tabIndex = 1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'COACH PACKAGES',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.card_membership, size: 14, color: Color(0xFFFFB300)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasCoach ? '${trainerPackages.length} Available' : 'Custom Plans',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFFFFB300)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.currentCurrencyInfo.flag} ${state.selectedCurrency} • View plans >',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. PACKAGES SECTION (DIRECTLY BELOW PT CREDITS)
        if (hasCoach) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Packages by Coach ${assignedTrainer.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('Direct personal training packages with custom pricing', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${user.ptCredits} Credits',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...trainerPackages.map((p) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: p.sessionsCount == 12 ? const Color(0xFFFF5722).withOpacity(0.6) : Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(p.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        Text(state.formatPrice(p.priceInr), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF00E676))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('+${p.sessionsCount} x 1-on-1 Sessions • Expiry in ${p.durationWeeks} Weeks', style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                    const SizedBox(height: 4),
                    Text(p.description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: p.perks.map((perk) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(6)),
                        child: Text(perk, style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openPurchaseOptionsModal(context, state, p),
                        child: Text('Purchase Package (${state.formatPrice(p.priceInr)}) 💳', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFFF5722), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Trainer Packages', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Select a coach in Discover to view customized 1-on-1 PT packages and pricing.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => setState(() => _tabIndex = 1),
                  child: const Text('Discover', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 4. Primary Hero Section: Active Trainer & Next Steps
        if (hasCoach) ...[
          // --- ACTIVE PERSONAL TRAINER CARD ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ACTIVE PERSONAL TRAINER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676), letterSpacing: 0.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: Color(0xFF00E676)),
                          SizedBox(width: 4),
                          Text('ASSIGNED & ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                      child: Text(
                        assignedTrainer.name.isNotEmpty ? assignedTrainer.name[0] : '?',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coach ${assignedTrainer.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            _getTrainerSpecialties(assignedTrainer).join(' • '),
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.verified_user, size: 12, color: Color(0xFF00E676)),
                              SizedBox(width: 4),
                              Text('1-on-1 Tracking & Form Coaching Active', style: TextStyle(fontSize: 10, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5722),
                          side: const BorderSide(color: Color(0xFFFF5722)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 14),
                        label: const Text('Message Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _openChatModal(context, state, peerName: assignedTrainer!.name),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.person_outline, size: 14),
                        label: const Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _openCoachProfileModal(context, state, assignedTrainer!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.calendar_month, size: 14),
                        label: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _openScheduleModal(context, state, targetTrainer: assignedTrainer),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ] else if (isPendingCoach) ...[
          // State B: Coach Request Pending
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFF9800), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach Approval Pending', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Your consultation is under review. You will be notified once accepted.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ] else ...[
          // State A: No Trainer Selected - Prominent Card with Popup Trigger
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.5), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF5722), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get a Personal Trainer 🏋️‍♂️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Live tracking, form reviews, and tailored workout programming.', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                          SizedBox(width: 8),
                          Expanded(child: Text('Custom Workout & Nutrition Plans', style: TextStyle(fontSize: 11.5, color: Colors.white70))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                          SizedBox(width: 8),
                          Expanded(child: Text('Real-Time Volume & Overload Tracking', style: TextStyle(fontSize: 11.5, color: Colors.white70))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                          SizedBox(width: 8),
                          Expanded(child: Text('1-on-1 Direct Messaging & Feedback', style: TextStyle(fontSize: 11.5, color: Colors.white70))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5722),
                          side: const BorderSide(color: Color(0xFFFF5722)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _openGetPersonalTrainerModal(context, state),
                        child: const Text('Why Get a Trainer? 💡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.explore, size: 16),
                        label: const Text('Discover Coaches 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => setState(() => _tabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 5. SCHEDULE & BOOKINGS SECTION (ALL DATA FROM PREVIOUS SESSIONS TAB)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bookings & Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  '${allUserSessions.length} sessions booked • ${user.ptCredits} PT Credits left',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Book Session 📅', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _openScheduleModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Multi-status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterOptions.map((opt) {
              final (label, count) = opt;
              final isSelected = _sessionFilter == label;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('$label ($count)'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF5722),
                  backgroundColor: const Color(0xFF161B22),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  side: BorderSide(color: isSelected ? const Color(0xFFFF5722) : Colors.white12),
                  onSelected: (sel) {
                    if (sel) setState(() => _sessionFilter = label);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Session Cards Section
        if (filteredSessions.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Icon(
                  _sessionFilter == 'All' ? Icons.event_busy : Icons.filter_alt_off,
                  size: 40,
                  color: Colors.white38,
                ),
                const SizedBox(height: 10),
                Text(
                  _sessionFilter == 'All'
                      ? 'No 1-on-1 sessions booked yet'
                      : 'No ${_sessionFilter.toLowerCase()} sessions found',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _sessionFilter == 'All'
                      ? 'Schedule a session with your coach or send a consultation request to get started.'
                      : 'Try switching the filter tab above to view other sessions.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (_sessionFilter == 'All') ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text('Book Session 📅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => _openScheduleModal(context, state),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Find Coach 🤝', style: TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _tabIndex = 1),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          ...filteredSessions.map((s) {
            final isPending = s.status == RequestStatus.pending;
            final isConfirmed = s.status == RequestStatus.confirmed;
            final isCompleted = s.status == RequestStatus.completed;

            final statusColor = isConfirmed
                ? const Color(0xFF00E676)
                : isPending
                    ? const Color(0xFFFF9800)
                    : isCompleted
                        ? const Color(0xFF29B6F6)
                        : Colors.white38;

            final statusLabel = isConfirmed
                ? '✓ CONFIRMED'
                : isPending
                    ? '⏳ PENDING APPROVAL'
                    : isCompleted
                        ? '✓ COMPLETED'
                        : '❌ CANCELLED';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isConfirmed
                      ? const Color(0xFF00E676).withOpacity(0.35)
                      : isPending
                          ? const Color(0xFFFF9800).withOpacity(0.4)
                          : Colors.white12,
                  width: (isConfirmed || isPending) ? 1.2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: statusColor.withOpacity(0.15),
                          child: Icon(
                            isPending
                                ? Icons.hourglass_top_rounded
                                : isConfirmed
                                    ? Icons.event_available
                                    : isCompleted
                                        ? Icons.task_alt
                                        : Icons.event_busy,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.focusArea, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                              const SizedBox(height: 3),
                              Text(
                                '${DateFormat('EEEE, dd MMMM yyyy').format(s.date)} • ${s.timeSlot}',
                                style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text('Trainer: Coach ${s.trainerName}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.5), width: 0.8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.white12),

                    // Action Buttons Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        if (isConfirmed) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.videocam, size: 14, color: Colors.black),
                            label: const Text('Join Live 📹', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF00E676),
                                  content: Text('📹 Opening live meeting room with Coach ${s.trainerName}... (${s.meetingLink ?? 'https://meet.mypt.pro'})'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF29B6F6),
                              side: const BorderSide(color: Color(0xFF29B6F6)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.edit_calendar, size: 13, color: Color(0xFF29B6F6)),
                            label: const Text('Reschedule 📅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _openRescheduleModal(context, state, s),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 13, color: Colors.redAccent),
                            label: const Text('Cancel Session', style: TextStyle(fontSize: 11)),
                            onPressed: () => _openCancelSessionModal(context, state, s),
                          ),
                        ] else if (isPending) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.close, size: 13, color: Colors.redAccent),
                            label: const Text('Withdraw Request', style: TextStyle(fontSize: 11)),
                            onPressed: () => state.cancelSession(s),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.replay, size: 13),
                            label: const Text('Book Again 📅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _openScheduleModal(context, state),
                          ),
                        ],
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5722),
                            side: const BorderSide(color: Color(0xFFFF5722)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 13, color: Color(0xFFFF5722)),
                          label: const Text('Message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _openChatModal(context, state, peerName: s.trainerName),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // Consultation Inquiries Section
        if (allUserRequests.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('1-on-1 Consultation Inquiries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Status of prospective coaching & inquiry requests submitted to trainers.', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),

          ...allUserRequests.map((req) {
            final isReqPending = req.status == RequestStatus.pending;
            final isReqConfirmed = req.status == RequestStatus.confirmed;
            final isReqCancelled = req.status == RequestStatus.cancelled;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isReqPending
                      ? const Color(0xFFFF9800).withOpacity(0.5)
                      : isReqConfirmed
                          ? const Color(0xFF00E676).withOpacity(0.4)
                          : Colors.redAccent.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Inquiry: ${req.requestType}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isReqPending
                                ? const Color(0xFFFF9800).withOpacity(0.15)
                                : isReqConfirmed
                                    ? const Color(0xFF00E676).withOpacity(0.15)
                                    : Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isReqPending
                                ? '⏳ PENDING REVIEW'
                                : isReqConfirmed
                                    ? '✓ ACCEPTED'
                                    : '❌ DECLINED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isReqPending
                                  ? const Color(0xFFFF9800)
                                  : isReqConfirmed
                                      ? const Color(0xFF00E676)
                                      : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coach: ${req.trainerName ?? 'Personal Trainer'} • Submitted ${DateFormat('dd MMM, hh:mm a').format(req.date)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${req.message}"',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    if (isReqCancelled && req.declineReason != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Reason: ${req.declineReason}',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 16, color: Colors.white12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isReqPending) ...[
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            onPressed: () => state.cancelConsultationRequest(req),
                            child: const Text('Cancel Inquiry', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                            icon: const Icon(Icons.chat_bubble_outline, size: 13),
                            label: const Text('Message Coach', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _openChatModal(context, state, peerName: req.trainerName ?? 'Coach'),
                          ),
                        ] else if (isReqCancelled) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                            icon: const Icon(Icons.explore, size: 14),
                            label: const Text('Explore Other Coaches 🚀', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => setState(() => _tabIndex = 1),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                            icon: const Icon(Icons.calendar_month, size: 14, color: Colors.black),
                            label: const Text('Book 1-on-1 Session 📅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _openScheduleModal(context, state),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // --- DISCOVER TAB (COACH SELECTION WITH CONSULTATION FLOW & RECOVERY) ---
  Widget _clientDiscoverTab(MyPtProvider state) {
    final user = state.currentUser!;
    final query = _coachSearchQuery.trim().toLowerCase();
    final userRequests = state.getRequestsForUser(user);
    final declinedRequests = userRequests.where((r) => r.status == RequestStatus.cancelled && r.declineReason != null && r.declineReason != 'Cancelled by client').toList();

    final filteredTrainers = state.allTrainers.where((t) {
      final specialties = _getTrainerSpecialties(t);
      if (_selectedCoachSpecialty != 'All') {
        final matchesChip = specialties.any((s) => s.toLowerCase().contains(_selectedCoachSpecialty.toLowerCase()));
        if (!matchesChip) return false;
      }
      if (query.isNotEmpty) {
        final nameMatches = t.name.toLowerCase().contains(query);
        final emailMatches = t.email.toLowerCase().contains(query);
        final specMatches = specialties.any((s) => s.toLowerCase().contains(query));
        if (!nameMatches && !emailMatches && !specMatches) return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const Text('Find Your Personal Coach', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Browse certified coaches in India, send free 1-on-1 consultation requests, or select your trainer.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),

        // Decline Recovery Banner (if any previous request was declined)
        if (declinedRequests.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Inquiry Update (Coach ${declinedRequests.first.trainerName ?? 'Trainer'})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Reason: "${declinedRequests.first.declineReason}"\nDon\'t worry! You can connect with any of our other certified coaches below.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],

        // Search Bar
        TextField(
          controller: _coachSearchCtrl,
          decoration: InputDecoration(
            hintText: 'Search by coach name, specialty (Hypertrophy, Strength)...',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722), size: 20),
            suffixIcon: _coachSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _coachSearchCtrl.clear();
                      setState(() => _coachSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF161B22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
          ),
          onChanged: (val) => setState(() => _coachSearchQuery = val.trim()),
        ),
        const SizedBox(height: 12),

        // Specialty Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _specialtyFilters.map((filter) {
              final isSelected = _selectedCoachSpecialty == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF5722),
                  backgroundColor: const Color(0xFF161B22),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  side: BorderSide(color: isSelected ? const Color(0xFFFF5722) : Colors.white12),
                  onSelected: (selected) {
                    setState(() => _selectedCoachSpecialty = selected ? filter : 'All');
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Text('${filteredTrainers.length} certified coaches available', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
            if (_coachSearchQuery.isNotEmpty || _selectedCoachSpecialty != 'All') ...[
              const Spacer(),
              InkWell(
                onTap: () {
                  _coachSearchCtrl.clear();
                  setState(() {
                    _coachSearchQuery = '';
                    _selectedCoachSpecialty = 'All';
                  });
                },
                child: const Text('Reset filters', style: TextStyle(fontSize: 11, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        if (filteredTrainers.isNotEmpty) ...[
          ...filteredTrainers.map((t) {
            final isPrimaryTrainer = user.trainerId == t.id && user.trainerApprovalStatus == TrainerApprovalStatus.approved;
            final isPendingTrainer = user.trainerId == t.id && user.trainerApprovalStatus == TrainerApprovalStatus.pending;
            final coachRequests = userRequests.where((r) => r.trainerId == t.id).toList();
            final hasPendingRequest = coachRequests.any((r) => r.status == RequestStatus.pending);
            final hasDeclinedRequest = coachRequests.any((r) => r.status == RequestStatus.cancelled && r.declineReason != null && r.declineReason != 'Cancelled by client');
            final specialties = _getTrainerSpecialties(t);
            final trainerPkgs = state.getPackagesForTrainer(t.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isPrimaryTrainer
                      ? const Color(0xFF00E676)
                      : (isPendingTrainer || hasPendingRequest)
                          ? const Color(0xFFFF9800)
                          : hasDeclinedRequest
                              ? Colors.redAccent.withOpacity(0.5)
                              : Colors.white10,
                  width: (isPrimaryTrainer || isPendingTrainer || hasPendingRequest) ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isPrimaryTrainer ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFFFF5722).withOpacity(0.2),
                          child: Text(
                            t.name[0],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPrimaryTrainer ? const Color(0xFF00E676) : const Color(0xFFFF5722),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(t.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF21262D),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                                        SizedBox(width: 2),
                                        Text('4.9', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text('Certified Strength & Conditioning Specialist', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              if (isPrimaryTrainer) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF00E676), width: 0.8),
                                  ),
                                  child: const Text('✓ YOUR PRIMARY TRAINER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                                ),
                              ] else if (isPendingTrainer || hasPendingRequest) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFF9800), width: 0.8),
                                  ),
                                  child: const Text('⏳ CONSULTATION PENDING REVIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
                                ),
                              ] else if (hasDeclinedRequest) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.redAccent, width: 0.8),
                                  ),
                                  child: const Text('❌ CONSULTATION DECLINED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: Colors.white12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: specialties.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
                      )).toList(),
                    ),
                    if (trainerPkgs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '1-on-1 Packages starting from ${state.formatPrice(trainerPkgs.first.priceInr)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF00E676), fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.person_outline, size: 15),
                            label: const Text('View Profile', style: TextStyle(fontSize: 12)),
                            onPressed: () => _openCoachProfileModal(context, state, t),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isPrimaryTrainer) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.calendar_month, size: 15, color: Colors.black),
                              label: const Text('Book Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => _openScheduleModal(context, state, targetTrainer: t),
                            ),
                          ),
                        ] else if (isPendingTrainer || hasPendingRequest) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF9800),
                                side: const BorderSide(color: Color(0xFFFF9800)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text('Message Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _openChatModal(context, state, peerName: t.name),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.handshake_outlined, size: 15),
                              label: const Text('Consultation 🤝', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => _openRequestConsultationModal(context, state, t),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('No coaches matched your search.', style: TextStyle(color: Colors.white60))),
          ),
        ],
      ],
    );
  }

  // --- 2-STEP COACH SELECTION CONFIRMATION MODAL ---
  void _openSelectCoachConfirmationModal(BuildContext context, MyPtProvider state, UserModel coach) {
    final specialties = _getTrainerSpecialties(coach);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                      child: Text(coach.name[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select ${coach.name} as primary trainer?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Certified Personal Trainer', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),
                const Text(
                  'By confirming, Coach will become your assigned primary trainer. You will be able to schedule 1-on-1 sessions, follow personalized workout protocols, and message them directly.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: specialties.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 10)), backgroundColor: const Color(0xFF0D1117))).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          state.selectPrimaryTrainer(coach);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF00E676),
                              content: Text('🎉 Coach ${coach.name} is now your primary trainer!'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: const Text('Confirm Selection ✓', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WORKOUTS TAB (EXERCISE COMPLETION DIFFERENTIATION) ---
  Widget _clientWorkoutsTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Workout Programs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E676), width: 0.8),
              ),
              child: const Text('Phase 1 Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Prescribed routines & custom workouts tailored for you.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),

        // Create / Start Workout Session Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('+ Build / Log Custom Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => _openCreateWorkoutModal(context, state),
          ),
        ),
        const SizedBox(height: 16),

        ...state.customWorkouts.map((routine) {
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prescribed by: ${routine.createdBy}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(routine.focusArea.split(',').first.trim(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  const Divider(height: 16, color: Colors.white12),
                  ...routine.exercises.asMap().entries.map((entry) {
                    final exIdx = entry.key;
                    final ex = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${exIdx + 1}. ${ex.name}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ex.sets} Sets x ${ex.reps} Reps${(state.enableExerciseTargetWeight && ex.hasTargetWeight) ? ' • Target: ${ex.weight}' : ''} • Rest: ${ex.restSeconds}',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5722),
                        side: const BorderSide(color: Color(0xFFFF5722)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('▶ Start Live Workout Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _openLiveWorkoutSessionModal(context, state, routine),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        if (state.workoutHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Completed Workout Sessions History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...state.workoutHistory.map((sess) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFF0D1117),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF00E676), width: 0.8)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  child: Icon(Icons.check, size: 20),
                ),
                title: Text(sess.routineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Logged by ${sess.loggedBy} • ${sess.completedAt.day}/${sess.completedAt.month}/${sess.completedAt.year} • ${sess.exercises.length} Exercises', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                trailing: Text(
                  '${sess.totalVolumeKg.toStringAsFixed(0)} kg\nTotal Vol',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF00E676)),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // --- PROGRESS TAB (MERGED ANALYTICS & BODY TRANSFORMATION TRACKER) ---
  Widget _clientProgressTab(MyPtProvider state) {
    final user = state.currentUser!;
    final history = state.measurementHistory;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Measurement', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openAddMeasurementModal(context, state),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // 1. Header & Weight Log Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress & Body Transformation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Nutrition targets, splits, progression chart & body scans', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21262D),
                  foregroundColor: const Color(0xFFFF5722),
                  side: const BorderSide(color: Color(0xFFFF5722)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.scale, size: 14),
                label: const Text('Log Weight', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _openWeightLogDialog(context, state),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Weight Stat Cards Row
          Row(
            children: [
              Expanded(child: _statCard('STARTING WEIGHT', '${user.startingWeight} kg', 'Baseline', const Color(0xFF21262D))),
              const SizedBox(width: 8),
              Expanded(child: _statCard('CURRENT WEIGHT', '${user.currentWeight} kg', '-${(user.startingWeight - user.currentWeight).toStringAsFixed(1)} kg lost', const Color(0xFF00E676))),
              const SizedBox(width: 8),
              Expanded(child: _statCard('TARGET WEIGHT', '60.0 kg', '4.5 kg to go', const Color(0xFF29B6F6))),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Nutrition Targets & Training Split (From Analytics)
          Card(
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phase 1: Hypertrophy & Fat Loss', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Text('ACTIVE PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Assigned by primary coach for body recomposition', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  const Divider(height: 20, color: Colors.white12),

                  const Text('Daily Nutrition Targets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _macroPill('Calories', '1,950 kcal', const Color(0xFFFF5722)),
                      const SizedBox(width: 6),
                      _macroPill('Protein', '150g', const Color(0xFF29B6F6)),
                      const SizedBox(width: 6),
                      _macroPill('Carbs', '190g', const Color(0xFF00E676)),
                      const SizedBox(width: 6),
                      _macroPill('Fat', '55g', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Weekly Workout Split', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Text(
                    '• Monday: Upper Hypertrophy & Arms\n• Tuesday: Lower Body Quads & Calves\n• Thursday: Push Strength & Shoulders\n• Friday: Pull Biomechanics & Core',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Weight & Body Fat Progression Chart (8 Weeks - From Analytics)
          Card(
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📉 Weight & Body Fat Decline (6 Scans)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Text('ON TRACK 🎯', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Progress tracking from starting baseline to current check-in.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  const Divider(height: 20, color: Colors.white12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: history.reversed.map((m) {
                      final normalizedHeight = ((m.weightKg - 60.0) / (70.0 - 60.0)).clamp(0.2, 1.0) * 100.0;
                      final dateLabel = DateFormat('dd MMM').format(m.date);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${m.weightKg}k', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: normalizedHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFF5722), Color(0xFF29B6F6)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(dateLabel, style: const TextStyle(fontSize: 9, color: Colors.white54)),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL LOSS', style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                              Text('-${(user.startingWeight - user.currentWeight).toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BODY FAT', style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                              Text('18.2% (-3.3%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF29B6F6))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PACE', style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                              Text('-0.5 kg/wk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Circumference Measurements Card (Latest Scan)
          Card(
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Circumference Measurements (Latest Scan)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Divider(height: 18, color: Colors.white12),
                  if (history.isNotEmpty) ...[
                    _measurementRow('Chest', '${history.first.chestCm} cm', '-2.0 cm from baseline'),
                    _measurementRow('Waist', '${history.first.waistCm} cm', '-4.0 cm from baseline'),
                    _measurementRow('Hips', '${history.first.hipsCm} cm', '-2.0 cm from baseline'),
                    _measurementRow('Arms', '${history.first.armsCm} cm', '+1.0 cm hypertrophy'),
                    _measurementRow('Thighs', '${history.first.thighsCm} cm', '-2.0 cm lean definition'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Scan History Logs
          const Text('Scan History Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...history.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFF161B22),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF5722).withOpacity(0.15),
                  child: const Icon(Icons.straighten, color: Color(0xFFFF5722), size: 18),
                ),
                title: Text('${entry.weightKg} kg • ${entry.bodyFatPercent}% Body Fat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${DateFormat('dd MMM yyyy').format(entry.date)} • ${entry.notes}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                trailing: Text('Waist: ${entry.waistCm}cm', style: const TextStyle(fontSize: 11, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ),
    );
  }

  static Widget _macroPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 7. COACH VIEWS (7 TABS: Dashboard, Requests, Schedule, Clients, Build Chart, Library, Packages)
  // ============================================================================
  Widget _buildCoachView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _coachDashboardTab(state),
      1 => _coachRequestsTab(state),
      2 => _coachScheduleTab(state),
      3 => _coachClientsTab(state),
      4 => _coachBuildChartTab(),
      5 => _coachLibraryTab(state),
      6 => _coachPackagesTab(state),
      _ => _coachDashboardTab(state),
    };
  }

  Widget _coachDashboardTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final myClients = state.getClientsForTrainer(coach.id);
    final mySessions = state.sessions.where((s) => s.trainerName.toLowerCase().contains(coach.name.toLowerCase()) || coach.name.toLowerCase().contains(s.trainerName.toLowerCase())).toList();
    final pendingSessions = mySessions.where((s) => s.status == RequestStatus.pending).length;
    final pendingOfflinePayments = state.packagePurchaseRequests.where((p) => p.trainerId == coach.id && p.status == RequestStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trainer Command Center', style: TextStyle(color: Colors.white60, fontSize: 13)),
                Text(coach.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _statCard('ASSIGNED CLIENTS', '${myClients.length}', 'Active Roster', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('EST. REVENUE', state.formatPrice(45990), 'This Month', const Color(0xFF00E676))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('PENDING REQUESTS', '${pendingSessions + pendingOfflinePayments.length}', 'Needs Review', const Color(0xFFFF9800))),
          ],
        ),
        const SizedBox(height: 16),

        if (pendingOfflinePayments.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF9800), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, color: Color(0xFFFF9800), size: 18),
                    SizedBox(width: 8),
                    Text('Pending Offline Payment Confirmations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ...pendingOfflinePayments.map((payReq) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${payReq.clientName} - ${payReq.packageTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Amount: ${state.formatPrice(payReq.priceInr)} • +${payReq.sessionsCount} PT Credits', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11)),
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('Decline', style: TextStyle(fontSize: 11)),
                          onPressed: () => state.declinePackagePurchase(payReq),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          child: const Text('Confirm & Credit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                          onPressed: () => state.approvePackagePurchase(payReq),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => _openScheduleModal(context, state),
              child: const Text('+ Schedule Session', style: TextStyle(color: Color(0xFFFF5722))),
            ),
          ],
        ),
        if (mySessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('No upcoming sessions scheduled.', style: TextStyle(color: Colors.white54))),
          )
        else
          ...mySessions.map((s) {
            final isPending = s.status == RequestStatus.pending;
            final isConfirmed = s.status == RequestStatus.confirmed;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isPending ? const Color(0xFFFF9800) : isConfirmed ? const Color(0xFF00E676).withOpacity(0.3) : Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isPending ? const Color(0xFFFF9800).withOpacity(0.15) : const Color(0xFFFF5722).withOpacity(0.15),
                          child: Icon(isPending ? Icons.hourglass_top_rounded : Icons.event, color: isPending ? const Color(0xFFFF9800) : const Color(0xFFFF5722), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${DateFormat('EEE, dd MMM yyyy').format(s.date)} • ${s.timeSlot}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('Focus: ${s.focusArea}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending ? const Color(0xFFFF9800).withOpacity(0.15) : isConfirmed ? const Color(0xFF00E676).withOpacity(0.15) : const Color(0xFF21262D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? '⏳ PENDING APPROVAL' : isConfirmed ? '✓ CONFIRMED' : s.status.name.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPending ? const Color(0xFFFF9800) : isConfirmed ? const Color(0xFF00E676) : Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPending) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Reject', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  backgroundColor: const Color(0xFF161B22),
                                  title: const Text('Decline Session Booking?', style: TextStyle(color: Colors.white)),
                                  content: Text('Decline ${s.clientName}\'s session on ${DateFormat("EEE, dd MMM").format(s.date)} at ${s.timeSlot}?\n\n1 PT Credit will be immediately refunded to ${s.clientName}.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () {
                                        Navigator.pop(dCtx);
                                        state.rejectSession(s);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.redAccent,
                                            content: Text('❌ Declined booking. 1 PT Credit refunded to ${s.clientName}.'),
                                          ),
                                        );
                                      },
                                      child: const Text('Decline & Refund Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            icon: const Icon(Icons.check, size: 14, color: Colors.black),
                            label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              state.approveSession(s);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF00E676),
                                  content: Text('✓ Approved 1-on-1 session for ${s.clientName}!'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          icon: const Icon(Icons.edit_calendar, size: 13, color: Color(0xFF29B6F6)),
                          label: const Text('Reschedule', style: TextStyle(fontSize: 11, color: Color(0xFF29B6F6))),
                          onPressed: () => _openRescheduleModal(context, state, s),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _openChatModal(context, state, peerName: s.clientName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF21262D), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
                            child: const Text('Message', style: TextStyle(fontSize: 11, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _coachRequestsTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final reqs = state.trainerRequests.where((r) => r.trainerId == coach.id || r.trainerId == null).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        const Text('Client Consultation Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Review prospective trainees seeking 1-on-1 coaching', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 14),

        if (reqs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('No pending consultation requests.', style: TextStyle(color: Colors.white54))),
          )
        else
          ...reqs.map((req) {
            final isPending = req.status == RequestStatus.pending;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF161B22),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(DateFormat('dd MMM').format(req.date), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(req.requestType, style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(req.message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const Divider(height: 16, color: Colors.white12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPending) ...[
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            onPressed: () => state.declineRequest(req),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                            onPressed: () => state.acceptRequest(req),
                            child: const Text('Accept Trainee', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ] else
                          Text(req.status.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ============================================================================
  // --- TRAINER GOOGLE CALENDAR SCHEDULE SYSTEM (MONTH, WEEK, 3-DAY, DAY, AGENDA) ---
  // ============================================================================
  int _parseStartHour(String timeSlot) {
    try {
      final startPart = timeSlot.split('-').first.trim();
      final isPm = startPart.toUpperCase().contains('PM');
      final isAm = startPart.toUpperCase().contains('AM');
      final timeOnly = startPart.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = timeOnly.split(':');
      int hour = int.parse(parts[0]);
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return hour;
    } catch (_) {
      return 10;
    }
  }

  String _formatShortTime(String timeSlot) {
    try {
      final startPart = timeSlot.split('-').first.trim();
      return startPart.replaceAll(':00', '').replaceAll(' ', '');
    } catch (_) {
      return '10A';
    }
  }

  List<SessionItem> _getTrainerSessions(MyPtProvider state, UserModel trainer) {
    final nameLower = trainer.name.toLowerCase();
    return state.sessions.where((s) {
      final matchTrainer = s.trainerId == trainer.id ||
          s.trainerName.toLowerCase().contains(nameLower) ||
          nameLower.contains(s.trainerName.toLowerCase());
      if (!matchTrainer) return false;
      if (_calendarStatusFilter == 'Confirmed') return s.status == RequestStatus.confirmed;
      if (_calendarStatusFilter == 'Pending') return s.status == RequestStatus.pending;
      return true;
    }).toList();
  }

  List<SessionItem> _getSessionsForDate(List<SessionItem> sessions, DateTime date) {
    return sessions.where((s) =>
      s.date.year == date.year && s.date.month == date.month && s.date.day == date.day
    ).toList();
  }

  Widget _coachScheduleTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final trainerSessions = _getTrainerSessions(state, coach);

    return Stack(
      children: [
        Column(
          children: [
            _buildCalendarHeader(context, state, coach, trainerSessions),
            Expanded(
              child: switch (_calendarViewMode) {
                'Month' => _buildMonthView(context, state, coach, trainerSessions),
                'Week' => _buildWeekView(context, state, coach, trainerSessions),
                '3-Day' => _buildThreeDayView(context, state, coach, trainerSessions),
                'Day' => _buildDayView(context, state, coach, trainerSessions),
                'Schedule' => _buildScheduleAgendaView(context, state, coach, trainerSessions),
                _ => _buildMonthView(context, state, coach, trainerSessions),
              },
            ),
          ],
        ),
        Positioned(
          bottom: 84,
          right: 18,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => _openScheduleModal(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(BuildContext context, MyPtProvider state, UserModel coach, List<SessionItem> sessions) {
    final now = DateTime.now();
    final isCurrentMonth = _calendarFocusedDate.year == now.year && _calendarFocusedDate.month == now.month;
    final allCount = sessions.length;
    final confirmedCount = sessions.where((s) => s.status == RequestStatus.confirmed).length;
    final pendingCount = sessions.where((s) => s.status == RequestStatus.pending).length;

    String dateTitle = switch (_calendarViewMode) {
      'Day' => DateFormat('EEEE, dd MMM yyyy').format(_calendarFocusedDate),
      'Week' => () {
        final start = _calendarFocusedDate.subtract(Duration(days: _calendarFocusedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
      }(),
      '3-Day' => () {
        final end = _calendarFocusedDate.add(const Duration(days: 2));
        return '${DateFormat('dd MMM').format(_calendarFocusedDate)} - ${DateFormat('dd MMM yyyy').format(end)}';
      }(),
      _ => DateFormat('MMMM yyyy').format(_calendarFocusedDate),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF12161E),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Month/Date Title Dropdown & Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showMonthYearPickerModal(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateTitle,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFFFF5722), size: 22),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isCurrentMonth ? const Color(0xFFFF5722) : Colors.white70,
                      side: BorderSide(color: isCurrentMonth ? const Color(0xFFFF5722) : Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.today, size: 12),
                    label: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        _calendarFocusedDate = DateTime.now();
                        _calendarSelectedDate = DateTime.now();
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Previous',
                    onPressed: () => _navigateCalendarDate(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Next',
                    onPressed: () => _navigateCalendarDate(1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Google Calendar View Switcher (Pill tabs)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _calendarViewPill('Month', Icons.calendar_view_month),
                const SizedBox(width: 6),
                _calendarViewPill('Week', Icons.calendar_view_week),
                const SizedBox(width: 6),
                _calendarViewPill('3-Day', Icons.view_column),
                const SizedBox(width: 6),
                _calendarViewPill('Day', Icons.calendar_view_day),
                const SizedBox(width: 6),
                _calendarViewPill('Schedule', Icons.view_agenda),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Status Filter Chips & Quick Count
          Row(
            children: [
              _calendarStatusFilterChip('All', allCount, const Color(0xFF29B6F6)),
              const SizedBox(width: 6),
              _calendarStatusFilterChip('Confirmed', confirmedCount, const Color(0xFF00E676)),
              const SizedBox(width: 6),
              _calendarStatusFilterChip('Pending', pendingCount, const Color(0xFFFF9800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarViewPill(String mode, IconData icon) {
    final isSelected = _calendarViewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _calendarViewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5722) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 4),
            Text(
              mode,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarStatusFilterChip(String label, int count, Color color) {
    final isSelected = _calendarStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _calendarStatusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('$label ($count)', style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.white60)),
          ],
        ),
      ),
    );
  }

  void _navigateCalendarDate(int direction) {
    setState(() {
      if (_calendarViewMode == 'Month') {
        _calendarFocusedDate = DateTime(_calendarFocusedDate.year, _calendarFocusedDate.month + direction, 1);
      } else if (_calendarViewMode == 'Week') {
        _calendarFocusedDate = _calendarFocusedDate.add(Duration(days: direction * 7));
      } else if (_calendarViewMode == '3-Day') {
        _calendarFocusedDate = _calendarFocusedDate.add(Duration(days: direction * 3));
      } else if (_calendarViewMode == 'Day') {
        _calendarFocusedDate = _calendarFocusedDate.add(Duration(days: direction));
      } else {
        _calendarFocusedDate = _calendarFocusedDate.add(Duration(days: direction * 7));
      }
      _calendarSelectedDate = _calendarFocusedDate;
    });
  }

  // --- 1. GOOGLE CALENDAR MONTH VIEW ---
  Widget _buildMonthView(BuildContext context, MyPtProvider state, UserModel coach, List<SessionItem> sessions) {
    final year = _calendarFocusedDate.year;
    final month = _calendarFocusedDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Mon, 7 = Sun
    final prevMonthDays = DateTime(year, month, 0).day;
    final now = DateTime.now();

    final prevPadding = firstWeekday - 1;
    final totalCells = ((prevPadding + daysInMonth + 6) ~/ 7) * 7;

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Weekday Column Header Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: weekDays.map((d) {
              final isWeekend = d == 'Sat' || d == 'Sun';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isWeekend ? const Color(0xFFFF5722) : Colors.white60,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 7-Column Calendar Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final childRatio = width > 900 ? 1.35 : (width > 600 ? 0.95 : 0.65);
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 96),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: childRatio,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: totalCells,
                itemBuilder: (context, idx) {
              DateTime cellDate;
              bool isCurrentMonth = true;

              if (idx < prevPadding) {
                final d = prevMonthDays - (prevPadding - idx - 1);
                cellDate = DateTime(year, month - 1, d);
                isCurrentMonth = false;
              } else if (idx < prevPadding + daysInMonth) {
                final d = idx - prevPadding + 1;
                cellDate = DateTime(year, month, d);
                isCurrentMonth = true;
              } else {
                final d = idx - (prevPadding + daysInMonth) + 1;
                cellDate = DateTime(year, month + 1, d);
                isCurrentMonth = false;
              }

              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final isSelected = cellDate.year == _calendarSelectedDate.year && cellDate.month == _calendarSelectedDate.month && cellDate.day == _calendarSelectedDate.day;
              final daySessions = _getSessionsForDate(sessions, cellDate);

              return GestureDetector(
                onTap: () {
                  setState(() => _calendarSelectedDate = cellDate);
                  if (daySessions.isNotEmpty) {
                    _showDaySessionsModal(context, state, cellDate, daySessions);
                  } else {
                    _openScheduleModal(context, state);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF5722).withOpacity(0.12)
                        : isCurrentMonth
                            ? const Color(0xFF161B22)
                            : const Color(0xFF0D1117).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF5722)
                          : isToday
                              ? const Color(0xFF29B6F6)
                              : Colors.white.withOpacity(0.06),
                      width: (isSelected || isToday) ? 1.2 : 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Number Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFFFF5722)
                                  : isSelected
                                      ? Colors.white24
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cellDate.day}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                                color: isToday
                                    ? Colors.white
                                    : isCurrentMonth
                                        ? Colors.white
                                        : Colors.white24,
                              ),
                            ),
                          ),
                          if (daySessions.isNotEmpty)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: daySessions.any((s) => s.status == RequestStatus.pending)
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Session Mini-Chips inside cell
                      Expanded(
                        child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ...daySessions.take(2).map((s) {
                              final isPending = s.status == RequestStatus.pending;
                              final chipColor = isPending ? const Color(0xFFFF9800) : const Color(0xFF00E676);

                              return GestureDetector(
                                onTap: () => _openSessionDetailsModal(context, state, s),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: chipColor.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${_formatShortTime(s.timeSlot)} ${s.clientName.split(' ').first}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (daySessions.length > 2)
                              Text(
                                '+${daySessions.length - 2} more',
                                style: const TextStyle(fontSize: 7.5, color: Color(0xFFFF5722), fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  ],
);
  }

  // --- 2. GOOGLE CALENDAR WEEK VIEW (7 DAYS) ---
  Widget _buildWeekView(BuildContext context, MyPtProvider state, UserModel coach, List<SessionItem> sessions) {
    final startOfWeek = _calendarFocusedDate.subtract(Duration(days: _calendarFocusedDate.weekday - 1));
    final weekDates = List.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: i)));
    final now = DateTime.now();

    return Column(
      children: [
        // Week Header (7 days with dates)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 44), // Time column padding
              ...weekDates.map((d) {
                final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
                final isSel = d.year == _calendarSelectedDate.year && d.month == _calendarSelectedDate.month && d.day == _calendarSelectedDate.day;

                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _calendarSelectedDate = d),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(d).toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFFFF5722) : Colors.white60),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFFFF5722)
                                : isSel
                                    ? Colors.white24
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${d.day}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isToday ? Colors.white : Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Hourly Grid (05:00 to 22:00)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: 18, // 5 AM to 10 PM
            itemBuilder: (context, hourIdx) {
              final hour = 5 + hourIdx;
              final hourLabel = '${hour.toString().padLeft(2, '0')}:00';

              return Container(
                height: 52,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    // Time Label
                    SizedBox(
                      width: 44,
                      child: Text(
                        hourLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9.5, color: Colors.white38, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Colors.white12),

                    // 7 Day Slots
                    ...weekDates.map((d) {
                      final daySessions = _getSessionsForDate(sessions, d);
                      final hourSession = daySessions.where((s) => _parseStartHour(s.timeSlot) == hour).firstOrNull;

                      return Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.white10)),
                          ),
                          child: hourSession == null
                              ? InkWell(
                                  onTap: () => _openScheduleModal(context, state),
                                  child: const SizedBox.expand(),
                                )
                              : GestureDetector(
                                  onTap: () => _openSessionDetailsModal(context, state, hourSession),
                                  child: Container(
                                    margin: const EdgeInsets.all(1.5),
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hourSession.status == RequestStatus.pending
                                          ? const Color(0xFFFF9800).withOpacity(0.9)
                                          : const Color(0xFF00E676).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          hourSession.clientName.split(' ').first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.black),
                                        ),
                                        Text(
                                          hourSession.focusArea,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 7.5, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. GOOGLE CALENDAR 3-DAY VIEW ---
  Widget _buildThreeDayView(BuildContext context, MyPtProvider state, UserModel coach, List<SessionItem> sessions) {
    final threeDates = List.generate(3, (i) => DateTime(_calendarFocusedDate.year, _calendarFocusedDate.month, _calendarFocusedDate.day).add(Duration(days: i)));
    final now = DateTime.now();

    return Column(
      children: [
        // 3-Day Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 50),
              ...threeDates.map((d) {
                final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
                return Expanded(
                  child: Column(
                    children: [
                      Text(DateFormat('EEEE').format(d), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFFFF5722) : Colors.white70)),
                      Text('${d.day} ${DateFormat('MMM').format(d)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isToday ? const Color(0xFFFF5722) : Colors.white)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Hourly Grid for 3 Days
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: 18,
            itemBuilder: (context, hourIdx) {
              final hour = 5 + hourIdx;
              final hourLabel = '${hour.toString().padLeft(2, '0')}:00';

              return Container(
                height: 56,
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(hourLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w600)),
                    ),
                    const VerticalDivider(width: 1, color: Colors.white12),
                    ...threeDates.map((d) {
                      final daySessions = _getSessionsForDate(sessions, d);
                      final hourSession = daySessions.where((s) => _parseStartHour(s.timeSlot) == hour).firstOrNull;

                      return Expanded(
                        child: Container(
                          decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white10))),
                          child: hourSession == null
                              ? InkWell(onTap: () => _openScheduleModal(context, state), child: const SizedBox.expand())
                              : GestureDetector(
                                  onTap: () => _openSessionDetailsModal(context, state, hourSession),
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: hourSession.status == RequestStatus.pending ? const Color(0xFFFF9800) : const Color(0xFF00E676),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(hourSession.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                        Text(hourSession.focusArea, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 4. GOOGLE CALENDAR DAY VIEW (1 DAY DETAIL TIMELINE) ---
  Widget _buildDayView(BuildContext context, MyPtProvider state, UserModel coach, List<SessionItem> sessions) {
    final daySessions = _getSessionsForDate(sessions, _calendarFocusedDate);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
      itemCount: 18,
      itemBuilder: (context, hourIdx) {
        final hour = 5 + hourIdx;
        final hourStr = '${hour.toString().padLeft(2, '0')}:00';
        final session = daySessions.where((s) => _parseStartHour(s.timeSlot) == hour).firstOrNull;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(hourStr, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: session == null
                    ? InkWell(
                        onTap: () => _openScheduleModal(context, state),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available Time Slot', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
                              Icon(Icons.add, size: 14, color: Colors.white.withOpacity(0.2)),
                            ],
                          ),
                        ),
                      )
                    : _buildFullCalendarSessionCard(context, state, session),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 5. GOOGLE CALENDAR SCHEDULE / AGENDA VIEW (CHRONOLOGICAL LIST) ---
  Widget _buildScheduleAgendaView(BuildContext context, MyPtProvider state, UserModel coach, List<SessionItem> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            const Text('No sessions match your calendar filter.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Try changing the status filter or schedule a new 1-on-1 session.', style: TextStyle(fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Schedule Session 📅', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _openScheduleModal(context, state),
            ),
          ],
        ),
      );
    }

    final sortedSessions = List<SessionItem>.from(sessions)..sort((a, b) => a.date.compareTo(b.date));
    final Map<String, List<SessionItem>> grouped = {};
    for (final s in sortedSessions) {
      final key = DateFormat('yyyy-MM-dd').format(s.date);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
      children: grouped.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        final list = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Google Calendar Date Pill on the Left
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                    ),
                    Text(
                      '${date.day}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      DateFormat('MMM').format(date),
                      style: const TextStyle(fontSize: 9.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Sessions list for this date
              Expanded(
                child: Column(
                  children: list.map((s) => _buildFullCalendarSessionCard(context, state, s)).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullCalendarSessionCard(BuildContext context, MyPtProvider state, SessionItem s) {
    final isPending = s.status == RequestStatus.pending;
    final isConfirmed = s.status == RequestStatus.confirmed;
    final statusColor = isPending ? const Color(0xFFFF9800) : (isConfirmed ? const Color(0xFF00E676) : Colors.white38);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.4), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Icon(isPending ? Icons.hourglass_top_rounded : Icons.fitness_center, color: statusColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      Text('${s.timeSlot} • ${s.focusArea}', style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending ? '⏳ PENDING' : (isConfirmed ? '✓ CONFIRMED' : s.status.name.toUpperCase()),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero),
                    child: const Text('Reject ❌', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      state.rejectSession(s);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text('❌ Declined booking. 1 PT Credit refunded to ${s.clientName}.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                    child: const Text('Approve ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      state.approveSession(s);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: const Color(0xFF00E676), content: Text('✓ Approved session for ${s.clientName}!')),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                ] else if (isConfirmed) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                    icon: const Icon(Icons.videocam, size: 12, color: Colors.black),
                    label: const Text('Join 📹', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: const Color(0xFF00E676), content: Text('📹 Opening live meeting with ${s.clientName}...')),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                ],
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF29B6F6),
                    side: const BorderSide(color: Color(0xFF29B6F6)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Reschedule 🔄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _openRescheduleModal(context, state, s),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _openChatModal(context, state, peerName: s.clientName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF21262D), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
                    child: const Text('Message', style: TextStyle(fontSize: 11, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DAY SESSIONS SUMMARY MODAL (WHEN TAPPING A DATE IN MONTH VIEW) ---
  void _showDaySessionsModal(BuildContext context, MyPtProvider state, DateTime date, List<SessionItem> daySessions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(date),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    Text('${daySessions.length} Sessions', style: const TextStyle(fontSize: 12, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white12),
                ...daySessions.map((s) => _buildFullCalendarSessionCard(context, state, s)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5722),
                      side: const BorderSide(color: Color(0xFFFF5722)),
                    ),
                    icon: const Icon(Icons.calendar_view_day, size: 16),
                    label: const Text('Open in Single-Day View', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _calendarFocusedDate = date;
                        _calendarSelectedDate = date;
                        _calendarViewMode = 'Day';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SESSION DETAILS MODAL ---
  void _openSessionDetailsModal(BuildContext context, MyPtProvider state, SessionItem session) {
    final isPending = session.status == RequestStatus.pending;
    final isConfirmed = session.status == RequestStatus.confirmed;
    final statusColor = isPending ? const Color(0xFFFF9800) : (isConfirmed ? const Color(0xFF00E676) : Colors.white60);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${session.focusArea} (1-on-1 PT)',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        isPending ? '⏳ PENDING APPROVAL' : isConfirmed ? '✓ CONFIRMED' : session.status.name.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _reviewRow('Client', session.clientName),
                      const Divider(height: 14, color: Colors.white12),
                      _reviewRow('Date', DateFormat('EEEE, dd MMMM yyyy').format(session.date)),
                      const Divider(height: 14, color: Colors.white12),
                      _reviewRow('Time Slot', session.timeSlot),
                      const Divider(height: 14, color: Colors.white12),
                      _reviewRow('Duration', '1 Hour (60 mins)'),
                      const Divider(height: 14, color: Colors.white12),
                      _reviewRow('Live Room', session.meetingLink ?? 'https://meet.mypt.pro'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    if (isPending) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            state.rejectSession(session);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: Colors.redAccent, content: Text('❌ Declined booking. 1 PT Credit refunded to ${session.clientName}.')),
                            );
                          },
                          child: const Text('Reject ❌'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            state.approveSession(session);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: const Color(0xFF00E676), content: Text('✓ Session confirmed with ${session.clientName}!')),
                            );
                          },
                          child: const Text('Approve ✓', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF29B6F6),
                            side: const BorderSide(color: Color(0xFF29B6F6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.edit_calendar, size: 14),
                          label: const Text('Reschedule 🔄'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openRescheduleModal(context, state, session);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text('Message 💬', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openChatModal(context, state, peerName: session.clientName);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MONTH & YEAR PICKER MODAL ---
  void _showMonthYearPickerModal(BuildContext context) {
    int selectedYear = _calendarFocusedDate.year;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPickerState) {
          final months = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December',
          ];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: () => setPickerState(() => selectedYear -= 1),
                    ),
                    Text('$selectedYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: () => setPickerState(() => selectedYear += 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Colors.white12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, mIdx) {
                    final monthName = months[mIdx];
                    final isCurrent = _calendarFocusedDate.year == selectedYear && _calendarFocusedDate.month == (mIdx + 1);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _calendarFocusedDate = DateTime(selectedYear, mIdx + 1, 1);
                          _calendarSelectedDate = _calendarFocusedDate;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFFF5722) : const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCurrent ? const Color(0xFFFF5722) : Colors.white12),
                        ),
                        child: Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _coachClientsTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final myClients = state.getClientsForTrainer(coach.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Assigned Trainees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Chip(label: Text('${myClients.length} Clients'), backgroundColor: const Color(0xFF21262D)),
          ],
        ),
        const SizedBox(height: 12),
        if (myClients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('No clients currently assigned.', style: TextStyle(color: Colors.white54))),
          )
        else
          ...myClients.map((client) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFF161B22),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                  child: Text(client.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                ),
                title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Goal: ${client.goal} • ${client.ptCredits} PT Credits Left'),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF5722), size: 20),
                  onPressed: () => _openChatModal(context, state, peerName: client.name),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _coachBuildChartTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        const Text('Client Protocol Builder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF161B22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prescribe Daily Macro Targets', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const TextField(decoration: InputDecoration(labelText: 'Calorie Target (kcal)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: TextField(decoration: InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()))),
                    SizedBox(width: 8),
                    Expanded(child: TextField(decoration: InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()))),
                    SizedBox(width: 8),
                    Expanded(child: TextField(decoration: InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Protocol saved and assigned to client!')));
                    },
                    child: const Text('Save & Assign to Client', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    Color bgColor;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = const Color(0xFF00E676);
        bgColor = const Color(0xFF00E676).withOpacity(0.14);
        break;
      case 'advanced':
        color = const Color(0xFFFF5252);
        bgColor = const Color(0xFFFF5252).withOpacity(0.14);
        break;
      case 'intermediate':
      default:
        color = const Color(0xFFFFB74D);
        bgColor = const Color(0xFFFFB74D).withOpacity(0.14);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        difficulty,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _exerciseInfoItem({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _coachLibraryTab(MyPtProvider state) {
    final searchLower = _exerciseSearchQuery.trim().toLowerCase();
    final filtered = state.movementLibrary.where((m) {
      // Muscle filter match
      if (_selectedMuscleFilter != 'All') {
        final matchesPrimary = m.primaryMuscle.toLowerCase().contains(_selectedMuscleFilter.toLowerCase());
        final matchesSecondary = m.secondaryMuscles.toLowerCase().contains(_selectedMuscleFilter.toLowerCase());
        final matchesCategory = m.category.toLowerCase().contains(_selectedMuscleFilter.toLowerCase());
        if (!matchesPrimary && !matchesSecondary && !matchesCategory) {
          return false;
        }
      }

      // Search text match
      if (searchLower.isNotEmpty) {
        final matchesName = m.name.toLowerCase().contains(searchLower);
        final matchesMuscle = m.primaryMuscle.toLowerCase().contains(searchLower) || m.secondaryMuscles.toLowerCase().contains(searchLower);
        final matchesEquip = m.equipment.toLowerCase().contains(searchLower);
        final matchesDiff = m.difficulty.toLowerCase().contains(searchLower);
        return matchesName || matchesMuscle || matchesEquip || matchesDiff;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Title row with count and Create button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exercise Movement Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${state.movementLibrary.length} Exercises Cataloged', style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Create Exercise', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _openCreateExerciseModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search Bar
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search exercise, muscle target, equipment...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
              suffixIcon: _exerciseSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                      onPressed: () => setState(() => _exerciseSearchQuery = ''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (val) => setState(() => _exerciseSearchQuery = val),
          ),
        ),
        const SizedBox(height: 12),

        // Muscle filter chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _muscleFilterCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final cat = _muscleFilterCategories[idx];
              final isSelected = cat == _selectedMuscleFilter;
              return ChoiceChip(
                label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.white70)),
                selected: isSelected,
                selectedColor: const Color(0xFFFF5722),
                backgroundColor: const Color(0xFF161B22),
                side: BorderSide(color: isSelected ? const Color(0xFFFF5722) : Colors.white12),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedMuscleFilter = cat);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Empty state or list of cards
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.white30, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    _exerciseSearchQuery.isNotEmpty || _selectedMuscleFilter != 'All'
                        ? 'No exercises match your search filters.'
                        : 'No exercises in library yet.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (_exerciseSearchQuery.isNotEmpty || _selectedMuscleFilter != 'All')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                      onPressed: () => setState(() {
                        _exerciseSearchQuery = '';
                        _selectedMuscleFilter = 'All';
                      }),
                      child: const Text('Reset Filters'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create First Exercise'),
                      onPressed: () => _openCreateExerciseModal(context, state),
                    ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((m) {
            final idx = state.movementLibrary.indexOf(m);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: InkWell(
                onTap: () => _openCreateExerciseModal(context, state, existingItem: m, existingIndex: idx),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Exercise Name, Difficulty Pill & More Actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              m.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDifficultyBadge(m.difficulty),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                            color: const Color(0xFF1C2128),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _openCreateExerciseModal(context, state, existingItem: m, existingIndex: idx);
                              } else if (val == 'delete') {
                                state.deleteMovementItem(idx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Removed "${m.name}" from library')),
                                );
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text('Edit Exercise', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Colors.white10),
                      const SizedBox(height: 10),

                      // 1. Muscle Targetted
                      _exerciseInfoItem(
                        icon: Icons.track_changes,
                        iconColor: const Color(0xFFFF5722),
                        label: 'Muscle Targetted',
                        value: (m.secondaryMuscles.isNotEmpty && m.secondaryMuscles != 'None')
                            ? '${m.primaryMuscle} (${m.secondaryMuscles})'
                            : m.primaryMuscle,
                      ),
                      const SizedBox(height: 6),

                      // 2. Equipments
                      _exerciseInfoItem(
                        icon: Icons.fitness_center,
                        iconColor: const Color(0xFF00E676),
                        label: 'Equipments',
                        value: m.equipment,
                      ),
                      const SizedBox(height: 6),

                      // 3. Suggested Sets and Reps
                      _exerciseInfoItem(
                        icon: Icons.repeat,
                        iconColor: const Color(0xFF40C4FF),
                        label: 'Suggested Sets & Reps',
                        value: m.defaultSetsReps,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _coachPackagesTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final myPkgs = state.getPackagesForTrainer(coach.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Training Packages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Create Package', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _openCreateTrainerPackageModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Set your custom INR pricing, session count, and client perks.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),

        if (myPkgs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('No custom packages created yet. Tap "+ Create Package" to add one.', style: TextStyle(color: Colors.white54))),
          )
        else
          ...myPkgs.map((pkg) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF161B22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(pkg.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                        Text(state.formatPrice(pkg.priceInr), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00E676))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${pkg.sessionsCount} x 1-on-1 Sessions • Expiry in ${pkg.durationWeeks} Weeks', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: pkg.perks.map((perk) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(6)),
                        child: Text(perk, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      )).toList(),
                    ),
                    const Divider(height: 16, color: Colors.white12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('Delete', style: TextStyle(fontSize: 11)),
                          onPressed: () => state.deleteTrainerPackage(pkg.id),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          child: const Text('Edit Package', style: TextStyle(fontSize: 11)),
                          onPressed: () => _openCreateTrainerPackageModal(context, state, existingPackage: pkg),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ============================================================================
  // 8. HEAD COACH / GYM MGR / SUPER ADMIN VIEWS
  // ============================================================================
  Widget _buildHeadCoachView(MyPtProvider state, int tab) {
    return switch (tab) {
      2 => _coachScheduleTab(state),
      _ => _coachDashboardTab(state),
    };
  }

  Widget _buildGymMgrView(MyPtProvider state, int tab) {
    return switch (tab) {
      2 => _coachScheduleTab(state),
      _ => _coachDashboardTab(state),
    };
  }

  Widget _buildAdminView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _adminDashboardTab(state),
      1 => _adminAccountsTab(state),
      2 => _adminFlagsTab(state),
      3 => _adminTelemetryTab(state),
      4 => _adminProfileTab(state),
      _ => _adminDashboardTab(state),
    };
  }

  Widget _adminDashboardTab(MyPtProvider state) {
    final allUsers = state.getAllAccounts();
    final clientCount = allUsers.where((u) => u.role == UserRole.client).length;
    final coachCount = allUsers.where((u) => u.role == UserRole.coach).length;
    final allSessions = state.sessions;
    final totalInquiries = state.trainerRequests.length;
    final activeFlags = state.globalFlags.values.where((v) => v).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // 1. Header with Master Governance Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Master Admin Command Center 👑', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  'Full governance • ${allUsers.length} accounts • ${allSessions.length} total sessions',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: const Text('Switch User 👑', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _openMasterUserSwitcherModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. High Level Platform KPI Bento
        Row(
          children: [
            Expanded(child: _statCard('TOTAL USERS', '${allUsers.length}', '$clientCount Clients • $coachCount Coaches', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('BOOKED SESSIONS', '${allSessions.length}', '$totalInquiries Inquiries', const Color(0xFF00E676))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _statCard('FLAGS ACTIVE', '$activeFlags / ${state.globalFlags.length}', 'Runtime Controls', const Color(0xFF29B6F6))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('CURRENCY & REGION', '${state.currentCurrencyInfo.flag} ${state.selectedCurrency}', state.selectedCountry, Colors.amber)),
          ],
        ),
        const SizedBox(height: 18),

        // 3. Quick Master Governance Shortcuts
        const Text('Governance Shortcuts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _adminShortcutCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'User Accounts',
                subtitle: 'Manage roles & clients',
                color: const Color(0xFF29B6F6),
                onTap: () => setState(() => _tabIndex = 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _adminShortcutCard(
                icon: Icons.toggle_on_outlined,
                title: 'Feature Flags',
                subtitle: 'Toggle kill-switches',
                color: const Color(0xFFFF5722),
                onTap: () => setState(() => _tabIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _adminShortcutCard(
                icon: Icons.dns_outlined,
                title: 'Telemetry & DB',
                subtitle: 'Audit logs & metrics',
                color: const Color(0xFF00E676),
                onTap: () => setState(() => _tabIndex = 3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _adminShortcutCard(
                icon: Icons.person_outline,
                title: 'Master Profile',
                subtitle: 'Theme & privileges',
                color: Colors.amber,
                onTap: () => setState(() => _tabIndex = 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Recent System Events & Activity Log
        Card(
          color: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Live Activity Stream', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E676)),
                        SizedBox(width: 6),
                        Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white12),
                if (state.notifications.isNotEmpty) ...[
                  ...state.notifications.take(4).map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFFFF5722)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(n.message, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                            ],
                          ),
                        ),
                        Text(DateFormat('hh:mm a').format(n.timestamp), style: const TextStyle(fontSize: 9.5, color: Colors.white38)),
                      ],
                    ),
                  )),
                ] else ...[
                  const Text('No recent alerts. System operating normally.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _adminShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminProfileTab(MyPtProvider state) {
    final user = state.currentUser!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Master Admin User Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4), width: 1.2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '👑',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('SUPER ADMIN 👑', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF00E676))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Master governance & omnipotent test privileges', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Dual Roles & Privileges
        const Text('DUAL ROLES & TESTING CAPABILITIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assigned Persona Roles:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _roleBadge('👑 Super Admin', const Color(0xFF00E676)),
                  _roleBadge('🥇 Head Coach', const Color(0xFFFFD54F)),
                  _roleBadge('🏢 Gym Manager', const Color(0xFFAB47BC)),
                  _roleBadge('🏋️ Coach / Trainer', const Color(0xFFFF5722)),
                  _roleBadge('👤 Client / Trainee', const Color(0xFF29B6F6)),
                ],
              ),
              const Divider(height: 20, color: Colors.white12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5722),
                    side: const BorderSide(color: Color(0xFFFF5722)),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Open 1-Tap Persona Switcher 👑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _openMasterUserSwitcherModal(context, state),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Theme & Appearance (Dark / Light Mode)
        const Text('THEME & APPEARANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (state.isDarkMode ? const Color(0xFF7C4DFF) : const Color(0xFFFFB300)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: state.isDarkMode ? const Color(0xFFB388FF) : const Color(0xFFFFB300),
                size: 20,
              ),
            ),
            title: Text(
              state.isDarkMode ? 'Dark Mode' : 'Light Mode',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            subtitle: Text(
              state.isDarkMode ? 'Sleek midnight dark theme active' : 'Bright crisp daylight theme active',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            trailing: Switch.adaptive(
              value: state.isDarkMode,
              activeColor: const Color(0xFFFF5722),
              inactiveThumbColor: const Color(0xFFFFB300),
              inactiveTrackColor: Colors.white24,
              onChanged: (val) => state.setIsDarkMode(val),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Regional Currency Selector
        const Text('CURRENCY & PRICING REGION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.currency_exchange, color: Color(0xFF00E676), size: 20),
            ),
            title: Text(
              '${state.currentCurrencyInfo.flag} ${state.selectedCountry} (${state.selectedCurrency})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            subtitle: const Text('Change default currency across the platform', style: TextStyle(fontSize: 12, color: Colors.white60)),
            trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () => _openCurrencySelector(context, state),
              child: const Text('Change', style: TextStyle(fontSize: 12)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sign Out Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21262D),
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign Out from myPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => state.logout(),
          ),
        ),
      ],
    );
  }

  Widget _roleBadge(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withOpacity(0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)),
    );
  }

  String _formatFlagTitle(String key) {
    return switch (key) {
      'ai_fitness_copilot' => 'AI Fitness Copilot',
      'bento_analytics_grid' => 'Bento Analytics Dashboard',
      'strict_headcoach_hierarchy' => 'Strict Head Coach Hierarchy',
      'dynamic_currency_converter' => 'Dynamic Currency Converter',
      'instant_package_checkout' => 'Instant Package Checkout',
      _ => key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
    };
  }

  String _formatFlagSubtitle(String key) {
    return switch (key) {
      'ai_fitness_copilot' => 'Intelligent workout recommendations, exercise insights, and form analysis.',
      'bento_analytics_grid' => 'Modular progress cards visualizing nutrition targets, weekly splits, and body recomposition.',
      'strict_headcoach_hierarchy' => 'Enforce multi-tier coach supervision, approval gates, and facility squad management.',
      'dynamic_currency_converter' => 'Real-time localized price conversion across INR (₹), USD (\$), EUR (€), GBP (£), and AED.',
      'instant_package_checkout' => 'Direct online payment and instant PT credit deposit for personalized training packages.',
      _ => 'Runtime dynamic platform feature toggle.',
    };
  }

  void _showResetFlagsConfirmationDialog(BuildContext context, MyPtProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: Color(0xFFFF5722), size: 22),
            SizedBox(width: 8),
            Text('Reset Feature Flags?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to restore all runtime feature flags to their default enabled states?',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              state.globalFlags.forEach((key, _) => state.toggleFlag(key, true));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF00E676),
                  content: Text('✓ All feature flags have been successfully reset to defaults!'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Confirm Reset', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _adminFlagsTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Super Admin Governance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5722),
                side: const BorderSide(color: Color(0xFFFF5722)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.restart_alt, size: 16, color: Color(0xFFFF5722)),
              label: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _showResetFlagsConfirmationDialog(context, state),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Runtime dynamic feature flags and platform controls', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        Card(
          color: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white12)),
          child: Column(
            children: state.globalFlags.entries.map((e) {
              final isLast = state.globalFlags.keys.last == e.key;
              final flagTitle = _formatFlagTitle(e.key);
              final flagSubtitle = _formatFlagSubtitle(e.key);

              return Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      flagTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        flagSubtitle,
                        style: const TextStyle(fontSize: 11.5, color: Colors.white60, height: 1.3),
                      ),
                    ),
                    value: e.value,
                    activeColor: const Color(0xFFFF5722),
                    onChanged: (val) => state.toggleFlag(e.key, val),
                  ),
                  if (!isLast) const Divider(height: 1, color: Colors.white10),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _adminAccountsTab(MyPtProvider state) {
    final allUsers = state.getAllAccounts();
    final clientCount = allUsers.where((u) => u.role == UserRole.client).length;
    final coachCount = allUsers.where((u) => u.role == UserRole.coach).length;
    final headCoachCount = allUsers.where((u) => u.role == UserRole.headCoach).length;
    final managerCount = allUsers.where((u) => u.role == UserRole.gymMgr).length;
    final adminCount = allUsers.where((u) => u.role == UserRole.superAdmin).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('User Accounts Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: const Text('Switch User 👑', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _openMasterUserSwitcherModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Master user governance & instant 1-tap account switching', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),

        // Summary Metric Cards
        Row(
          children: [
            Expanded(child: _statCard('TOTAL USERS', '${allUsers.length}', 'Registered', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('CLIENTS', '$clientCount', 'Trainees', const Color(0xFF29B6F6))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('COACHES', '$coachCount', 'Trainers', const Color(0xFF00E676))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('LEADERSHIP', '${headCoachCount + managerCount + adminCount}', 'Admins/Leads', Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),

        // User Directory List
        const Text('All Registered User Accounts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...allUsers.map((u) {
          final isCurrent = state.currentUser?.id == u.id;
          final isMaster = u.email == 'master@mypt.com';
          final roleColor = switch (u.role) {
            UserRole.client => const Color(0xFF29B6F6),
            UserRole.coach => const Color(0xFFFF5722),
            UserRole.headCoach => const Color(0xFFFFD54F),
            UserRole.gymMgr => const Color(0xFFAB47BC),
            UserRole.superAdmin => const Color(0xFF00E676),
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: isCurrent ? const Color(0xFF21262D) : const Color(0xFF161B22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isCurrent ? const Color(0xFFFF5722) : Colors.white12,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: roleColor.withOpacity(0.2),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0] : '?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: roleColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    u.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.role.name.toUpperCase(),
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                                  ),
                                ),
                                if (isMaster) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('MASTER 👑', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF00E676))),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(u.email, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Text('ACTIVE NOW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                        ),
                    ],
                  ),
                  const Divider(height: 18, color: Colors.white12),

                  // Account Details Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (u.role == UserRole.client) ...[
                        Text('PT Credits: ${u.ptCredits}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                        Text('Weight: ${u.currentWeight} kg', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ] else if (u.role == UserRole.coach) ...[
                        Text('Managed Clients: ${state.getClientsForTrainer(u.id).length}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        Text('Packages: ${state.getPackagesForTrainer(u.id).length}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ] else ...[
                        Text('Dual Roles: ${u.dualRoles?.map((r) => r.name).join(', ') ?? 'None'}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (u.role == UserRole.client) ...[
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          icon: const Icon(Icons.token_outlined, size: 13, color: Color(0xFF29B6F6)),
                          label: const Text('Adjust Credits', style: TextStyle(fontSize: 11, color: Color(0xFF29B6F6))),
                          onPressed: () => _openAdjustCreditsDialog(context, state, u),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (!isCurrent)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.person_pin, size: 13),
                          label: const Text('Impersonate / Switch 👤', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            state.impersonateUser(u);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF00E676),
                                content: Text('👑 Switched to ${u.name} (${u.role.name.toUpperCase()})'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _adminTelemetryTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const Text('System Telemetry & Live Diagnostics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Real-time runtime state, audit counters, and event log', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),

        Card(
          color: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RUNTIME METRICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                _telemetryRow('Active User', '${state.currentUser?.name} (${state.currentUser?.email})'),
                _telemetryRow('Impersonation Status', state.isImpersonating ? 'Active (Anchored to ${state.originalMasterUser?.name})' : 'Inactive (Direct)'),
                _telemetryRow('Region & Currency', '${state.userLocation} • ${state.selectedCurrency}'),
                _telemetryRow('Total Booked Sessions', '${state.sessions.length} sessions recorded'),
                _telemetryRow('Consultation Requests', '${state.trainerRequests.length} inquiries'),
                _telemetryRow('Custom Trainer Packages', '${state.packages.length} active packages'),
                _telemetryRow('Movement Library Entries', '${state.movementLibrary.length} exercises cataloged'),
                _telemetryRow('Total System Notifications', '${state.notifications.length} in-app alerts'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _telemetryRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
        ],
      ),
    );
  }

  void _openAdjustCreditsDialog(BuildContext context, MyPtProvider state, UserModel client) {
    final ctrl = TextEditingController(text: client.ptCredits.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adjust Credits: ${client.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance: ${client.ptCredits} PT Credits', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New PT Credit Balance',
                filled: true,
                fillColor: Color(0xFF0D1117),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 0) {
                state.updateClientCredits(client.id, val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF00E676),
                    content: Text('✓ Updated ${client.name}\'s PT Credits to $val.'),
                  ),
                );
              }
            },
            child: const Text('Save Credits'),
          ),
        ],
      ),
    );
  }

  // --- ACTIVE MASTER IMPERSONATION BANNER (RESPONSIVE ZERO-OVERFLOW) ---
  Widget _buildImpersonationBanner(BuildContext context, MyPtProvider state) {
    final user = state.currentUser!;
    final origMaster = state.originalMasterUser?.name ?? 'Master Admin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF5722)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '👑 Master: ${user.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${user.email} • Via $origMaster',
                  style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF161B22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _openMasterUserSwitcherModal(context, state),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 12, color: Color(0xFFFF5722)),
                SizedBox(width: 3),
                Text('Switch', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE65100),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              state.returnToMasterAdmin();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF00E676),
                  content: Text('👑 Exited impersonation. Restored Master Admin account.'),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 12, color: Color(0xFFE65100)),
                SizedBox(width: 3),
                Text('Exit', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MASTER USER SWITCHER MODAL (ANY SPECIFIC USER ACCOUNT) ---
  void _openMasterUserSwitcherModal(BuildContext context, MyPtProvider state) {
    String searchQuery = '';
    String selectedRoleFilter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final allUsers = state.getAllAccounts();

          final filteredUsers = allUsers.where((u) {
            final q = searchQuery.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                u.role.name.toLowerCase().contains(q) ||
                u.goal.toLowerCase().contains(q);

            final matchesRole = selectedRoleFilter == 'All' ||
                switch (selectedRoleFilter) {
                  'Clients' => u.role == UserRole.client,
                  'Coaches' => u.role == UserRole.coach,
                  'Head Coaches' => u.role == UserRole.headCoach,
                  'Managers' => u.role == UserRole.gymMgr,
                  'Admins' => u.role == UserRole.superAdmin,
                  _ => true,
                };

            return matchesQuery && matchesRole;
          }).toList();

          final clientCount = allUsers.where((u) => u.role == UserRole.client).length;
          final coachCount = allUsers.where((u) => u.role == UserRole.coach).length;
          final headCoachCount = allUsers.where((u) => u.role == UserRole.headCoach).length;
          final managerCount = allUsers.where((u) => u.role == UserRole.gymMgr).length;
          final adminCount = allUsers.where((u) => u.role == UserRole.superAdmin).length;

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.manage_accounts, color: Color(0xFFFF5722), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Master User Switcher 👑', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Impersonate or test any individual user account', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (state.isImpersonating) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          state.returnToMasterAdmin();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF00E676),
                              content: Text('👑 Returned to Master Admin account.'),
                            ),
                          );
                        },
                        child: const Text('Exit to Master', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Super Admin Governance & Feature Flags Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune, color: Color(0xFFFF5722), size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Weight Feature Flag',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Display target weights configured by coaches/clients',
                                  style: TextStyle(fontSize: 10, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: state.enableExerciseTargetWeight,
                            activeColor: const Color(0xFF00E676),
                            onChanged: (val) {
                              state.setEnableExerciseTargetWeight(val);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 10, color: Colors.white10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00E676), size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meal Photo & Nutrition Log Flag',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Enable meal picture upload in 1-on-1 trainer chat',
                                  style: TextStyle(fontSize: 10, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: state.enableMealPhotoUpload,
                            activeColor: const Color(0xFF00E676),
                            onChanged: (val) {
                              state.setEnableMealPhotoUpload(val);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by user name, email, or role...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.white60),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setModalState(() => searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setModalState(() => searchQuery = val),
                ),
                const SizedBox(height: 10),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _roleFilterChip('All (${allUsers.length})', 'All', selectedRoleFilter, (sel) => setModalState(() => selectedRoleFilter = sel)),
                      const SizedBox(width: 6),
                      _roleFilterChip('Clients 👤 ($clientCount)', 'Clients', selectedRoleFilter, (sel) => setModalState(() => selectedRoleFilter = sel)),
                      const SizedBox(width: 6),
                      _roleFilterChip('Coaches 🏋️ ($coachCount)', 'Coaches', selectedRoleFilter, (sel) => setModalState(() => selectedRoleFilter = sel)),
                      const SizedBox(width: 6),
                      _roleFilterChip('Head Coaches 🥇 ($headCoachCount)', 'Head Coaches', selectedRoleFilter, (sel) => setModalState(() => selectedRoleFilter = sel)),
                      const SizedBox(width: 6),
                      _roleFilterChip('Managers 🏢 ($managerCount)', 'Managers', selectedRoleFilter, (sel) => setModalState(() => selectedRoleFilter = sel)),
                      const SizedBox(width: 6),
                      _roleFilterChip('Admins 👑 ($adminCount)', 'Admins', selectedRoleFilter, (sel) => setModalState(() => selectedRoleFilter = sel)),
                    ],
                  ),
                ),
                const Divider(height: 20, color: Colors.white12),

                // User Cards List
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(
                          child: Text('No users match the search filter.', style: TextStyle(color: Colors.white54)),
                        )
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, idx) {
                            final u = filteredUsers[idx];
                            final isCurrent = state.currentUser?.id == u.id;
                            final isMaster = u.email == 'master@mypt.com';

                            final roleColor = switch (u.role) {
                              UserRole.client => const Color(0xFF29B6F6),
                              UserRole.coach => const Color(0xFFFF5722),
                              UserRole.headCoach => const Color(0xFFFFD54F),
                              UserRole.gymMgr => const Color(0xFFAB47BC),
                              UserRole.superAdmin => const Color(0xFF00E676),
                            };

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isCurrent ? const Color(0xFF21262D) : const Color(0xFF0D1117),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isCurrent
                                      ? const Color(0xFFFF5722)
                                      : isMaster
                                          ? const Color(0xFF00E676).withOpacity(0.4)
                                          : Colors.white10,
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: roleColor.withOpacity(0.2),
                                      child: Text(
                                        u.name.isNotEmpty ? u.name[0] : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: roleColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  u.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  u.role.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: roleColor,
                                                  ),
                                                ),
                                              ),
                                              if (isMaster) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00E676).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'MASTER',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF00E676),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            u.email,
                                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            u.role == UserRole.client
                                                ? '${u.ptCredits} PT Credits • ${u.goal}'
                                                : u.role == UserRole.coach
                                                    ? 'Assigned to Head Coach: ${u.headCoachId ?? 'None'}'
                                                    : 'Privilege Level: Full System Access',
                                            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ACTIVE 👤',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00E676),
                                          ),
                                        ),
                                      )
                                    else
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF5722),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          state.impersonateUser(u);
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: const Color(0xFF00E676),
                                              content: Text('👑 Switched to ${u.name} (${u.role.name.toUpperCase()})'),
                                            ),
                                          );
                                        },
                                        child: const Text('Switch 👤', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roleFilterChip(String label, String key, String current, Function(String) onSelect) {
    final isSel = current == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: const Color(0xFFFF5722),
      backgroundColor: const Color(0xFF0D1117),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? Colors.white : Colors.white70,
      ),
      onSelected: (val) {
        if (val) onSelect(key);
      },
    );
  }

  // ============================================================================
  // 9. MODALS & BOTTOM SHEETS
  // ============================================================================

  void _openLocationPromptModal(BuildContext context, MyPtProvider state) {
    final supportedCountries = [
      ('India', '🇮🇳', 'INR'),
      ('United States', '🇺🇸', 'USD'),
      ('United Kingdom', '🇬🇧', 'GBP'),
      ('Canada', '🇨🇦', 'CAD'),
      ('United Arab Emirates', '🇦🇪', 'AED'),
      ('Australia', '🇦🇺', 'AUD'),
      ('Singapore', '🇸🇬', 'SGD'),
      ('Germany', '🇩🇪', 'EUR'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFFFF5722)),
                        SizedBox(width: 8),
                        Text('Select Your Country 🌍', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Default pricing & certified trainer matching is localized to your country.', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: supportedCountries.map((item) {
                    final (country, flag, cur) = item;
                    final isSelected = state.selectedCountry == country;
                    return ChoiceChip(
                      label: Text('$flag $country'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFF5722),
                      backgroundColor: const Color(0xFF0D1117),
                      labelStyle: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.white70),
                      onSelected: (sel) {
                        if (sel) {
                          state.setUserLocation(country, currencyCode: cur);
                          Navigator.pop(ctx);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCurrencySelector(BuildContext context, MyPtProvider state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...MyPtProvider.supportedCurrencies.values.map((cur) {
                  final isSelected = state.selectedCurrency == cur.code;
                  return ListTile(
                    leading: Text(cur.flag, style: const TextStyle(fontSize: 22)),
                    title: Text('${cur.name} (${cur.code})', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFFF5722) : Colors.white)),
                    trailing: Text(cur.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onTap: () {
                      state.setCurrency(cur.code);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPurchaseOptionsModal(BuildContext context, MyPtProvider state, TrainingPackage pkg) {
    final user = state.currentUser;
    String selectedGoal = (user != null && kStandardFitnessGoals.contains(user.goal)) ? user.goal : kStandardFitnessGoals.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPurchaseState) {
          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(pkg.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                        Text(state.formatPrice(pkg.priceInr), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00E676))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('+${pkg.sessionsCount} PT Credits • Coach ${pkg.trainerName}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const Divider(height: 18, color: Colors.white12),

                    // Primary Fitness Goal Selector
                    const Row(
                      children: [
                        Icon(Icons.flag_circle, size: 14, color: Color(0xFFFF5722)),
                        SizedBox(width: 6),
                        Text('Target Fitness Goal for this Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: kStandardFitnessGoals.contains(selectedGoal) ? selectedGoal : kStandardFitnessGoals.first,
                          dropdownColor: const Color(0xFF161B22),
                          items: kStandardFitnessGoals.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setPurchaseState(() => selectedGoal = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Choose Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 10),

                    InkWell(
                      onTap: () {
                        state.updateUserGoal(selectedGoal);
                        state.requestPackagePurchase(pkg, 'offline');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFFF9800),
                            content: Text('⏳ Offline payment request sent to Coach ${pkg.trainerName} for "$selectedGoal". Once approved, +${pkg.sessionsCount} PT Credits will be added.'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.handshake, color: Color(0xFFFF9800), size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('💵 Payment Taken Offline (Cash / Direct UPI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  SizedBox(height: 2),
                                  Text('Pay trainer directly. Coach confirms receipt to activate PT credits.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    InkWell(
                      onTap: () {
                        state.updateUserGoal(selectedGoal);
                        state.requestPackagePurchase(pkg, 'online');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF00E676),
                            content: Text('🎉 Instant Online Payment Successful! +${pkg.sessionsCount} PT Credits added for "$selectedGoal".'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.credit_card, color: Color(0xFF00E676), size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('⚡ Instant Online / UPI Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  SizedBox(height: 2),
                                  Text('Immediate activation and PT credit deposit.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openRescheduleModal(BuildContext context, MyPtProvider state, SessionItem session) {
    DateTime selectedDate = session.date;
    String selectedSlot = session.timeSlot;

    final timeSlots = [
      '05:00 AM - 06:00 AM', '05:30 AM - 06:30 AM', '06:00 AM - 07:00 AM', '06:30 AM - 07:30 AM',
      '07:00 AM - 08:00 AM', '07:30 AM - 08:30 AM', '08:00 AM - 09:00 AM', '08:30 AM - 09:30 AM',
      '09:00 AM - 10:00 AM', '09:30 AM - 10:30 AM', '10:00 AM - 11:00 AM', '10:30 AM - 11:30 AM',
      '11:00 AM - 12:00 PM', '11:30 AM - 12:30 PM', '12:00 PM - 01:00 PM', '12:30 PM - 01:30 PM',
      '01:00 PM - 02:00 PM', '01:30 PM - 02:30 PM', '02:00 PM - 03:00 PM', '02:30 PM - 03:30 PM',
      '03:00 PM - 04:00 PM', '03:30 PM - 04:30 PM', '04:00 PM - 05:00 PM', '04:30 PM - 05:30 PM',
      '05:00 PM - 06:00 PM', '05:30 PM - 06:30 PM', '06:00 PM - 07:00 PM', '06:30 PM - 07:30 PM',
      '07:00 PM - 08:00 PM', '07:30 PM - 08:30 PM', '08:00 PM - 09:00 PM', '08:30 PM - 09:30 PM',
      '09:00 PM - 10:00 PM', '09:30 PM - 10:30 PM', '10:00 PM - 11:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reschedule Session: ${session.focusArea}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('With: ${session.clientName} & Coach ${session.trainerName}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.white12),

                    // Date Selection with 21-day horizontal scroll + Calendar Picker Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select New Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Color(0xFFFF5722)),
                              SizedBox(width: 4),
                              Text('Pick Calendar Date 📅', style: TextStyle(fontSize: 11, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(21, (i) {
                          final now = DateTime.now();
                          final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
                          final isSel = selectedDate.year == d.year && selectedDate.month == d.month && selectedDate.day == d.day;
                          final isToday = i == 0;
                          final labelText = isToday ? 'Today, ${DateFormat('dd MMM').format(d)}' : DateFormat('EEE, dd MMM').format(d);

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(labelText),
                              selected: isSel,
                              selectedColor: const Color(0xFFFF5722),
                              backgroundColor: const Color(0xFF0D1117),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : Colors.white70,
                              ),
                              onSelected: (sel) => setModalState(() => selectedDate = d),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Select New Time Slot (1-Hour Duration)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: timeSlots.contains(selectedSlot) ? selectedSlot : timeSlots[10],
                          dropdownColor: const Color(0xFF161B22),
                          menuMaxHeight: 300,
                          items: timeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedSlot = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                        onPressed: () {
                          state.rescheduleSession(session, selectedDate, selectedSlot);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF00E676),
                              content: Text('✓ Session rescheduled to ${DateFormat('EEEE, dd MMM').format(selectedDate)} at $selectedSlot!'),
                            ),
                          );
                        },
                        child: const Text('Confirm Reschedule 🔄', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- DYNAMIC BOOKING FLOW (14 DAYS + CALENDAR PICKER + CONFIRMATION REVIEW MODAL) ---
  void _openScheduleModal(BuildContext context, MyPtProvider state, {UserModel? targetTrainer}) {
    final user = state.currentUser;
    if (user == null) return;

    // Check if client has a trainer
    UserModel? trainer = targetTrainer;
    if (trainer == null && user.trainerId != null) {
      for (final t in state.allTrainers) {
        if (t.id == user.trainerId) {
          trainer = t;
          break;
        }
      }
    }

    if (user.role == UserRole.client) {
      if (trainer == null || user.trainerApprovalStatus != TrainerApprovalStatus.approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFF9800),
            content: Text('Please select your primary coach first before scheduling a session.'),
          ),
        );
        setState(() => _tabIndex = 1); // Open Discover tab
        return;
      }
      if (user.ptCredits <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFF9800),
            content: Text('You have 0 PT Credits available. Please view training packages to top up credits.'),
          ),
        );
        setState(() => _tabIndex = 0); // Open Dashboard Packages section
        return;
      }
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '10:00 AM - 11:00 AM';
    String selectedGoal = (kStandardFitnessGoals.contains(user.goal)) ? user.goal : kStandardFitnessGoals.first;
    String focus = 'Hypertrophy & Form';
    final focusCtrl = TextEditingController(text: focus);

    final timeSlots = [
      '05:00 AM - 06:00 AM', '05:30 AM - 06:30 AM', '06:00 AM - 07:00 AM', '06:30 AM - 07:30 AM',
      '07:00 AM - 08:00 AM', '07:30 AM - 08:30 AM', '08:00 AM - 09:00 AM', '08:30 AM - 09:30 AM',
      '09:00 AM - 10:00 AM', '09:30 AM - 10:30 AM', '10:00 AM - 11:00 AM', '10:30 AM - 11:30 AM',
      '11:00 AM - 12:00 PM', '11:30 AM - 12:30 PM', '12:00 PM - 01:00 PM', '12:30 PM - 01:30 PM',
      '01:00 PM - 02:00 PM', '01:30 PM - 02:30 PM', '02:00 PM - 03:00 PM', '02:30 PM - 03:30 PM',
      '03:00 PM - 04:00 PM', '03:30 PM - 04:30 PM', '04:00 PM - 05:00 PM', '04:30 PM - 05:30 PM',
      '05:00 PM - 06:00 PM', '05:30 PM - 06:30 PM', '06:00 PM - 07:00 PM', '06:30 PM - 07:30 PM',
      '07:00 PM - 08:00 PM', '07:30 PM - 08:30 PM', '08:00 PM - 09:00 PM', '08:30 PM - 09:30 PM',
      '09:00 PM - 10:00 PM', '09:30 PM - 10:30 PM', '10:00 PM - 11:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final coachName = trainer?.name ?? 'Alex Rivera';

          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('Schedule with Coach $coachName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFFF5722).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text('${user.ptCredits} PT Credits Left', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date Selection with 14-day horizontal scroll + Calendar Picker Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Color(0xFFFF5722)),
                              SizedBox(width: 4),
                              Text('Pick Calendar Date 📅', style: TextStyle(fontSize: 11, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(21, (i) {
                          final now = DateTime.now();
                          final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
                          final isSel = selectedDate.year == d.year && selectedDate.month == d.month && selectedDate.day == d.day;
                          final isToday = i == 0;
                          final labelText = isToday ? 'Today, ${DateFormat('dd MMM').format(d)}' : DateFormat('EEE, dd MMM').format(d);

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(labelText),
                              selected: isSel,
                              selectedColor: const Color(0xFFFF5722),
                              backgroundColor: const Color(0xFF0D1117),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : Colors.white70,
                              ),
                              onSelected: (sel) => setModalState(() => selectedDate = d),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time Slot Selector
                    const Text('Select Time Slot (1-Hour Duration)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: timeSlots.contains(selectedSlot) ? selectedSlot : timeSlots[10],
                          dropdownColor: const Color(0xFF161B22),
                          menuMaxHeight: 300,
                          items: timeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedSlot = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Primary Fitness Goal Selector
                    const Row(
                      children: [
                        Icon(Icons.flag_circle, size: 14, color: Color(0xFFFF5722)),
                        SizedBox(width: 6),
                        Text('Primary Fitness Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: kStandardFitnessGoals.contains(selectedGoal) ? selectedGoal : kStandardFitnessGoals.first,
                          dropdownColor: const Color(0xFF161B22),
                          items: kStandardFitnessGoals.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedGoal = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Custom Workout Focus Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.fitness_center, size: 14, color: Color(0xFF29B6F6)),
                            SizedBox(width: 6),
                            Text('Workout Focus (Custom)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                          ],
                        ),
                        Text('Type custom focus', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: focusCtrl,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF0D1117),
                        hintText: 'e.g. Hypertrophy & Form, Chest & Triceps, Deadlift PR...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white30),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => focus = val.trim(),
                    ),
                    const SizedBox(height: 8),

                    // Quick suggested tags that populate the custom focus
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Hypertrophy & Form',
                          'Upper Body Power',
                          'Squats & Leg Drive',
                          'Core & Conditioning',
                          'Mobility & Form Check',
                        ].map((sug) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(sug, style: const TextStyle(fontSize: 10)),
                            backgroundColor: const Color(0xFF0D1117),
                            side: const BorderSide(color: Colors.white12),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            onPressed: () {
                              setModalState(() {
                                focusCtrl.text = sug;
                                focus = sug;
                              });
                            },
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                        onPressed: () {
                          final customFocus = focusCtrl.text.trim().isNotEmpty ? focusCtrl.text.trim() : focus;
                          Navigator.pop(ctx);
                          _openBookingReviewModal(
                            context,
                            state,
                            coachName: coachName,
                            date: selectedDate,
                            timeSlot: selectedSlot,
                            goal: selectedGoal,
                            focusArea: customFocus,
                          );
                        },
                        child: const Text('Review & Confirm Booking 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REVIEW & CONFIRM BOOKING MODAL (PREVENTS ACCIDENTAL DOUBLE CLICKS) ---
  void _openBookingReviewModal(
    BuildContext context,
    MyPtProvider state, {
    required String coachName,
    required DateTime date,
    required String timeSlot,
    required String goal,
    required String focusArea,
  }) {
    final user = state.currentUser;
    if (user == null) return;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setReviewState) {
          final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(date);

          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Confirm Your Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: Column(
                        children: [
                          _reviewRow('Coach', 'Coach $coachName'),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Date', formattedDate),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Time', timeSlot),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Primary Goal', goal),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Workout Focus', focusArea),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Duration', '1 Hour (60 mins)'),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Approval Status', 'Pending Coach Acceptance', isHighlight: true),
                          const Divider(height: 14, color: Colors.white12),
                          _reviewRow('Cost', '1 PT Credit (${user.ptCredits - 1} PT Credits balance after request)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () {
                                    setReviewState(() => isProcessing = true);
                                    state.updateUserGoal(goal);
                                    state.scheduleSession(
                                      SessionItem(
                                        id: 's_${DateTime.now().millisecondsSinceEpoch}',
                                        clientId: user.id,
                                        clientName: user.name,
                                        trainerName: coachName,
                                        date: date,
                                        timeSlot: timeSlot,
                                        focusArea: focusArea,
                                        status: RequestStatus.pending,
                                      ),
                                    );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFFFF9800),
                                        content: Text('⏳ Session booking requested! Waiting for Coach $coachName to approve.'),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  },
                            child: Text(
                              isProcessing ? 'Submitting...' : 'Request Booking ⏳',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _reviewRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
              color: isHighlight ? const Color(0xFF00E676) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // --- CHAT MODAL (WITH MEAL PICTURE & NUTRITION LOGGING) ---
  void _openChatModal(BuildContext context, MyPtProvider state, {required String peerName}) {
    final textCtrl = TextEditingController();
    final isTrainer = state.currentUser?.role == UserRole.coach;
    final myName = state.currentUser?.name ?? 'User';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final messages = state.getMessagesBetween(myName, peerName);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.82,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                        child: Text(peerName.isNotEmpty ? peerName[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coach $peerName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Text('1-on-1 Direct Chat • Nutrition & Workout Tracking', style: TextStyle(fontSize: 11, color: Colors.white60)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.white12),

                  Expanded(
                    child: messages.isEmpty
                        ? const Center(child: Text('Say hello or log your daily meals for coach review!', style: TextStyle(color: Colors.white54, fontSize: 13)))
                        : ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (context, idx) {
                              final m = messages[idx];
                              final isMe = m.senderName.toLowerCase() == myName.toLowerCase();
                              final meal = m.mealAttachment;

                              if (meal != null) {
                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.78,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF1E2632) : const Color(0xFF161B22),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isMe ? const Color(0xFFFF5722).withOpacity(0.6) : const Color(0xFF00E676).withOpacity(0.4),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header with Meal Type Tag & Date
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF5722).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.4)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(meal.emoji, style: const TextStyle(fontSize: 12)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    meal.mealType.toUpperCase(),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              DateFormat('dd MMM • hh:mm a').format(meal.mealDate),
                                              style: const TextStyle(fontSize: 10, color: Colors.white54),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Meal Photo
                                        if (meal.photoUrl != null && meal.photoUrl!.isNotEmpty) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              height: 140,
                                              width: double.infinity,
                                              color: const Color(0xFF0D1117),
                                              child: Image.network(
                                                meal.photoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: const Color(0xFF0D1117),
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(meal.emoji, style: const TextStyle(fontSize: 32)),
                                                        const SizedBox(height: 4),
                                                        Text('${meal.mealType} Photo Log', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],

                                        // Meal Description
                                        Text(
                                          meal.description,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),

                                        // Macros / Calories Pills (if available)
                                        if (meal.caloriesKcal != null || meal.proteinGrams != null) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              if (meal.caloriesKcal != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF9800).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '🔥 ${meal.caloriesKcal} kcal',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                                                  ),
                                                ),
                                              if (meal.proteinGrams != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00E676).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '💪 ${meal.proteinGrams}g Protein',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],

                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            const Icon(Icons.done_all, size: 12, color: Color(0xFF00E676)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Logged for Coach Review',
                                              style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFFFF5722) : const Color(0xFF21262D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(m.text, style: const TextStyle(fontSize: 13, color: Colors.white)),
                                      const SizedBox(height: 2),
                                      Text(DateFormat('hh:mm a').format(m.timestamp), style: const TextStyle(fontSize: 9, color: Colors.white54)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  Row(
                    children: [
                      // Camera / Meal Picture Upload Button (Controlled by Feature Flag)
                      if (state.enableMealPhotoUpload) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00E676), size: 20),
                            tooltip: 'Upload Meal Picture & Log',
                            onPressed: () {
                              _openMealUploadModal(
                                context,
                                state,
                                peerName: peerName,
                                isFromTrainer: isTrainer,
                                onMealSent: () => setModalState(() {}),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: textCtrl,
                          decoration: InputDecoration(
                            hintText: 'Type a message to Coach $peerName...',
                            filled: true,
                            fillColor: const Color(0xFF0D1117),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onChanged: (_) => setModalState(() {}),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              state.sendChatMessage(senderName: myName, receiverName: peerName, text: val.trim(), isFromTrainer: isTrainer);
                              textCtrl.clear();
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: textCtrl.text.trim().isNotEmpty ? const Color(0xFFFF5722) : Colors.white12,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          onPressed: textCtrl.text.trim().isEmpty
                              ? null
                              : () {
                                  state.sendChatMessage(senderName: myName, receiverName: peerName, text: textCtrl.text.trim(), isFromTrainer: isTrainer);
                                  textCtrl.clear();
                                  setModalState(() {});
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- POPUP MODAL: UPLOAD MEAL PICTURE & DAILY NUTRITION LOG ---
  void _openMealUploadModal(
    BuildContext context,
    MyPtProvider state, {
    required String peerName,
    required bool isFromTrainer,
    required VoidCallback onMealSent,
  }) {
    final myName = state.currentUser?.name ?? 'User';
    String selectedMealType = 'Breakfast';
    DateTime selectedDate = DateTime.now();
    final descCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();

    // Curated high quality fitness meal photos
    final presetMealPhotos = [
      (
        'Avocado Toast & Eggs',
        'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&q=80',
        '2 poached eggs on sourdough toast with sliced avocado & chili flakes',
        380,
        22,
      ),
      (
        'Grilled Chicken Bowl',
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
        '200g grilled chicken breast with quinoa, steamed broccoli & olive oil',
        520,
        48,
      ),
      (
        'Salmon & Sweet Potato',
        'https://images.unsplash.com/photo-1546069901-d419b4cfb028?w=500&q=80',
        'Pan-seared salmon fillet with roasted sweet potato & asparagus',
        560,
        42,
      ),
      (
        'Protein Oatmeal & Berries',
        'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=500&q=80',
        'Rolled oats with whey protein isolate, blueberries & chia seeds',
        410,
        32,
      ),
      (
        'Greek Yogurt & Almonds',
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500&q=80',
        'Non-fat Greek yogurt with raw almonds, honey drizzle & berries',
        280,
        25,
      ),
      (
        'Steak & Rice Bowl',
        'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
        'Sirloin steak slices with jasmine rice and sautéed bell peppers',
        640,
        50,
      ),
    ];

    int selectedPhotoIdx = 0;
    String selectedPhotoUrl = presetMealPhotos[0].$2;
    descCtrl.text = presetMealPhotos[0].$3;
    caloriesCtrl.text = '${presetMealPhotos[0].$4}';
    proteinCtrl.text = '${presetMealPhotos[0].$5}';

    final mealCategories = [
      ('Breakfast', '🍳'),
      ('Lunch', '🥗'),
      ('Snacks', '🥪'),
      ('Dinner', '🍲'),
      ('Extra Meal', '🍱'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(modalCtx).size.height * 0.90),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFF00E676), width: 1.5)),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.restaurant, size: 12, color: Color(0xFF00E676)),
                          SizedBox(width: 4),
                          Text('NUTRITION & MEAL TRACKING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text('Log & Share Meal Picture 📸', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Upload photo and description for Coach $peerName to review', style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
                const SizedBox(height: 16),

                // 1. Meal Category Selection (5 Categories)
                const Text('SELECT MEAL CATEGORY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: mealCategories.map((cat) {
                      final isSelected = selectedMealType == cat.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(cat.$2, style: const TextStyle(fontSize: 13)),
                          label: Text(cat.$1, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF5722),
                          backgroundColor: const Color(0xFF0D1117),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? const Color(0xFFFF5722) : Colors.white12),
                          ),
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedMealType = cat.$1);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Day / Date Selector
                const Text('MEAL LOG DATE / DAY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Color(0xFFFF5722)),
                            const SizedBox(width: 8),
                            Text(DateFormat('EEEE, dd MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                        const Icon(Icons.edit_calendar, size: 14, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Meal Photo Selection & Preview
                const Text('MEAL PICTURE / PHOTO PROOF', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: const Color(0xFF0D1117),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          selectedPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                presetMealPhotos[selectedPhotoIdx].$1,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PHOTO ATTACHED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Preset Meal Photo Carousel
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetMealPhotos.length,
                    itemBuilder: (context, idx) {
                      final item = presetMealPhotos[idx];
                      final isSelected = selectedPhotoIdx == idx;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedPhotoIdx = idx;
                            selectedPhotoUrl = item.$2;
                            descCtrl.text = item.$3;
                            caloriesCtrl.text = '${item.$4}';
                            proteinCtrl.text = '${item.$5}';
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFF00E676) : Colors.white12, width: isSelected ? 2 : 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(item.$2, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Description Input
                const Text('MEAL DESCRIPTION & INGREDIENTS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., 200g Grilled chicken breast with quinoa and steamed veggies...',
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Optional Macros (Calories & Protein)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CALORIES (KCAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: caloriesCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. 520',
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROTEIN (GRAMS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: proteinCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. 45',
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text('Send $selectedMealType to Coach 📤', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    onPressed: () {
                      final desc = descCtrl.text.trim();
                      if (desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a brief meal description')));
                        return;
                      }
                      final cal = int.tryParse(caloriesCtrl.text.trim());
                      final pro = int.tryParse(proteinCtrl.text.trim());

                      final attachment = MealLogAttachment(
                        mealType: selectedMealType,
                        description: desc,
                        photoUrl: selectedPhotoUrl,
                        mealDate: selectedDate,
                        caloriesKcal: cal,
                        proteinGrams: pro,
                      );

                      state.sendChatMessage(
                        senderName: myName,
                        receiverName: peerName,
                        text: '',
                        isFromTrainer: isFromTrainer,
                        mealAttachment: attachment,
                      );

                      Navigator.pop(modalCtx);
                      onMealSent();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF00E676),
                          content: Text('🥗 $selectedMealType logged and sent to Coach $peerName!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCoachProfileModal(BuildContext context, MyPtProvider state, UserModel coach) {
    final specialties = _getTrainerSpecialties(coach);
    final packages = state.getPackagesForTrainer(coach.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                  child: Text(coach.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach ${coach.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('⭐ 4.9 Rating • Certified Trainer in India', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white12),

            const Text('Specialties & Expertise', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: specialties.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFF0D1117))).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Personalized Training Packages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...packages.map((pkg) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: const Color(0xFF0D1117),
                child: ListTile(
                  title: Text(pkg.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('+${pkg.sessionsCount} PT Credits • ${pkg.durationWeeks} Weeks Access'),
                  trailing: Text(state.formatPrice(pkg.priceInr), style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              );
            }),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openSelectCoachConfirmationModal(context, state, coach);
                },
                child: const Text('Select Coach as Primary Trainer 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateWorkoutModal(BuildContext context, MyPtProvider state) {
    final nameCtrl = TextEditingController(text: 'Legs & Core Power Blast');
    final focusCtrl = TextEditingController(text: 'Quads, Hamstrings & Core');
    final exercises = <WorkoutExercise>[
      WorkoutExercise(name: 'Barbell Back Squat', sets: '4', reps: '8', weight: '80 kg'),
      WorkoutExercise(name: 'Romanian Deadlift', sets: '3', reps: '10', weight: '65 kg'),
      WorkoutExercise(name: 'Plank Hold', sets: '3', reps: '60s', weight: 'Bodyweight'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalVolume = exercises.fold(0.0, (acc, ex) => acc + ex.sumProductKg);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Build Custom Workout Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Routine Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: focusCtrl, decoration: const InputDecoration(labelText: 'Focus Area (e.g., Quads, Chest)', border: OutlineInputBorder())),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Exercises & Sets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Total Calculated Volume: ${totalVolume.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Exercise'),
                      onPressed: () {
                        setModalState(() {
                          exercises.add(WorkoutExercise(name: 'Dumbbell Lunges', sets: '3', reps: '12', weight: '16 kg'));
                        });
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, idx) {
                      final ex = exercises[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: const Color(0xFF0D1117),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setModalState(() => exercises.removeAt(idx)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: ex.sets,
                                      decoration: const InputDecoration(labelText: 'Sets', isDense: true, border: OutlineInputBorder()),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setModalState(() => ex.sets = v),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: ex.reps,
                                      decoration: const InputDecoration(labelText: 'Reps', isDense: true, border: OutlineInputBorder()),
                                      onChanged: (v) => setModalState(() => ex.reps = v),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: ex.weight,
                                      decoration: const InputDecoration(labelText: 'Weight', isDense: true, border: OutlineInputBorder()),
                                      onChanged: (v) => setModalState(() => ex.weight = v),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                    onPressed: () {
                      final newRoutine = CustomWorkoutRoutine(
                        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Custom Workout Session',
                        focusArea: focusCtrl.text.trim().isNotEmpty ? focusCtrl.text.trim() : 'Full Body',
                        exercises: exercises,
                      );
                      state.addCustomWorkout(newRoutine);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Custom workout session saved!')));
                    },
                    child: const Text('Save Workout Routine 💾', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- INTERACTIVE LIVE WORKOUT SESSION LOGGER WITH TOTAL WEIGHT LIFTED, HISTORY & COMPARISON ---
  void _openLiveWorkoutSessionModal(BuildContext context, MyPtProvider state, CustomWorkoutRoutine routine) {
    // Track selected tab per exercise (0 = Sets, 1 = History)
    final activeExerciseTabs = <int, int>{};

    // Build set tracking items for each exercise
    final activeExercises = routine.exercises.map((ex) {
      final sCount = int.tryParse(ex.sets) ?? 3;
      final rCount = int.tryParse(RegExp(r'(\d+)').firstMatch(ex.reps)?.group(1) ?? '10') ?? 10;
      final wVal = double.tryParse(RegExp(r'(\d+)').firstMatch(ex.weight)?.group(1) ?? '60') ?? 60.0;

      final setList = List.generate(sCount, (sIdx) {
        return SetDetail(
          setNumber: sIdx + 1,
          weightKg: wVal,
          reps: rCount,
          isCompleted: false,
        );
      });

      return WorkoutExercise(
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
        restSeconds: ex.restSeconds,
        isCompleted: false,
        setDetails: setList,
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSessionState) {
          final totalVolumeKg = activeExercises.fold(0.0, (acc, ex) => acc + ex.sumProductKg);
          final totalCompletedSets = activeExercises.fold(0, (acc, ex) => acc + (ex.setDetails?.where((s) => s.isCompleted).length ?? 0));
          final totalSetsCount = activeExercises.fold(0, (acc, ex) => acc + (ex.setDetails?.length ?? 0));

          void showEndConfirmation() {
            showDialog(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                backgroundColor: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white12)),
                title: const Row(
                  children: [
                    Icon(Icons.flag_rounded, color: Color(0xFFFF5722)),
                    SizedBox(width: 8),
                    Text('End Workout Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You logged $totalCompletedSets of $totalSetsCount sets with a Total Weight Lifted of ${totalVolumeKg.toStringAsFixed(0)} kg.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    const Text('Select an option to proceed:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  // Option 1: Cancel (Neutral - remains in session)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancel'),
                  ),
                  // Option 2: Exit Without Saving (Destructive)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5252)),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.white24,
                          content: Text('Workout session exited without saving.'),
                        ),
                      );
                    },
                    child: const Text('Exit Without Saving', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Option 3: Save Workout (Primary)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      final sessionLog = WorkoutSessionLog(
                        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
                        routineName: routine.name,
                        focusArea: routine.focusArea,
                        completedAt: DateTime.now(),
                        totalVolumeKg: totalVolumeKg,
                        loggedBy: state.currentUser?.name ?? 'You',
                        exercises: activeExercises,
                      );
                      state.saveCompletedWorkoutSession(sessionLog);
                      Navigator.pop(dialogCtx);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF00E676),
                          content: Text('🎉 "${routine.name}" completed! Total Weight Lifted: ${totalVolumeKg.toStringAsFixed(0)} kg saved to history.'),
                        ),
                      );
                    },
                    child: const Text('Save Workout 💾', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),

                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(routine.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFF5722).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                child: const Text('LIVE SESSION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                              ),
                            ],
                          ),
                          Text('Prescribed by: ${routine.createdBy} • ${routine.focusArea}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                      onPressed: showEndConfirmation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Session Volume & Progress Metrics Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Weight Lifted', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          const SizedBox(height: 2),
                          Text(
                            '⚡ ${totalVolumeKg.toStringAsFixed(0)} kg',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF00E676)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.white12),
                      Column(
                        children: [
                          const Text('Sets Done', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          const SizedBox(height: 2),
                          Text(
                            '$totalCompletedSets / $totalSetsCount',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.white12),
                      Column(
                        children: [
                          const Text('Exercises', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          const SizedBox(height: 2),
                          Text(
                            '${activeExercises.length}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Exercises & Sets List
                Expanded(
                  child: ListView.builder(
                    itemCount: activeExercises.length,
                    itemBuilder: (context, exIdx) {
                      final ex = activeExercises[exIdx];
                      final sets = ex.setDetails ?? [];
                      final selectedTab = activeExerciseTabs[exIdx] ?? 0;

                      // Query historical records for this exercise from state.workoutHistory
                      final pastRecords = <Map<String, dynamic>>[];
                      for (final pastSession in state.workoutHistory) {
                        for (final pastEx in pastSession.exercises) {
                          if (pastEx.name.trim().toLowerCase() == ex.name.trim().toLowerCase()) {
                            pastRecords.add({
                              'session': pastSession,
                              'exercise': pastEx,
                              'date': pastSession.completedAt,
                              'volume': pastEx.sumProductKg,
                              'sets': pastEx.setDetails ?? [],
                            });
                          }
                        }
                      }

                      final prevRecord = pastRecords.isNotEmpty ? pastRecords.first : null;
                      final prevVolume = (prevRecord?['volume'] as double?) ?? 0.0;
                      final currentCompletedVolume = ex.sumProductKg;

                      // Comparison calculation vs previous session
                      String comparisonText = '';
                      Color badgeColor = Colors.white54;
                      IconData badgeIcon = Icons.info_outline;

                      if (prevVolume > 0) {
                        if (currentCompletedVolume > 0) {
                          final diff = currentCompletedVolume - prevVolume;
                          final pct = (diff / prevVolume) * 100.0;
                          if (diff > 0) {
                            comparisonText = 'Lifted ${pct.toStringAsFixed(1)}% more than previous session (${prevVolume.toStringAsFixed(0)} kg)';
                            badgeColor = const Color(0xFF00E676);
                            badgeIcon = Icons.trending_up_rounded;
                          } else if (diff < 0) {
                            comparisonText = 'Lifted ${pct.abs().toStringAsFixed(1)}% less than previous session (${prevVolume.toStringAsFixed(0)} kg)';
                            badgeColor = const Color(0xFFFF9100);
                            badgeIcon = Icons.trending_down_rounded;
                          } else {
                            comparisonText = 'Matched previous session total (${prevVolume.toStringAsFixed(0)} kg)';
                            badgeColor = const Color(0xFF29B6F6);
                            badgeIcon = Icons.horizontal_rule_rounded;
                          }
                        } else {
                          comparisonText = 'Target: Prev session was ${prevVolume.toStringAsFixed(0)} kg (${prevRecord?['exercise']?.sets ?? '4'} sets) • Check off DONE sets to compare';
                          badgeColor = Colors.white54;
                          badgeIcon = Icons.flag_outlined;
                        }
                      } else {
                        comparisonText = 'Baseline Session • No prior history recorded';
                        badgeColor = Colors.white54;
                        badgeIcon = Icons.star_border_rounded;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF0D1117),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: sets.every((s) => s.isCompleted) && sets.isNotEmpty
                                ? const Color(0xFF00E676).withOpacity(0.4)
                                : Colors.white12,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exercise Header & Sets/History Tab Switcher
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${exIdx + 1}. ${ex.name}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                        ),
                                        Text(
                                          'Rest: ${ex.restSeconds}${(state.enableExerciseTargetWeight && ex.hasTargetWeight) ? ' • Target: ${ex.weight}' : ''}',
                                          style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161B22),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => setSessionState(() => activeExerciseTabs[exIdx] = 0),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: selectedTab == 0 ? const Color(0xFFFF5722) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Sets',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: selectedTab == 0 ? Colors.white : Colors.white60,
                                              ),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setSessionState(() => activeExerciseTabs[exIdx] = 1),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: selectedTab == 1 ? const Color(0xFFFF5722) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  size: 12,
                                                  color: selectedTab == 1 ? Colors.white : Colors.white60,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'History${pastRecords.isNotEmpty ? ' (${pastRecords.length})' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: selectedTab == 1 ? Colors.white : Colors.white60,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // TAB CONTENT: SETS LOGGER vs HISTORY RECORDS
                              if (selectedTab == 0) ...[
                                const Divider(height: 14, color: Colors.white12),

                                // Set Table Header (SET, WEIGHT, REPS, DONE, DELETE)
                                const Row(
                                  children: [
                                    SizedBox(width: 36, child: Text('SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54))),
                                    Expanded(flex: 4, child: Text('WEIGHT (KG)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54))),
                                    SizedBox(width: 8),
                                    Expanded(flex: 4, child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54))),
                                    SizedBox(width: 8),
                                    SizedBox(width: 38, child: Text('DONE', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54))),
                                    SizedBox(width: 34, child: Text('DEL', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54))),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Set Rows
                                ...sets.asMap().entries.map((entry) {
                                  final sIdx = entry.key;
                                  final setItem = entry.value;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: setItem.isCompleted ? const Color(0xFF00E676).withOpacity(0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 36,
                                          child: Text(
                                            '#${sIdx + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: setItem.isCompleted ? const Color(0xFF00E676) : Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: SizedBox(
                                            height: 34,
                                            child: TextFormField(
                                              initialValue: setItem.weightKg % 1 == 0 ? setItem.weightKg.toInt().toString() : setItem.weightKg.toString(),
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              onChanged: (v) {
                                                final parsed = double.tryParse(v) ?? setItem.weightKg;
                                                setSessionState(() => setItem.weightKg = parsed);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 4,
                                          child: SizedBox(
                                            height: 34,
                                            child: TextFormField(
                                              initialValue: setItem.reps.toString(),
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              onChanged: (v) {
                                                final parsed = int.tryParse(v) ?? setItem.reps;
                                                setSessionState(() => setItem.reps = parsed);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 38,
                                          child: IconButton(
                                            icon: Icon(
                                              setItem.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                                              color: setItem.isCompleted ? const Color(0xFF00E676) : Colors.white38,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Mark Done',
                                            onPressed: () {
                                              setSessionState(() => setItem.isCompleted = !setItem.isCompleted);
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 34,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Delete Set',
                                            onPressed: () {
                                              setSessionState(() {
                                                sets.removeAt(sIdx);
                                                for (int i = 0; i < sets.length; i++) {
                                                  sets[i].setNumber = i + 1;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                const Divider(height: 14, color: Colors.white12),

                                // Bottom Card Controls: Add Set on Left & Total Weight Lifted on Right
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF5722)),
                                      label: const Text('Add Set', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                                      onPressed: () {
                                        setSessionState(() {
                                          final last = sets.isNotEmpty ? sets.last : null;
                                          sets.add(
                                            SetDetail(
                                              setNumber: sets.length + 1,
                                              weightKg: last?.weightKg ?? 60.0,
                                              reps: last?.reps ?? 10,
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.35)),
                                      ),
                                      child: Text(
                                        '⚡ Total Weight Lifted: ${ex.formattedSumProduct}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                                      ),
                                    ),
                                  ],
                                ),

                                // Progression vs Previous Session Banner
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: badgeColor.withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(badgeIcon, size: 14, color: badgeColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          comparisonText,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: badgeColor == Colors.white54 ? Colors.white70 : badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // HISTORY TAB: PAST EXERCISE RECORDS
                                const Divider(height: 14, color: Colors.white12),
                                if (pastRecords.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        const Icon(Icons.history_toggle_off, size: 28, color: Colors.white24),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'No Past Records Yet',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Complete sets for ${ex.name} in this session to start your history log.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: pastRecords.asMap().entries.map((pEntry) {
                                      final pIdx = pEntry.key;
                                      final record = pEntry.value;
                                      final pastSession = record['session'] as WorkoutSessionLog;
                                      final pastEx = record['exercise'] as WorkoutExercise;
                                      final dateStr = DateFormat('EEE, dd MMM yyyy').format(record['date'] as DateTime);
                                      final vol = record['volume'] as double;
                                      final setDetails = record['sets'] as List<SetDetail>;

                                      String? deltaVsOlder;
                                      if (pIdx + 1 < pastRecords.length) {
                                        final olderVol = pastRecords[pIdx + 1]['volume'] as double;
                                        if (olderVol > 0) {
                                          final d = vol - olderVol;
                                          final p = (d / olderVol) * 100.0;
                                          deltaVsOlder = d >= 0 ? '▲ Lifted +${p.toStringAsFixed(1)}% vs prior session' : '▼ Lifted -${p.abs().toStringAsFixed(1)}% vs prior session';
                                        }
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF161B22),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00E676).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    'Lifted: ${vol.toStringAsFixed(0)} kg',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Routine: ${pastSession.routineName}',
                                              style: const TextStyle(fontSize: 10, color: Colors.white54),
                                            ),
                                            const SizedBox(height: 6),
                                            if (setDetails.isNotEmpty)
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: setDetails.map((s) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.06),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '#${s.setNumber}: ${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)}kg × ${s.reps}',
                                                      style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                                                    ),
                                                  );
                                                }).toList(),
                                              )
                                            else
                                              Text(
                                                '${pastEx.sets} Sets x ${pastEx.reps} Reps @ ${pastEx.weight}',
                                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                                              ),
                                            if (deltaVsOlder != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                deltaVsOlder,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: deltaVsOlder.startsWith('▲') ? const Color(0xFF00E676) : const Color(0xFFFF9100),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Bottom Actions: End Workout Session Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.flag_rounded, size: 20),
                    label: const Text('End Workout Session 🏁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: showEndConfirmation,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAddMeasurementModal(BuildContext context, MyPtProvider state) {
    final weightCtrl = TextEditingController(text: state.currentUser?.currentWeight.toString() ?? '64.5');
    final fatCtrl = TextEditingController(text: '18.2');
    final waistCtrl = TextEditingController(text: '78.0');
    final chestCtrl = TextEditingController(text: '96.0');
    final notesCtrl = TextEditingController(text: 'Weekly transformation check-in');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Circumference & Body Scan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Body Fat %', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: waistCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Waist (cm)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: chestCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Chest (cm)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                onPressed: () {
                  final w = double.tryParse(weightCtrl.text) ?? 64.5;
                  final bf = double.tryParse(fatCtrl.text) ?? 18.0;
                  final waist = double.tryParse(waistCtrl.text) ?? 78.0;
                  final chest = double.tryParse(chestCtrl.text) ?? 96.0;

                  state.addMeasurement(
                    BodyMeasurementEntry(
                      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                      date: DateTime.now(),
                      weightKg: w,
                      bodyFatPercent: bf,
                      waistCm: waist,
                      chestCm: chest,
                      notes: notesCtrl.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Measurement saved! Charts updated.')));
                },
                child: const Text('Save Measurement 📏', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateExerciseModal(BuildContext context, MyPtProvider state, {MovementItem? existingItem, int? existingIndex}) {
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final primaryMuscleCtrl = TextEditingController(text: existingItem?.primaryMuscle ?? 'Chest');
    final secondaryMusclesCtrl = TextEditingController(text: existingItem?.secondaryMuscles ?? '');
    final equipmentCtrl = TextEditingController(text: existingItem?.equipment ?? 'Barbell, Bench');
    final setsRepsCtrl = TextEditingController(text: existingItem?.defaultSetsReps ?? '3-4 sets x 8-12 reps');
    String selectedDifficulty = existingItem?.difficulty ?? 'Beginner';

    final primaryMuscles = [
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Quadriceps',
      'Hamstrings',
      'Glutes',
      'Calves',
      'Abdominals',
      'Obliques',
      'Lower Back',
      'Full Body',
      'Legs',
    ];

    final equipments = [
      'Barbell, Bench',
      'Dumbbells, Bench',
      'Barbell, Incline Bench',
      'Dumbbells, Incline Bench',
      'Barbell, Rack',
      'Dumbbells',
      'Cable Machine',
      'Machine',
      'Bodyweight',
      'Pull-Up Bar',
      'Dip Station',
      'EZ Bar',
      'Treadmill',
      'Stationary Bike',
      'Elliptical Machine',
      'Rowing Machine',
      'Jump Rope',
      'Battle Ropes',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existingItem == null ? 'Create Exercise Movement' : 'Edit Exercise Movement',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Exercise Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: 'e.g., Incline Dumbbell Bench Press',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center, color: Color(0xFFFF5722), size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Difficulty Level Selector
                const Text('Difficulty Level', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: ['Beginner', 'Intermediate', 'Advanced'].map((diff) {
                    final isSelected = selectedDifficulty.toLowerCase() == diff.toLowerCase();
                    Color diffColor;
                    if (diff == 'Beginner') {
                      diffColor = const Color(0xFF00E676);
                    } else if (diff == 'Advanced') {
                      diffColor = const Color(0xFFFF5252);
                    } else {
                      diffColor = const Color(0xFFFFB74D);
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(
                            diff,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: diffColor.withOpacity(0.3),
                          backgroundColor: const Color(0xFF21262D),
                          side: BorderSide(color: isSelected ? diffColor : Colors.white12),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedDifficulty = diff);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                
                // 3. Primary Muscle Target Selector
                const Text('Primary Muscle Target', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: primaryMuscles.contains(primaryMuscleCtrl.text) ? primaryMuscleCtrl.text : primaryMuscles.first,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.track_changes, color: Color(0xFFFF5722), size: 20)),
                  dropdownColor: const Color(0xFF1C2128),
                  items: primaryMuscles.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => primaryMuscleCtrl.text = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 4. Secondary Muscles (Optional)
                TextField(
                  controller: secondaryMusclesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Muscles Targetted (Optional)',
                    hintText: 'e.g., Triceps, Shoulders',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category, color: Colors.white54, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Equipment Selector
                const Text('Required Equipment', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: equipments.contains(equipmentCtrl.text) ? equipmentCtrl.text : equipments.first,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.fitness_center, color: Color(0xFF00E676), size: 20)),
                  dropdownColor: const Color(0xFF1C2128),
                  items: equipments.map((eq) => DropdownMenuItem(value: eq, child: Text(eq, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => equipmentCtrl.text = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 6. Suggested Sets and Reps
                TextField(
                  controller: setsRepsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Suggested Sets & Reps / Target Protocol',
                    hintText: 'e.g., 3-4 sets x 8-12 reps',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.repeat, color: Color(0xFF40C4FF), size: 20),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an exercise name')));
                        return;
                      }

                      final newItem = MovementItem(
                        name: name,
                        primaryMuscle: primaryMuscleCtrl.text.trim().isEmpty ? 'Chest' : primaryMuscleCtrl.text.trim(),
                        secondaryMuscles: secondaryMusclesCtrl.text.trim().isEmpty ? 'None' : secondaryMusclesCtrl.text.trim(),
                        equipment: equipmentCtrl.text.trim().isEmpty ? 'Standard Gym Equipment' : equipmentCtrl.text.trim(),
                        defaultSetsReps: setsRepsCtrl.text.trim().isEmpty ? '3-4 sets x 10 reps' : setsRepsCtrl.text.trim(),
                        difficulty: selectedDifficulty,
                        category: 'Strength',
                      );

                      if (existingIndex != null && existingIndex >= 0) {
                        state.updateMovementItem(existingIndex, newItem);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated "${newItem.name}" in library')));
                      } else {
                        state.addMovementItem(newItem);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${newItem.name}" to exercise library! 🏋️')));
                      }

                      Navigator.pop(ctx);
                    },
                    child: Text(
                      existingItem == null ? '+ Save to Movement Library' : 'Update Exercise',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCreateTrainerPackageModal(BuildContext context, MyPtProvider state, {TrainingPackage? existingPackage}) {
    final titleCtrl = TextEditingController(text: existingPackage?.title ?? '');
    final priceCtrl = TextEditingController(text: existingPackage != null ? existingPackage.priceInr.toStringAsFixed(0) : '');
    final sessionsCtrl = TextEditingController(text: existingPackage != null ? existingPackage.sessionsCount.toString() : '');
    final weeksCtrl = TextEditingController(text: existingPackage != null ? existingPackage.durationWeeks.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(existingPackage == null ? 'Create Custom Package' : 'Edit Package', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Package Title',
                hintText: 'e.g., 8-Week Biomechanics Masterclass',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price in INR (₹)',
                      hintText: 'e.g., 7999',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: sessionsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PT Credits (Sessions)',
                      hintText: 'e.g., 8',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: weeksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expiry in weeks',
                      hintText: 'e.g., 8',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final coach = state.currentUser!;
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a package title')));
                    return;
                  }

                  final pInr = double.tryParse(priceCtrl.text.trim()) ?? 4999.0;
                  final count = int.tryParse(sessionsCtrl.text.trim()) ?? 8;
                  final wks = int.tryParse(weeksCtrl.text.trim()) ?? 8;

                  state.addOrUpdateTrainerPackage(
                    TrainingPackage(
                      id: existingPackage?.id ?? 'pkg_${DateTime.now().millisecondsSinceEpoch}',
                      trainerId: coach.id,
                      trainerName: coach.name,
                      title: title,
                      priceInr: pInr,
                      sessionsCount: count,
                      durationWeeks: wks,
                      perks: ['$count x 1-on-1 Sessions', 'Direct Coach Support', 'Weekly Form Audits', 'Expiry in $wks weeks'],
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Package saved to your coach profile!')));
                },
                child: const Text('Save Package 💾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationModal(BuildContext context, MyPtProvider state) {
    final notifs = state.currentNotifications;
    final isCoach = state.currentUser?.role == UserRole.coach;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFFFF5722), size: 22),
                    SizedBox(width: 8),
                    Text('In-App Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => state.markAllNotificationsRead(),
                      child: const Text('Mark all read', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16, color: Colors.white12),
            if (notifs.isEmpty)
              const Expanded(child: Center(child: Text('No notifications right now.', style: TextStyle(color: Colors.white54))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: notifs.length,
                  itemBuilder: (context, idx) {
                    final n = notifs[idx];

                    // Match associated session if any
                    SessionItem? linkedSession;
                    if (n.sessionId != null) {
                      for (final s in state.sessions) {
                        if (s.id == n.sessionId) {
                          linkedSession = s;
                          break;
                        }
                      }
                    }

                    final showTrainerSessionActions = isCoach &&
                        linkedSession != null &&
                        linkedSession.status == RequestStatus.pending;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: n.isRead ? const Color(0xFF0D1117) : const Color(0xFF21262D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: showTrainerSessionActions ? const Color(0xFFFF9800).withOpacity(0.5) : Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (showTrainerSessionActions)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9800).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ACTION REQUIRED',
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${DateFormat('dd MMM, hh:mm a').format(n.timestamp)}\n${n.message}',
                                style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
                              ),
                            ),
                            isThreeLine: true,
                          ),
                          if (showTrainerSessionActions) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Reject ❌', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      state.rejectSession(linkedSession!);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.redAccent,
                                          content: Text('❌ Declined booking. 1 PT Credit refunded to ${linkedSession.clientName}.'),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF29B6F6),
                                      side: const BorderSide(color: Color(0xFF29B6F6)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Reschedule 🔄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _openRescheduleModal(context, state, linkedSession!);
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Accept ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      state.approveSession(linkedSession!);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFF00E676),
                                          content: Text('✓ Session confirmed with ${linkedSession.clientName}!'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openProfileModal(BuildContext context, MyPtProvider state) {
    final user = state.currentUser;
    if (user == null) return;

    bool isMaximized = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final media = MediaQuery.of(context);
          final modalHeight = isMaximized ? media.size.height * 0.94 : media.size.height * 0.72;

          // Find assigned trainer if any
          UserModel? assignedTrainer;
          if (user.trainerId != null) {
            for (final t in state.allTrainers) {
              if (t.id == user.trainerId) {
                assignedTrainer = t;
                break;
              }
            }
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: modalHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isMaximized ? Icons.fullscreen_exit : Icons.fullscreen, color: const Color(0xFFFF5722), size: 22),
                        tooltip: isMaximized ? 'Restore View' : 'Maximize to Fullscreen',
                        onPressed: () => setModalState(() => isMaximized = !isMaximized),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),

                // Scrollable Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // User Identity Card
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFFF5722),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0] : '?',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(user.email, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5722).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(user.role.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('${user.ptCredits} PT CREDITS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Health & Body Profile Grid
                      const Text('FITNESS & HEALTH ATTRIBUTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                _showChangeGoalDialog(context, state);
                                setModalState(() {});
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Text('Primary Fitness Goal', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                        SizedBox(width: 4),
                                        Icon(Icons.edit, size: 12, color: Color(0xFFFF5722)),
                                      ],
                                    ),
                                    Text(user.goal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF5722))),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 16, color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Current Weight', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                Text('${user.currentWeight} kg (Start: ${user.startingWeight} kg)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF29B6F6))),
                              ],
                            ),
                            const Divider(height: 16, color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Age & Height', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                Text('${user.age} yrs • ${user.heightCm.toInt()} cm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                              ],
                            ),
                            const Divider(height: 16, color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Emergency Contact', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                Text(user.emergencyContact, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Coach & Credits Section
                      if (user.role == UserRole.client) ...[
                        const Text('PRIMARY COACH & SESSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                                    child: Text(assignedTrainer != null ? assignedTrainer.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignedTrainer != null ? 'Coach ${assignedTrainer.name}' : 'No Trainer Assigned',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          assignedTrainer != null ? '1-on-1 Certified Personal Trainer' : 'Select a coach in the Discover tab',
                                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() => _tabIndex = 1);
                                    },
                                    child: Text(
                                      assignedTrainer != null ? 'Change' : 'Discover',
                                      style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Theme & Appearance
                      const Text('THEME & APPEARANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (state.isDarkMode ? const Color(0xFF7C4DFF) : const Color(0xFFFFB300)).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: state.isDarkMode ? const Color(0xFFB388FF) : const Color(0xFFFFB300),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            state.isDarkMode ? 'Dark Mode' : 'Light Mode',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          subtitle: Text(
                            state.isDarkMode ? 'Sleek midnight dark theme active' : 'Bright crisp daylight theme active',
                            style: const TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                          trailing: Switch.adaptive(
                            value: state.isDarkMode,
                            activeColor: const Color(0xFFFF5722),
                            inactiveThumbColor: const Color(0xFFFFB300),
                            inactiveTrackColor: Colors.white24,
                            onChanged: (val) {
                              state.setIsDarkMode(val);
                              setModalState(() {});
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Regional Preferences
                      const Text('REGIONAL & APP PREFERENCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.location_on, color: Color(0xFFFF5722)),
                              title: const Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              subtitle: Text(state.userLocation, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                              onTap: () {
                                Navigator.pop(ctx);
                                _openLocationPromptModal(context, state);
                              },
                            ),
                            const Divider(height: 1, color: Colors.white10),
                            ListTile(
                              leading: const Icon(Icons.currency_exchange, color: Color(0xFF00E676)),
                              title: const Text('Pricing Region & Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              subtitle: Text('${state.currentCurrencyInfo.flag} ${state.selectedCountry} • ${state.currentCurrencyInfo.name} (${state.selectedCurrency})', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                              onTap: () {
                                Navigator.pop(ctx);
                                _openCurrencySelector(context, state);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Master User Controls
                      if (state.isMasterUser || state.isImpersonating || user.role == UserRole.superAdmin) ...[
                        const Text('MASTER USER CONTROLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722), letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.4)),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFF5722)),
                                title: const Text('Switch / Impersonate Any User', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Access any client, trainer, head coach, or manager account', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _openMasterUserSwitcherModal(context, state);
                                },
                              ),
                              if (state.isImpersonating) ...[
                                const Divider(height: 1, color: Colors.white10),
                                ListTile(
                                  leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF00E676)),
                                  title: const Text('Return to Master Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                                  subtitle: const Text('Exit impersonation and restore Master Admin session', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    state.returnToMasterAdmin();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Color(0xFF00E676),
                                        content: Text('👑 Returned to Master Admin account.'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF21262D),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                          ),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sign Out of myPT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.logout();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChangeGoalDialog(BuildContext context, MyPtProvider state) {
    final user = state.currentUser;
    if (user == null) return;
    String selected = (kStandardFitnessGoals.contains(user.goal)) ? user.goal : kStandardFitnessGoals.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
          title: const Row(
            children: [
              Icon(Icons.flag_circle, color: Color(0xFFFF5722), size: 22),
              SizedBox(width: 8),
              Text('Select Primary Fitness Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: kStandardFitnessGoals.map((g) {
              final isSel = selected == g;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFFF5722).withOpacity(0.15) : const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? const Color(0xFFFF5722) : Colors.white10),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    g,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? const Color(0xFFFF5722) : Colors.white,
                    ),
                  ),
                  trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFFFF5722), size: 18) : null,
                  onTap: () {
                    setDialogState(() => selected = g);
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              onPressed: () {
                state.updateUserGoal(selected);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF00E676),
                    content: Text('✓ Primary Fitness Goal updated to "$selected"'),
                  ),
                );
              },
              child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openWeightLogDialog(BuildContext context, MyPtProvider state) {
    final user = state.currentUser;
    final currentW = user?.currentWeight ?? 64.5;
    final startW = user?.startingWeight ?? 68.0;
    final ctrl = TextEditingController(text: currentW.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF29B6F6).withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.scale, color: Color(0xFF29B6F6), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Log Today\'s Weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baseline Start Weight: $startW kg', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Weight (kg)',
                hintText: 'e.g. 64.0',
                suffixText: 'kg',
                filled: true,
                fillColor: Color(0xFF0D1117),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
            onPressed: () {
              final w = double.tryParse(ctrl.text.trim());
              if (w != null && w > 20 && w < 300) {
                state.logTodayWeight(w);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF00E676),
                    content: Text('✓ Weight updated to $w kg! Progress updated.'),
                  ),
                );
              }
            },
            child: const Text('Save Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String val, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: col)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: col.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _measurementRow(String label, String current, String change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('$current ($change)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676), fontSize: 13)),
        ],
      ),
    );
  }

  // --- CONSULTATION REQUEST MODAL (FREE INQUIRY / 0 PT CREDITS) ---
  void _openRequestConsultationModal(BuildContext context, MyPtProvider state, UserModel coach) {
    final user = state.currentUser;
    String selectedGoal = (user != null && kStandardFitnessGoals.contains(user.goal)) ? user.goal : kStandardFitnessGoals.first;
    String selectedTopic = 'Initial PT Consultation';
    String selectedAvailability = 'Morning (06:00 AM - 10:00 AM)';
    final msgCtrl = TextEditingController(
      text: 'Looking to start a structured workout & nutrition routine tailored to my goals. Would love to discuss training options.',
    );

    final topics = [
      'Initial PT Consultation',
      'Strength Coaching 1-on-1',
      'Fat Loss & Body Recomp',
      'Hypertrophy & Posture Mastery',
      'Injury Rehab & Mobility',
      'Nutrition & Meal Strategy',
    ];

    final availabilityOptions = [
      'Morning (06:00 AM - 10:00 AM)',
      'Afternoon (12:00 PM - 04:00 PM)',
      'Evening (05:00 PM - 09:00 PM)',
      'Flexible / Any Slot',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                      child: Text(coach.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722), fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Request Consultation with Coach ${coach.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Free 1-on-1 Inquiry (0 PT Credits deducted)', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white12),

                // Primary Fitness Goal Selector
                const Row(
                  children: [
                    Icon(Icons.flag_circle, size: 14, color: Color(0xFFFF5722)),
                    SizedBox(width: 6),
                    Text('Primary Fitness Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: kStandardFitnessGoals.contains(selectedGoal) ? selectedGoal : kStandardFitnessGoals.first,
                      dropdownColor: const Color(0xFF161B22),
                      items: kStandardFitnessGoals.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedGoal = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Consultation Topic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedTopic,
                      dropdownColor: const Color(0xFF161B22),
                      items: topics.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedTopic = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Your Preferred Availability', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availabilityOptions.map((avail) {
                      final isSel = selectedAvailability == avail;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(avail),
                          selected: isSel,
                          selectedColor: const Color(0xFFFF5722),
                          backgroundColor: const Color(0xFF0D1117),
                          labelStyle: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : Colors.white70,
                          ),
                          onSelected: (sel) {
                            if (sel) setModalState(() => selectedAvailability = avail);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Message to Coach / Goals & Questions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Share your fitness background, injuries, or what you hope to achieve...',
                    filled: true,
                    fillColor: Color(0xFF0D1117),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                    onPressed: () {
                      state.updateUserGoal(selectedGoal);
                      final fullMessage = 'Goal: $selectedGoal\n${msgCtrl.text.trim()}\nPreferred Slot: $selectedAvailability';
                      state.sendConsultationRequest(
                        coach: coach,
                        requestType: selectedTopic,
                        message: fullMessage,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF00E676),
                          content: Text('✓ Consultation request sent to Coach ${coach.name}! You will be notified once reviewed.'),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    child: const Text('Send Consultation Request 🤝', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CANCEL SESSION CONFIRMATION MODAL WITH PT CREDIT REFUND GUARANTEE ---
  void _openCancelSessionModal(BuildContext context, MyPtProvider state, SessionItem session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Cancel Session?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your session ("${session.focusArea}") with Coach ${session.trainerName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1 PT Credit will be refunded immediately to your account balance.',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Session', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              state.cancelSession(session);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF00E676),
                  content: Text('✓ Session cancelled. 1 PT Credit has been refunded to your balance.'),
                ),
              );
            },
            child: const Text('Confirm Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 4-STEP ONBOARDING TUTORIAL / USER GUIDE ---
  void _openOnboardingTutorial(BuildContext context, MyPtProvider state) {
    int currentStep = 0;

    final steps = [
      (
        'Welcome to myPT 🙏',
        'India\'s Premier Personal Training Experience',
        'myPT connects you with verified elite personal trainers across India. Enjoy transparent pricing in Indian Rupees (₹), customized workout splits, and dedicated 1-on-1 coaching.',
        Icons.flash_on,
        const Color(0xFFFF5722),
      ),
      (
        'Discover & Connect 🤝',
        'Request Free Consultations with Top Coaches',
        'Browse coach specialties from hypertrophy to biomechanics. Send free 1-on-1 consultation requests (0 PT credits) or connect directly with your primary trainer.',
        Icons.person_search,
        const Color(0xFF00E676),
      ),
      (
        'Tailored Packages & Credits 💳',
        'Transparent Direct Trainer Pricing',
        'Packages in myPT are created directly by your assigned coach with custom pricing. Purchase credits instantly online or confirm offline with your trainer.',
        Icons.token_outlined,
        const Color(0xFF29B6F6),
      ),
      (
        'Schedule, Train & Transform 📅',
        'Seamless 1-on-1 Booking & Real-Time Tracking',
        'Schedule 1-hour sessions with full calendar freedom, join live video workouts, log body scans, and watch your transformation progression unfold.',
        Icons.calendar_month,
        const Color(0xFFFF9800),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setTutorialState) {
          final (title, subtitle, description, iconData, accentColor) = steps[currentStep];
          final isLastStep = currentStep == steps.length - 1;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () {
                        state.setHasSeenOnboarding(true);
                        Navigator.pop(ctx);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Step Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(iconData, color: accentColor, size: 36),
                ),
                const SizedBox(height: 16),

                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor)),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 22),

                // Step Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(steps.length, (idx) {
                    final isCurrent = idx == currentStep;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFFFF5722) : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Bottom Navigation Buttons
                Row(
                  children: [
                    if (currentStep > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => setTutorialState(() => currentStep -= 1),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        if (isLastStep) {
                          state.setHasSeenOnboarding(true);
                          Navigator.pop(ctx);
                        } else {
                          setTutorialState(() => currentStep += 1);
                        }
                      },
                      child: Text(
                        isLastStep ? 'Get Started 🚀' : 'Next →',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- POPUP MODAL: GET A PERSONAL TRAINER FOR TRACKING & COACHING ---
  void _openGetPersonalTrainerModal(BuildContext context, MyPtProvider state) {
    state.setHasSeenNoTrainerPrompt(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFFFF5722), width: 1.5)),
        ),
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: [
            // Top Drag & Close Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Color(0xFFFF5722)),
                      SizedBox(width: 4),
                      Text('1-ON-1 COACHING & TRACKING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Header Hero
            const Text(
              'Get a Personal Trainer for Live Tracking & Coaching 🏋️‍♂️',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
            ),
            const SizedBox(height: 8),
            const Text(
              'Achieve results 3x faster with a dedicated certified coach who designs your workouts, monitors your form in real-time, and tracks your progress weekly.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            // 4 Benefit Cards
            _buildTrainerBenefitCard(
              icon: Icons.fitness_center_rounded,
              iconColor: const Color(0xFFFF5722),
              title: 'Tailored Workout Programming',
              description: 'Custom routines crafted for your body type, experience level, and target muscle groups with progressive overload.',
            ),
            const SizedBox(height: 10),
            _buildTrainerBenefitCard(
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFF00E676),
              title: 'Live Exercise & Weight Tracking',
              description: 'Your trainer tracks your sets, reps, total volume lifted, and body circumference measurements after every session.',
            ),
            const SizedBox(height: 10),
            _buildTrainerBenefitCard(
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF29B6F6),
              title: '1-on-1 Direct Chat & Video Check-Ins',
              description: 'Send form check videos, ask questions, and receive feedback directly from your coach anytime.',
            ),
            const SizedBox(height: 10),
            _buildTrainerBenefitCard(
              icon: Icons.restaurant_menu_rounded,
              iconColor: const Color(0xFFFFB300),
              title: 'Nutrition & Habit Guidance',
              description: 'Caloric targets, protein goals, and lifestyle adjustments to ensure you hit your goals consistently.',
            ),
            const SizedBox(height: 24),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.person_search_rounded, size: 20),
                label: const Text('Find & Select Your Personal Trainer 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _tabIndex = 1); // Switch to Discover Coaches Tab
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Maybe Later', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
