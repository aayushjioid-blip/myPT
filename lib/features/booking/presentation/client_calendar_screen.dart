import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/entities/session_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../packages/presentation/packages_view_model.dart';
import '../../packages/presentation/package_selection_dialog.dart';
import 'booking_view_model.dart';

class ClientCalendarScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDiscovery;
  final VoidCallback? onNavigateToWorkouts;

  const ClientCalendarScreen({
    super.key,
    this.onNavigateToDiscovery,
    this.onNavigateToWorkouts,
  });

  @override
  State<ClientCalendarScreen> createState() => _ClientCalendarScreenState();
}

class _ClientCalendarScreenState extends State<ClientCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<BookingViewModel>().loadClientSessions(authVM.currentUser.id);
      context.read<PackagesViewModel>().loadPackagesForClient(authVM.currentUser.id);
    });
  }

  void _showBookingDialog(BuildContext context, String clientId, PackagesViewModel pkgVM, BookingViewModel bookingVM) {
    final activePkg = pkgVM.activePackage;
    if (activePkg == null || activePkg.remainingSessions <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No Active PT Credits', style: AppTypography.heading3),
          content: const Text(
            'You currently have 0 remaining session credits. You can select a new package from your coach or use the instant demo credit button to test booking immediately.',
            style: TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                PackageSelectionDialog.show(
                  context,
                  clientId: clientId,
                  onNavigateToDiscovery: widget.onNavigateToDiscovery,
                  onNavigateToWorkouts: widget.onNavigateToWorkouts,
                );
              },
              child: const Text('Select Package 🛒'),
            ),
              CustomButton(
                text: '⚡ Instant Add 10 Credits',
                onPressed: () async {
                  final pkgRepo = context.read<IPackageRepository>();
                  await pkgRepo.requestPackagePurchase(clientId, 'pkg-10pt', 'UPI-DEMO-AUTO');
                  final payments = await pkgRepo.getPendingPaymentsForTrainer('trn-alex');
                  if (payments.isNotEmpty) {
                    await pkgRepo.verifyPayment(payments.first.id, true);
                  }
                  await pkgVM.loadPackagesForClient(clientId);
                  Navigator.pop(ctx);
                  _showBookingDialog(context, clientId, pkgVM, bookingVM);
                },
              ),
          ],
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00 AM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Book Personal Training Session', style: AppTypography.heading3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trainer: Alex Rivera • Package: ${activePkg.remainingSessions} Credits Available', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                const Text('Select Date & Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (d != null) {
                            setDialogState(() => selectedDate = d);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInput : AppColors.lightInput,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (t != null) {
                            setDialogState(() => selectedTime = t.format(context));
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInput : AppColors.lightInput,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '🛡️ Rule: Booking a session deducts 0 PT credits. Exactly 1 credit is deducted ONLY upon workout completion.',
                    style: TextStyle(fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Request Booking (0 Credits) 📅',
                onPressed: () async {
                  final scheduled = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
                  await bookingVM.requestBooking(
                    clientId: clientId,
                    trainerId: activePkg.trainerId,
                    clientPackageId: activePkg.id,
                    scheduledStart: scheduled,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session booking requested! (0 credits deducted on booking).')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final pkgVM = context.watch<PackagesViewModel>();
    final bookingVM = context.watch<BookingViewModel>();
    final clientId = authVM.currentUser.id;
    final sessions = bookingVM.clientSessions;
    final hasCredits = pkgVM.activeRemainingCredits > 0;

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
                  Text('Personal Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Session Calendar', style: AppTypography.heading1),
                ],
              ),
              CustomButton(
                text: '+ Book PT Session',
                height: 36,
                onPressed: () => _showBookingDialog(context, clientId, pkgVM, bookingVM),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Active Balance Indicator with direct Package Selection trigger
          InkWell(
            onTap: () {
              PackageSelectionDialog.show(
                context,
                clientId: clientId,
                onNavigateToDiscovery: widget.onNavigateToDiscovery,
                onNavigateToWorkouts: widget.onNavigateToWorkouts,
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasCredits ? AppColors.primary.withOpacity(0.08) : AppColors.rose.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: hasCredits ? AppColors.primary.withOpacity(0.3) : AppColors.rose.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE PACKAGE CREDITS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasCredits ? AppColors.primary : AppColors.rose,
                            ),
                          ),
                          Text('${pkgVM.activeRemainingCredits} PT Sessions Remaining', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                      StatusBadge(
                        text: hasCredits ? 'Active' : 'Zero Balance',
                        type: hasCredits ? BadgeType.primary : BadgeType.rose,
                      ),
                    ],
                  ),
                  if (!hasCredits) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Tap to select package, talk to coach or switch', style: TextStyle(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.rose),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sessions List
          const Text('Your Booked Sessions', style: AppTypography.heading2),
          const SizedBox(height: 8),
          if (sessions.isEmpty) ...[
            FitnessCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.darkTextMuted),
                      const SizedBox(height: 8),
                      const Text('No scheduled sessions yet.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      if (!hasCredits) ...[
                        const Text('Select a package or talk to your coach to activate session credits.', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: '⚡ Choose Package & Coach ➔',
                          height: 36,
                          onPressed: () {
                            PackageSelectionDialog.show(
                              context,
                              clientId: clientId,
                              onNavigateToDiscovery: widget.onNavigateToDiscovery,
                              onNavigateToWorkouts: widget.onNavigateToWorkouts,
                            );
                          },
                        ),
                      ] else ...[
                        const Text('Tap "+ Book PT Session" to request a time slot.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            ...sessions.map((sess) {
              BadgeType bType;
              switch (sess.status) {
                case SessionStatus.requested:
                  bType = BadgeType.amber;
                  break;
                case SessionStatus.confirmed:
                  bType = BadgeType.blue;
                  break;
                case SessionStatus.completed:
                  bType = BadgeType.primary;
                  break;
                case SessionStatus.cancelled:
                case SessionStatus.rejected:
                  bType = BadgeType.rose;
                  break;
                default:
                  bType = BadgeType.subtle;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FitnessCard(
                  hasGlow: sess.status == SessionStatus.confirmed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fitness_center, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(sess.sessionType == SessionType.personalTraining ? '1-on-1 PT Session' : 'Own Workout', style: AppTypography.heading3),
                            ],
                          ),
                          StatusBadge(text: sess.status.name.toUpperCase(), type: bType),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Date: ${sess.scheduledStart.month}/${sess.scheduledStart.day} • 10:00 AM - 11:00 AM',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sess.status == SessionStatus.completed
                            ? '✓ Completed • 1 PT credit deducted'
                            : 'Status: ${sess.status.name.toUpperCase()} (0 credits deducted)',
                        style: TextStyle(
                          fontSize: 11,
                          color: sess.status == SessionStatus.completed ? AppColors.primary : AppColors.darkTextMuted,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
