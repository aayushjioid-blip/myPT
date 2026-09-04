import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeType { primary, blue, amber, rose, purple, subtle }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = BadgeType.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.primary:
        bg = AppColors.primary.withOpacity(0.15);
        fg = AppColors.primary;
        break;
      case BadgeType.blue:
        bg = AppColors.blue.withOpacity(0.15);
        fg = AppColors.blue;
        break;
      case BadgeType.amber:
        bg = AppColors.amber.withOpacity(0.15);
        fg = AppColors.amber;
        break;
      case BadgeType.rose:
        bg = AppColors.rose.withOpacity(0.15);
        fg = AppColors.rose;
        break;
      case BadgeType.purple:
        bg = AppColors.purple.withOpacity(0.15);
        fg = AppColors.purple;
        break;
      case BadgeType.subtle:
        bg = Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkInput
            : AppColors.lightInput;
        fg = Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
