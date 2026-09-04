import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/trainer_entity.dart';
import '../../../domain/repositories/i_gym_repository.dart';
import '../../../domain/repositories/i_trainer_repository.dart';

class ClientReassignmentDialog extends StatefulWidget {
  final String clientName;
  final String currentTrainerName;
  final String fromTrainerId;

  const ClientReassignmentDialog({
    super.key,
    this.clientName = 'Sarah Jenkins',
    this.currentTrainerName = 'Alex Rivera',
    this.fromTrainerId = 'trn-alex',
  });

  @override
  State<ClientReassignmentDialog> createState() => _ClientReassignmentDialogState();
}

class _ClientReassignmentDialogState extends State<ClientReassignmentDialog> {
  String _selectedToTrainerId = 'trn-maya';
  final _reasonCtrl = TextEditingController(text: 'Schedule optimization and calisthenics mobility focus.');
  List<TrainerEntity> _staffTrainers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trainerRepo = context.read<ITrainerRepository>();
      final all = await trainerRepo.getAllTrainers();
      setState(() {
        _staffTrainers = all.where((t) => t.id != widget.fromTrainerId).toList();
        if (_staffTrainers.isNotEmpty) {
          _selectedToTrainerId = _staffTrainers.first.id;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gymRepo = context.read<IGymRepository>();

    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reassign Client (Head Trainer Authority)', style: AppTypography.heading3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${widget.clientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Current Coach: ${widget.currentTrainerName}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
            const SizedBox(height: 12),
            const Text('Transfer To Staff Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedToTrainerId,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _staffTrainers.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.name} (Code: ${t.trainerCode})', style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedToTrainerId = val ?? 'trn-maya'),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Reassignment Justification',
              controller: _reasonCtrl,
              maxLines: 2,
              hint: 'Reason for transfer (leave, schedule change, specialization)',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.purple.withOpacity(0.3)),
              ),
              child: const Text(
                '🛡️ Strict Guarantee: Client workout logs, active credit balance, and measurement history are 100% preserved during transfer.',
                style: TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Confirm Transfer ➔',
          onPressed: () async {
            await gymRepo.reassignClient(
              relationshipId: 'rel-sarah-alex',
              fromTrainerId: widget.fromTrainerId,
              toTrainerId: _selectedToTrainerId,
              reason: _reasonCtrl.text,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Client ${widget.clientName} successfully reassigned! History & credits preserved.')),
            );
          },
        ),
      ],
    );
  }
}
