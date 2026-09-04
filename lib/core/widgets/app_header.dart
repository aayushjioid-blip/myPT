import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../domain/entities/user_entity.dart';
import '../../features/profile/presentation/user_profile_sheet.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final UserEntity? user;
  final Widget? trailing;
  final VoidCallback? onNotificationTap;
  final int unreadNotifications;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onProfileTap;
  final bool isDark;

  const AppHeader({
    super.key,
    this.title = 'myPT',
    this.user,
    this.trailing,
    this.onNotificationTap,
    this.unreadNotifications = 0,
    this.onThemeToggle,
    this.onProfileTap,
    this.isDark = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _showProfileSheet(BuildContext context) {
    if (onProfileTap != null) {
      onProfileTap!();
      return;
    }

    final u = user;
    if (u == null) return;

    UserProfileSheet.show(context, u);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          // myPT Custom High-Energy Logo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.flash_on, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'myPT',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (onThemeToggle != null)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
            onPressed: onThemeToggle,
            tooltip: 'Toggle Theme',
          ),
        if (onNotificationTap != null)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: onNotificationTap,
                tooltip: 'Notifications',
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.rose,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        // Tappable Profile Avatar with Glow
        if (user != null)
          GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: Container(
              margin: const EdgeInsets.only(right: 12, left: 4),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.8), width: 1.8),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(user!.avatar, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
