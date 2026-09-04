import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../../features/auth/presentation/auth_view_model.dart';

class DemoRoleHUD extends StatelessWidget {
  const DemoRoleHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final currentRole = authVM.currentUser.role;

    return Container(
      width: double.infinity,
      color: const Color(0xFF101216),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              '⚡ ROLE:',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            _buildRoleChip(
              label: '🛡️ Aayush (Super Admin)',
              userId: 'usr_aayush',
              role: UserRole.superAdmin,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_aayush'),
            ),
            _buildRoleChip(
              label: '🛡️ Himani (Super Admin)',
              userId: 'usr_himani',
              role: UserRole.superAdmin,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_himani'),
            ),
            _buildRoleChip(
              label: '👑 Neeli (Head/Gym Mgr)',
              userId: 'usr_neeli',
              role: UserRole.headTrainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_neeli'),
            ),
            _buildRoleChip(
              label: '🥊 Khushboo (Coach/Client)',
              userId: 'usr_khushboo',
              role: UserRole.trainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_khushboo'),
            ),
            _buildRoleChip(
              label: '⚡ Rincy (Coach)',
              userId: 'usr_rincy',
              role: UserRole.trainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_rincy'),
            ),
            _buildRoleChip(
              label: '🏋️ Kumar (Coach)',
              userId: 'usr_kumar',
              role: UserRole.trainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_kumar'),
            ),
            _buildRoleChip(
              label: '👤 Sourabh (Client)',
              userId: 'usr_sourabh',
              role: UserRole.client,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_sourabh'),
            ),
            _buildRoleChip(
              label: '👤 RK (Client)',
              userId: 'usr_rk',
              role: UserRole.client,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_rk'),
            ),
            _buildRoleChip(
              label: '👤 Odin (Client)',
              userId: 'usr_odin',
              role: UserRole.client,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr_odin'),
            ),
            _buildRoleChip(
              label: '👤 Sarah (Client)',
              userId: 'usr-client-1',
              role: UserRole.client,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-client-1'),
            ),
            _buildRoleChip(
              label: '🏋️ Alex (Coach)',
              userId: 'usr-trn-1',
              role: UserRole.trainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-trn-1'),
            ),
            _buildRoleChip(
              label: '🥇 Marcus (Head Coach)',
              userId: 'usr-headtrn-1',
              role: UserRole.headTrainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-headtrn-1'),
            ),
            _buildRoleChip(
              label: '🏢 Elena (Gym Mgr)',
              userId: 'usr-gymmgr-1',
              role: UserRole.gymManager,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-gymmgr-1'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required String userId,
    required UserRole role,
    required UserRole currentRole,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRole == role;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white12,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
