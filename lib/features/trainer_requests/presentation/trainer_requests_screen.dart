import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/repositories/i_package_repository.dart';
import 'trainer_requests_view_model.dart';

class TrainerRequestsScreen extends StatefulWidget {
  const TrainerRequestsScreen({super.key});

  @override
  State<TrainerRequestsScreen> createState() => _TrainerRequestsScreenState();
}

class _TrainerRequestsScreenState extends State<TrainerRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainerRequestsViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestsVM = context.watch<TrainerRequestsViewModel>();
    final consultations = requestsVM.pendingConsultations;
    final payments = requestsVM.pendingPayments;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => requestsVM.refresh(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inbound Queue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                    Text('Requests & Payments', style: AppTypography.heading1),
                  ],
                ),
                StatusBadge(
                  text: '${requestsVM.totalPendingCount} Pending',
                  type: requestsVM.totalPendingCount > 0 ? BadgeType.amber : BadgeType.primary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SECTION 1: Pending Consultation Requests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1. Consultation Requests', style: AppTypography.heading2),
                if (consultations.isNotEmpty)
                  StatusBadge(text: '${consultations.length} New', type: BadgeType.amber),
              ],
            ),
            const SizedBox(height: 8),
            if (consultations.isEmpty) ...[
              FitnessCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text('No pending consultation requests.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final pkgRepo = context.read<IPackageRepository>();
                            await pkgRepo.requestConsultation(
                              clientId: 'usr-client-1',
                              trainerId: 'trn-alex',
                              goals: 'Athletic Hypertrophy & Core Stability',
                              notes: 'Looking to start next week with 10-session pack.',
                            );
                            await requestsVM.refresh();
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Simulate Inbound Consultation Request', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...consultations.map((rel) {
                final client = requestsVM.getUserById(rel.clientId);
                final clientName = client?.name ?? 'Sarah Jenkins';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FitnessCard(
                    hasGlow: true,
                    borderColor: AppColors.blue.withOpacity(0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.blue.withOpacity(0.2),
                                  child: Text(clientName[0], style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text(clientName, style: AppTypography.heading3),
                              ],
                            ),
                            const StatusBadge(text: 'Consultation', type: BadgeType.blue),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Goal: "${rel.goals}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                        if (rel.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Notes: ${rel.notes}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomButton(
                              text: 'Accept Client 🤝',
                              height: 36,
                              onPressed: () async {
                                await requestsVM.acceptConsultation(rel.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Accepted $clientName! Client can now purchase training packages.')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),

            // SECTION 2: Pending Offline Payment Verification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('2. Payment Verification Queue', style: AppTypography.heading2),
                if (payments.isNotEmpty)
                  StatusBadge(text: '${payments.length} Pending', type: BadgeType.primary),
              ],
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty) ...[
              FitnessCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('No pending payments to verify.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                  ),
                ),
              ),
            ] else ...[
              ...payments.map((pay) {
                final client = requestsVM.getUserById(pay.clientId);
                final clientName = client?.name ?? 'Sarah Jenkins';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FitnessCard(
                    hasGlow: true,
                    borderColor: AppColors.amber.withOpacity(0.5),
                    backgroundColor: AppColors.amber.withOpacity(0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Offline Payment • $clientName', style: AppTypography.heading3),
                            Text('₹${pay.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Transaction Ref: ${pay.transactionRef}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const Text('Method: Manual UPI / Bank Transfer', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Action: Activates +10 PT Credits',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            CustomButton(
                              text: 'Verify & Activate (+10) ✓',
                              height: 36,
                              onPressed: () async {
                                await requestsVM.verifyPayment(pay.id, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Payment Verified! Package activated with +10 PT session credits.')),
                                );
                              },
                            ),
                          ],
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
