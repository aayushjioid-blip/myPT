import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'progress_view_model.dart';
import 'measurement_logger_dialog.dart';

class ClientProgressScreen extends StatefulWidget {
  const ClientProgressScreen({super.key});

  @override
  State<ClientProgressScreen> createState() => _ClientProgressScreenState();
}

class _ClientProgressScreenState extends State<ClientProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<ProgressViewModel>().loadForClient(authVM.currentUser.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final progressVM = context.watch<ProgressViewModel>();
    final user = authVM.currentUser;
    final latest = progressVM.latestMeasurement;
    final filtered = progressVM.filteredMeasurements;

    final currentWeight = latest?.weightKg ?? user.weightKg ?? 64.5;
    final currentHeight = latest?.heightCm ?? user.heightCm ?? 168.0;
    final currentBmi = latest?.bmi ?? Formatters.calculateBmi(currentWeight, currentHeight);
    final currentBf = latest?.bodyFatPercentage ?? 21.8;

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
                  Text('Body Composition', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Progress Tracking', style: AppTypography.heading1),
                ],
              ),
              CustomButton(
                text: '+ Log Check-In',
                height: 36,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => MeasurementLoggerDialog(clientId: user.id, progressVM: progressVM),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. Core Metric Tiles
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Current Weight',
                  value: '$currentWeight',
                  unit: 'kg',
                  subtitle: '↓ ${progressVM.totalWeightLost} kg lost',
                  valueColor: AppColors.primary,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: 'Body BMI',
                  value: '$currentBmi',
                  unit: Formatters.getBmiCategory(currentBmi),
                  subtitle: 'Normal Range',
                  valueColor: AppColors.blue,
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: 'Body Fat',
                  value: '$currentBf',
                  unit: '%',
                  subtitle: 'Athletic',
                  valueColor: AppColors.purple,
                  icon: Icons.pie_chart_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Medical Privacy Shield Card (CRITICAL RULE 2 & 4)
          FitnessCard(
            hasGlow: user.sharePersonalInfoWithTrainer,
            borderColor: user.sharePersonalInfoWithTrainer ? AppColors.primary.withOpacity(0.4) : AppColors.darkBorder,
            child: Row(
              children: [
                Icon(
                  user.sharePersonalInfoWithTrainer ? Icons.lock_open : Icons.lock_outline,
                  color: user.sharePersonalInfoWithTrainer ? AppColors.primary : AppColors.darkTextMuted,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Medical & Progress Privacy Shield', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        user.sharePersonalInfoWithTrainer
                            ? 'Sharing ON: Coach Alex can view your body metrics & injury notes.'
                            : 'Sharing OFF: Private medical & body metrics are hidden from your trainer.',
                        style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: user.sharePersonalInfoWithTrainer,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    await authVM.togglePersonalInfoSharing(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(val ? 'Progress metrics shared with your trainer.' : 'Progress metrics set to private.')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Interactive Progress Trend Chart Card
          FitnessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight Progression Trend', style: AppTypography.heading3),
                    Row(
                      children: [
                        _buildRangeChip('1M', ProgressTimeRange.oneMonth, progressVM),
                        _buildRangeChip('3M', ProgressTimeRange.threeMonths, progressVM),
                        _buildRangeChip('6M', ProgressTimeRange.sixMonths, progressVM),
                        _buildRangeChip('All', ProgressTimeRange.allTime, progressVM),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visual Sparkline Trend Chart
                SizedBox(
                  height: 110,
                  child: CustomPaint(
                    size: const Size(double.infinity, 110),
                    painter: _ProgressChartPainter(
                      dataPoints: filtered.map((m) => m.weightKg).toList().reversed.toList(),
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Initial: ${progressVM.initialMeasurement?.weightKg ?? 68.0} kg',
                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                    ),
                    Text(
                      'Current: $currentWeight kg (↓ ${progressVM.totalWeightLost} kg)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. 8-Point Circumference Body Scan
          FitnessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('8-Point Body Circumferences', style: AppTypography.heading3),
                    StatusBadge(text: 'Latest Scan', type: BadgeType.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildCircumferenceTile('Chest', '${latest?.chestCm ?? 91.0} cm', '-3.0 cm'),
                    _buildCircumferenceTile('Waist', '${latest?.waistCm ?? 72.0} cm', '-4.0 cm'),
                    _buildCircumferenceTile('Hips', '${latest?.hipsCm ?? 96.0} cm', '-3.0 cm'),
                    _buildCircumferenceTile('Biceps', '${latest?.bicepsCm ?? 29.0} cm', '+0.5 cm'),
                    _buildCircumferenceTile('Thighs', '${latest?.thighsCm ?? 55.0} cm', '-2.0 cm'),
                    _buildCircumferenceTile('Calves', '${latest?.calvesCm ?? 36.5} cm', '0.0 cm'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Optional Progress Photos Gallery
          FitnessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress Photo Gallery', style: AppTypography.heading3),
                const SizedBox(height: 4),
                const Text('Private Front, Side & Back visual check-ins', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPhotoPlaceholder('Front Pose', '📸 Front View Uploaded'),
                    const SizedBox(width: 8),
                    _buildPhotoPlaceholder('Side Pose', '📸 Side View Uploaded'),
                    const SizedBox(width: 8),
                    _buildPhotoPlaceholder('Back Pose', 'Tap to add Back photo', isPending: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 6. Assessment Check-In History
          const Text('Assessment Check-In History', style: AppTypography.heading2),
          const SizedBox(height: 8),

          ...progressVM.allMeasurements.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FitnessCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${m.date.month}/${m.date.day}/${m.date.year} Check-In',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        StatusBadge(
                          text: '${m.weightKg} kg • BMI ${m.bmi}',
                          type: BadgeType.primary,
                        ),
                      ],
                    ),
                    if (m.notes != null && m.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(m.notes!, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, ProgressTimeRange range, ProgressViewModel vm) {
    final isSelected = vm.selectedRange == range;
    return InkWell(
      onTap: () => vm.setTimeRange(range),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppColors.darkTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCircumferenceTile(String label, String value, String delta) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInput : AppColors.lightInput,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(delta, style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String label, String status, {bool isPending = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: isPending ? Colors.transparent : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPending ? AppColors.darkBorder : AppColors.primary.withOpacity(0.4),
            style: isPending ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(isPending ? Icons.add_a_photo_outlined : Icons.photo_camera_front, size: 22, color: isPending ? AppColors.darkTextMuted : AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            Text(isPending ? 'Optional' : '✓ Uploaded', style: const TextStyle(fontSize: 8, color: AppColors.darkTextMuted)),
          ],
        ),
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final bool isDark;

  _ProgressChartPainter({required this.dataPoints, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paintDot = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final minVal = dataPoints.reduce((a, b) => a < b ? a : b) - 1.0;
    final maxVal = dataPoints.reduce((a, b) => a > b ? a : b) + 1.0;
    final range = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    final stepX = dataPoints.length > 1 ? size.width / (dataPoints.length - 1) : size.width;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - ((dataPoints[i] - minVal) / range * (size.height - 20)) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, paintDot);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
