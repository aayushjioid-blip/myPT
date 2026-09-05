import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/session_entity.dart';
import '../../../domain/entities/workout_entity.dart';
import '../../../domain/entities/exercise_entity.dart';
import '../../../domain/entities/exercise_catalog.dart';
import '../../../domain/repositories/i_workout_repository.dart';
import '../presentation/workout_view_model.dart';

class SetRowItem {
  final int setNumber;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;

  SetRowItem({
    required this.setNumber,
    double initialWeight = 60.0,
    int initialReps = 10,
  })  : weightCtrl = TextEditingController(text: initialWeight % 1 == 0 ? initialWeight.toInt().toString() : initialWeight.toString()),
        repsCtrl = TextEditingController(text: initialReps.toString());

  double get weightKg => double.tryParse(weightCtrl.text) ?? 0.0;
  int get reps => int.tryParse(repsCtrl.text) ?? 10;
  double get volumeKg => weightKg * reps;

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

class PreviousExerciseStats {
  final double volumeKg;
  final int reps;
  final String sessionDateLabel;
  final bool hasPreviousSession;

  const PreviousExerciseStats({
    required this.volumeKg,
    required this.reps,
    required this.sessionDateLabel,
    required this.hasPreviousSession,
  });
}

class LiveWorkoutLoggerDialog extends StatefulWidget {
  final SessionEntity session;
  final String clientName;

  const LiveWorkoutLoggerDialog({
    super.key,
    required this.session,
    this.clientName = 'Sarah Jenkins',
  });

  @override
  State<LiveWorkoutLoggerDialog> createState() => _LiveWorkoutLoggerDialogState();
}

class _LiveWorkoutLoggerDialogState extends State<LiveWorkoutLoggerDialog> {
  late List<WorkoutExerciseItem> _exercises;
  late List<ExerciseEntity> _allExercises;
  List<WorkoutEntity> _clientPastWorkouts = [];

  // Exercise Builder State: Muscle ➔ Exercise ➔ Sets & Reps
  ExerciseCategory _selectedCategory = ExerciseCategory.chest;
  ExerciseEntity? _selectedExercise;
  final TextEditingController _customExerciseCtrl = TextEditingController();

  // Dynamic Per-Set List
  final List<SetRowItem> _sets = [];

  final Map<ExerciseCategory, String> _categoryEmojis = {
    ExerciseCategory.chest: '🏋️',
    ExerciseCategory.back: '🚣',
    ExerciseCategory.legs: '🦵',
    ExerciseCategory.shoulders: '🥥',
    ExerciseCategory.biceps: '💪',
    ExerciseCategory.triceps: '⚡',
    ExerciseCategory.core: '🧘',
    ExerciseCategory.glutes: '🍑',
    ExerciseCategory.forearms: '🥋',
    ExerciseCategory.calves: '🏃',
    ExerciseCategory.hips: '🤸',
    ExerciseCategory.fullBody: '🔥',
  };

  @override
  void initState() {
    super.initState();
    // Default current in-progress workout items
    _exercises = [
      const WorkoutExerciseItem(
        id: 'we-1',
        exerciseId: 'ex-chest-1',
        name: 'Flat Barbell Bench Press',
        sets: 3,
        repetitions: 10,
        weightKg: 60,
        setDetails: [
          WorkoutSetDetail(setNumber: 1, reps: 10, weightKg: 60),
          WorkoutSetDetail(setNumber: 2, reps: 10, weightKg: 60),
          WorkoutSetDetail(setNumber: 3, reps: 10, weightKg: 60),
        ],
      ),
      const WorkoutExerciseItem(
        id: 'we-2',
        exerciseId: 'ex-back-2',
        name: 'Lat Pulldown',
        sets: 3,
        repetitions: 12,
        weightKg: 50,
        setDetails: [
          WorkoutSetDetail(setNumber: 1, reps: 12, weightKg: 50),
          WorkoutSetDetail(setNumber: 2, reps: 12, weightKg: 50),
          WorkoutSetDetail(setNumber: 3, reps: 12, weightKg: 50),
        ],
      ),
      const WorkoutExerciseItem(
        id: 'we-3',
        exerciseId: 'ex-sh-3',
        name: 'Dumbbell Lateral Raise',
        sets: 3,
        repetitions: 15,
        weightKg: 10,
        setDetails: [
          WorkoutSetDetail(setNumber: 1, reps: 15, weightKg: 10),
          WorkoutSetDetail(setNumber: 2, reps: 15, weightKg: 10),
          WorkoutSetDetail(setNumber: 3, reps: 15, weightKg: 10),
        ],
      ),
      const WorkoutExerciseItem(
        id: 'we-4',
        exerciseId: 'ex-tri-1',
        name: 'Triceps Rope Pushdown',
        sets: 3,
        repetitions: 12,
        weightKg: 25,
        setDetails: [
          WorkoutSetDetail(setNumber: 1, reps: 12, weightKg: 25),
          WorkoutSetDetail(setNumber: 2, reps: 12, weightKg: 25),
          WorkoutSetDetail(setNumber: 3, reps: 12, weightKg: 25),
        ],
      ),
    ];

    // Seed catalog
    _allExercises = List.from(ExerciseCatalog.defaultExercises);
    final initialMatching = _allExercises.where((e) => e.category == _selectedCategory).toList();
    if (initialMatching.isNotEmpty) {
      _selectedExercise = initialMatching.first;
    }

    _initDefaultSets();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initDefaultSets() {
    _sets.clear();
    _sets.add(SetRowItem(setNumber: 1, initialWeight: 60.0, initialReps: 10));
    _sets.add(SetRowItem(setNumber: 2, initialWeight: 60.0, initialReps: 10));
    _sets.add(SetRowItem(setNumber: 3, initialWeight: 60.0, initialReps: 10));
  }

  void _addSetRow() {
    setState(() {
      final lastSet = _sets.isNotEmpty ? _sets.last : null;
      final nextNum = _sets.length + 1;
      final weight = lastSet != null ? lastSet.weightKg : 60.0;
      final reps = lastSet != null ? lastSet.reps : 10;
      _sets.add(SetRowItem(setNumber: nextNum, initialWeight: weight, initialReps: reps));
    });
  }

  void _removeSetRow(int index) {
    if (_sets.length <= 1) return;
    setState(() {
      _sets[index].dispose();
      _sets.removeAt(index);
    });
  }

  void _applyPresetWeightToAll(double weight) {
    setState(() {
      for (final s in _sets) {
        s.weightCtrl.text = weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
      }
    });
  }

  double get _currentExerciseVolume {
    double total = 0;
    for (final s in _sets) {
      total += s.volumeKg;
    }
    return total;
  }

  int get _currentExerciseReps {
    int total = 0;
    for (final s in _sets) {
      total += s.reps;
    }
    return total;
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<IWorkoutRepository>();
      final list = await repo.getAllExercises();
      final past = await repo.getWorkoutsForClient(widget.session.clientId);

      // Sort client's past completed workouts from most recent to oldest
      past.sort((a, b) {
        final aDate = a.completedAt ?? a.assignedDate;
        final bDate = b.completedAt ?? b.assignedDate;
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _clientPastWorkouts = past;
          if (list.isNotEmpty) {
            _allExercises = list;
            final matching = list.where((e) => e.category == _selectedCategory).toList();
            if (matching.isNotEmpty && (_selectedExercise == null || !_allExercises.contains(_selectedExercise))) {
              _selectedExercise = matching.first;
            }
          }
        });
      }
    } catch (_) {}
  }

  // DYNAMIC LOOKUP: Strictly searches the client's immediately preceding completed workout
  PreviousExerciseStats _getPreviousExerciseStats(String exerciseName) {
    // 1. Search client's past completed workouts (sorted newest to oldest)
    for (final workout in _clientPastWorkouts) {
      if (workout.status == WorkoutStatus.completed && workout.exercises.isNotEmpty) {
        for (final ex in workout.exercises) {
          if (_isExerciseMatch(ex.name, exerciseName)) {
            final vol = _getExerciseItemVolume(ex);
            final reps = _getExerciseItemReps(ex);
            if (vol > 0) {
              final date = workout.completedAt ?? workout.assignedDate;
              final dateStr = '${date.month}/${date.day}';
              return PreviousExerciseStats(
                volumeKg: vol,
                reps: reps,
                sessionDateLabel: dateStr,
                hasPreviousSession: true,
              );
            }
          }
        }
      }
    }

    // 2. Default baseline if this is the client's first time performing this exercise
    final defVol = _getDefaultHistoricalVolume(exerciseName);
    return PreviousExerciseStats(
      volumeKg: defVol,
      reps: 30,
      sessionDateLabel: 'last session',
      hasPreviousSession: false,
    );
  }

  bool _isExerciseMatch(String nameA, String nameB) {
    final a = nameA.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final b = nameB.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (a == b) return true;
    if (a.contains('bench') && b.contains('bench')) return true;
    if (a.contains('latpull') && b.contains('latpull')) return true;
    if (a.contains('lateral') && b.contains('lateral')) return true;
    if (a.contains('tricep') && b.contains('tricep')) return true;
    if (a.contains('squat') && b.contains('squat')) return true;
    if (a.contains('deadlift') && b.contains('deadlift')) return true;
    return a.contains(b) || b.contains(a);
  }

  double _getDefaultHistoricalVolume(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('bench')) return 1650.0; // 3x10 @ 55kg
    if (lower.contains('lat pulldown') || lower.contains('pulldown')) return 1440.0; // 3x12 @ 40kg
    if (lower.contains('lateral raise') || lower.contains('lateral')) return 360.0; // 3x12 @ 10kg
    if (lower.contains('tricep') || lower.contains('rope')) return 720.0; // 3x12 @ 20kg
    if (lower.contains('squat')) return 1080.0;
    if (lower.contains('deadlift')) return 1800.0;
    if (lower.contains('row')) return 1350.0;
    if (lower.contains('curl')) return 360.0;
    if (lower.contains('press')) return 1200.0;
    return 1000.0;
  }

  double _getExerciseItemVolume(WorkoutExerciseItem ex) {
    if (ex.setDetails != null && ex.setDetails!.isNotEmpty) {
      return ex.setDetails!.fold<double>(0.0, (sum, s) => sum + (s.weightKg * s.reps));
    }
    return ex.sets * ex.repetitions * ex.weightKg;
  }

  int _getExerciseItemReps(WorkoutExerciseItem ex) {
    if (ex.setDetails != null && ex.setDetails!.isNotEmpty) {
      return ex.setDetails!.fold<int>(0, (sum, s) => sum + s.reps);
    }
    return ex.sets * ex.repetitions;
  }

  double get _totalSessionVolume {
    double total = 0;
    for (final ex in _exercises) {
      total += _getExerciseItemVolume(ex);
    }
    return total;
  }

  void _onCategoryChanged(ExerciseCategory cat) {
    setState(() {
      _selectedCategory = cat;
      final matching = _allExercises.where((e) => e.category == cat).toList();
      _selectedExercise = matching.isNotEmpty ? matching.first : null;
      _customExerciseCtrl.clear();
    });
  }

  void _addCurrentExerciseToSession() {
    final exerciseName = _customExerciseCtrl.text.trim().isNotEmpty
        ? _customExerciseCtrl.text.trim()
        : (_selectedExercise?.name ?? 'Custom Exercise');

    final exerciseId = _selectedExercise?.id ?? 'ex-custom-${DateTime.now().millisecondsSinceEpoch}';

    final setDetails = _sets.asMap().entries.map((entry) {
      final idx = entry.key;
      final setItem = entry.value;
      return WorkoutSetDetail(
        setNumber: idx + 1,
        reps: setItem.reps,
        weightKg: setItem.weightKg,
      );
    }).toList();

    final newItem = WorkoutExerciseItem(
      id: 'we-${DateTime.now().millisecondsSinceEpoch}',
      exerciseId: exerciseId,
      name: exerciseName,
      sets: _sets.length,
      repetitions: _sets.isNotEmpty ? _sets.first.reps : 10,
      weightKg: _sets.isNotEmpty ? _sets.first.weightKg : 60.0,
      setDetails: setDetails,
    );

    final addedVol = _currentExerciseVolume;

    setState(() {
      _exercises.add(newItem);
      _customExerciseCtrl.clear();
      _initDefaultSets();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Added $exerciseName (${_sets.length} Sets • ${addedVol.toStringAsFixed(0)} kg Total Volume)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _addSetToLoggedExercise(int exerciseIndex) {
    setState(() {
      final ex = _exercises[exerciseIndex];
      final currentDetails = ex.setDetails != null ? List<WorkoutSetDetail>.from(ex.setDetails!) : <WorkoutSetDetail>[];
      final lastSet = currentDetails.isNotEmpty ? currentDetails.last : null;
      final nextNum = currentDetails.length + 1;
      final newSet = WorkoutSetDetail(
        setNumber: nextNum,
        reps: lastSet?.reps ?? ex.repetitions,
        weightKg: lastSet?.weightKg ?? ex.weightKg,
      );
      currentDetails.add(newSet);

      _exercises[exerciseIndex] = ex.copyWith(
        sets: currentDetails.length,
        setDetails: currentDetails,
      );
    });
  }

  void _removeSetFromLoggedExercise(int exerciseIndex, int setIndex) {
    setState(() {
      final ex = _exercises[exerciseIndex];
      final currentDetails = ex.setDetails != null ? List<WorkoutSetDetail>.from(ex.setDetails!) : <WorkoutSetDetail>[];
      if (currentDetails.length > 1 && setIndex < currentDetails.length) {
        currentDetails.removeAt(setIndex);
        for (int i = 0; i < currentDetails.length; i++) {
          currentDetails[i] = currentDetails[i].copyWith(setNumber: i + 1);
        }
        _exercises[exerciseIndex] = ex.copyWith(
          sets: currentDetails.length,
          setDetails: currentDetails,
        );
      }
    });
  }

  // WIDGET: PER-EXERCISE VOLUME & PROGRESSIVE OVERLOAD CARD (SUMPRODUCT)
  Widget _buildExerciseVolumeCard({
    required BuildContext context,
    required String exerciseName,
    required double currentVolume,
    required int totalReps,
    bool isPreview = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _getPreviousExerciseStats(exerciseName);
    final previousVolume = stats.volumeKg;
    final volDelta = currentVolume - previousVolume;
    final volPercent = previousVolume > 0 ? (volDelta / previousVolume) * 100 : 0.0;
    final isProgressiveOverload = volDelta >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181F) : const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProgressiveOverload ? AppColors.accentGreen.withOpacity(0.5) : AppColors.amber.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isProgressiveOverload ? Icons.trending_up : Icons.trending_flat,
                    color: isProgressiveOverload ? AppColors.accentGreen : AppColors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPreview ? 'EXERCISE VOLUME & OVERLOAD (PREVIEW)' : 'EXERCISE VOLUME & OVERLOAD',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
              StatusBadge(
                text: isProgressiveOverload ? 'Overload Achieved 🚀' : 'Baseline Matched',
                type: isProgressiveOverload ? BadgeType.primary : BadgeType.amber,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Big 3-Column Metric Display: Total Lifted (Sumproduct) | Total Reps | Vs Previous Session
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total Lifted (Sumproduct)', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text(
                    '${currentVolume.toStringAsFixed(0)} kg',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: AppColors.darkBorder),
              Column(
                children: [
                  const Text('Total Reps', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReps',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: AppColors.darkBorder),
              Column(
                children: [
                  const Text('Vs Previous Session', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text(
                    '${volDelta >= 0 ? '+' : ''}${volDelta.toStringAsFixed(0)} kg (${volPercent >= 0 ? '+' : ''}${volPercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isProgressiveOverload ? AppColors.accentGreen : AppColors.rose,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),

          Text(
            isProgressiveOverload
                ? '📈 Progressive Overload: ${widget.clientName.split(' ').first} lifted ${volDelta.toStringAsFixed(0)} kg more on $exerciseName today compared to the previous session on ${stats.sessionDateLabel} (${previousVolume.toStringAsFixed(0)} kg ➔ ${currentVolume.toStringAsFixed(0)} kg).'
                : 'ℹ️ Exercise Baseline: Lifted ${currentVolume.toStringAsFixed(0)} kg on $exerciseName today (${volDelta.toStringAsFixed(0)} kg vs previous session of ${previousVolume.toStringAsFixed(0)} kg). Aim for ${(previousVolume + 50).toStringAsFixed(0)} kg in the next session to achieve progressive overload.',
            style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted, height: 1.3),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _sets) {
      s.dispose();
    }
    _customExerciseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutVM = context.read<WorkoutViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryName = ExerciseEntity.getCategoryName(_selectedCategory);
    final categoryEmoji = _categoryEmojis[_selectedCategory] ?? '🏋️';
    final categoryExercises = _allExercises.where((e) => e.category == _selectedCategory).toList();

    final activeBuilderExerciseName = _customExerciseCtrl.text.trim().isNotEmpty
        ? _customExerciseCtrl.text.trim()
        : (_selectedExercise?.name ?? 'Exercise');

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Live Workout: ${widget.clientName}', style: AppTypography.heading3),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Session Status Header Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SESSION IN PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const Text('Upper Body Hypertrophy Focus • 1-on-1 PT Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '${_exercises.length} Exercises Logged • ${_totalSessionVolume.toStringAsFixed(0)} kg Total Tonnage',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // INTERACTIVE EXERCISE & PER-SET BUILDER (Weights first, then Reps + Sumproduct calculation)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191C24) : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Add Exercise to Workout', style: AppTypography.heading3),
                        ],
                      ),
                      StatusBadge(text: 'Live Builder', type: BadgeType.primary),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // STEP 1: SELECT MUSCLE CATEGORY
                  const Text('1. SELECT TARGET MUSCLE GROUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ExerciseCategory.values.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        final emoji = _categoryEmojis[cat] ?? '🏋️';
                        final name = ExerciseEntity.getCategoryName(cat);

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('$emoji $name', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.25),
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.darkBorder, width: isSelected ? 1.5 : 1),
                            onSelected: (_) => _onCategoryChanged(cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // STEP 2: SELECT EXERCISE NAME (COMMON WORKOUTS FOR SELECTED MUSCLE)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2. SELECT EXERCISE ($categoryEmoji ${categoryName.toUpperCase()})',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        '${categoryExercises.length} common workouts',
                        style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: categoryExercises.map((ex) {
                      final isChosen = _selectedExercise?.id == ex.id && _customExerciseCtrl.text.isEmpty;
                      return ChoiceChip(
                        avatar: isChosen ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        label: Text(ex.name, style: TextStyle(fontSize: 11, fontWeight: isChosen ? FontWeight.bold : FontWeight.normal)),
                        selected: isChosen,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isChosen ? Colors.white : null),
                        side: BorderSide(color: isChosen ? AppColors.primary : AppColors.darkBorder),
                        onSelected: (val) {
                          setState(() {
                            _selectedExercise = ex;
                            _customExerciseCtrl.clear();
                          });
                        },
                      );
                    }).toList(),
                  ),

                  if (_selectedExercise != null && _customExerciseCtrl.text.isEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Target: ${_selectedExercise!.target} • ${_selectedExercise!.equipment}',
                              style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Custom exercise name textfield override
                  CustomTextField(
                    label: 'Or Custom Exercise Name',
                    controller: _customExerciseCtrl,
                    hint: 'e.g. Incline Smith Press, Landmine Press',
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // STEP 3: CONFIGURE PER-SET DETAILS (WEIGHT FIRST, THEN REPS)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('3. LOG PER-SET WEIGHT & REPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_sets.length} Sets Total',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sets Table Header: SET | WEIGHT (KG) | REPETITIONS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 50, child: Text('SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted))),
                        Expanded(child: Text('WEIGHT (KG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted))),
                        SizedBox(width: 8),
                        Expanded(child: Text('REPETITIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted))),
                        SizedBox(width: 32),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Dynamic Set Rows: SET | WEIGHT (KG) | REPETITIONS
                  ..._sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final setItem = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkInput : AppColors.lightInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            // Set # Badge
                            SizedBox(
                              width: 50,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Set ${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // WEIGHT (KG) FIELD (FIRST)
                            Expanded(
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        final current = setItem.weightKg;
                                        if (current >= 2.5) {
                                          final next = current - 2.5;
                                          setItem.weightCtrl.text = next % 1 == 0 ? next.toInt().toString() : next.toString();
                                          setState(() {});
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.remove, size: 16, color: AppColors.primary),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: setItem.weightCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          suffixText: 'kg',
                                          suffixStyle: TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final current = setItem.weightKg;
                                        final next = current + 2.5;
                                        setItem.weightCtrl.text = next % 1 == 0 ? next.toInt().toString() : next.toString();
                                        setState(() {});
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.add, size: 16, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // REPETITIONS FIELD (SECOND)
                            Expanded(
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        final current = setItem.reps;
                                        if (current > 1) {
                                          setItem.repsCtrl.text = (current - 1).toString();
                                          setState(() {});
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.remove, size: 16, color: AppColors.primary),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: setItem.repsCtrl,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final current = setItem.reps;
                                        setItem.repsCtrl.text = (current + 1).toString();
                                        setState(() {});
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.add, size: 16, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Delete Set Button
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.rose),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: _sets.length > 1 ? () => _removeSetRow(index) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // "+ Add Set" button and quick weight presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _addSetRow,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('+ Add Another Set', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),

                      // Quick preset pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [0.0, 20.0, 40.0, 60.0, 80.0, 100.0].map((w) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: InkWell(
                                onTap: () => _applyPresetWeightToAll(w),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  child: Text(
                                    w == 0 ? 'BW' : '${w.toInt()}k',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // LIVE EXERCISE VOLUME & OVERLOAD PREVIEW CARD (FOR CURRENTLY CONFIGURED EXERCISE)
                  _buildExerciseVolumeCard(
                    context: context,
                    exerciseName: activeBuilderExerciseName,
                    currentVolume: _currentExerciseVolume,
                    totalReps: _currentExerciseReps,
                    isPreview: true,
                  ),

                  const SizedBox(height: 14),

                  // STEP 4: ADD BUTTON WITH SUMPRODUCT PREVIEW
                  CustomButton(
                    text: '+ Add $activeBuilderExerciseName (${_currentExerciseVolume.toStringAsFixed(0)} kg Volume) ✓',
                    isFullWidth: true,
                    height: 44,
                    onPressed: _addCurrentExerciseToSession,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LOGGED EXERCISES LIST HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Logged Exercises & Sets', style: AppTypography.heading2),
                StatusBadge(text: '${_exercises.length} Exercises', type: BadgeType.primary),
              ],
            ),
            const SizedBox(height: 8),

            if (_exercises.isEmpty)
              FitnessCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: const [
                        Icon(Icons.fitness_center_outlined, size: 32, color: AppColors.darkTextMuted),
                        SizedBox(height: 8),
                        Text('No exercises added yet.', style: TextStyle(color: AppColors.darkTextMuted, fontWeight: FontWeight.bold)),
                        Text('Use the builder panel above to select muscle, exercise, weights & reps.', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._exercises.asMap().entries.map((entry) {
                final idx = entry.key;
                final ex = entry.value;
                final details = ex.setDetails ?? List.generate(ex.sets, (i) => WorkoutSetDetail(setNumber: i + 1, reps: ex.repetitions, weightKg: ex.weightKg));
                final exVolume = _getExerciseItemVolume(ex);
                final exReps = _getExerciseItemReps(ex);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FitnessCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${idx + 1}. ${ex.name}', style: AppTypography.heading3),
                            ),
                            Row(
                              children: [
                                Text('${details.length} Sets Completed ✓', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                                  onPressed: () => _removeExercise(idx),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Per-set breakdown table: SET | WEIGHT | REPS | DONE | DEL
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkInput : AppColors.lightInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              ...details.asMap().entries.map((entry) {
                                final sIdx = entry.key;
                                final setDetail = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text('Set ${setDetail.setNumber}:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('${setDetail.weightKg.toStringAsFixed(setDetail.weightKg % 1 == 0 ? 0 : 1)} kg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                      const Text('×', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text('${setDetail.reps} reps', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                      const Icon(Icons.check_circle, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: details.length > 1 ? () => _removeSetFromLoggedExercise(idx, sIdx) : null,
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: details.length > 1 ? AppColors.rose : Colors.white24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // EACH EXERCISE'S DEDICATED PROGRESSIVE OVERLOAD & VOLUME (SUMPRODUCT) CARD
                        _buildExerciseVolumeCard(
                          context: context,
                          exerciseName: ex.name,
                          currentVolume: exVolume,
                          totalReps: exReps,
                          isPreview: false,
                        ),

                        const SizedBox(height: 6),
                        // Quick "+ Set" button on the logged exercise card
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                            label: const Text('+ Add Set to Exercise', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                            onPressed: () => _addSetToLoggedExercise(idx),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Credit Deduction Rules Reminder Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.rose.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.rose.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('⚡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completing this session will trigger CreditLedgerService and deduct exactly 1 PT credit from Sarah\'s active package.',
                      style: TextStyle(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Complete Session Button
            CustomButton(
              text: 'Complete Session (${_totalSessionVolume.toStringAsFixed(0)} kg Total Lifted) 💪',
              isFullWidth: true,
              height: 52,
              onPressed: () async {
                await workoutVM.completeSession(
                  sessionId: widget.session.id,
                  workoutId: 'wo-${widget.session.id}',
                  exercises: _exercises,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Session Completed! Logged ${_exercises.length} exercises with ${_totalSessionVolume.toStringAsFixed(0)} kg total tonnage. Exactly 1 PT credit deducted.',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
