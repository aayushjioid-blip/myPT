import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../domain/entities/notification_entity.dart';
import 'notification_view_model.dart';

class NotificationCenterDialog extends StatelessWidget {
  const NotificationCenterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final notifications = notifVM.notifications;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications', style: AppTypography.heading3),
          actions: [
            if (notifVM.unreadCount > 0)
              TextButton(
                onPressed: () => notifVM.markAllAsRead(),
                child: const Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (notifications.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_outlined, size: 48, color: AppColors.darkTextMuted),
                      SizedBox(height: 12),
                      Text('All caught up!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('No new notifications.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...notifications.map((n) {
                IconData icon;
                Color color;
                switch (n.type) {
                  case NotificationType.booking:
                    icon = Icons.calendar_month;
                    color = AppColors.blue;
                    break;
                  case NotificationType.payment:
                    icon = Icons.attach_money;
                    color = AppColors.primary;
                    break;
                  case NotificationType.workout:
                    icon = Icons.fitness_center;
                    color = AppColors.primary;
                    break;
                  case NotificationType.warning:
                    icon = Icons.warning_amber_rounded;
                    color = AppColors.amber;
                    break;
                  default:
                    icon = Icons.info_outline;
                    color = AppColors.purple;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FitnessCard(
                    hasGlow: !n.read,
                    borderColor: !n.read ? AppColors.primary.withOpacity(0.4) : AppColors.darkBorder,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (!n.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.message, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
