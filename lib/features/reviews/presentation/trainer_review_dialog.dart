import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/repositories/i_trainer_repository.dart';
import '../../auth/presentation/auth_view_model.dart';

class TrainerReviewDialog extends StatefulWidget {
  final String trainerId;
  final String trainerName;

  const TrainerReviewDialog({
    super.key,
    required this.trainerId,
    required this.trainerName,
  });

  @override
  State<TrainerReviewDialog> createState() => _TrainerReviewDialogState();
}

class _TrainerReviewDialogState extends State<TrainerReviewDialog> {
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController(text: 'Alex is an exceptional coach! Very knowledgeable on hypertrophy and form correction.');

  @override
  Widget build(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final trainerRepo = context.read<ITrainerRepository>();
    final user = authVM.currentUser;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Rate & Review ${widget.trainerName}', style: AppTypography.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Rating (1 to 5 Stars)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              return IconButton(
                icon: Icon(
                  starNum <= _selectedRating ? Icons.star : Icons.star_border,
                  color: AppColors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _selectedRating = starNum),
              );
            }),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Written Review & Feedback',
            controller: _commentCtrl,
            maxLines: 3,
            hint: 'Describe your coaching experience, workouts, progress',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Submit Review ⭐',
          onPressed: () async {
            final review = ReviewEntity(
              id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
              trainerId: widget.trainerId,
              clientId: user.id,
              clientName: user.name,
              rating: _selectedRating,
              comment: _commentCtrl.text,
              createdAt: DateTime.now(),
            );

            await trainerRepo.addReview(review);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Review submitted for ${widget.trainerName}! Rating: $_selectedRating ⭐')),
            );
          },
        ),
      ],
    );
  }
}
