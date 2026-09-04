import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../domain/repositories/i_trainer_repository.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/trainer_entity.dart';
import 'admin_view_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserEntity> _users = [];
  List<TrainerEntity> _trainers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authRepo = context.read<IAuthRepository>();
    final trainerRepo = context.read<ITrainerRepository>();
    final u = await authRepo.getAllUsers();
    final t = await trainerRepo.getAllTrainers();
    setState(() {
      _users = u;
      _trainers = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final flags = adminVM.featureFlags;

    final verifiedCount = _trainers.where((t) => t.verificationStatus == VerificationStatus.verified).length;
    final unverifiedCount = _trainers.where((t) => t.verificationStatus == VerificationStatus.unverified).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Administration', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                Text('Super Admin 🛡️', style: AppTypography.heading1),
              ],
            ),
            StatusBadge(text: '${_users.length} Users Registered', type: BadgeType.rose),
          ],
        ),

        const SizedBox(height: 16),

        // 1. Real-time Platform KPIs
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Platform Users',
                value: '${_users.length}',
                subtitle: '5 User Roles',
                valueColor: AppColors.rose,
                icon: Icons.admin_panel_settings_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Coaches',
                value: '${_trainers.length}',
                subtitle: '$verifiedCount Verified • $unverifiedCount Unverified',
                valueColor: AppColors.primary,
                icon: Icons.sports_mma_outlined,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: MetricTile(
                label: 'Facilities',
                value: '1',
                subtitle: 'IronCore Fitness',
                valueColor: AppColors.purple,
                icon: Icons.domain,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Centralized Feature Flags Console (CRITICAL RULE 1)
        FitnessCard(
          hasGlow: true,
          borderColor: AppColors.rose.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🚩 RUNTIME FEATURE FLAGS (GLOBAL CONTROLS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.rose)),
                  StatusBadge(text: 'Live Effect', type: BadgeType.rose),
                ],
              ),
              const SizedBox(height: 12),
              ...flags.entries.map((entry) {
                String description;
                switch (entry.key) {
                  case 'advanced_trainer_search':
                    description = 'Enables multi-parameter filters in Client Discovery (Default: FALSE)';
                    break;
                  case 'client_personal_information':
                    description = 'Enables medical/injury intake collection (Default: TRUE)';
                    break;
                  case 'online_payments':
                    description = 'Enables mock online payment gateway vs offline UPI (Default: FALSE)';
                    break;
                  case 'trainer_reviews':
                    description = 'Enables 1-5 star review submission on trainer profiles (Default: TRUE)';
                    break;
                  case 'client_upcoming_workout_visibility':
                    description = 'Displays tomorrow\'s scheduled workout on client hub (Default: TRUE)';
                    break;
                  default:
                    description = 'Platform feature toggle';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(description, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                          ],
                        ),
                      ),
                      Switch(
                        value: entry.value,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          adminVM.toggleFeatureFlag(entry.key, val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Feature flag "${entry.key}" set to $val')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Trainer Verification Queue & Control
        FitnessCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COACH VERIFICATION CONTROL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  StatusBadge(text: 'Discovery Gating', type: BadgeType.primary),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Verified coaches appear in public discovery. Unverified coaches (e.g. Leo Novak) can use all app features but are strictly hidden from public discovery.',
                style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
              ),
              const SizedBox(height: 12),
              ..._trainers.map((t) {
                final isVerified = t.verificationStatus == VerificationStatus.verified;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInput : AppColors.lightInput,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.name} (Code: ${t.trainerCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(isVerified ? '✓ Verified (Public Discovery Active)' : '🔒 Unverified (Hidden from Public Search)', style: TextStyle(fontSize: 10, color: isVerified ? AppColors.primary : AppColors.amber)),
                          ],
                        ),
                      ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isVerified ? AppColors.rose.withOpacity(0.2) : AppColors.primary,
                            foregroundColor: isVerified ? AppColors.rose : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () async {
                            await adminVM.setTrainerVerification(t.id, !isVerified);
                            await _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.name} verification status set to ${!isVerified ? "VERIFIED" : "UNVERIFIED"}')),
                            );
                          },
                          child: Text(isVerified ? 'Revoke' : 'Verify ✓', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. Platform User Directory
        const Text('User Directory (5 Roles)', style: AppTypography.heading2),
        const SizedBox(height: 8),

        ..._users.map((u) {
          BadgeType rType;
          switch (u.role) {
            case UserRole.superAdmin:
              rType = BadgeType.rose;
              break;
            case UserRole.gymManager:
            case UserRole.headTrainer:
              rType = BadgeType.purple;
              break;
            case UserRole.trainer:
              rType = BadgeType.blue;
              break;
            case UserRole.client:
              rType = BadgeType.primary;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FitnessCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(u.avatar, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(u.email, style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                        ],
                      ),
                    ],
                  ),
                  StatusBadge(text: u.role.name.toUpperCase(), type: rType),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
