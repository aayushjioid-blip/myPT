import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/entities/user_entity.dart';
import 'client_reassignment_dialog.dart';

class GymDashboardScreen extends StatelessWidget {
  final UserEntity user;

  const GymDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isHeadTrainer = user.role == UserRole.headTrainer;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHeadTrainer ? 'Head Trainer Console' : 'Facility Management',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
                ),
                const Text('IronCore Fitness 🏢', style: AppTypography.heading1),
              ],
            ),
            StatusBadge(
              text: isHeadTrainer ? 'Head Trainer 👑' : 'Gym Manager 🏢',
              type: BadgeType.purple,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Facility Operational KPIs
        const Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Staff Trainers',
                value: '3',
                subtitle: '94% utilization',
                valueColor: AppColors.purple,
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Gym Clients',
                value: '18',
                subtitle: '100% active',
                valueColor: AppColors.primary,
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Floor Occupancy',
                value: '28/40',
                subtitle: '70% capacity',
                valueColor: AppColors.blue,
                icon: Icons.fitness_center,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Head Trainer & Gym Manager Client Reassignment Console (PHASE 5 CRITICAL)
        FitnessCard(
          hasGlow: true,
          borderColor: AppColors.purple.withOpacity(0.5),
          backgroundColor: AppColors.purple.withOpacity(0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('👑 CLIENT REASSIGNMENT CONSOLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple)),
                  StatusBadge(text: 'Gym Authority', type: BadgeType.purple),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Transfer client between staff trainers due to leave, schedule mismatch, or specialization. Client workout logs, active credit balance, and progress history are 100% preserved.',
                style: TextStyle(fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sarah Jenkins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Coach: Alex Rivera • 9 Session Credits Active', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                      ],
                    ),
                    CustomButton(
                      text: 'Transfer ➔',
                      height: 36,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ClientReassignmentDialog(
                            clientName: 'Sarah Jenkins',
                            currentTrainerName: 'Alex Rivera',
                            fromTrainerId: 'trn-alex',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Staff Roster
        const Text('Staff Trainer Roster', style: AppTypography.heading2),
        const SizedBox(height: 8),

        _buildTrainerRosterTile(context, 'Alex Rivera', 'NASM-CPT • 8 Yrs Exp', '12 Clients', 'TRN001', true),
        const SizedBox(height: 8),
        _buildTrainerRosterTile(context, 'Maya Lin', 'ACE-CPT, RYT-500 • 6 Yrs Exp', '8 Clients', 'MAYA02', true),
        const SizedBox(height: 8),
        _buildTrainerRosterTile(context, 'Leo Novak', 'Boxing Coach • 3 Yrs Exp', '2 Clients', 'LEO007', false),

        const SizedBox(height: 16),

        // Facility Specs Card
        FitnessCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Facility Specifications', style: AppTypography.heading3),
              SizedBox(height: 6),
              Text('• Location: 742 Evergreen Blvd, Metro City', style: TextStyle(fontSize: 11)),
              Text('• Operating Hours: 06:00 - 22:00 Daily', style: TextStyle(fontSize: 11)),
              Text('• Max Floor Capacity: 40 Clients', style: TextStyle(fontSize: 11)),
              Text('• Amenities: Olympic Platforms, Sauna & Ice Bath, Turf Sprint Track', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerRosterTile(BuildContext context, String name, String subtitle, String clientCount, String code, bool isVerified) {
    return FitnessCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.purple.withOpacity(0.2),
                child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 6),
                      StatusBadge(
                        text: isVerified ? 'Verified' : 'Unverified',
                        type: isVerified ? BadgeType.primary : BadgeType.amber,
                      ),
                    ],
                  ),
                  Text('$subtitle • Code: $code', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                ],
              ),
            ],
          ),
          Text(clientCount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}
