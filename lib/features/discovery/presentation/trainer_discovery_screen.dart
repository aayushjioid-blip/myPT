import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../trainers/presentation/trainer_profile_screen.dart';
import 'trainer_discovery_view_model.dart';

class TrainerDiscoveryScreen extends StatelessWidget {
  const TrainerDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discoveryVM = context.watch<TrainerDiscoveryViewModel>();
    final trainers = discoveryVM.trainers;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text('Discover Trainers', style: AppTypography.heading1),
          const Text(
            'Browse verified trainers or connect via direct trainer code.',
            style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
          ),

          const SizedBox(height: 16),

          // Search Bar
          TextField(
            onChanged: (val) => discoveryVM.search(val),
            decoration: InputDecoration(
              hintText: '🔍 Search trainer by name or specialization...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          // Feature Flag Gated: Advanced Filters (RULE 1)
          if (discoveryVM.isAdvancedSearchEnabled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ ADVANCED FILTERS (FEATURE FLAG ACTIVE)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        StatusBadge(text: 'All Specializations', type: BadgeType.primary),
                        SizedBox(width: 6),
                        StatusBadge(text: 'Fat Loss', type: BadgeType.subtle),
                        SizedBox(width: 6),
                        StatusBadge(text: 'Hypertrophy', type: BadgeType.subtle),
                        SizedBox(width: 6),
                        StatusBadge(text: 'Mobility & Rehab', type: BadgeType.subtle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '🔒 Advanced search filters hidden (Feature flag: advanced_trainer_search = false)',
                style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Verified Trainers List
          ...trainers.map((trainer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FitnessCard(
                hasGlow: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainer: trainer)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(trainer.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(trainer.name, style: AppTypography.heading3),
                                  const SizedBox(width: 6),
                                  const StatusBadge(text: '✓ Verified', type: BadgeType.primary),
                                ],
                              ),
                              Text(
                                '${trainer.experienceYears}+ Yrs Exp • ${trainer.location}',
                                style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('⭐ ${trainer.rating}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.amber)),
                            Text('(${trainer.reviewCount} reviews)', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trainer.bio,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: trainer.specializations.map((s) => StatusBadge(text: s, type: BadgeType.subtle)).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Code: ${trainer.trainerCode}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        CustomButton(
                          text: 'View Profile & Packages ➔',
                          height: 38,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainer: trainer)),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 10),

          // Unverified Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Text(
              'ℹ️ Unverified Trainer Access: Unverified trainers (e.g. Leo Novak) do not appear in public search, but clients can connect instantly using direct trainer codes (e.g. LEO007).',
              style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
