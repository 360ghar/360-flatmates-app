import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class MapFilterBar extends StatelessWidget {
  const MapFilterBar({
    required this.budgetMin,
    required this.budgetMax,
    required this.roomType,
    required this.moveInFilter,
    required this.genderPref,
    required this.verifiedOnly,
    required this.onBudgetChanged,
    required this.onRoomTypeChanged,
    required this.onMoveInChanged,
    required this.onGenderChanged,
    required this.onVerifiedChanged,
    super.key,
  });

  final double budgetMin;
  final double budgetMax;
  final String roomType;
  final String moveInFilter;
  final String genderPref;
  final bool verifiedOnly;
  final void Function(double, double) onBudgetChanged;
  final void Function(String) onRoomTypeChanged;
  final void Function(String) onMoveInChanged;
  final void Function(String) onGenderChanged;
  final void Function(bool) onVerifiedChanged;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FlatmatesChip(
              icon: Icons.currency_rupee_rounded,
              label:
                  '₹${budgetMin.toStringAsFixed(0)}-₹${budgetMax.toStringAsFixed(0)}',
              selected: budgetMin != 5000 || budgetMax != 100000,
              onSelected: (_) => _showBudgetDialog(context),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.sharingPrivateRoom,
              selected: roomType == 'private_room',
              onSelected: (_) => onRoomTypeChanged(
                roomType == 'private_room' ? 'all' : 'private_room',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.sharingSharedRoom,
              selected: roomType == 'shared_room',
              onSelected: (_) => onRoomTypeChanged(
                roomType == 'shared_room' ? 'all' : 'shared_room',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.genderAny,
              selected: genderPref == 'any',
              onSelected: (_) => onGenderChanged('any'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.timelineImmediate,
              selected: moveInFilter == 'immediate',
              onSelected: (_) => onMoveInChanged(
                moveInFilter == 'immediate' ? 'all' : 'immediate',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.moveInThisMonth,
              selected: moveInFilter == 'this_month',
              onSelected: (_) => onMoveInChanged(
                moveInFilter == 'this_month' ? 'all' : 'this_month',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.moveInNextMonth,
              selected: moveInFilter == 'next_month',
              onSelected: (_) => onMoveInChanged(
                moveInFilter == 'next_month' ? 'all' : 'next_month',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              label: locale.timelineFlexible,
              selected: moveInFilter == 'all',
              onSelected: (_) => onMoveInChanged('all'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FlatmatesChip(
              icon: Icons.verified_outlined,
              label: locale.verifiedFilterLabel,
              selected: verifiedOnly,
              onSelected: (_) => onVerifiedChanged(!verifiedOnly),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final locale = AppLocalizations.of(context);
    double min = budgetMin;
    double max = budgetMax;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(locale.monthlyBudgetLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RangeSlider(
                values: RangeValues(min, max),
                min: 5000,
                max: 100000,
                divisions: 19,
                labels: RangeLabels(
                  '₹${min.toStringAsFixed(0)}',
                  '₹${max.toStringAsFixed(0)}',
                ),
                onChanged: (v) => setDialogState(() {
                  min = v.start;
                  max = v.end;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.cancelCta),
            ),
            FlatmatesButton(
              label: locale.commonSave,
              onPressed: () {
                onBudgetChanged(min, max);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
