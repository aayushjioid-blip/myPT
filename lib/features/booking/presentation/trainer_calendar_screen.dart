import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/entities/session_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../workouts/presentation/live_workout_logger_dialog.dart';
import 'booking_view_model.dart';

class TrainerCalendarScreen extends StatefulWidget {
  const TrainerCalendarScreen({super.key});

  @override
  State<TrainerCalendarScreen> createState() => _TrainerCalendarScreenState();
}

class _TrainerCalendarScreenState extends State<TrainerCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<BookingViewModel>().loadTrainerSessions(authVM.currentUser.id == 'usr-trn-1' ? 'trn-alex' : 'trn-alex');
    });
  }

  void _showScheduleClientSessionDialog(BuildContext context, BookingViewModel bookingVM) {
    String selectedClientId = 'usr-client-1';
    String selectedClientName = 'Sarah Jenkins';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00 AM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Schedule Session with Client', style: AppTypography.heading3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedClientId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'usr-client-1', child: Text('Sarah Jenkins (Active Client)')),
                    DropdownMenuItem(value: 'usr-client-2', child: Text('David Kim (Active Client)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedClientId = val;
                        selectedClientName = val == 'usr-client-1' ? 'Sarah Jenkins' : 'David Kim';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Date & Time Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                const SizedBox(height: 10),
                const Text(
                  '🛡️ Note: Scheduling consumes 0 credits. Exactly 1 credit is deducted when the session is logged and completed.',
                  style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Schedule Session 📅',
                onPressed: () async {
                  final scheduled = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
                  await bookingVM.requestBooking(
                    clientId: selectedClientId,
                    trainerId: 'trn-alex',
                    clientPackageId: 'cpkg-seed-$selectedClientId',
                    scheduledStart: scheduled,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✓ Session scheduled with $selectedClientName!')),
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
    final bookingVM = context.watch<BookingViewModel>();
    final sessions = bookingVM.trainerSessions;

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
                  Text('Trainer Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                  Text('Session Management', style: AppTypography.heading1),
                ],
              ),
              CustomButton(
                text: '+ Schedule Session',
                height: 36,
                onPressed: () => _showScheduleClientSessionDialog(context, bookingVM),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Policy & Slot Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Text('ℹ️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Policy: 4-Hour Cancellation Policy active. Booking acceptance deducts 0 credits. Exactly 1 credit is deducted upon session completion.',
                    style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('Upcoming & Requested Sessions', style: AppTypography.heading2),
          const SizedBox(height: 8),

          if (sessions.isEmpty) ...[
            FitnessCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.darkTextMuted),
                      SizedBox(height: 8),
                      Text('No session requests at the moment.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            ...sessions.map((sess) {
              final isRequested = sess.status == SessionStatus.requested;
              final isConfirmed = sess.status == SessionStatus.confirmed;
              final isCompleted = sess.status == SessionStatus.completed;

              BadgeType bType;
              if (isRequested) {
                bType = BadgeType.amber;
              } else if (isConfirmed) {
                bType = BadgeType.blue;
              } else if (isCompleted) {
                bType = BadgeType.primary;
              } else {
                bType = BadgeType.rose;
              }

              final clientName = sess.clientId == 'usr-client-2' ? 'David Kim' : 'Sarah Jenkins';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FitnessCard(
                  hasGlow: isRequested || isConfirmed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary,
                                child: Text(clientName[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                              ),
                              const SizedBox(width: 8),
                              Text('$clientName • 1-on-1 PT', style: AppTypography.heading3),
                            ],
                          ),
                          StatusBadge(text: sess.status.name.toUpperCase(), type: bType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scheduled: ${sess.scheduledStart.month}/${sess.scheduledStart.day} at 10:00 AM - 11:00 AM',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                            ? '✓ Session Completed • 1 PT Credit Deducted'
                            : 'Credits consumed: 0 (Deducted only upon session completion)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted ? AppColors.primary : AppColors.darkTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isRequested) ...[
                            CustomButton(
                              text: 'Accept Booking (0 Credits) 🗓️',
                              height: 36,
                              onPressed: () async {
                                await bookingVM.acceptBooking(sess.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Booking Confirmed! (0 credits deducted).')),
                                );
                              },
                            ),
                          ] else if (isConfirmed) ...[
                            CustomButton(
                              text: 'Start Session & Log Sets ⏱️',
                              height: 38,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => LiveWorkoutLoggerDialog(session: sess, clientName: clientName),
                                );
                              },
                            ),
                          ],
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
    );
  }
}
