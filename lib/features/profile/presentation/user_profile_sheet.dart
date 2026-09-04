import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../progress/presentation/progress_view_model.dart';

class UserProfileSheet extends StatefulWidget {
  final UserEntity user;

  const UserProfileSheet({super.key, required this.user});

  static void show(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UserProfileSheet(user: user),
    );
  }

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> {
  bool _isEditing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _medicalCtrl;

  late String _selectedAvatar;
  late String _selectedGoal;
  late String _selectedLevel;
  late bool _shareWithTrainer;

  final List<String> _avatars = const [
    '👩', '🏃‍♀️', '🏋️', '🧘', '🥊', '👑', '🏢', '⚡', '🦁', '🔥', '👤', '🦸'
  ];

  final List<String> _goals = const [
    'Fat Loss & Hypertrophy',
    'Strength & Powerlifting',
    'Body Recomposition & Lean Mass',
    'Endurance & Stamina',
    'Athletic Conditioning & Mobility',
  ];

  final List<String> _levels = const [
    'Beginner (0 - 1 years)',
    'Intermediate (1 - 3 years)',
    'Advanced (3+ years)',
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.name);
    _emailCtrl = TextEditingController(text: u.email);
    _phoneCtrl = TextEditingController(text: u.emergencyContact ?? '+1 (555) 019-2834');
    _weightCtrl = TextEditingController(text: (u.weightKg ?? 64.5).toStringAsFixed(1));
    _heightCtrl = TextEditingController(text: (u.heightCm ?? 168.0).toStringAsFixed(0));
    _medicalCtrl = TextEditingController(text: u.medicalInfo ?? 'No severe injuries. Minor lower back tightness.');

    _selectedAvatar = u.avatar;
    if (!_avatars.contains(_selectedAvatar)) {
      _selectedAvatar = _avatars.first;
    }

    _selectedGoal = u.fitnessGoal ?? _goals.first;
    if (!_goals.contains(_selectedGoal)) {
      _selectedGoal = _goals.first;
    }

    _selectedLevel = u.fitnessLevel ?? _levels[1];
    if (!_levels.contains(_selectedLevel)) {
      _selectedLevel = _levels[1];
    }

    _shareWithTrainer = u.sharePersonalInfoWithTrainer;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _medicalCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authVM = context.read<AuthViewModel>();
    final progressVM = context.read<ProgressViewModel>();

    final weight = double.tryParse(_weightCtrl.text) ?? widget.user.weightKg ?? 64.5;
    final height = double.tryParse(_heightCtrl.text) ?? widget.user.heightCm ?? 168.0;

    final updated = widget.user.copyWith(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      avatar: _selectedAvatar,
      fitnessGoal: _selectedGoal,
      fitnessLevel: _selectedLevel,
      weightKg: weight,
      heightCm: height,
      emergencyContact: _phoneCtrl.text.trim(),
      medicalInfo: _medicalCtrl.text.trim(),
      sharePersonalInfoWithTrainer: _shareWithTrainer,
    );

    await authVM.updateUserProfile(updated);

    // Sync weight with progress logger if client
    if (widget.user.role == UserRole.client) {
      await progressVM.logMeasurement(
        clientId: widget.user.id,
        weightKg: weight,
        heightCm: height,
        notes: 'Updated from Profile Settings',
      );
    }

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Profile updated successfully for ${updated.name}!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = widget.user;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header & Mode Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Profile & Info ✏️' : 'User Profile & Settings',
                  style: AppTypography.heading2,
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.visibility_outlined : Icons.edit_note, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  tooltip: _isEditing ? 'View Mode' : 'Edit Profile',
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (!_isEditing) ...[
              // --- VIEW MODE ---
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(u.avatar, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 10),
              Text(u.name, style: AppTypography.heading2),
              Text(
                '${u.email} • ${u.role.name.toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
              ),

              const SizedBox(height: 16),

              // Status Badges Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14181F) : const Color(0xFFEFF3F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn('STATUS', u.status, AppColors.primary),
                    Container(width: 1, height: 26, color: AppColors.darkBorder),
                    _buildMetricColumn('FACILITY', 'IronCore Gym', Colors.white),
                    Container(width: 1, height: 26, color: AppColors.darkBorder),
                    _buildMetricColumn('MEMBER ID', u.id.substring(0, u.id.length > 8 ? 8 : u.id.length).toUpperCase(), AppColors.blue),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Fitness & Health Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14181F) : const Color(0xFFEFF3F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FITNESS & HEALTH METRICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 10),
                    _buildDetailRow('🎯 Primary Goal', u.fitnessGoal ?? 'Fat Loss & Hypertrophy'),
                    const SizedBox(height: 6),
                    _buildDetailRow('⚡ Experience Level', u.fitnessLevel ?? 'Intermediate (1-3 yrs)'),
                    const SizedBox(height: 6),
                    _buildDetailRow('⚖️ Current Weight', '${(u.weightKg ?? 64.5).toStringAsFixed(1)} kg'),
                    const SizedBox(height: 6),
                    _buildDetailRow('📏 Height', '${(u.heightCm ?? 168.0).toStringAsFixed(0)} cm'),
                    const SizedBox(height: 6),
                    _buildDetailRow('📞 Contact / Phone', u.emergencyContact ?? '+1 (555) 019-2834'),
                    const SizedBox(height: 6),
                    _buildDetailRow('🩹 Medical Notes', u.medicalInfo ?? 'None recorded'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                      label: const Text('Edit Basic Info ✏️', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // --- EDIT MODE ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose Avatar:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _avatars.map((av) {
                    final isSel = _selectedAvatar == av;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = av),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? AppColors.primary.withOpacity(0.25) : Colors.transparent,
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.darkBorder, width: 2),
                        ),
                        child: Text(av, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              CustomTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                hint: 'e.g. Sarah Jenkins',
              ),
              const SizedBox(height: 10),

              CustomTextField(
                label: 'Email Address',
                controller: _emailCtrl,
                hint: 'e.g. sarah.jenkins@fitapp.dev',
              ),
              const SizedBox(height: 10),

              // Goal Selector Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: InputDecoration(
                  labelText: 'Primary Fitness Goal',
                  filled: true,
                  fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedGoal = v);
                },
              ),
              const SizedBox(height: 10),

              // Level Selector Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: InputDecoration(
                  labelText: 'Fitness Experience Level',
                  filled: true,
                  fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedLevel = v);
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Weight (kg)',
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: '64.5',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Height (cm)',
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: '168',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              CustomTextField(
                label: 'Phone / Emergency Contact',
                controller: _phoneCtrl,
                hint: '+1 (555) 019-2834',
              ),
              const SizedBox(height: 10),

              CustomTextField(
                label: 'Medical & Injury Notes',
                controller: _medicalCtrl,
                maxLines: 2,
                hint: 'e.g. Lower back tightness, asthma, none',
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text('Share Health Details with Trainer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Allows your coach to personalize workouts safely.', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                value: _shareWithTrainer,
                onChanged: (val) => setState(() => _shareWithTrainer = val),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Save Changes ✓',
                      onPressed: _saveProfile,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: valColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted)),
        ),
        Expanded(
          child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
