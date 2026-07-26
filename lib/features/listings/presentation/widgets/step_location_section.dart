import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';

/// Step 0 — Location (society, address, city, locality).
class StepLocationSection extends StatelessWidget {
  const StepLocationSection({
    required this.societyController,
    required this.addressController,
    required this.cityController,
    required this.localityController,
    required this.onChanged,
    this.showSocietyValidation = false,
    this.showCityValidation = false,
    this.showLocalityValidation = false,
    super.key,
  });

  final TextEditingController societyController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController localityController;
  final VoidCallback onChanged;
  final bool showSocietyValidation;
  final bool showCityValidation;
  final bool showLocalityValidation;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('listing_society_input'),
            controller: societyController,
            decoration: InputDecoration(
              labelText: locale.societyBuildingLabel,
              hintText: locale.societyBuildingHint,
              prefixIcon: const Icon(Icons.apartment_outlined),
              errorText: showSocietyValidation ? locale.fieldRequired : null,
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: locale.fullAddressLabel,
              hintText: locale.fullAddressHint,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('listing_city_input'),
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: locale.cityLabel,
                    errorText: showCityValidation ? locale.fieldRequired : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextFormField(
                  key: const Key('listing_locality_input'),
                  controller: localityController,
                  decoration: InputDecoration(
                    labelText: locale.localityLabel,
                    errorText: showLocalityValidation
                        ? locale.fieldRequired
                        : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
