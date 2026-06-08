import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';

class BasicInfoPage extends ConsumerStatefulWidget {
  const BasicInfoPage({
    required this.onNext,
    super.key,
    this.initialCity,
    this.initialLocality,
  });

  final void Function(Map<String, dynamic> data) onNext;
  final String? initialCity;
  final String? initialLocality;

  @override
  ConsumerState<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends ConsumerState<BasicInfoPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.initialCity ?? '';
    _localityController.text = widget.initialLocality ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final age = int.tryParse(_ageController.text.trim());
    return _nameController.text.trim().isNotEmpty &&
        age != null &&
        age >= 18 &&
        _professionController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.sm),
            // Step progress
            const FlatmatesStepProgress.dots(currentStep: 2, totalSteps: 4),
            const SizedBox(height: AppSpacing.section),
            Text(locale.basicInfoTitle, style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.basicInfoSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            FlatmatesCard(
              child: Column(
                children: [
                  TextField(
                    key: const Key('onboarding_name'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: locale.fullNameLabel,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('onboarding_age'),
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: locale.ageLabel,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      helperText: locale.ageHelperText,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('onboarding_profession'),
                    controller: _professionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: locale.professionLabel,
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('onboarding_city'),
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: locale.cityLabel,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('onboarding_locality'),
                    controller: _localityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: locale.localityLabel,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
            FlatmatesButton(
              key: const Key('onboarding_basic_info_next'),
              label: locale.onboardingNext,
              fullWidth: true,
              onPressed: _isValid
                  ? () {
                      final age = int.tryParse(_ageController.text.trim());
                      if (age == null) return;
                      widget.onNext({
                        'full_name': _nameController.text.trim(),
                        'age': age,
                        'profession': _professionController.text.trim(),
                        'city': _cityController.text.trim(),
                        'locality': _localityController.text.trim().isEmpty
                            ? null
                            : _localityController.text.trim(),
                      });
                    }
                  : null,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
