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
              label: 'Client (Sarah)',
              userId: 'usr-client-1',
              role: UserRole.client,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-client-1'),
            ),
            _buildRoleChip(
              label: 'Coach (Alex)',
              userId: 'usr-trn-1',
              role: UserRole.trainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-trn-1'),
            ),
            _buildRoleChip(
              label: 'Head Coach (Marcus)',
              userId: 'usr-headtrn-1',
              role: UserRole.headTrainer,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-headtrn-1'),
            ),
            _buildRoleChip(
              label: 'Gym Mgr (Elena)',
              userId: 'usr-gymmgr-1',
              role: UserRole.gymManager,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-gymmgr-1'),
            ),
            _buildRoleChip(
              label: 'Super Admin',
              userId: 'usr-admin-1',
              role: UserRole.superAdmin,
              currentRole: currentRole,
              onTap: () => authVM.switchDemoRole('usr-admin-1'),
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
