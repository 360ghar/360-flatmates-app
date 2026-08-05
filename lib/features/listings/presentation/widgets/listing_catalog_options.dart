import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';

/// Catalog option lookups for the create-listing form.
///
/// Business metadata is server-driven via `/flatmates/catalogs`, so these read
/// from bootstrap first and only fall back to bundled strings when the server
/// sent nothing for a key. Extracted from `create_listing_page.dart` to keep
/// that page under the 500-line limit; they need only a [WidgetRef] and an
/// [AppLocalizations], no form state.

/// Server-provided options for [key], falling back to bundled defaults.
List<CatalogOption> listingCatalog(
  WidgetRef ref,
  AppLocalizations locale,
  String key,
) {
  final options =
      ref.watch(bootstrapControllerProvider).valueOrNull?.catalogOptions(key) ??
      const <CatalogOption>[];
  if (options.isNotEmpty) return options;
  return listingCatalogFallback(locale, key);
}

/// Bundled defaults for the two catalogs the backend may not populate.
List<CatalogOption> listingCatalogFallback(
  AppLocalizations locale,
  String key,
) {
  return switch (key) {
    'flatmates_kitchen_types' => [
      CatalogOption(id: 'vegetarian', label: locale.kitchenTypeVegetarian),
      CatalogOption(
        id: 'non_vegetarian',
        label: locale.kitchenTypeNonVegetarian,
      ),
      CatalogOption(id: 'eggetarian', label: locale.kitchenTypeEggetarian),
      CatalogOption(id: 'any', label: locale.kitchenTypeAny),
    ],
    'flatmates_ventilation_options' => [
      CatalogOption(id: 'good', label: locale.ventilationGood),
      CatalogOption(id: 'average', label: locale.ventilationAverage),
      CatalogOption(id: 'poor', label: locale.ventilationPoor),
    ],
    _ => const [],
  };
}

/// Display label for [id] within catalog [key].
///
/// An id with no matching option is humanized rather than shown raw, so a new
/// server enum still reads sensibly.
String listingCatalogLabel(
  WidgetRef ref,
  AppLocalizations locale,
  String key,
  String id,
) {
  return listingCatalog(ref, locale, key)
      .firstWhere(
        (o) => o.id == id,
        orElse: () => CatalogOption(id: id, label: humanizeFlatmatesToken(id)),
      )
      .label;
}
