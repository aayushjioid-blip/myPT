import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ============================================================================
// 1. ROLES & DATA MODELS
// ============================================================================
enum UserRole { client, coach, headCoach, gymMgr, superAdmin }
enum RequestStatus { pending, confirmed, completed, cancelled }

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
    this.phone = '+1-555-0199',
    this.age = 28,
    this.heightCm = 168.0,
    this.emergencyContact = '+1-555-0100 (Emergency Contact)',
    this.medicalInfo = 'No known medical restrictions',
    this.headCoachId,
    this.trainerId,
    this.dualRoles,
  });
}

class SessionItem {
  final String id;
  final String clientName;
  final String trainerName;
  DateTime date;
  String timeSlot;
  String focusArea;
  RequestStatus status;

  SessionItem({
    required this.id,
    required this.clientName,
    required this.trainerName,
    required this.date,
    required this.timeSlot,
    required this.focusArea,
    this.status = RequestStatus.pending,
  });
}

class TrainingPackage {
  final String id;
  final String title;
  final double price;
  final int sessionsCount;
  final int durationWeeks;
  final List<String> perks;

  TrainingPackage({
    required this.id,
    required this.title,
    required this.price,
    required this.sessionsCount,
    required this.durationWeeks,
    required this.perks,
  });
}

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final double rate; // Rate relative to USD

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

  MovementItem({
    required this.name,
    required this.category,
    required this.defaultSetsReps,
    required this.equipment,
  });
}

class WorkoutExercise {
  final String name;
  final String sets;
  final String reps;
  final String weight;

  WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}

class ClientRequestItem {
  final String id;
  final String clientName;
  final String email;
  final String requestType;
  final String message;
  final DateTime date;
  RequestStatus status;

  ClientRequestItem({
    required this.id,
    required this.clientName,
    required this.email,
    required this.requestType,
    required this.message,
    required this.date,
    this.status = RequestStatus.pending,
  });
}

// ============================================================================
// 2. STATE PROVIDER WITH AUTH, HIERARCHY & PERSISTED DATA
// ============================================================================
class MyPtProvider extends ChangeNotifier {
  UserModel? currentUser; // Null when logged out
  bool isDevMode = !kReleaseMode;

  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'USD': CurrencyInfo(code: 'USD', symbol: '\$', name: 'United States Dollar', flag: '🇺🇸', rate: 1.0),
    'INR': CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳', rate: 83.0),
    'EUR': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺', rate: 0.92),
    'GBP': CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧', rate: 0.79),
    'AED': CurrencyInfo(code: 'AED', symbol: 'AED ', name: 'UAE Dirham', flag: '🇦🇪', rate: 3.67),
    'CAD': CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '🇨🇦', rate: 1.36),
    'AUD': CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺', rate: 1.52),
    'SGD': CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬', rate: 1.35),
  };

  late String selectedCurrency = _autoDetectCurrency();

  static String _autoDetectCurrency() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      final country = locale.countryCode?.toUpperCase() ?? '';
      if (country == 'IN') return 'INR';
      if (country == 'GB') return 'GBP';
      if (country == 'AE') return 'AED';
      if (country == 'CA') return 'CAD';
      if (country == 'AU') return 'AUD';
      if (country == 'SG') return 'SGD';
      if (['DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'PT', 'IE', 'FI', 'GR'].contains(country)) return 'EUR';
    } catch (_) {}
    return 'USD';
  }

  void setCurrency(String code) {
    if (supportedCurrencies.containsKey(code)) {
      selectedCurrency = code;
      notifyListeners();
    }
  }

  CurrencyInfo get currentCurrencyInfo =>
      supportedCurrencies[selectedCurrency] ?? supportedCurrencies['USD']!;

  String formatPrice(double priceUsd) {
    final cur = currentCurrencyInfo;
    final converted = priceUsd * cur.rate;
    return '${cur.symbol}${NumberFormat('#,##0').format(converted.round())}';
  }


  // Pre-configured demo passwords map for reference & validation
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
    // --- MASTER PRODUCTION SUPERUSER (ALL ROLES) ---
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
      dualRoles: [
        UserRole.superAdmin,
        UserRole.headCoach,
        UserRole.gymMgr,
        UserRole.coach,
        UserRole.client,
      ],
    ),
    // --- NEW USERS ---
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
    // --- EXISTING SEED USERS ---
    'sarah@mypt.com': UserModel(
      id: 'usr_sarah',
      name: 'Sarah Jenkins',
      email: 'sarah@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      startingWeight: 68.0,
      ptCredits: 0,
      goal: 'Fat Loss & Hypertrophy',
      trainerId: 'trn_alex',
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
    ),
    UserModel(
      id: 'usr_sarah',
      name: 'Sarah Jenkins',
      email: 'sarah@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      startingWeight: 68.0,
      ptCredits: 0,
      goal: 'Fat Loss & Hypertrophy',
      trainerId: 'trn_alex',
    ),
    UserModel(
      id: 'c2',
      name: 'David Miller',
      email: 'david.m@mypt.com',
      role: UserRole.client,
      currentWeight: 82.0,
      ptCredits: 8,
      goal: 'Strength & Powerlifting',
      trainerId: 'trn_alex',
    ),
    UserModel(
      id: 'c3',
      name: 'Priya Sharma',
      email: 'priya.s@mypt.com',
      role: UserRole.client,
      currentWeight: 58.2,
      ptCredits: 2,
      goal: 'Endurance & Core',
      trainerId: 'usr_khushboo',
    ),
    UserModel(
      id: 'c4',
      name: 'Marcus Sterling',
      email: 'marcus.s@mypt.com',
      role: UserRole.client,
      currentWeight: 91.0,
      ptCredits: 6,
      goal: 'Body Recomposition',
      trainerId: 'usr_khushboo',
    ),
    UserModel(
      id: 'usr_khushboo_client',
      name: 'Khushboo (Client Mode)',
      email: 'khushboo.client@mypt.com',
      role: UserRole.client,
      currentWeight: 56.0,
      startingWeight: 59.0,
      ptCredits: 5,
      goal: 'Athletic Conditioning & Hypertrophy',
      trainerId: 'trn_alex',
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
      id: 's2',
      clientName: 'David Miller',
      trainerName: 'Alex Rivera',
      date: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '04:00 PM - 05:00 PM',
      focusArea: 'Deadlift Technique & Core',
      status: RequestStatus.confirmed,
    ),
    SessionItem(
      id: 's3',
      clientName: 'Sarah Jenkins',
      trainerName: 'Alex Rivera',
      date: DateTime.now().add(const Duration(days: 4)),
      timeSlot: '02:00 PM - 03:00 PM',
      focusArea: 'Legs & Squat Biomechanics',
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
    ),
    ClientRequestItem(
      id: 'req_2',
      clientName: 'Liam Johnson',
      email: 'liam.j@example.com',
      requestType: 'Strength Coaching 1-on-1',
      message: 'Need help increasing my bench press and fixing shoulder stability.',
      date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  List<TrainingPackage> packages = [
    TrainingPackage(
      id: 'pkg_starter',
      title: 'Foundation Starter',
      price: 199.0,
      sessionsCount: 4,
      durationWeeks: 4,
      perks: ['4 1-on-1 Sessions', 'Custom AI Meal Plan', 'Weekly Body Stat Scan'],
    ),
    TrainingPackage(
      id: 'pkg_transformation',
      title: '12-Week Transformation',
      price: 499.0,
      sessionsCount: 12,
      durationWeeks: 12,
      perks: ['12 1-on-1 Sessions', 'Priority Coach WhatsApp', '24/7 Form Guard', 'Custom Nutrition Protocol'],
    ),
    TrainingPackage(
      id: 'pkg_elite',
      title: 'Elite Athlete Blueprint',
      price: 899.0,
      sessionsCount: 24,
      durationWeeks: 24,
      perks: ['24 1-on-1 Sessions', 'Bi-weekly Biomechanics Audit', 'Full Supplementation Protocol', 'Dedicated Head Coach Review'],
    ),
  ];

  List<MovementItem> movementLibrary = [
    MovementItem(name: 'Barbell Back Squat', category: 'Legs / Quads', defaultSetsReps: '4 sets x 8 reps @ RPE 8', equipment: 'Barbell & Squat Rack'),
    MovementItem(name: 'Incline Dumbbell Bench Press', category: 'Chest / Push', defaultSetsReps: '3 sets x 10-12 reps', equipment: 'Adjustable Bench & Dumbbells'),
    MovementItem(name: 'Conventional Deadlift', category: 'Posterior Chain', defaultSetsReps: '3 sets x 5 reps @ RPE 8.5', equipment: 'Olympic Barbell & Plates'),
    MovementItem(name: 'Lat Pulldown (Neutral Grip)', category: 'Back / Pull', defaultSetsReps: '4 sets x 12 reps', equipment: 'Cable Station'),
    MovementItem(name: 'Romanian Deadlift (RDL)', category: 'Hamstrings & Glutes', defaultSetsReps: '3 sets x 10 reps', equipment: 'Barbell or Dumbbells'),
    MovementItem(name: 'Standing Overhead Press (OHP)', category: 'Shoulders', defaultSetsReps: '4 sets x 6 reps', equipment: 'Olympic Barbell'),
  ];

  List<WorkoutExercise> activeWorkoutRoutine = [
    WorkoutExercise(name: 'Barbell Bench Press', sets: '4', reps: '8-10', weight: '75 kg'),
    WorkoutExercise(name: 'Incline DB Press', sets: '3', reps: '12', weight: '26 kg'),
    WorkoutExercise(name: 'Standing Overhead Press', sets: '3', reps: '8', weight: '45 kg'),
    WorkoutExercise(name: 'Cable Tricep Pushdowns', sets: '4', reps: '15', weight: '30 kg'),
    WorkoutExercise(name: 'Hanging Leg Raises', sets: '3', reps: '15', weight: 'Bodyweight'),
  ];

  Map<String, bool> globalFlags = {
    'ai_fitness_copilot': true,
    'bento_analytics_grid': true,
    'strict_headcoach_hierarchy': true,
    'dynamic_currency_converter': true,
    'instant_package_checkout': true,
  };

  // --- HIERARCHY METHODS (Head Coach -> Trainer -> Client) ---
  List<UserModel> getTrainersForHeadCoach(String headCoachId) {
    return allTrainers.where((t) => t.headCoachId == headCoachId).toList();
  }

  List<UserModel> getClientsForTrainer(String trainerId) {
    return rosterClients.where((c) => c.trainerId == trainerId).toList();
  }

  List<UserModel> getClientsForHeadCoach(String headCoachId) {
    final squadTrainerIds = getTrainersForHeadCoach(headCoachId).map((t) => t.id).toSet();
    return rosterClients.where((c) => c.trainerId != null && squadTrainerIds.contains(c.trainerId)).toList();
  }

  void recruitTrainerToSquad({
    required String name,
    required String email,
    required String headCoachId,
  }) {
    final trainer = UserModel(
      id: 'trn_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: UserRole.coach,
      headCoachId: headCoachId,
    );
    allTrainers.add(trainer);
    demoAccounts[email.toLowerCase()] = trainer;
    notifyListeners();
  }

  void assignClientToTrainer({
    required UserModel client,
    required String trainerId,
  }) {
    client.trainerId = trainerId;
    notifyListeners();
  }

  void selectTrainerForCurrentUser(String trainerId) {
    if (currentUser != null) {
      currentUser!.trainerId = trainerId;
      notifyListeners();
    }
  }

  void addClientToTrainer({
    required String name,
    required String email,
    required String trainerId,
    required String goal,
    required double weight,
  }) {
    final client = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: UserRole.client,
      trainerId: trainerId,
      goal: goal,
      currentWeight: weight,
      startingWeight: weight,
      ptCredits: 4,
    );
    rosterClients.add(client);
    demoAccounts[email.toLowerCase()] = client;
    notifyListeners();
  }

  // --- AUTH METHODS ---
  bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    if (demoAccounts.containsKey(cleanEmail)) {
      currentUser = demoAccounts[cleanEmail];
      notifyListeners();
      return true;
    }
    currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      email: email,
      role: UserRole.client,
    );
    notifyListeners();
    return true;
  }

  bool register({required String name, required String email, required UserRole role}) {
    final cleanEmail = email.trim().toLowerCase();
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
    );
    demoAccounts[cleanEmail] = newUser;
    if (role == UserRole.coach) {
      allTrainers.add(newUser);
    } else if (role == UserRole.client) {
      rosterClients.add(newUser);
    }
    currentUser = newUser;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  bool get hasDualRole => currentUser?.dualRoles != null && (currentUser!.dualRoles?.length ?? 0) > 1;
  bool get isMasterUser => currentUser?.email.toLowerCase() == 'master@mypt.com';

  void setMasterRole(UserRole role) {
    if (currentUser != null && isMasterUser) {
      currentUser!.role = role;
      notifyListeners();
    }
  }

  void toggleDualRole() {
    if (currentUser == null || !hasDualRole) return;
    final current = currentUser!.role;
    final roles = currentUser!.dualRoles!;
    final nextIndex = (roles.indexOf(current) + 1) % roles.length;
    currentUser!.role = roles[nextIndex];
    notifyListeners();
  }

  void switchRole(UserRole role) {
    if (role == UserRole.client) currentUser = demoAccounts['sourabh@mypt.com'] ?? demoAccounts['sarah@mypt.com'];
    if (role == UserRole.coach) currentUser = demoAccounts['rincy@mypt.com'] ?? demoAccounts['alex@mypt.com'];
    if (role == UserRole.headCoach) {
      currentUser = demoAccounts['neeli@mypt.com'] ?? demoAccounts['marcus@mypt.com'];
      if (currentUser?.email == 'neeli@mypt.com') currentUser!.role = UserRole.headCoach;
    }
    if (role == UserRole.gymMgr) {
      currentUser = demoAccounts['neeli@mypt.com'] ?? demoAccounts['elena@mypt.com'];
      if (currentUser?.email == 'neeli@mypt.com') currentUser!.role = UserRole.gymMgr;
    }
    if (role == UserRole.superAdmin) currentUser = demoAccounts['aayush@mypt.com'] ?? demoAccounts['admin@mypt.com'];
    notifyListeners();
  }

  void switchUserByEmail(String email) {
    final clean = email.trim().toLowerCase();
    if (demoAccounts.containsKey(clean)) {
      currentUser = demoAccounts[clean];
      notifyListeners();
    }
  }

  void switchUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  void updateCurrentUserProfile({
    required String name,
    required String email,
    required String goal,
    required String phone,
    required int age,
    required double heightCm,
    required double weightKg,
    required String emergencyContact,
    required String medicalInfo,
  }) {
    if (currentUser == null) return;
    final oldEmail = currentUser!.email.toLowerCase();
    currentUser!.name = name;
    currentUser!.email = email;
    currentUser!.goal = goal;
    currentUser!.phone = phone;
    currentUser!.age = age;
    currentUser!.heightCm = heightCm;
    currentUser!.currentWeight = weightKg;
    currentUser!.emergencyContact = emergencyContact;
    currentUser!.medicalInfo = medicalInfo;

    // Keep demoAccounts synced
    if (oldEmail != email.toLowerCase()) {
      demoAccounts.remove(oldEmail);
      demoAccounts[email.toLowerCase()] = currentUser!;
    } else {
      demoAccounts[oldEmail] = currentUser!;
    }
    notifyListeners();
  }

  // --- APP ACTIONS ---
  void logTodayWeight(double newWeight) {
    if (currentUser != null) {
      currentUser!.currentWeight = newWeight;
      notifyListeners();
    }
  }

  void buyPackage(TrainingPackage pkg) {
    if (currentUser != null) {
      currentUser!.ptCredits += pkg.sessionsCount;
      notifyListeners();
    }
  }

  void addClientCredit(UserModel client) {
    client.ptCredits++;
    notifyListeners();
  }

  void scheduleSession({
    required String clientName,
    required DateTime date,
    required String timeSlot,
    required String focus,
  }) {
    sessions.insert(
      0,
      SessionItem(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        clientName: clientName,
        trainerName: 'Alex Rivera',
        date: date,
        timeSlot: timeSlot,
        focusArea: focus,
        status: RequestStatus.confirmed,
      ),
    );
    notifyListeners();
  }

  void acceptRequest(ClientRequestItem req) {
    req.status = RequestStatus.confirmed;
    sessions.insert(
      0,
      SessionItem(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        clientName: req.clientName,
        trainerName: currentUser?.name ?? 'Alex Rivera',
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '11:00 AM',
        focusArea: req.requestType,
        status: RequestStatus.confirmed,
      ),
    );
    notifyListeners();
  }

  void declineRequest(ClientRequestItem req) {
    req.status = RequestStatus.cancelled;
    notifyListeners();
  }

  void toggleFlag(String key, bool val) {
    globalFlags[key] = val;
    notifyListeners();
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
      theme: ThemeData(
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
// 4. AUTH SCREEN (SIGN IN / SIGN UP WITH VALIDATIONS)
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
  late final TextEditingController emailCtrl;
  late final TextEditingController passCtrl;
  final nameCtrl = TextEditingController();
  UserRole selectedRole = UserRole.client;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: kReleaseMode ? '' : 'sarah@mypt.com');
    passCtrl = TextEditingController(text: kReleaseMode ? '' : 'client123');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MyPtProvider>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'myPT',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isSignUp ? 'Create your account' : 'Welcome back to myPT',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  isSignUp ? 'Start your fitness journey today.' : 'Sign in to access your dashboard.',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // 1-Tap Demo Logins (Dev Mode Only)
                if (state.isDevMode) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app, size: 16, color: Color(0xFFFF5722)),
                            SizedBox(width: 6),
                            Text(
                              '1-Tap Quick Demo Login (Testers)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF5722)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('⚡ MASTER ADMIN (ALL ROLES TOGGLE)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _demoButton('⚡ Master (All Roles)', 'master@mypt.com', 'master', state),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('👑 SUPER ADMINS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _demoButton('🛡️ Aayush', 'aayush@mypt.com', 'admin123', state),
                            _demoButton('🛡️ Himani', 'himani@mypt.com', 'admin123', state),
                            _demoButton('🛡️ Elena Admin', 'admin@mypt.com', 'admin123', state),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('🥇 HEAD COACH & GYM MANAGER (DUAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _demoButton('👑 Neeli (Head/Gym Mgr)', 'neeli@mypt.com', 'lead123', state),
                            _demoButton('🥇 Marcus (Head Coach)', 'marcus@mypt.com', 'head123', state),
                            _demoButton('🏢 Elena (Gym Manager)', 'elena@mypt.com', 'manager123', state),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('🏋️ TRAINERS / COACHES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _demoButton('⚡ Rincy (Coach)', 'rincy@mypt.com', 'trainer123', state),
                            _demoButton('🏋️ Kumar (Coach)', 'kumar@mypt.com', 'trainer123', state),
                            _demoButton('🥊 Khushboo (Coach/Client)', 'khushboo@mypt.com', 'coachclient123', state),
                            _demoButton('🏋️ Alex (Coach)', 'alex@mypt.com', 'coach123', state),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('👤 CLIENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _demoButton('👤 Sourabh (Client)', 'sourabh@mypt.com', 'client123', state),
                            _demoButton('👤 RK (Client)', 'rk@mypt.com', 'client123', state),
                            _demoButton('👤 Odin (Client)', 'odin@mypt.com', 'client123', state),
                            _demoButton('👤 Sarah Jenkins', 'sarah@mypt.com', 'client123', state),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (isSignUp) ...[
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Alex Rivera',
                      prefixIcon: Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
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
                ],

                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Color(0xFF161B22),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email address is required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: passCtrl,
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
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 22),

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
                      if (!_formKey.currentState!.validate()) return;
                      if (isSignUp) {
                        state.register(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          role: selectedRole,
                        );
                      } else {
                        state.login(emailCtrl.text.trim(), passCtrl.text);
                      }
                    },
                    child: Text(
                      isSignUp ? 'Sign Up' : 'Sign In',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      isSignUp = !isSignUp;
                      _formKey.currentState?.reset();
                    }),
                    child: Text(
                      isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                      style: const TextStyle(color: Color(0xFFFF5722)),
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

  Widget _demoButton(String title, String email, String pass, MyPtProvider state) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF21262D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 11),
      ),
      onPressed: () {
        emailCtrl.text = email;
        passCtrl.text = pass;
        state.login(email, pass);
      },
      child: Text(title),
    );
  }
}

// ============================================================================
// 5. MAIN SHELL SCREEN (FULL MULTI-TAB BOTTOM NAVIGATION)
// ============================================================================
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<MyPtProvider>(context);
    final user = state.currentUser!;

    final List<BottomNavigationBarItem> navItems = switch (user.role) {
      UserRole.client => const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Charts'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Packages'),
      ],
      UserRole.coach => const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
        BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Build Chart'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Library'),
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Templates'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Packages'),
      ],
      UserRole.headCoach => const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'Squad Tree'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Protocols'),
        BottomNavigationBarItem(icon: Icon(Icons.domain), label: 'Facility'),
      ],
      UserRole.gymMgr => const [
        BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Floor'),
        BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Members'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Equipment'),
      ],
      UserRole.superAdmin => const [
        BottomNavigationBarItem(icon: Icon(Icons.toggle_on), label: 'Flags'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Accounts'),
        BottomNavigationBarItem(icon: Icon(Icons.dns), label: 'Telemetry'),
      ],
    };

    final int safeTabIndex = _tabIndex.clamp(0, navItems.length - 1);

    return Scaffold(
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
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                      ),
                    ),
                    if (state.isMasterUser) ...[
                      const SizedBox(width: 8),
                      PopupMenuButton<UserRole>(
                        tooltip: 'Switch Master Role',
                        color: const Color(0xFF161B22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                        ),
                        onSelected: (newRole) {
                          state.setMasterRole(newRole);
                          setState(() => _tabIndex = 0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFFFFD700),
                              content: Text(
                                '⚡ Master Role switched to ${newRole.name.toUpperCase()}',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                        itemBuilder: (ctx) => [
                          _buildMasterRoleMenuItem(UserRole.superAdmin, '👑 Super Admin', user.role),
                          _buildMasterRoleMenuItem(UserRole.headCoach, '🥇 Head Coach', user.role),
                          _buildMasterRoleMenuItem(UserRole.gymMgr, '🏢 Gym Manager', user.role),
                          _buildMasterRoleMenuItem(UserRole.coach, '🏋️ Coach / Trainer', user.role),
                          _buildMasterRoleMenuItem(UserRole.client, '👤 Client', user.role),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, size: 14, color: Color(0xFFFFD700)),
                              const SizedBox(width: 4),
                              Text(
                                '⚡ ${user.role.name.toUpperCase()} ▾',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (state.hasDualRole) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          state.toggleDualRole();
                          setState(() => _tabIndex = 0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF00E676),
                              content: Text('🔄 Switched persona to ${state.currentUser!.role.name.toUpperCase()} Mode'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_horiz, size: 14, color: Color(0xFF00E676)),
                              const SizedBox(width: 4),
                              Text(
                                user.role == UserRole.headCoach
                                    ? '⇄ Gym Mgr Mode'
                                    : user.role == UserRole.gymMgr
                                        ? '⇄ Head Coach Mode'
                                        : user.role == UserRole.coach
                                            ? '⇄ Client Mode'
                                            : '⇄ Coach Mode',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openProfileModal(context, state),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF5722), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF21262D),
                          child: Icon(Icons.face, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.isDevMode) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFFFF5722), size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'PERSONA: ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                        ),
                        const SizedBox(width: 6),
                        _userChip('⚡ Master', 'master@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🛡️ Aayush', 'aayush@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🛡️ Himani', 'himani@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👑 Neeli (Dual)', 'neeli@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🥊 Khushboo (Dual)', 'khushboo@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('⚡ Rincy (Coach)', 'rincy@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🏋️ Kumar (Coach)', 'kumar@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👤 Sourabh (Client)', 'sourabh@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👤 RK (Client)', 'rk@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👤 Odin (Client)', 'odin@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('👤 Sarah (Client)', 'sarah@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🏋️ Alex (Coach)', 'alex@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🥇 Marcus (Head)', 'marcus@mypt.com', state),
                        const SizedBox(width: 6),
                        _userChip('🏢 Elena (Gym Mgr)', 'elena@mypt.com', state),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: switch (user.role) {
        UserRole.client => _buildClientView(state, safeTabIndex),
        UserRole.coach => _buildCoachView(state, safeTabIndex),
        UserRole.headCoach => _buildHeadCoachView(state, safeTabIndex),
        UserRole.gymMgr => _buildGymMgrView(state, safeTabIndex),
        UserRole.superAdmin => _buildAdminView(state, safeTabIndex),
      },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeTabIndex,
        backgroundColor: const Color(0xFF0D1117),
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _tabIndex = i),
        items: navItems,
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            color: sel ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 6. CLIENT VIEWS (7 TABS: Home, Discover, Workouts, Charts, Schedule, Progress, Packages)
  // ============================================================================
  Widget _buildClientView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _clientHomeTab(state),
      1 => _clientDiscoverTab(state),
      2 => _clientWorkoutsTab(state),
      3 => _clientChartsTab(),
      4 => _clientScheduleTab(state),
      5 => _clientProgressTab(state),
      6 => _packagesList(state),
      _ => _clientHomeTab(state),
    };
  }

  Widget _clientHomeTab(MyPtProvider state) {
    final user = state.currentUser!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Welcome Back,', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(user.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 6),
                child: _statCard(
                  'REMAINING CREDITS',
                  '${user.ptCredits} Sessions',
                  'Tap to view packages',
                  const Color(0xFFFF5722),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _openWeightLogDialog(context, state),
                child: _statCard(
                  'CURRENT WEIGHT',
                  '${user.currentWeight} kg',
                  '↓ ${(user.startingWeight - user.currentWeight).toStringAsFixed(1)} kg lost',
                  const Color(0xFF29B6F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Start Your Training Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Explore verified coaches and book a session.', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                  onPressed: () => setState(() => _tabIndex = 1),
                  child: const Text('Discover Coaches 🚀', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Upcoming Confirmed Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...state.sessions.where((s) => s.clientName == user.name).map(
          (s) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2A150D),
                child: Icon(Icons.event, color: Color(0xFFFF5722)),
              ),
              title: Text(s.focusArea, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat('EEE, dd MMM').format(s.date)} at ${s.timeSlot}\nTrainer: ${s.trainerName}'),
              trailing: Chip(
                label: Text(s.status.name.toUpperCase()),
                backgroundColor: const Color(0xFF2A150D),
                labelStyle: const TextStyle(fontSize: 10, color: Color(0xFFFF5722)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _clientDiscoverTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Find Your Personal Coach', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Browse certified coaches tailored to your fitness goals.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        ...state.allTrainers.map(
          (t) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                        child: Text(t.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Text('Certified Personal Trainer • Strength & Conditioning', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Chip(label: Text('⭐ 4.9'), backgroundColor: Color(0xFF21262D)),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text('Specialties: Hypertrophy, Biomechanics, Fat Loss, Powerlifting', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openScheduleModal(context, state),
                          child: const Text('Book Consultation'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                          onPressed: () {
                            state.selectTrainerForCurrentUser(t.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF00E676),
                                content: Text('🎉 Coach ${t.name} selected as your primary trainer!'),
                              ),
                            );
                          },
                          child: const Text('Select Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _clientWorkoutsTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assigned Workout Program', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Chip(label: const Text('Phase 1 Active'), backgroundColor: const Color(0xFF00E676).withOpacity(0.2)),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Prescribed by Coach Alex Rivera', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
        const SizedBox(height: 14),
        ...state.activeWorkoutRoutine.map(
          (ex) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Color(0xFFFF5722)),
              title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${ex.sets} Sets x ${ex.reps} Reps • Target: ${ex.weight}'),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00E676)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logged ${ex.name} (${ex.sets} sets)!')),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
          icon: const Icon(Icons.add),
          label: const Text('Build / Log Custom Workout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Custom Workout Logger activated!')),
            );
          },
        ),
      ],
    );
  }

  Widget _clientChartsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Assigned Fitness Charts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phase 1: Hypertrophy & Fat Loss', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Assigned by Coach Alex Rivera', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
                Divider(height: 20),
                Text('🥗 Daily Targets: 1,950 kcal | 150g Protein | 190g Carbs | 55g Fat'),
                SizedBox(height: 10),
                Text('💪 Workout Split:\n• Mon: Upper Hypertrophy\n• Tue: Lower Quads\n• Thu: Push Strength\n• Fri: Pull & Core'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _clientScheduleTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bookings & Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Book Session', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _openScheduleModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Your Booked Sessions Calendar', style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 14),
        ...state.sessions.map(
          (s) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2A150D),
                child: Icon(Icons.calendar_today, color: Color(0xFFFF5722)),
              ),
              title: Text(s.focusArea, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat('EEEE, dd MMM yyyy').format(s.date)}\nTime Slot: ${s.timeSlot}\nCoach: ${s.trainerName}'),
              trailing: Chip(
                label: Text(s.status.name.toUpperCase()),
                backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _clientProgressTab(MyPtProvider state) {
    final user = state.currentUser!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Body Transformation Tracker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Log Today', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _openWeightLogDialog(context, state),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('CURRENT WEIGHT', '${user.currentWeight} kg', 'Starting: ${user.startingWeight} kg', const Color(0xFF29B6F6))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('TOTAL LOSS', '${(user.startingWeight - user.currentWeight).toStringAsFixed(1)} kg', 'Target: -5.0 kg', const Color(0xFF00E676))),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Body Circumference Measurements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _measurementRow('Chest', '96 cm', '-2.5 cm'),
                _measurementRow('Waist', '78 cm', '-4.0 cm'),
                _measurementRow('Hips', '92 cm', '-1.5 cm'),
                _measurementRow('Arms', '34 cm', '+1.2 cm'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _measurementRow(String label, String current, String change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('$current ($change)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
        ],
      ),
    );
  }

  // ============================================================================
  // 7. COACH VIEWS (8 TABS: Dashboard, Requests, Schedule, Clients, Build Chart, Library, Templates, Packages)
  // ============================================================================
  Widget _buildCoachView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _coachDashboardTab(state),
      1 => _coachRequestsTab(state),
      2 => _coachScheduleTab(state),
      3 => _coachClientsTab(state),
      4 => _coachBuildChartTab(),
      5 => _coachLibraryTab(state),
      6 => _coachTemplatesTab(),
      7 => _coachPackagesTab(state),
      _ => _coachDashboardTab(state),
    };
  }

  Widget _coachDashboardTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final myClients = state.getClientsForTrainer(coach.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Trainer Command Center', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(coach.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('ASSIGNED CLIENTS', '${myClients.length}', 'Active Trainees', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('MONTHLY REV', state.formatPrice(1398), '+14% growth', const Color(0xFF00E676))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('ACTIVE PACKS', '${state.packages.length}', 'Manage tiers', const Color(0xFF29B6F6))),
          ],
        ),
        const SizedBox(height: 16),
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
        ...state.sessions.map(
          (s) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2A150D),
                child: Icon(Icons.event, color: Color(0xFFFF5722)),
              ),
              title: Text(s.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat('dd MMM').format(s.date)} at ${s.timeSlot}\nFocus: ${s.focusArea}'),
              trailing: Chip(
                label: Text(s.status.name.toUpperCase()),
                backgroundColor: const Color(0xFF2A150D),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coachRequestsTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Client Booking Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Pending consultations & session requests requiring approval.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        if (state.trainerRequests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No pending requests at this time.')),
            ),
          )
        else
          ...state.trainerRequests.map(
            (req) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Chip(label: Text(req.status.name.toUpperCase()), backgroundColor: const Color(0xFF21262D)),
                      ],
                    ),
                    Text(req.requestType, style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('"${req.message}"', style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    if (req.status == RequestStatus.pending)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => state.declineRequest(req),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                              onPressed: () => state.acceptRequest(req),
                              child: const Text('Accept & Book', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _coachScheduleTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Trainer Weekly Calendar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Add Slot', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _openScheduleModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.sessions.map(
          (s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: Color(0xFFFF5722)),
              title: Text('${s.clientName} (${s.focusArea})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat('EEEE, dd MMM').format(s.date)} • ${s.timeSlot}'),
              trailing: Chip(label: Text(s.status.name.toUpperCase()), backgroundColor: const Color(0xFF00E676).withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coachClientsTab(MyPtProvider state) {
    final coach = state.currentUser!;
    final myClients = state.getClientsForTrainer(coach.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Assigned Trainees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Chip(
              label: Text('${myClients.length} Trainees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              backgroundColor: const Color(0xFF21262D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (myClients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_add_disabled, size: 42, color: Colors.white38),
                SizedBox(height: 12),
                Text('No Clients Assigned Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  'You currently do not have any active clients under your roster. Book sessions or ask your Head Coach to assign clients to you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...myClients.map(
            (client) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                          child: Text(client.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(client.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${client.ptCredits} Credits', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🎯 Goal: ${client.goal}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('⚖️ ${client.currentWeight} kg', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('+1 Credit', style: TextStyle(fontSize: 12)),
                            onPressed: () => state.addClientCredit(client),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                            onPressed: () => _openScheduleModal(context, state),
                            child: const Text('Book Session', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _coachBuildChartTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Client Chart Builder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Design customized nutrition macros and weekly workout protocols for your clients.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Macro Prescription Tool', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const TextField(decoration: InputDecoration(labelText: 'Daily Calorie Target (kcal)', border: OutlineInputBorder())),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Fitness & Nutrition Chart Saved & Assigned!')),
                      );
                    },
                    child: const Text('Assign Chart to Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _coachLibraryTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Exercise Movement Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Standardized exercises catalog for workout planning', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 14),
        ...state.movementLibrary.map(
          (m) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fitness_center, color: Color(0xFFFF5722), size: 20),
              ),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${m.category} • ${m.equipment}\nPrescription: ${m.defaultSetsReps}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              trailing: Chip(
                label: Text(m.category.split('/').first.trim()),
                backgroundColor: const Color(0xFF2A150D),
                labelStyle: const TextStyle(fontSize: 10, color: Color(0xFFFF5722)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coachTemplatesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Workout Plan Templates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.library_books, color: Color(0xFFFF5722)),
            title: Text('4-Day Upper / Lower Hypertrophy', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('4 sessions per week • Hypertrophy & Volume Focus'),
            trailing: Chip(label: Text('ASSIGN')),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.library_books, color: Color(0xFFFF5722)),
            title: Text('5x5 Strength Foundation', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('3 sessions per week • Squat, Bench, Deadlift focus'),
            trailing: Chip(label: Text('ASSIGN')),
          ),
        ),
      ],
    );
  }

  Widget _coachPackagesTab(MyPtProvider state) {
    return _packagesList(state);
  }

  // ============================================================================
  // 8. HEAD COACH VIEWS (5 TABS: Overview, Squad Tree, Schedule, Protocols, Facility)
  // ============================================================================
  Widget _buildHeadCoachView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _headCoachOverviewTab(state),
      1 => _headCoachSquadTab(state),
      2 => _headCoachScheduleTab(state),
      3 => _headCoachProtocolsTab(),
      4 => _gymFacilityTab(),
      _ => _headCoachOverviewTab(state),
    };
  }

  Widget _headCoachOverviewTab(MyPtProvider state) {
    final headCoach = state.currentUser!;
    final myTrainers = state.getTrainersForHeadCoach(headCoach.id);
    final myClients = state.getClientsForHeadCoach(headCoach.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Head Coach Command', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(headCoach.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('COACH SQUAD', '${myTrainers.length} Trainers', myTrainers.isEmpty ? 'Empty Squad' : 'Active', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('TOTAL TRAINEES', '${myClients.length} Clients', 'Under Squad', const Color(0xFF00E676))),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'SQUAD LOAD',
                myTrainers.isEmpty ? '0%' : '${((myClients.length / (myTrainers.length * 15)) * 100).round()}%',
                'Capacity',
                const Color(0xFF29B6F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (myTrainers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 48, color: Color(0xFFFF5722)),
                const SizedBox(height: 12),
                const Text('Your Coaching Squad is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'As a Head Coach, you oversee trainers who coach clients (Head Coach ➔ Trainer ➔ Client).\nRecruit or assign certified trainers to your squad to start managing their rosters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Recruit Trainer to Squad', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openRecruitTrainerModal(context, state),
                ),
              ],
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Coaching Squad Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF5722)),
                        label: const Text('Add Trainer', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
                        onPressed: () => _openRecruitTrainerModal(context, state),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ...myTrainers.map(
                    (trainer) {
                      final trainerClients = state.getClientsForTrainer(trainer.id);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF21262D),
                          child: Text(trainer.name[0], style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(trainer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${trainerClients.length} Assigned Clients • ${trainer.email}'),
                        trailing: Chip(
                          label: Text('${trainerClients.length}/15 LOAD'),
                          backgroundColor: const Color(0xFF2A150D),
                          labelStyle: const TextStyle(fontSize: 10, color: Color(0xFFFF5722)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _headCoachSquadTab(MyPtProvider state) {
    final headCoach = state.currentUser!;
    final myTrainers = state.getTrainersForHeadCoach(headCoach.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Squad & Trainee Tree', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 11),
              ),
              icon: const Icon(Icons.person_add, size: 14),
              label: const Text('Recruit Coach'),
              onPressed: () => _openRecruitTrainerModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Hierarchy: Head Coach ➔ Trainer ➔ Assigned Clients', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        if (myTrainers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 42, color: Colors.white38),
                const SizedBox(height: 12),
                const Text('No Trainers in Your Squad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Add or assign trainers to start viewing the full hierarchy and managing trainee workloads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                  onPressed: () => _openRecruitTrainerModal(context, state),
                  child: const Text('Add First Trainer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          ...myTrainers.map(
            (trainer) {
              final trainerClients = state.getClientsForTrainer(trainer.id);
              final loadRatio = (trainerClients.length / 15).clamp(0.0, 1.0);
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                            child: const Icon(Icons.fitness_center, color: Color(0xFFFF5722), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trainer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Trainer / Coach • ${trainer.email}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text('${trainerClients.length} Trainees'),
                            backgroundColor: const Color(0xFF21262D),
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _progressBar('Workload (${trainerClients.length}/15 Capacity)', loadRatio, loadRatio > 0.8 ? Colors.amber : const Color(0xFF00E676)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ASSIGNED TRAINEES (${trainerClients.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            icon: const Icon(Icons.add, size: 14, color: Color(0xFFFF5722)),
                            label: const Text('Assign Trainee', style: TextStyle(fontSize: 11, color: Color(0xFFFF5722))),
                            onPressed: () => _openAssignClientModal(context, state, trainer),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (trainerClients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No clients currently assigned to this trainer.', style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
                        )
                      else
                        ...trainerClients.map(
                          (c) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Color(0xFF00E676)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('${c.goal} • ${c.currentWeight} kg', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${c.ptCredits} Credits', style: const TextStyle(color: Color(0xFFFF5722), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _headCoachScheduleTab(MyPtProvider state) {
    return _coachScheduleTab(state);
  }

  Widget _headCoachProtocolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Master Coaching Protocols', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Standard Operating Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Divider(height: 20),
                Text('1. Biomechanics Assessment required on Session 1'),
                SizedBox(height: 8),
                Text('2. Progressive Overload logging every 14 days'),
                SizedBox(height: 8),
                Text('3. Nutrition macro audit upon Phase 2 transition'),
                SizedBox(height: 8),
                Text('4. Injury screening protocol before heavy compound lifts'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 9. GYM MANAGER VIEWS (4 TABS: Floor, Members, Schedule, Equipment)
  // ============================================================================
  Widget _buildGymMgrView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _gymMgrFloorTab(state),
      1 => _gymMgrMembersTab(state),
      2 => _coachScheduleTab(state),
      3 => _gymFacilityTab(),
      _ => _gymMgrFloorTab(state),
    };
  }

  Widget _gymMgrFloorTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Facility Operations Hub', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(state.currentUser!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('FLOOR CAPACITY', '38 / 100', 'Safe Load (38%)', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('MONTHLY SALES', state.formatPrice(14820), '+18% vs Target', const Color(0xFF00E676))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('EQUIPMENT STATUS', '100% OK', 'All Racks Ready', const Color(0xFF29B6F6))),
          ],
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gym Floor Real-Time Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Divider(height: 20),
                Text('• Free Weights Zone: 16 Members'),
                SizedBox(height: 6),
                Text('• Cardio Deck: 12 Members'),
                SizedBox(height: 6),
                Text('• PT Studio Room A: 4 Private Sessions Active'),
                SizedBox(height: 6),
                Text('• Facility Climate: 20.5°C (Optimized)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gymMgrMembersTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Facility Member Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.rosterClients.map(
          (m) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.badge, color: Color(0xFFFF5722)),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: Active Pass • ${m.ptCredits} PT Sessions booked'),
              trailing: const Chip(label: Text('CHECKED IN'), backgroundColor: Color(0xFF00E676)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gymFacilityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Facility Equipment Audit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛠️ Equipment Health Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Divider(height: 20),
                Text('• Olympic Squat Racks (x6): Certified Inspected'),
                SizedBox(height: 8),
                Text('• Cable Crossover Stations: Cable Tension Tested'),
                SizedBox(height: 8),
                Text('• Treadmills Matrix (x10): Belt Lubricated'),
                SizedBox(height: 8),
                Text('• Emergency First Aid & Defibrillator: Battery 100%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 10. SUPER ADMIN VIEWS (3 TABS: Flags, Accounts, Telemetry)
  // ============================================================================
  Widget _buildAdminView(MyPtProvider state, int tab) {
    return switch (tab) {
      0 => _adminFlagsTab(state),
      1 => _adminAccountsTab(state),
      2 => _adminSystemTab(),
      _ => _adminFlagsTab(state),
    };
  }

  Widget _adminFlagsTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Governance & Flags', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(state.currentUser!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        const Text('Global Feature Flags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...state.globalFlags.entries.map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              activeColor: const Color(0xFFFF5722),
              title: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              value: entry.value,
              onChanged: (val) => state.toggleFlag(entry.key, val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _adminAccountsTab(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('User Accounts & Role Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.demoAccounts.entries.map(
          (e) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFFF5722)),
              title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.key} • Role: ${e.value.role.name}'),
              trailing: OutlinedButton(
                onPressed: () => state.switchUser(e.value),
                child: const Text('Switch'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _adminSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('System Infrastructure & Diagnostics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚡ Real-time Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Divider(height: 20),
                Text('• Supabase Database: Connected (Lat: 42ms)'),
                SizedBox(height: 8),
                Text('• State Provider: Active & Synchronized'),
                SizedBox(height: 8),
                Text('• Authentication Gateway: Nominal'),
                SizedBox(height: 8),
                Text('• Uptime SLA: 99.98%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 11. SUB-WIDGETS & MODALS (PACKAGES, CHECKOUT, RECRUIT, ASSIGN, PROFILE)
  // ============================================================================
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
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: col)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: col.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _progressBar(String label, double value, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFF21262D),
            valueColor: AlwaysStoppedAnimation<Color>(col),
          ),
        ),
      ],
    );
  }

  Widget _packagesList(MyPtProvider state) {
    final cur = state.currentCurrencyInfo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRICING REGION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                    Text('${cur.flag} ${cur.name} (${cur.code})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.currency_exchange, size: 14, color: Color(0xFFFF5722)),
                label: const Text('Change', style: TextStyle(fontSize: 11)),
                onPressed: () => _openCurrencySelector(context, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available Packages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Balance: ${state.currentUser?.ptCredits ?? 0} Credits',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.packages.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: p.sessionsCount > 6 ? const Color(0xFFFF5722).withOpacity(0.5) : Colors.white12,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openPackageCheckoutModal(context, state, p),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.sessionsCount == 12)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🔥 MOST POPULAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              const SizedBox(height: 2),
                              Text('${p.sessionsCount} 1-on-1 Sessions • ${p.durationWeeks} Weeks', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              state.formatPrice(p.price),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF00E676)),
                            ),
                            Text(
                              '${state.formatPrice(p.price / p.sessionsCount)}/session',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ...p.perks.map(
                      (perk) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(perk, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openPackageCheckoutModal(context, state, p),
                        child: Text(
                          'Purchase Package (${state.formatPrice(p.price)})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openPackageCheckoutModal(BuildContext context, MyPtProvider state, TrainingPackage p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Confirm Package Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('+${p.sessionsCount} PT Sessions • ${p.durationWeeks} Weeks Access', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  Text(
                    state.formatPrice(p.price),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00E676)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF5722)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFFFF5722)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Instant Card Payment (•••• 4242)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Icon(Icons.check_circle, color: Color(0xFFFF5722), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  state.buyPackage(p);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF00E676),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.black),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '🎉 Purchased ${p.title}! +${p.sessionsCount} Credits added (Total: ${state.currentUser?.ptCredits ?? 0}).',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                child: Text(
                  'Pay ${state.formatPrice(p.price)} & Add +${p.sessionsCount} Credits',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openCurrencySelector(BuildContext context, MyPtProvider state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Your Currency Region', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Prices will automatically adapt to your selected country currency.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            ...MyPtProvider.supportedCurrencies.values.map(
              (cur) {
                final isSelected = state.selectedCurrency == cur.code;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Text(cur.flag, style: const TextStyle(fontSize: 24)),
                  title: Text('${cur.name} (${cur.code})', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFFF5722) : Colors.white)),
                  trailing: Text(cur.symbol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? const Color(0xFFFF5722) : Colors.white60)),
                  tileColor: isSelected ? const Color(0xFF21262D) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    state.setCurrency(cur.code);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openWeightLogDialog(BuildContext context, MyPtProvider state) {
    final ctrl = TextEditingController(text: state.currentUser!.currentWeight.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Today\'s Weight'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            onPressed: () {
              final w = double.tryParse(ctrl.text);
              if (w != null) {
                state.logTodayWeight(w);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openScheduleModal(BuildContext context, MyPtProvider state) {
    DateTime dt = DateTime.now().add(const Duration(days: 1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book Session'),
        content: const Text('Book a 1-on-1 session with Coach Alex Rivera for tomorrow at 10:00 AM?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            onPressed: () {
              state.scheduleSession(
                clientName: state.currentUser!.name,
                date: dt,
                timeSlot: '10:00 AM',
                focus: 'Hypertrophy & Form',
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openRecruitTrainerModal(BuildContext context, MyPtProvider state) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final headCoach = state.currentUser!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recruit Trainer to Squad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Assign a trainer under Head Coach ${headCoach.name}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Divider(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Trainer Full Name',
                  prefixIcon: Icon(Icons.fitness_center),
                  filled: true,
                  fillColor: Color(0xFF0D1117),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Trainer name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Trainer Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Color(0xFF0D1117),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    state.recruitTrainerToSquad(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      headCoachId: headCoach.id,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF00E676),
                        content: Text('🎉 Coach ${nameCtrl.text.trim()} added to your squad!'),
                      ),
                    );
                  },
                  child: const Text('Add Trainer to Squad', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAssignClientModal(BuildContext context, MyPtProvider state, UserModel trainer) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: 'Hypertrophy & Fat Loss');
    final weightCtrl = TextEditingController(text: '70.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('Assign Trainee to ${trainer.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Client Full Name',
                  prefixIcon: Icon(Icons.person),
                  filled: true,
                  fillColor: Color(0xFF0D1117),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Client name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Client Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Color(0xFF0D1117),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) return 'Valid email required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: goalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Training Goal',
                        filled: true,
                        fillColor: Color(0xFF0D1117),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        filled: true,
                        fillColor: Color(0xFF0D1117),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final weight = double.tryParse(weightCtrl.text) ?? 70.0;
                    state.addClientToTrainer(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      trainerId: trainer.id,
                      goal: goalCtrl.text.trim(),
                      weight: weight,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF00E676),
                        content: Text('🎉 Client ${nameCtrl.text.trim()} assigned to ${trainer.name}!'),
                      ),
                    );
                  },
                  child: Text('Assign Client to ${trainer.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileModal(BuildContext context, MyPtProvider state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101216),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Profile Banner
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF21262D),
                    child: Icon(Icons.face, color: Color(0xFFFF5722), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.currentUser!.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          state.currentUser!.email,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(state.currentUser!.role.name.toUpperCase()),
                    backgroundColor: const Color(0xFF2A150D),
                    labelStyle: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Personal Details Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: Color(0xFFFF5722), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'PERSONAL DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openEditProfileSheet(context, state);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Color(0xFFFF5722), size: 13),
                                SizedBox(width: 3),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: Color(0xFFFF5722), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Colors.white12),
                    _profileInfoRow(Icons.flag_outlined, 'Focus / Goal', state.currentUser!.goal),
                    const SizedBox(height: 8),
                    _profileInfoRow(
                      Icons.monitor_weight_outlined,
                      'Body Stats',
                      '${state.currentUser!.currentWeight} kg  •  ${state.currentUser!.heightCm.toStringAsFixed(0)} cm  •  ${state.currentUser!.age} yrs',
                    ),
                    const SizedBox(height: 8),
                    _profileInfoRow(Icons.phone_outlined, 'Phone', state.currentUser!.phone),
                    const SizedBox(height: 8),
                    _profileInfoRow(Icons.contact_emergency_outlined, 'Emergency Contact', state.currentUser!.emergencyContact),
                    const SizedBox(height: 8),
                    _profileInfoRow(Icons.medical_information_outlined, 'Medical / Notes', state.currentUser!.medicalInfo),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Edit Personal Details Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21262D),
                    foregroundColor: const Color(0xFFFF5722),
                    side: const BorderSide(color: Color(0xFFFF5722), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.edit, size: 16, color: Color(0xFFFF5722)),
                  label: const Text('Edit Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openEditProfileSheet(context, state);
                  },
                ),
              ),

              if (state.isMasterUser) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'MASTER PRODUCTION ROLE TOGGLE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD700),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _masterRoleChip(ctx, state, UserRole.superAdmin, '👑 Super Admin'),
                          _masterRoleChip(ctx, state, UserRole.headCoach, '🥇 Head Coach'),
                          _masterRoleChip(ctx, state, UserRole.gymMgr, '🏢 Gym Mgr'),
                          _masterRoleChip(ctx, state, UserRole.coach, '🏋️ Coach'),
                          _masterRoleChip(ctx, state, UserRole.client, '👤 Client'),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (state.hasDualRole) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz, color: Color(0xFF00E676)),
                  title: Text(
                    state.currentUser!.role == UserRole.headCoach
                        ? 'Switch to Gym Manager Mode'
                        : state.currentUser!.role == UserRole.gymMgr
                            ? 'Switch to Head Coach Mode'
                            : state.currentUser!.role == UserRole.coach
                                ? 'Switch to Client Mode'
                                : 'Switch to Coach Mode',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00E676)),
                  ),
                  subtitle: Text(
                    'Dual-role account active (${state.currentUser!.email})',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF00E676)),
                  onTap: () {
                    state.toggleDualRole();
                    Navigator.pop(ctx);
                    setState(() => _tabIndex = 0);
                  },
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    state.logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFF5722)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _openEditProfileSheet(BuildContext context, MyPtProvider state) {
    final user = state.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    final goalCtrl = TextEditingController(text: user.goal);
    final weightCtrl = TextEditingController(text: user.currentWeight.toString());
    final heightCtrl = TextEditingController(text: user.heightCm.toString());
    final ageCtrl = TextEditingController(text: user.age.toString());
    final emergencyCtrl = TextEditingController(text: user.emergencyContact);
    final medicalCtrl = TextEditingController(text: user.medicalInfo);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101216),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit, color: Color(0xFFFF5722), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Edit Personal Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: goalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fitness Focus / Goal',
                      prefixIcon: Icon(Icons.flag_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            filled: true,
                            fillColor: Color(0xFF161B22),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || double.tryParse(val) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            filled: true,
                            fillColor: Color(0xFF161B22),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || double.tryParse(val) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age (yrs)',
                            filled: true,
                            fillColor: Color(0xFF161B22),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || int.tryParse(val) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emergencyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact',
                      prefixIcon: Icon(Icons.contact_emergency_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: medicalCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Medical History / Injuries / Notes',
                      prefixIcon: Icon(Icons.medical_information_outlined),
                      filled: true,
                      fillColor: Color(0xFF161B22),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            state.updateCurrentUserProfile(
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              goal: goalCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              age: int.tryParse(ageCtrl.text.trim()) ?? 28,
                              heightCm: double.tryParse(heightCtrl.text.trim()) ?? 168.0,
                              weightKg: double.tryParse(weightCtrl.text.trim()) ?? 64.5,
                              emergencyContact: emergencyCtrl.text.trim(),
                              medicalInfo: medicalCtrl.text.trim(),
                            );
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF00E676),
                                content: Text('✅ Personal details updated successfully!'),
                              ),
                            );
                          },
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<UserRole> _buildMasterRoleMenuItem(UserRole role, String label, UserRole currentRole) {
    final isSelected = role == currentRole;
    return PopupMenuItem<UserRole>(
      value: role,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (isSelected) const Icon(Icons.check, color: Color(0xFFFFD700), size: 16),
        ],
      ),
    );
  }

  Widget _masterRoleChip(BuildContext ctx, MyPtProvider state, UserRole role, String label) {
    final isCurrent = state.currentUser!.role == role;
    return InkWell(
      onTap: () {
        state.setMasterRole(role);
        Navigator.pop(ctx);
        setState(() => _tabIndex = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFFFFD700),
            content: Text(
              '⚡ Master persona switched to ${role.name.toUpperCase()}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFFFD700) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? const Color(0xFFFFD700) : Colors.white24,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
