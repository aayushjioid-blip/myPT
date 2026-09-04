import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';

class PackageBuilderDialog extends StatefulWidget {
  final String trainerId;
  final IPackageRepository packageRepo;

  const PackageBuilderDialog({
    super.key,
    required this.trainerId,
    required this.packageRepo,
  });

  @override
  State<PackageBuilderDialog> createState() => _PackageBuilderDialogState();
}

class _PackageBuilderDialogState extends State<PackageBuilderDialog> {
  final _nameCtrl = TextEditingController(text: '12 PT Sessions Transformation');
  final _descCtrl = TextEditingController(text: 'Includes bi-weekly body scans, custom programming and nutrition check-ins.');
  final _sessionsCtrl = TextEditingController(text: '12');
  final _priceCtrl = TextEditingController(text: '599');
  final _validityCtrl = TextEditingController(text: '60');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _sessionsCtrl.dispose();
    _priceCtrl.dispose();
    _validityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Training Package', style: AppTypography.heading3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Package Name',
              controller: _nameCtrl,
              hint: 'e.g. 10 Sessions Starter Pack',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Package Description',
              controller: _descCtrl,
              maxLines: 2,
              hint: 'Coaching details, features, inclusions',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'PT Sessions',
                    controller: _sessionsCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Price (₹)',
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Validity Period (Days)',
              controller: _validityCtrl,
              keyboardType: TextInputType.number,
              hint: 'e.g. 45 or 60 days',
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Package validity is fully configurable by you. Expired credits cannot be used for new bookings.',
              style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: _isSaving ? 'Saving...' : 'Save Package ✓',
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  final sessions = int.tryParse(_sessionsCtrl.text) ?? 10;
                  final price = double.tryParse(_priceCtrl.text) ?? 499.0;
                  final validity = int.tryParse(_validityCtrl.text) ?? 45;

                  final pkg = PackageEntity(
                    id: 'pkg-${DateTime.now().millisecondsSinceEpoch}',
                    trainerId: widget.trainerId,
                    name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Custom PT Package',
                    description: _descCtrl.text.trim(),
                    sessions: sessions,
                    price: price,
                    validityDays: validity,
                    validityMode: ValidityMode.custom,
                    status: 'ACTIVE',
                  );

                  await widget.packageRepo.createPackage(pkg);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
        ),
      ],
    );
  }
}
