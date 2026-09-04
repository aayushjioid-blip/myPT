import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'trainer_clients_view_model.dart';

class TrainerClientsScreen extends StatefulWidget {
  const TrainerClientsScreen({super.key});

  @override
  State<TrainerClientsScreen> createState() => _TrainerClientsScreenState();
}

class _TrainerClientsScreenState extends State<TrainerClientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<TrainerClientsViewModel>().loadClientsForTrainer(authVM.currentUser.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsVM = context.watch<TrainerClientsViewModel>();
    final clients = clientsVM.clients;

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
                  Text('Client Management', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Client Roster (360°)', style: AppTypography.heading1),
                ],
              ),
              StatusBadge(text: '${clients.length} Active Clients', type: BadgeType.primary),
            ],
          ),

          const SizedBox(height: 16),

          // Search Bar
          TextField(
            onChanged: (val) => clientsVM.search(val),
            decoration: InputDecoration(
              hintText: '🔍 Search clients by name...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          ...clients.map((profile) {
            final user = profile.user;
            final activePkg = profile.activePackage;
            final credits = activePkg?.remainingSessions ?? 0;
            final isShared = user.sharePersonalInfoWithTrainer;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FitnessCard(
                hasGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(user.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(user.name, style: AppTypography.heading3),
                                  const SizedBox(width: 6),
                                  StatusBadge(
                                    text: credits > 0 ? '$credits Credits' : '0 Credits',
                                    type: credits > 0 ? BadgeType.primary : BadgeType.rose,
                                  ),
                                ],
                              ),
                              Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Active Package & Goal Info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInput : AppColors.lightInput,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ACTIVE PACKAGE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                              Text(activePkg != null ? '${activePkg.totalSessions} Sessions Starter' : 'No Active Package', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('WORKOUTS LOGGED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                              Text('${profile.workoutHistory.length} Completed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Privacy Shielded Medical Section (CRITICAL RULE 2 & 4)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isShared ? AppColors.primary.withOpacity(0.08) : AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isShared ? AppColors.primary.withOpacity(0.3) : AppColors.darkBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isShared ? Icons.health_and_safety : Icons.lock_outline, size: 14, color: isShared ? AppColors.primary : AppColors.darkTextMuted),
                              const SizedBox(width: 6),
                              Text(
                                isShared ? 'CLIENT MEDICAL & INJURY RECORD (SHARED)' : 'MEDICAL & HEALTH RECORD (PROTECTED)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isShared ? AppColors.primary : AppColors.darkTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (isShared) ...[
                            Text('Goal: ${user.fitnessGoal ?? "General fitness"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            if (user.injuries != null) Text('Injuries: ${user.injuries}', style: const TextStyle(fontSize: 11, color: AppColors.rose)),
                            if (user.medicalInfo != null) Text('Medical Notes: ${user.medicalInfo}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                            if (profile.sharedMeasurements.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Latest Weight: ${profile.sharedMeasurements.first.weightKg} kg (BMI: ${profile.sharedMeasurements.first.bmi})', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                            ],
                          ] else ...[
                            const Text(
                              '🔒 Medical & injury intake is private. Client has not enabled "Share with trainer" toggle in their privacy settings.',
                              style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
