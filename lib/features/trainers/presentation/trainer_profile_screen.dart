import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/relationship_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../packages/presentation/packages_view_model.dart';
import 'trainer_profile_view_model.dart';

class TrainerProfileScreen extends StatefulWidget {
  final TrainerEntity trainer;

  const TrainerProfileScreen({super.key, required this.trainer});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<TrainerProfileViewModel>().loadProfile(widget.trainer.id, authVM.currentUser.id);
    });
  }

  void _showConsultationDialog(BuildContext context, TrainerProfileViewModel profileVM, String clientId) {
    final goalsCtrl = TextEditingController(text: 'Fat Loss & Hypertrophy');
    final notesCtrl = TextEditingController(text: 'Looking for 1-on-1 coaching 3x/week.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Consultation Request with ${widget.trainer.name}', style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Primary Fitness Goals',
              controller: goalsCtrl,
              hint: 'e.g. Fat loss, hypertrophy, mobility',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Notes / Scheduling Preference',
              controller: notesCtrl,
              maxLines: 2,
              hint: 'e.g. Prefer mornings, past injuries',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Send Request 🚀',
            onPressed: () async {
              await profileVM.requestConsultation(
                clientId: clientId,
                trainerId: widget.trainer.id,
                goals: goalsCtrl.text,
                notes: notesCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✓ Consultation request sent to ${widget.trainer.name}!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, PackageEntity package, String clientId) {
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
              Text('Price: ₹${package.price.toStringAsFixed(0)} • ${package.sessions} PT Sessions', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                    const Text('OFFLINE UPI PAYMENT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue)),
                    const SizedBox(height: 4),
                    Text('UPI ID: ${widget.trainer.upiId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Mobile: ${widget.trainer.mobilePaymentNumber}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Payment Transaction Reference ID',
                controller: refCtrl,
                hint: 'e.g. UPI-998822 or Cash ref',
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Your package starts with 0 active credits until the trainer verifies your offline payment.',
                style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
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
            text: 'I Have Paid Submit ✓',
            onPressed: () async {
              final packagesVM = context.read<PackagesViewModel>();
              await packagesVM.purchasePackage(
                clientId: clientId,
                packageId: package.id,
                transactionRef: refCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment submitted for ${package.name}! Coach ${widget.trainer.name.split(' ').first} will verify your credits.'),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profileVM = context.watch<TrainerProfileViewModel>();
    final pkgRepo = context.read<IPackageRepository>();
    final clientId = authVM.currentUser.id;
    final trainer = profileVM.trainer ?? widget.trainer;
    final rel = profileVM.relationship;
    final isApproved = rel?.status == RelationshipStatus.accepted;
    final isPending = rel?.status == RelationshipStatus.requested;

    return Scaffold(
      appBar: AppBar(
        title: Text(trainer.name, style: AppTypography.heading3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          FitnessCard(
            hasGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(trainer.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(trainer.name, style: AppTypography.heading2),
                              const SizedBox(width: 6),
                              const StatusBadge(text: 'Verified', type: BadgeType.primary),
                            ],
                          ),
                          Text('${trainer.experienceYears}+ Years Exp • ${trainer.location}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                          const SizedBox(height: 4),
                          Text('Code: ${trainer.trainerCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(trainer.bio, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: trainer.specializations.map((s) => StatusBadge(text: s, type: BadgeType.subtle)).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Consultation Status / CTA
          if (isApproved) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Text('🤝', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Client Approved! You are verified with Alex and eligible to purchase training packages below.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('⏳', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consultation Request Pending: Waiting for Alex to accept your request in coach mode.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showConsultationDialog(context, profileVM, clientId),
                          child: const Text('Update Message', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.black),
                          onPressed: () async {
                            if (rel != null) {
                              await pkgRepo.acceptConsultation(rel.id);
                              await profileVM.loadProfile(widget.trainer.id, clientId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Client Approved! Packages unlocked for purchase.')),
                              );
                            }
                          },
                          child: const Text('⚡ Demo Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            CustomButton(
              text: 'Request Consultation 💬',
              isFullWidth: true,
              onPressed: () => _showConsultationDialog(context, profileVM, clientId),
            ),
          ],

          const SizedBox(height: 20),

          // Packages Section
          const Text('Training Packages', style: AppTypography.heading2),
          const SizedBox(height: 8),
          ...profileVM.packages.map((pkg) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FitnessCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(pkg.name, style: AppTypography.heading3)),
                        Text('₹${pkg.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(pkg.description, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${pkg.sessions} Sessions • ${pkg.validityDays} Days Validity', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        CustomButton(
                          text: isApproved ? 'Select & Pay 💳' : 'Requires Approval 🔒',
                          height: 36,
                          variant: isApproved ? ButtonVariant.primary : ButtonVariant.secondary,
                          onPressed: isApproved
                              ? () => _showPurchaseDialog(context, pkg, clientId)
                              : () => _showConsultationDialog(context, profileVM, clientId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // Reviews Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Client Reviews', style: AppTypography.heading2),
              Text('⭐ ${trainer.rating} (${trainer.reviewCount})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.amber)),
            ],
          ),
          const SizedBox(height: 8),
          ...profileVM.reviews.map((rev) {
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
                        Text(rev.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('⭐' * rev.rating, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(rev.comment, style: const TextStyle(fontSize: 11, height: 1.3)),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
