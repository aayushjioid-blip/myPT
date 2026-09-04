import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fitness_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../../data/mock/mock_data_store.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'package:fittrainer/features/trainer_packages/presentation/package_builder_dialog.dart';

class TrainerPackagesScreen extends StatefulWidget {
  const TrainerPackagesScreen({super.key});

  @override
  State<TrainerPackagesScreen> createState() => _TrainerPackagesScreenState();
}

class _TrainerPackagesScreenState extends State<TrainerPackagesScreen> {
  List<PackageEntity> _packages = [];
  bool _isLoading = false;
  StreamSubscription? _dataStoreSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackages();
      try {
        final dataStore = context.read<MockDataStore>();
        _dataStoreSub = dataStore.stateChanges.listen((_) {
          if (mounted) {
            _loadPackages();
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _dataStoreSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authVM = context.read<AuthViewModel>();
    final pkgRepo = context.read<IPackageRepository>();
    final trainerId = authVM.currentUser.id == 'usr-trn-1' ? 'trn-alex' : authVM.currentUser.id;
    final list = await pkgRepo.getPackagesByTrainerId(trainerId);
    if (mounted) {
      setState(() {
        _packages = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final pkgRepo = context.read<IPackageRepository>();
    final trainerId = authVM.currentUser.id == 'usr-trn-1' ? 'trn-alex' : authVM.currentUser.id;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPackages,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pricing & Products', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted)),
                    Text('Training Packages', style: AppTypography.heading1),
                  ],
                ),
                CustomButton(
                  text: '+ New Package',
                  height: 36,
                  onPressed: () async {
                    final created = await showDialog<bool>(
                      context: context,
                      builder: (_) => PackageBuilderDialog(trainerId: trainerId, packageRepo: pkgRepo),
                    );
                    if (created == true && mounted) {
                      await _loadPackages();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ New Training Package published and live for clients!')),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isLoading && _packages.isEmpty) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ] else if (_packages.isEmpty) ...[
              FitnessCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.darkTextMuted),
                        SizedBox(height: 10),
                        Text('No training packages created yet.', style: TextStyle(color: AppColors.darkTextMuted, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Tap "+ New Package" above to create your first PT package.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ..._packages.map((pkg) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FitnessCard(
                    hasGlow: true,
                    borderColor: AppColors.primary.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(pkg.name, style: AppTypography.heading3),
                            ),
                            Text('\$${pkg.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        if (pkg.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(pkg.description, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted, height: 1.3)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${pkg.sessions} PT Sessions • ${pkg.validityDays} Days Validity',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const StatusBadge(text: 'Active Product', type: BadgeType.primary),
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
