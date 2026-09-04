import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/measurement_entity.dart';
import 'progress_view_model.dart';

class MeasurementLoggerDialog extends StatefulWidget {
  final String clientId;
  final ProgressViewModel progressVM;
  final String source;

  const MeasurementLoggerDialog({
    super.key,
    required this.clientId,
    required this.progressVM,
    this.source = 'CLIENT',
  });

  @override
  State<MeasurementLoggerDialog> createState() => _MeasurementLoggerDialogState();
}

class _MeasurementLoggerDialogState extends State<MeasurementLoggerDialog> {
  final _weightCtrl = TextEditingController(text: '64.5');
  final _heightCtrl = TextEditingController(text: '168.0');
  final _bodyFatCtrl = TextEditingController(text: '21.8');
  final _chestCtrl = TextEditingController(text: '91.0');
  final _waistCtrl = TextEditingController(text: '72.0');
  final _hipsCtrl = TextEditingController(text: '96.0');
  final _bicepsCtrl = TextEditingController(text: '29.0');
  final _thighsCtrl = TextEditingController(text: '55.0');
  final _calvesCtrl = TextEditingController(text: '36.5');
  final _notesCtrl = TextEditingController(text: 'Feeling leaner and increased bench press strength.');

  bool _frontPhotoAttached = true;
  bool _sidePhotoAttached = true;
  bool _backPhotoAttached = false;

  double get _computedBmi {
    final w = double.tryParse(_weightCtrl.text) ?? 64.5;
    final h = double.tryParse(_heightCtrl.text) ?? 168.0;
    return Formatters.calculateBmi(w, h);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Body Assessment Check-In', style: AppTypography.heading3),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Core Metrics & Live Auto BMI Calculation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CORE ASSESSMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text(
                        'Live Auto BMI: $_computedBmi (${Formatters.getBmiCategory(_computedBmi)})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Weight (kg)',
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Height (cm)',
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Body Fat (%)',
                          controller: _bodyFatCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 8-Point Circumference Metrics
            const Text('8-Point Body Circumferences (cm)', style: AppTypography.heading2),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Chest (cm)',
                    controller: _chestCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Waist (cm)',
                    controller: _waistCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Hips (cm)',
                    controller: _hipsCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Biceps (cm)',
                    controller: _bicepsCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Thighs (cm)',
                    controller: _thighsCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Calves (cm)',
                    controller: _calvesCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Optional Progress Photos
            const Text('Progress Photos (Optional)', style: AppTypography.heading2),
            const Text('Attach private progress photos for visual comparison.', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildPhotoToggle('Front Pose', _frontPhotoAttached, (val) => setState(() => _frontPhotoAttached = val)),
                const SizedBox(width: 8),
                _buildPhotoToggle('Side Pose', _sidePhotoAttached, (val) => setState(() => _sidePhotoAttached = val)),
                const SizedBox(width: 8),
                _buildPhotoToggle('Back Pose', _backPhotoAttached, (val) => setState(() => _backPhotoAttached = val)),
              ],
            ),

            const SizedBox(height: 16),

            // Notes
            CustomTextField(
              label: 'Assessment Notes / Observations',
              controller: _notesCtrl,
              maxLines: 2,
              hint: 'Energy levels, sleep, nutrition compliance',
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Save Assessment Check-In 📊',
              isFullWidth: true,
              height: 50,
              onPressed: () async {
                final w = double.tryParse(_weightCtrl.text) ?? 64.5;
                final h = double.tryParse(_heightCtrl.text) ?? 168.0;
                final bf = double.tryParse(_bodyFatCtrl.text) ?? 21.8;
                final ch = double.tryParse(_chestCtrl.text) ?? 91.0;
                final wa = double.tryParse(_waistCtrl.text) ?? 72.0;
                final hi = double.tryParse(_hipsCtrl.text) ?? 96.0;
                final bi = double.tryParse(_bicepsCtrl.text) ?? 29.0;
                final th = double.tryParse(_thighsCtrl.text) ?? 55.0;
                final ca = double.tryParse(_calvesCtrl.text) ?? 36.5;

                await widget.progressVM.logMeasurement(
                  clientId: widget.clientId,
                  weightKg: w,
                  heightCm: h,
                  bodyFat: bf,
                  chest: ch,
                  waist: wa,
                  hips: hi,
                  biceps: bi,
                  thighs: th,
                  calves: ca,
                  photos: ProgressPhotos(
                    frontUrl: _frontPhotoAttached ? '📸 Front Pose' : null,
                    sideUrl: _sidePhotoAttached ? '📸 Side Pose' : null,
                    backUrl: _backPhotoAttached ? '📸 Back Pose' : null,
                  ),
                  notes: _notesCtrl.text,
                  source: widget.source,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assessment logged! Weight: ${w}kg • BMI: ${Formatters.calculateBmi(w, h)}.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoToggle(String title, bool isAttached, ValueChanged<bool> onChanged) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(!isAttached),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isAttached ? AppColors.primary.withOpacity(0.12) : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAttached ? AppColors.primary : AppColors.darkBorder,
              width: isAttached ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(isAttached ? Icons.check_circle : Icons.camera_alt_outlined, size: 20, color: isAttached ? AppColors.primary : AppColors.darkTextMuted),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 10, fontWeight: isAttached ? FontWeight.bold : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
