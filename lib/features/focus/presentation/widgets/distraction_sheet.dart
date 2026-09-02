import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/timer_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DistractionSheet extends ConsumerStatefulWidget {
  const DistractionSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const DistractionSheet(),
    );
  }

  @override
  ConsumerState<DistractionSheet> createState() => _DistractionSheetState();
}

class _DistractionSheetState extends ConsumerState<DistractionSheet> {
  String _selectedType = 'Social media';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _noteController.text.trim();
    ref.read(timerServiceProvider).logDistraction(_selectedType, note: note);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged distraction: $_selectedType'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(PhosphorIconsRegular.warningCircle, size: 20, color: AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Log a Distraction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Acknowledge what pulled your attention, log it quickly, and jump right back into focus.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              const Text('Type of Distraction', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 10),

              // Quick Pick Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.distractionPresets.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = type);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              const Text('Note (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Received a phone call from client...',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Log & Resume'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
