import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ============================================================================
// 1. ROLES & DATA MODELS (LOGIC PRESERVED 100%)
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
  String? headCoachId; // If Coach: ID of Head Coach managing this coach
  String? trainerId;   // If Client: ID of Trainer training this client

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.currentWeight = 64.5,
    this.startingWeight = 68.0,
    this.ptCredits = 0,
    this.goal = 'Fat Loss & Hypertrophy',
    this.headCoachId,
    this.trainerId,
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

// ============================================================================
// 2. STATE PROVIDER WITH AUTH & HIERARCHY (LOGIC PRESERVED 100%)
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

  void toggleDevMode() {
    isDevMode = !isDevMode;
    notifyListeners();
  }

  // Pre-configured accounts for the 5 roles
  final Map<String, UserModel> demoAccounts = {
    'sarah@mypt.com': UserModel(
      id: 'usr_sarah',
      name: 'Sarah Jenkins',
      email: 'sarah@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      startingWeight: 68.0,
      ptCredits: 4,
      trainerId: 'trn_alex',
    ),
    'alex@mypt.com': UserModel(
      id: 'trn_alex',
      name: 'Alex Rivera',
      email: 'alex@mypt.com',
      role: UserRole.coach,
      headCoachId: 'trn_marcus',
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
      id: 'trn_alex',
      name: 'Alex Rivera',
      email: 'alex@mypt.com',
      role: UserRole.coach,
      headCoachId: 'trn_marcus',
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
      id: 'c1',
      name: 'Sarah Jenkins',
      email: 'sarah.j@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      ptCredits: 4,
      goal: 'Hypertrophy & Fat Loss',
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
      trainerId: 'trn_elena',
    ),
    UserModel(
      id: 'c4',
      name: 'Marcus Sterling',
      email: 'marcus.s@mypt.com',
      role: UserRole.client,
      currentWeight: 91.0,
      ptCredits: 6,
      goal: 'Body Recomposition',
      trainerId: 'trn_elena',
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
      perks: ['12 1-on-1 Sessions', 'Priority Coach WhatsApp', '24/7 AI Form Guard', 'Custom Nutrition Protocol'],
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

  List<UserModel> getUnassignedTrainers(String currentHeadCoachId) {
    return allTrainers.where((t) => t.headCoachId == null || t.headCoachId != currentHeadCoachId).toList();
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

  void assignExistingTrainerToSquad({
    required UserModel trainer,
    required String headCoachId,
  }) {
    trainer.headCoachId = headCoachId;
    notifyListeners();
  }

  void assignClientToTrainer({
    required UserModel client,
    required String trainerId,
  }) {
    client.trainerId = trainerId;
    notifyListeners();
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

  void switchRole(UserRole role) {
    if (role == UserRole.client) currentUser = demoAccounts['sarah@mypt.com'];
    if (role == UserRole.coach) currentUser = demoAccounts['alex@mypt.com'];
    if (role == UserRole.headCoach) currentUser = demoAccounts['marcus@mypt.com'];
    if (role == UserRole.gymMgr) currentUser = demoAccounts['elena@mypt.com'];
    if (role == UserRole.superAdmin) currentUser = demoAccounts['admin@mypt.com'];
    notifyListeners();
  }

  void switchUser(UserModel user) {
    currentUser = user;
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

  void toggleFlag(String key, bool val) {
    globalFlags[key] = val;
    notifyListeners();
  }
}

// ============================================================================
// 3. MAIN APP & THEME CONFIGURATION (PAPERPILLAR / GHANI PRADITA STYLE)
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
      title: 'myPT — AI-Driven Fitness Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B11),
        cardColor: const Color(0xFF121826),
        primaryColor: const Color(0xFFFF5722),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5722),
          onPrimary: Colors.white,
          secondary: Color(0xFF00E599),
          onSecondary: Color(0xFF080B11),
          surface: Color(0xFF121826),
          onSurface: Colors.white,
          tertiary: Color(0xFF8B5CF6),
        ),
        dividerColor: const Color(0xFF222D42),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFFF5722),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: state.currentUser == null ? const AuthScreen() : const MainShellScreen(),
    );
  }
}

// ============================================================================
// 4. AUTH SCREEN (SIGN IN / SIGN UP WITH VALIDATIONS & PAPERPILLAR GLASS UI)
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF182238),
              Color(0xFF0E1320),
              Color(0xFF080B11),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6D3B), Color(0xFFFF5722)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5722).withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'myPT',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                          ),
                          child: const Text(
                            'AI POWERED',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6), letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF151D2F), Color(0xFF0F1523)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF222D42), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Segmented Tab Toggle
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0E17),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF222D42)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isSignUp) {
                                          setState(() => isSignUp = false);
                                          _formKey.currentState?.reset();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !isSignUp ? const Color(0xFFFF5722) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: !isSignUp ? Colors.white : Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!isSignUp) {
                                          setState(() => isSignUp = true);
                                          _formKey.currentState?.reset();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSignUp ? const Color(0xFFFF5722) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSignUp ? Colors.white : Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Dev Mode Tester Quick Login
                            if (state.isDevMode) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101625),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.bolt, size: 14, color: Color(0xFFFF5722)),
                                        SizedBox(width: 6),
                                        Text(
                                          '1-Tap Demo Tester Logins',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFFF5722)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _demoQuickChip('👤 Client', 'sarah@mypt.com', 'client123', state),
                                        _demoQuickChip('🏋️ Trainer', 'alex@mypt.com', 'coach123', state),
                                        _demoQuickChip('🥇 Head Coach', 'marcus@mypt.com', 'head123', state),
                                        _demoQuickChip('🏢 Gym Mgr', 'elena@mypt.com', 'manager123', state),
                                        _demoQuickChip('🛡️ Admin', 'admin@mypt.com', 'admin123', state),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Inputs
                            if (isSignUp) ...[
                              _buildInputLabel('Full Name'),
                              TextFormField(
                                controller: nameCtrl,
                                decoration: _inputStyle(hint: 'e.g. Alex Rivera', icon: Icons.person_outline),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Full name is required';
                                  if (val.trim().length < 2) return 'Full name must be at least 2 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildInputLabel('Account Role'),
                              DropdownButtonFormField<UserRole>(
                                value: selectedRole,
                                dropdownColor: const Color(0xFF151D2F),
                                decoration: _inputStyle(hint: 'Select Role', icon: Icons.badge_outlined),
                                items: const [
                                  DropdownMenuItem(value: UserRole.client, child: Text('👤 Client (Fitness Trainee)')),
                                  DropdownMenuItem(value: UserRole.coach, child: Text('🏋️ Coach / Trainer')),
                                  DropdownMenuItem(value: UserRole.headCoach, child: Text('🥇 Head Coach (Squad Leader)')),
                                  DropdownMenuItem(value: UserRole.gymMgr, child: Text('🏢 Gym Facility Manager')),
                                ],
                                onChanged: (val) => setState(() => selectedRole = val!),
                              ),
                              const SizedBox(height: 14),
                            ],

                            _buildInputLabel('Email Address'),
                            TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputStyle(hint: 'name@example.com', icon: Icons.email_outlined),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Email address is required';
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(val.trim())) return 'Please enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildInputLabel('Password'),
                            TextFormField(
                              controller: passCtrl,
                              obscureText: _obscurePassword,
                              decoration: _inputStyle(
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.white54,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                if (val.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5722),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                  shadowColor: const Color(0xFFFF5722).withOpacity(0.4),
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isSignUp ? 'Create My Account' : 'Sign In to Dashboard',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
      ),
    );
  }

  InputDecoration _inputStyle({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white54, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0B0F19),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF222D42)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF222D42)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _demoQuickChip(String label, String email, String pass, MyPtProvider state) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        emailCtrl.text = email;
        passCtrl.text = pass;
        state.login(email, pass);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E283D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ============================================================================
// 5. MAIN SHELL SCREEN (GHANI PRADITA DESKTOP / RESPONSIVE EXPLORATION)
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

    return Scaffold(
      backgroundColor: const Color(0xFF080B11),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(state.isDevMode ? 120 : 70),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0B0F19),
              border: Border(bottom: BorderSide(color: Color(0xFF1D263B), width: 1.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Brand Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6D3B), Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'myPT',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF172033),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2B3854)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00E599),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.role.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Currency Selector Pill
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openCurrencySelector(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151D2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF222F48)),
                        ),
                        child: Row(
                          children: [
                            Text(state.currentCurrencyInfo.flag, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              state.currentCurrencyInfo.code,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // User Profile Avatar
                    GestureDetector(
                      onTap: () => _openProfileModal(context, state),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF5722), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF1A233A),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Dev Mode Switcher Row
                if (state.isDevMode) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFFFF5722), size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'QUICK ROLE: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                        ),
                        const SizedBox(width: 6),
                        _roleChip('👤 Client', UserRole.client, state),
                        const SizedBox(width: 6),
                        _roleChip('🏋️ Coach', UserRole.coach, state),
                        const SizedBox(width: 6),
                        _roleChip('🥇 Head Coach', UserRole.headCoach, state),
                        const SizedBox(width: 6),
                        _roleChip('🏢 Gym Mgr', UserRole.gymMgr, state),
                        const SizedBox(width: 6),
                        _roleChip('🛡️ Admin', UserRole.superAdmin, state),
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
        UserRole.client => _buildClientView(state),
        UserRole.coach => _buildCoachView(state),
        UserRole.headCoach => _buildHeadCoachView(state),
        UserRole.gymMgr => _buildGymMgrView(state),
        UserRole.superAdmin => _buildAdminView(state),
      },
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0F19),
          border: Border(top: BorderSide(color: Color(0xFF1D263B), width: 1.2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFF5722),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _tabIndex = i),
          items: switch (user.role) {
            UserRole.client => const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Packages'),
              BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'AI Plan'),
            ],
            UserRole.coach => const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clients'),
              BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Exercises'),
            ],
            UserRole.headCoach => const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
              BottomNavigationBarItem(icon: Icon(Icons.account_tree_rounded), label: 'Squad Tree'),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Protocols'),
            ],
            UserRole.gymMgr => const [
              BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Floor'),
              BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Members'),
              BottomNavigationBarItem(icon: Icon(Icons.build_rounded), label: 'Equipment'),
            ],
            UserRole.superAdmin => const [
              BottomNavigationBarItem(icon: Icon(Icons.toggle_on_rounded), label: 'Flags'),
              BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: 'Accounts'),
              BottomNavigationBarItem(icon: Icon(Icons.dns_rounded), label: 'Telemetry'),
            ],
          },
        ),
      ),
    );
  }

  Widget _roleChip(String title, UserRole role, MyPtProvider state) {
    final isSelected = state.currentUser?.role == role;
    return GestureDetector(
      onTap: () {
        state.switchRole(role);
        setState(() => _tabIndex = 0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF182236),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF283652)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 6. CLIENT DASHBOARD (GHANI PRADITA AI BENTO GRID EXPLORATION)
  // ============================================================================
  Widget _buildClientView(MyPtProvider state) {
    if (_tabIndex == 1) return _packagesList(state);
    if (_tabIndex == 2) return _chartsView();

    final user = state.currentUser!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // AI Fitness Copilot Card (Paperpillar Hallmark)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF241B44),
                Color(0xFF171B32),
                Color(0xFF101424),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI FITNESS COPILOT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC084FC),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E599).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00E599).withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF00E599), size: 14),
                        SizedBox(width: 4),
                        Text('94% READINESS', style: TextStyle(color: Color(0xFF00E599), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Good morning, ${user.name.split(' ').first}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your recovery score is optimal today. Recommended daily target: 2,800 kcal (175g Protein). High-intensity hypertrophy session queued.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openAiAssistantModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1424),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Color(0xFFC084FC), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ask AI Coach anything (Nutrition, Form, Recovery)...',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Color(0xFFC084FC), size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title
        const Text(
          'Daily Health & Performance Vitals',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),

        // Bento Grid Metrics
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF5722),
                title: 'CALORIES BURNED',
                value: '2,450',
                unit: 'kcal',
                badge: '88% of goal',
                badgeColor: const Color(0xFFFF5722),
                progress: 0.88,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _bentoCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'HEART RATE ZONE',
                value: '124',
                unit: 'bpm',
                badge: 'Fat Burn Zone',
                badgeColor: const Color(0xFF38BDF8),
                progress: 0.72,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF00E599),
                title: 'HYDRATION',
                value: '2.6',
                unit: '/ 3.0 L',
                badge: '+250ml logged',
                badgeColor: const Color(0xFF00E599),
                progress: 0.86,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => _openWeightLogDialog(context, state),
                child: _bentoCard(
                  icon: Icons.monitor_weight_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'CURRENT WEIGHT',
                  value: '${user.currentWeight}',
                  unit: 'kg',
                  badge: '↓ ${(user.startingWeight - user.currentWeight).toStringAsFixed(1)} kg lost',
                  badgeColor: const Color(0xFFF59E0B),
                  progress: 0.65,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Today's Scheduled AI Workout Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF151D2F), Color(0xFF0F1523)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's AI Workout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('45 MINS • 6 EXERCISES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Upper Body Push & Core Hypertrophy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('Focus: Incline DB Press, Barbell OHP, Cable Flys, Cable Crunches', style: TextStyle(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      label: const Text('Start AI Guided Session', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: () => _openScheduleModal(context, state),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2B3854)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => setState(() => _tabIndex = 1),
                    child: const Text('Get Credits', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bentoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String badge,
    required Color badgeColor,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151D2F), Color(0xFF0F1523)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222D42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFF1E283E),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 7. COACH / TRAINER VIEW (LOGIC PRESERVED, PAPERPILLAR UI)
  // ============================================================================
  Widget _buildCoachView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildCoachClientsView(state);
    if (_tabIndex == 2) return _buildCoachLibraryView(state);

    final coach = state.currentUser!;
    final myClients = state.getClientsForTrainer(coach.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trainer Command Hub', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(coach.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00E599).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E599).withOpacity(0.3)),
              ),
              child: Text('${myClients.length} Active Trainees', style: const TextStyle(color: Color(0xFF00E599), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Summary Metric Bento
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFFFF5722),
                title: 'ASSIGNED CLIENTS',
                value: '${myClients.length}',
                unit: 'Trainees',
                badge: '100% Active',
                badgeColor: const Color(0xFFFF5722),
                progress: myClients.isEmpty ? 0.1 : (myClients.length / 10).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _bentoCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF00E599),
                title: 'MONTHLY EARNINGS',
                value: state.formatPrice(1450),
                unit: '',
                badge: '+18% vs Last Mo',
                badgeColor: const Color(0xFF00E599),
                progress: 0.78,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Confirmed Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFFF5722)),
              label: const Text('Schedule', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _openScheduleModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...state.sessions.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: Color(0xFFFF5722), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${DateFormat('dd MMM').format(s.date)} • ${s.timeSlot}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('Focus: ${s.focusArea}', style: const TextStyle(color: Color(0xFF00E599), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E599).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s.status.name.toUpperCase(), style: const TextStyle(color: Color(0xFF00E599), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachClientsView(MyPtProvider state) {
    final coach = state.currentUser!;
    final myClients = state.getClientsForTrainer(coach.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Assigned Trainees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Chip(
              label: Text('${myClients.length} Clients', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              backgroundColor: const Color(0xFF1E283D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (myClients.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_add_disabled_rounded, size: 48, color: Colors.white38),
                SizedBox(height: 12),
                Text('No Clients Assigned Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  'You currently have no active clients assigned under your roster. Book sessions or ask your Head Coach to assign trainees to you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...myClients.map(
            (client) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222D42)),
              ),
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
                            Text(client.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(client.email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E599).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${client.ptCredits} Credits', style: const TextStyle(color: Color(0xFF00E599), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFF222D42)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🎯 Goal: ${client.goal}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('⚖️ ${client.currentWeight} kg', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2B3854)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          label: const Text('+1 Credit', style: TextStyle(fontSize: 11)),
                          onPressed: () => state.addClientCredit(client),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openScheduleModal(context, state),
                          child: const Text('Book Session', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCoachLibraryView(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Movement Library Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Standardized exercise definitions for coaching & workout programs', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 14),
        ...state.movementLibrary.map(
          (m) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E283D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: Color(0xFFFF5722), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('${m.category} • ${m.equipment}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('Prescription: ${m.defaultSetsReps}', style: const TextStyle(color: Color(0xFF00E599), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(m.category.split('/').first.trim(), style: const TextStyle(color: Color(0xFFFF5722), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 8. HEAD COACH DASHBOARD (HIERARCHY: HEAD COACH -> TRAINER -> CLIENT)
  // ============================================================================
  Widget _buildHeadCoachView(MyPtProvider state) {
    final headCoach = state.currentUser!;
    final myTrainers = state.getTrainersForHeadCoach(headCoach.id);
    final myClients = state.getClientsForHeadCoach(headCoach.id);

    if (_tabIndex == 1) return _buildHeadCoachSquadView(state);
    if (_tabIndex == 2) return _buildHeadCoachProtocolsView();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Head Coach Command', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(headCoach.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('+ Recruit Trainer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _openRecruitTrainerModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Bento Stats
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFFFF5722),
                title: 'COACHING SQUAD',
                value: '${myTrainers.length}',
                unit: 'Trainers',
                badge: myTrainers.isEmpty ? 'Empty Squad' : 'Active Staff',
                badgeColor: const Color(0xFFFF5722),
                progress: myTrainers.isEmpty ? 0.0 : (myTrainers.length / 5).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _bentoCard(
                icon: Icons.assignment_ind_rounded,
                iconColor: const Color(0xFF00E599),
                title: 'TOTAL TRAINEES',
                value: '${myClients.length}',
                unit: 'Clients',
                badge: 'Under Squad',
                badgeColor: const Color(0xFF00E599),
                progress: myClients.isEmpty ? 0.0 : (myClients.length / 20).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (myTrainers.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 48, color: Color(0xFFFF5722)),
                const SizedBox(height: 14),
                const Text('Your Coaching Squad is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'As Head Coach, you oversee trainers who coach clients (Head Coach ➔ Trainer ➔ Client).\nRecruit certified trainers to your squad to start managing rosters and delegating clients.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Recruit First Trainer to Squad', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openRecruitTrainerModal(context, state),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Squad Staff Roster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _tabIndex = 1),
                      child: const Text('View Full Tree ➔', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFF222D42)),
                ...myTrainers.map(
                  (trainer) {
                    final trainerClients = state.getClientsForTrainer(trainer.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D121E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E283D)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFF5722).withOpacity(0.2),
                            child: Text(trainer.name[0], style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trainer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${trainerClients.length} Assigned Clients • ${trainer.email}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E283D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${trainerClients.length}/15 LOAD', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeadCoachSquadView(MyPtProvider state) {
    final headCoach = state.currentUser!;
    final myTrainers = state.getTrainersForHeadCoach(headCoach.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Squad Hierarchy Tree', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.person_add, size: 14),
              label: const Text('Recruit Coach', style: TextStyle(fontSize: 11)),
              onPressed: () => _openRecruitTrainerModal(context, state),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Head Coach ➔ Trainer / Coach ➔ Assigned Clients', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 14),
        if (myTrainers.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: const Column(
              children: [
                Icon(Icons.groups_outlined, size: 48, color: Colors.white38),
                SizedBox(height: 12),
                Text('No Trainers In Your Squad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Add trainers to start managing their rosters and client assignments.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )
        else
          ...myTrainers.map(
            (trainer) {
              final trainerClients = state.getClientsForTrainer(trainer.id);
              final loadRatio = (trainerClients.length / 15).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF222D42)),
                ),
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
                              Text('Trainer • ${trainer.email}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E283D),
                          ),
                          child: Text('${trainerClients.length} Trainees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _progressIndicator('Workload (${trainerClients.length}/15 Capacity)', loadRatio, loadRatio > 0.8 ? Colors.amber : const Color(0xFF00E599)),
                    const Divider(height: 24, color: Color(0xFF222D42)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D121E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Color(0xFF00E599)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('${c.goal} • ${c.currentWeight} kg', style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
              );
            },
          ),
      ],
    );
  }

  Widget _buildHeadCoachProtocolsView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Master Coaching Protocols', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋 Standard Operating Guidelines', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Divider(height: 20, color: Color(0xFF222D42)),
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
      ],
    );
  }

  // ============================================================================
  // 9. GYM MANAGER & SUPER ADMIN (LOGIC PRESERVED)
  // ============================================================================
  Widget _buildGymMgrView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildGymMgrMembersView(state);
    if (_tabIndex == 2) return _buildGymMgrFacilityView();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Facility Operations Hub', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(state.currentUser!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.meeting_room_rounded,
                iconColor: const Color(0xFFFF5722),
                title: 'FLOOR CAPACITY',
                value: '38',
                unit: '/ 100',
                badge: 'Safe Load (38%)',
                badgeColor: const Color(0xFFFF5722),
                progress: 0.38,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _bentoCard(
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF00E599),
                title: 'MONTHLY SALES',
                value: state.formatPrice(14820),
                unit: '',
                badge: '+18% vs Target',
                badgeColor: const Color(0xFF00E599),
                progress: 0.88,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gym Floor Real-Time Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Divider(height: 20, color: Color(0xFF222D42)),
              Text('• Free Weights Zone: 16 Members Active'),
              SizedBox(height: 6),
              Text('• Cardio Deck: 12 Members Active'),
              SizedBox(height: 6),
              Text('• PT Studio Room A: 4 Private Sessions Active'),
              SizedBox(height: 6),
              Text('• Facility Climate: 20.5°C (Optimized)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGymMgrMembersView(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Facility Member Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.rosterClients.map(
          (m) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge, color: Color(0xFFFF5722)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Active Pass • ${m.ptCredits} Sessions Booked', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E599).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('CHECKED IN', style: TextStyle(color: Color(0xFF00E599), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGymMgrFacilityView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Facility Equipment Audit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🛠️ Equipment Health Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Divider(height: 20, color: Color(0xFF222D42)),
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
      ],
    );
  }

  Widget _buildAdminView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildAdminAccountsView(state);
    if (_tabIndex == 2) return _buildAdminSystemView();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Governance & Feature Flags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.globalFlags.entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
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

  Widget _buildAdminAccountsView(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('User Accounts Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.demoAccounts.entries.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222D42)),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Color(0xFFFF5722)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${e.key} • Role: ${e.value.role.name}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2B3854))),
                  onPressed: () => state.switchUser(e.value),
                  child: const Text('Switch', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSystemView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('System Health Telemetry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚡ Real-time Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Divider(height: 20, color: Color(0xFF222D42)),
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
      ],
    );
  }

  // ============================================================================
  // 10. PACKAGES & CHECKOUT (WITH LOCALIZED CURRENCY)
  // ============================================================================
  Widget _packagesList(MyPtProvider state) {
    final cur = state.currentCurrencyInfo;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Region & Currency Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRICING REGION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
                    Text('${cur.flag} ${cur.name} (${cur.code})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF2B3854)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.currency_exchange, size: 14, color: Color(0xFFFF5722)),
                label: const Text('Change', style: TextStyle(fontSize: 11)),
                onPressed: () => _openCurrencySelector(context, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Training Packages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Balance: ${state.currentUser?.ptCredits ?? 0} Credits',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...state.packages.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: p.sessionsCount > 6 ? const Color(0xFFFF5722).withOpacity(0.5) : const Color(0xFF222D42),
                width: p.sessionsCount > 6 ? 1.5 : 1.0,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openPackageCheckoutModal(context, state, p),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.sessionsCount == 12)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🔥 MOST POPULAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    const Divider(height: 20, color: Color(0xFF222D42)),
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
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFF101524),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
            const Divider(color: Color(0xFF222D42)),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF222D42)),
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
            const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF151D2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF5722)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFFFF5722)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Instant Card Payment (•••• 4242)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  state.buyPackage(p);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF00E599),
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
      backgroundColor: const Color(0xFF101524),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Your Currency Region', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Prices automatically adapt to your selected country currency.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            ...MyPtProvider.supportedCurrencies.values.map(
              (cur) {
                final isSelected = state.selectedCurrency == cur.code;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Text(cur.flag, style: const TextStyle(fontSize: 24)),
                  title: Text('${cur.name} (${cur.code})', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFFF5722) : Colors.white)),
                  trailing: Text(cur.symbol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? const Color(0xFFFF5722) : Colors.white60)),
                  tileColor: isSelected ? const Color(0xFF1E283D) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _chartsView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Assigned Fitness Charts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151D2F), Color(0xFF0F1523)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phase 1: Hypertrophy & Fat Loss', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Assigned by Coach Alex Rivera', style: TextStyle(color: Color(0xFFFF5722), fontSize: 12)),
              Divider(height: 20, color: Color(0xFF222D42)),
              Text('🥗 Daily Targets: 1,950 kcal | 150g Protein | 190g Carbs | 55g Fat'),
              SizedBox(height: 10),
              Text('💪 Workout Split:\n• Mon: Upper Hypertrophy\n• Tue: Lower Quads\n• Thu: Push Strength\n• Fri: Pull & Core'),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 11. MODALS (RECRUIT TRAINER, ASSIGN CLIENT, AI ASSISTANT, PROFILE)
  // ============================================================================
  void _openAiAssistantModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101524),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Fitness Copilot Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Instant nutrition, form, and recovery insights', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFF222D42)),
            const Text('Suggested Prompts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _aiPromptChip('🥗 High-Protein Meal Plan'),
                _aiPromptChip('🏋️ Modify Workout for Shoulder Strain'),
                _aiPromptChip('⚡ Explain Readiness Score (94%)'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D121E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 14),
                      SizedBox(width: 6),
                      Text('AI Daily Analysis Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E599))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your training volume this week is 14% higher than average. Sleep duration was 8.2 hrs. Optimal for pushing hypertrophy sets today.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close AI Copilot', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiPromptChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E283D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
      backgroundColor: const Color(0xFF101524),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
              const SizedBox(height: 2),
              Text('Assign a trainer under Head Coach ${headCoach.name}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Divider(height: 20, color: Color(0xFF222D42)),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Trainer Full Name',
                  prefixIcon: Icon(Icons.fitness_center),
                  filled: true,
                  fillColor: Color(0xFF090D15),
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
                  fillColor: Color(0xFF090D15),
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
                        backgroundColor: const Color(0xFF00E599),
                        content: Text(
                          '🎉 Coach ${nameCtrl.text.trim()} recruited to your squad!',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
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
      backgroundColor: const Color(0xFF101524),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
              const Divider(height: 18, color: Color(0xFF222D42)),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Client Full Name',
                  prefixIcon: Icon(Icons.person),
                  filled: true,
                  fillColor: Color(0xFF090D15),
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
                  fillColor: Color(0xFF090D15),
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
                        fillColor: Color(0xFF090D15),
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
                        fillColor: Color(0xFF090D15),
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
                        backgroundColor: const Color(0xFF00E599),
                        content: Text(
                          '🎉 Client ${nameCtrl.text.trim()} assigned to ${trainer.name}!',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
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

  void _openWeightLogDialog(BuildContext context, MyPtProvider state) {
    final ctrl = TextEditingController(text: state.currentUser!.currentWeight.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151D2F),
        title: const Text('Log Today\'s Weight'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
        backgroundColor: const Color(0xFF151D2F),
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
                focus: 'Hypertrophy',
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openProfileModal(BuildContext context, MyPtProvider state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101524),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Color(0xFF1E283D), child: Icon(Icons.face, color: Color(0xFFFF5722), size: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.currentUser!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(state.currentUser!.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
            const Divider(height: 24, color: Color(0xFF222D42)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFFFF5722),
              title: const Text('Dev / Tester Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Toggle demo role switchers & tester shortcuts', style: TextStyle(fontSize: 11, color: Colors.white54)),
              value: state.isDevMode,
              onChanged: (val) {
                state.toggleDevMode();
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
    );
  }

  Widget _progressIndicator(String label, double value, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: const Color(0xFF1E283D),
            valueColor: AlwaysStoppedAnimation<Color>(col),
          ),
        ),
      ],
    );
  }
}
