import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../../domain/repositories/i_trainer_repository.dart';
import '../../trainers/presentation/trainer_profile_screen.dart';
import '../../trainers/presentation/trainer_profile_view_model.dart';
import 'packages_view_model.dart';

class PackageSelectionDialog extends StatefulWidget {
  final String clientId;
  final VoidCallback? onNavigateToDiscovery;
  final VoidCallback? onNavigateToWorkouts;

  const PackageSelectionDialog({
    super.key,
    required this.clientId,
    this.onNavigateToDiscovery,
    this.onNavigateToWorkouts,
  });

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    VoidCallback? onNavigateToDiscovery,
    VoidCallback? onNavigateToWorkouts,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PackageSelectionDialog(
        clientId: clientId,
        onNavigateToDiscovery: onNavigateToDiscovery,
        onNavigateToWorkouts: onNavigateToWorkouts,
      ),
    );
  }

  @override
  State<PackageSelectionDialog> createState() => _PackageSelectionDialogState();
}

class _PackageSelectionDialogState extends State<PackageSelectionDialog> {
  TrainerEntity? _currentTrainer;
  List<PackageEntity> _trainerPackages = [];
  List<TrainerEntity> _allTrainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final trainerRepo = context.read<ITrainerRepository>();
    final pkgRepo = context.read<IPackageRepository>();

    final trainers = await trainerRepo.getVerifiedTrainers();
    final defaultTrainer = trainers.isNotEmpty ? trainers.first : await trainerRepo.getTrainerById('trn-alex');

    List<PackageEntity> pkgs = [];
    if (defaultTrainer != null) {
      pkgs = await pkgRepo.getPackagesByTrainerId(defaultTrainer.id);
      if (pkgs.isEmpty) {
        pkgs = await pkgRepo.getPackagesByTrainerId('trn-alex');
      }
    }

    if (mounted) {
      setState(() {
        _allTrainers = trainers;
        _currentTrainer = defaultTrainer;
        _trainerPackages = pkgs;
        _isLoading = false;
      });
    }
  }

  void _showPurchasePaymentDialog(BuildContext context, PackageEntity package, TrainerEntity trainer) {
    final refCtrl = TextEditingController(text: 'UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Purchase ${package.name}', style: AppTypography.heading3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price: ₹${package.price.toStringAsFixed(0)} • ${package.sessions} PT Sessions',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFFLINE UPI / PAYMENT DETAILS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue),
                    ),
                    const SizedBox(height: 4),
                    Text('Coach: ${trainer.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('UPI ID: ${trainer.upiId}', style: const TextStyle(fontSize: 12)),
                    Text('Mobile: ${trainer.mobilePaymentNumber}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Payment Transaction Reference ID',
                controller: refCtrl,
                hint: 'e.g. UPI-998822 or Cash',
              ),
              const SizedBox(height: 8),
              const Text(
                '🛡️ Verified Process: Submitting payment creates a pending package. Once your coach verifies the offline payment, your session credits activate immediately.',
                style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted, height: 1.3),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Submit Verification ✓',
            variant: ButtonVariant.secondary,
            onPressed: () async {
              final packagesVM = context.read<PackagesViewModel>();
              await packagesVM.purchasePackage(
                clientId: widget.clientId,
                packageId: package.id,
                transactionRef: refCtrl.text,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment submitted for ${package.name}! Coach ${trainer.name.split(' ').first} will verify your credits shortly.'),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
          CustomButton(
            text: '⚡ Instant Activate (+${package.sessions} Credits)',
            onPressed: () async {
              final packagesVM = context.read<PackagesViewModel>();
              final pkgRepo = context.read<IPackageRepository>();
              await packagesVM.purchasePackage(
                clientId: widget.clientId,
                packageId: package.id,
                transactionRef: refCtrl.text,
              );
              final payments = await pkgRepo.getPendingPaymentsForTrainer(package.trainerId);
              if (payments.isNotEmpty) {
                await pkgRepo.verifyPayment(payments.first.id, true);
              }
              await packagesVM.loadPackagesForClient(widget.clientId);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Package Activated! +${package.sessions} PT Credits added to your account.'),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTalkToCoachDialog(BuildContext context, TrainerEntity trainer) {
    final goalsCtrl = TextEditingController(text: 'I am interested in buying a training package and discussing custom session goals.');
    final notesCtrl = TextEditingController(text: 'Looking for 1-on-1 PT schedule options.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Message Coach ${trainer.name}', style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Your Message / Package Inquiry',
              controller: goalsCtrl,
              maxLines: 2,
              hint: 'e.g. Ask for package pricing, frequency, or trial',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Availability & Notes',
              controller: notesCtrl,
              maxLines: 2,
              hint: 'e.g. Weekday mornings, gym preference',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Send Message 🚀',
            onPressed: () async {
              final profileVM = context.read<TrainerProfileViewModel>();
              await profileVM.requestConsultation(
                clientId: widget.clientId,
                trainerId: trainer.id,
                goals: goalsCtrl.text,
                notes: notesCtrl.text,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Message sent to Coach ${trainer.name}!')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trainer = _currentTrainer;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14171D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkTextMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRAINING PACKAGES & COACHES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text('Choose Your Package', style: AppTypography.heading2),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Scrollable Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Zero balance explanation banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Text('🎟️', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Active Session Credits',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Select a package with your coach, talk to them for custom plans, or explore other coaches.',
                                    style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SECTION 1: Active Coach & Packages
                      if (trainer != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Packages with Coach ${trainer.name.split(' ').first}', style: AppTypography.heading3),
                            const StatusBadge(text: 'Current Coach', type: BadgeType.primary),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Trainer info mini card
                        FitnessCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withOpacity(0.2),
                                child: Text(trainer.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trainer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${trainer.experienceYears}+ Years Exp • ⭐ ${trainer.rating}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                                  ],
                                ),
                              ),
                              CustomButton(
                                text: '💬 Talk to Coach',
                                height: 32,
                                variant: ButtonVariant.secondary,
                                onPressed: () => _showTalkToCoachDialog(context, trainer),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Packages List for current trainer
                        ..._trainerPackages.map((pkg) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FitnessCard(
                              hasGlow: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                      Text(
                                        '₹${pkg.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(pkg.description, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${pkg.sessions} Sessions • ${pkg.validityDays} Days',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      CustomButton(
                                        text: 'Select & Pay 💳',
                                        height: 36,
                                        onPressed: () => _showPurchasePaymentDialog(context, pkg, trainer),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 16),

                      // SECTION 2: Switch / Explore Other Coaches
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_alt_outlined, color: AppColors.blue, size: 20),
                                SizedBox(width: 8),
                                Text('Explore & Switch Coaches', style: AppTypography.heading3),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Looking for different training packages, rates, or specializations (e.g. Mobility, Boxing, Fat Loss)? You can explore all certified coaches.',
                              style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted, height: 1.4),
                            ),
                            const SizedBox(height: 14),

                            // Other trainers preview
                            if (_allTrainers.length > 1) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _allTrainers.where((t) => t.id != _currentTrainer?.id).map((t) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainer: t)),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: AppColors.blue.withOpacity(0.2),
                                            child: Text(t.name[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue)),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(t.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right, size: 14, color: AppColors.blue),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            CustomButton(
                              text: 'Browse Full Trainer Directory ➔',
                              variant: ButtonVariant.primary,
                              isFullWidth: true,
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onNavigateToDiscovery?.call();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SECTION 3: Free Own Workout
                      FitnessCard(
                        child: Row(
                          children: [
                            const Text('🏃', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Train For Free Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Log an independent Own Workout. 0 PT credits needed.', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                                ],
                              ),
                            ),
                            CustomButton(
                              text: 'Workout ➔',
                              height: 32,
                              variant: ButtonVariant.secondary,
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onNavigateToWorkouts?.call();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
