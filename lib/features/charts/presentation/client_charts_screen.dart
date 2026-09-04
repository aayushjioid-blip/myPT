import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'fitness_chart_view_model.dart';

class ClientChartsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToWorkouts;

  const ClientChartsScreen({super.key, this.onNavigateToWorkouts});

  @override
  State<ClientChartsScreen> createState() => _ClientChartsScreenState();
}

class _ClientChartsScreenState extends State<ClientChartsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<FitnessChartViewModel>().loadChartsForClient(authVM.currentUser.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chartVM = context.watch<FitnessChartViewModel>();
    final charts = chartVM.clientCharts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrition & Programming', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('My Fitness Charts 🥗', style: AppTypography.heading1),
                ],
              ),
              StatusBadge(text: '${charts.length} Assigned', type: BadgeType.primary),
            ],
          ),

          const SizedBox(height: 16),

          // Overview banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.25),
                  AppColors.purple.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Coach Tailored Plans', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(
                        'Your assigned macro nutrition targets and structured exercise splits updated in real time by your trainer.',
                        style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (charts.isEmpty)
            FitnessCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: const [
                      Icon(Icons.restaurant_menu_outlined, size: 36, color: AppColors.darkTextMuted),
                      SizedBox(height: 10),
                      Text('No charts assigned yet.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                      Text('Your trainer will dispatch personalized nutrition & workout charts to you.', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...charts.map((chart) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FitnessCard(
                  hasGlow: true,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chart.title, style: AppTypography.heading3),
                              const SizedBox(height: 2),
                              Text(
                                'By Coach ${chart.trainerName} • ${chart.goalCategory}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          text: '${chart.createdAt.month}/${chart.createdAt.day}',
                          type: BadgeType.subtle,
                        ),
                      ],
                    ),
                    children: [
                      // Total Macros Summary Row
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF14181F) : const Color(0xFFEFF3F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Total Calories', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                Text('${chart.totalCalories} kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.amber)),
                              ],
                            ),
                            Container(width: 1, height: 24, color: AppColors.darkBorder),
                            Column(
                              children: [
                                const Text('Total Protein', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                Text('${chart.totalProtein}g', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)),
                              ],
                            ),
                            Container(width: 1, height: 24, color: AppColors.darkBorder),
                            Column(
                              children: [
                                const Text('Meals Planned', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                Text('${chart.dietPlan.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Section 1: Nutritional Diet Plan
                      Row(
                        children: const [
                          Icon(Icons.restaurant, size: 16, color: AppColors.amber),
                          SizedBox(width: 6),
                          Text('NUTRITIONAL DIET PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...chart.dietPlan.map((meal) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkInput : AppColors.lightInput,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  meal.mealName,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amber),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meal.foodItems, style: const TextStyle(fontSize: 11, height: 1.3)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🔥 ${meal.calories} kcal  •  💪 ${meal.proteinGrams}g Protein  •  🌾 ${meal.carbsGrams}g Carbs',
                                      style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Section 2: Workout Routine Split
                      Row(
                        children: const [
                          Icon(Icons.fitness_center, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('WORKOUT ROUTINE SPLIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...chart.workoutPlan.map((ex) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkInput : AppColors.lightInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ex.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('Target: ${ex.targetMuscle} • ${ex.notes}', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${ex.sets} Sets × ${ex.reps} Reps',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      if (widget.onNavigateToWorkouts != null) ...[
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Log Workout in Studio 🏋️',
                          isFullWidth: true,
                          height: 38,
                          variant: ButtonVariant.secondary,
                          onPressed: widget.onNavigateToWorkouts,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
