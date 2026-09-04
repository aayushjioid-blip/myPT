import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ================= 1. ROLES & MODELS =================
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

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.currentWeight = 64.5,
    this.startingWeight = 68.0,
    this.ptCredits = 0,
    this.goal = 'Fat Loss & Hypertrophy',
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

// ================= 2. STATE PROVIDER WITH AUTH =================
class MyPtProvider extends ChangeNotifier {
  UserModel? currentUser; // Null when logged out
  bool isDevMode = !kReleaseMode;

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
      ptCredits: 0,
    ),
    'alex@mypt.com': UserModel(
      id: 'trn_alex',
      name: 'Alex Rivera',
      email: 'alex@mypt.com',
      role: UserRole.coach,
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
    ),
    'admin@mypt.com': UserModel(
      id: 'adm_root',
      name: 'Elena Admin',
      email: 'admin@mypt.com',
      role: UserRole.superAdmin,
    ),
  };

  List<UserModel> rosterClients = [
    UserModel(
      id: 'c1',
      name: 'Sarah Jenkins',
      email: 'sarah.j@mypt.com',
      role: UserRole.client,
      currentWeight: 64.5,
      ptCredits: 4,
      goal: 'Hypertrophy & Fat Loss',
    ),
    UserModel(
      id: 'c2',
      name: 'David Miller',
      email: 'david.m@mypt.com',
      role: UserRole.client,
      currentWeight: 82.0,
      ptCredits: 8,
      goal: 'Strength & Powerlifting',
    ),
    UserModel(
      id: 'c3',
      name: 'Priya Sharma',
      email: 'priya.s@mypt.com',
      role: UserRole.client,
      currentWeight: 58.2,
      ptCredits: 2,
      goal: 'Endurance & Core',
    ),
    UserModel(
      id: 'c4',
      name: 'Marcus Sterling',
      email: 'marcus.s@mypt.com',
      role: UserRole.client,
      currentWeight: 91.0,
      ptCredits: 6,
      goal: 'Body Recomposition',
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
      id: 'pkg_1',
      title: 'Starter Kickstarter',
      price: 199.0,
      sessionsCount: 4,
      durationWeeks: 4,
      perks: ['4 1-on-1 PT Sessions', 'Diet Macro Blueprint', 'App Progress Tracking'],
    ),
    TrainingPackage(
      id: 'pkg_2',
      title: 'Pro Transformation',
      price: 499.0,
      sessionsCount: 12,
      durationWeeks: 8,
      perks: [
        '12 1-on-1 Sessions',
        'Weekly Bodyfat Analysis',
        '24/7 Coach Chat Support',
        'Custom Supplement Protocol',
      ],
    ),
  ];

  final List<MovementItem> movementLibrary = [
    MovementItem(
      name: 'Barbell Bench Press',
      category: 'Chest',
      defaultSetsReps: '4 Sets × 8-10 Reps',
      equipment: 'Barbell & Bench',
    ),
    MovementItem(
      name: 'Incline Dumbbell Press',
      category: 'Chest',
      defaultSetsReps: '3 Sets × 12 Reps',
      equipment: 'Dumbbells',
    ),
    MovementItem(
      name: 'Barbell Deadlift',
      category: 'Back',
      defaultSetsReps: '4 Sets × 6 Reps',
      equipment: 'Barbell & Plates',
    ),
    MovementItem(
      name: 'Lat Pulldown',
      category: 'Back',
      defaultSetsReps: '4 Sets × 10-12 Reps',
      equipment: 'Cable Pulldown',
    ),
    MovementItem(
      name: 'Barbell Back Squat',
      category: 'Legs',
      defaultSetsReps: '4 Sets × 8 Reps',
      equipment: 'Squat Rack',
    ),
    MovementItem(
      name: 'Standing Overhead Press',
      category: 'Shoulders',
      defaultSetsReps: '4 Sets × 8 Reps',
      equipment: 'Barbell',
    ),
    MovementItem(
      name: 'Incline Bicep Curls',
      category: 'Arms',
      defaultSetsReps: '3 Sets × 12 Reps',
      equipment: 'Dumbbells',
    ),
    MovementItem(
      name: 'Hanging Leg Raises',
      category: 'Core',
      defaultSetsReps: '3 Sets × 15 Reps',
      equipment: 'Pull-up Bar',
    ),
  ];

  Map<String, bool> globalFlags = {
    'Client Direct Booking': true,
    'Trainer Custom Pricing': true,
    'Realtime In-App Chat': true,
    'Direct Card Payments': true,
    'Beta AI Workout Generator': false,
    'Maintenance Mode': false,
  };

  // --- AUTH METHODS ---
  bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    if (demoAccounts.containsKey(cleanEmail)) {
      currentUser = demoAccounts[cleanEmail];
      notifyListeners();
      return true;
    }
    // Generic login fallback
    currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      email: email,
      role: UserRole.client,
    );
    notifyListeners();
    return true;
  }

  void register({required String name, required String email, required UserRole role}) {
    currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
    );
    demoAccounts[email.toLowerCase()] = currentUser!;
    notifyListeners();
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

// ================= 3. MAIN APP & NAVIGATION ROOT =================
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
          ),
        ),
      ),
      home: state.currentUser == null ? const AuthScreen() : const MainShellScreen(),
    );
  }
}

// ================= 4. AUTH SCREEN (SIGN IN / SIGN UP) =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignUp = false;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Logo & Title
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isSignUp ? 'Create your account' : 'Welcome back to myPT',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                isSignUp
                    ? 'Start your fitness journey today.'
                    : 'Sign in to access your dashboard.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // 1-TAP DEMO LOGINS PANEL (Dev Mode Only)
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _demoButton('👤 Client (Sarah)', 'sarah@mypt.com', 'client123', state),
                          _demoButton('🏋️ Coach (Alex)', 'alex@mypt.com', 'coach123', state),
                          _demoButton('🥇 Head Coach', 'marcus@mypt.com', 'head123', state),
                          _demoButton('🏢 Gym Mgr', 'elena@mypt.com', 'manager123', state),
                          _demoButton('🛡️ Super Admin', 'admin@mypt.com', 'admin123', state),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Form Inputs
              if (isSignUp) ...[
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: Color(0xFF161B22),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Account Role',
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
                const SizedBox(height: 12),
              ],
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: Color(0xFF161B22),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Color(0xFF161B22),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (isSignUp) {
                      state.register(
                        name: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'New User',
                        email: emailCtrl.text,
                        role: selectedRole,
                      );
                    } else {
                      state.login(emailCtrl.text, passCtrl.text);
                    }
                  },
                  child: Text(
                    isSignUp ? 'Sign Up' : 'Sign In',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Sign In / Sign Up
              Center(
                child: TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(
                    isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                    style: const TextStyle(color: Color(0xFFFF5722)),
                  ),
                ),
              ),
            ],
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

// ================= 5. MAIN SHELL (AFTER AUTH) =================
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (!state.isDevMode) ...[
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
                          'ROLE: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _chip('Client (Sarah)', UserRole.client, state),
                        const SizedBox(width: 6),
                        _chip('Coach (Alex)', UserRole.coach, state),
                        const SizedBox(width: 6),
                        _chip('Head Coach', UserRole.headCoach, state),
                        const SizedBox(width: 6),
                        _chip('Gym Mgr', UserRole.gymMgr, state),
                        const SizedBox(width: 6),
                        _chip('Super Admin', UserRole.superAdmin, state),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        backgroundColor: const Color(0xFF0D1117),
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _tabIndex = i),
        items: switch (user.role) {
          UserRole.client => const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Packages'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Charts'),
          ],
          UserRole.coach => const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Library'),
          ],
          UserRole.headCoach => const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Squad'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Protocols'),
          ],
          UserRole.gymMgr => const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Members'),
            BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Facility'),
          ],
          UserRole.superAdmin => const [
            BottomNavigationBarItem(icon: Icon(Icons.toggle_on), label: 'Flags'),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Accounts'),
            BottomNavigationBarItem(icon: Icon(Icons.dns), label: 'System'),
          ],
        },
      ),
    );
  }

  Widget _chip(String title, UserRole role, MyPtProvider state) {
    final sel = state.currentUser?.role == role;
    return GestureDetector(
      onTap: () {
        state.switchRole(role);
        setState(() => _tabIndex = 0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF5722) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFFFF5722) : Colors.white12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            color: sel ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ================= 6. CLIENT VIEWS (3 TABS) =================
  Widget _buildClientView(MyPtProvider state) {
    if (_tabIndex == 1) return _packagesList(state);
    if (_tabIndex == 2) return _chartsView();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Welcome Back,', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(state.currentUser!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 1),
                child: _statCard(
                  'REMAINING CREDITS',
                  '${state.currentUser!.ptCredits} PT Sessions',
                  'Tap to select pack',
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
                  '${state.currentUser!.currentWeight} kg',
                  '↓ ${(state.currentUser!.startingWeight - state.currentUser!.currentWeight).toStringAsFixed(1)} kg lost',
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
              const Text(
                'Start Your Training Journey',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore verified coaches and book a session.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _openScheduleModal(context, state),
                  child: const Text('Discover Coaches 🚀', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= 7. COACH VIEWS (3 TABS) =================
  Widget _buildCoachView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildCoachClientsView(state);
    if (_tabIndex == 2) return _buildCoachLibraryView(state);

    // Tab 0: Coach Overview
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Trainer Command Center', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(state.currentUser!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'ACTIVE CLIENTS',
                '${state.rosterClients.length}',
                '100% attendance',
                const Color(0xFFFF5722),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard('MONTHLY REV', '\$1,398', '+14% growth', const Color(0xFF00E676)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard('ACTIVE PACKS', '${state.packages.length}', 'Manage tiers', const Color(0xFF29B6F6)),
            ),
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
              subtitle: Text(
                '${DateFormat('dd MMM').format(s.date)} at ${s.timeSlot}\nFocus: ${s.focusArea}',
              ),
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

  // Coach Tab 1: Clients Roster
  Widget _buildCoachClientsView(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Client Roster', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Chip(
              label: Text('${state.rosterClients.length} Trainees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              backgroundColor: const Color(0xFF21262D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.rosterClients.map(
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

  // Coach Tab 2: Movement Library
  Widget _buildCoachLibraryView(MyPtProvider state) {
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
                label: Text(m.category),
                backgroundColor: const Color(0xFF2A150D),
                labelStyle: const TextStyle(fontSize: 10, color: Color(0xFFFF5722)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= 8. HEAD COACH VIEWS (3 TABS) =================
  Widget _buildHeadCoachView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildHeadCoachSquadView(state);
    if (_tabIndex == 2) return _buildHeadCoachProtocolsView();

    // Tab 0: Head Coach Overview
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Head Coach Command', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(state.currentUser!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('COACH SQUAD', '4 Coaches', '100% On-Duty', const Color(0xFFFF5722))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('TOTAL TRAINEES', '38 Clients', '+6 this week', const Color(0xFF00E676))),
            const SizedBox(width: 8),
            Expanded(child: _statCard('AVG RETENTION', '94.2%', 'Tier 1 Target', const Color(0xFF29B6F6))),
          ],
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coaching Squad Roster & Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Color(0xFF21262D), child: Text('AR', style: TextStyle(color: Color(0xFFFF5722)))),
                  title: Text('Alex Rivera (Senior Coach)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('12 Active Clients • 98% Satisfaction'),
                  trailing: Chip(label: Text('ACTIVE'), backgroundColor: Color(0xFF00E676)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Color(0xFF21262D), child: Text('ER', style: TextStyle(color: Color(0xFFFF5722)))),
                  title: Text('Elena Rostova (Coach)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('9 Active Clients • 95% Satisfaction'),
                  trailing: Chip(label: Text('ACTIVE'), backgroundColor: Color(0xFF00E676)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Head Coach Tab 1: Squad Breakdown
  Widget _buildHeadCoachSquadView(MyPtProvider state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Squad Management & Coach Workloads', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trainer Workload Capacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _progressBar('Coach Alex Rivera (12/15 Capacity)', 0.8, const Color(0xFFFF5722)),
                const SizedBox(height: 12),
                _progressBar('Coach Elena Rostova (9/15 Capacity)', 0.6, const Color(0xFF00E676)),
                const SizedBox(height: 12),
                _progressBar('Coach Priya Sharma (6/15 Capacity)', 0.4, const Color(0xFF29B6F6)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Head Coach Tab 2: Protocols & Curriculum
  Widget _buildHeadCoachProtocolsView() {
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

  // ================= 9. GYM MANAGER VIEWS (3 TABS) =================
  Widget _buildGymMgrView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildGymMgrMembersView(state);
    if (_tabIndex == 2) return _buildGymMgrFacilityView();

    // Tab 0: Gym Mgr Overview
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
            Expanded(child: _statCard('MONTHLY SALES', '\$14,820', '+18% vs Target', const Color(0xFF00E676))),
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

  // Gym Mgr Tab 1: Members
  Widget _buildGymMgrMembersView(MyPtProvider state) {
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

  // Gym Mgr Tab 2: Facility
  Widget _buildGymMgrFacilityView() {
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

  // ================= 10. SUPER ADMIN VIEWS (3 TABS) =================
  Widget _buildAdminView(MyPtProvider state) {
    if (_tabIndex == 1) return _buildAdminAccountsView(state);
    if (_tabIndex == 2) return _buildAdminSystemView();

    // Tab 0: Feature Flags
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

  // Super Admin Tab 1: Accounts & Roles
  Widget _buildAdminAccountsView(MyPtProvider state) {
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

  // Super Admin Tab 2: System Health
  Widget _buildAdminSystemView() {
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

  // ================= 11. SUB-WIDGETS & MODALS =================
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Available Packages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.packages.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '\$${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${p.sessionsCount} Sessions • ${p.durationWeeks} Weeks',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => state.buyPackage(p),
                    child: Text('Purchase Package (+${p.sessionsCount} Credits)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartsView() {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
            ),
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Color(0xFF21262D), child: Icon(Icons.face, color: Color(0xFFFF5722), size: 26)),
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
            const Divider(height: 24),
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
            const SizedBox(height: 12),
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
    );
  }
}
