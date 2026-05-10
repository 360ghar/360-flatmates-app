This file is a merged representation of a subset of the codebase, containing specifically included files and files not matching ignore patterns, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: lib/**/*.dart, test/**/*.dart, pubspec.yaml, pubspec.lock, analysis_options.yaml, l10n.yaml, .fvmrc, .env.example, CLAUDE.md, AGENTS.md, DESIGN.md, docs/prd.md, maestro/**, .maestro/**
- Files matching these patterns are excluded: lib/l10n/gen/**, build/**, .dart_tool/**, .ruff_cache/**, .factory/**, .agents/**, .claude/**, .idea/**, .git/**, android/**, ios/**, assets/illustrations/**, docs/ui_screens/**, .env, *.iml, deliverables/**, skills-lock.json
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
.maestro/
  config.yaml
  flatmates_e2e.yaml
docs/
  prd.md
lib/
  app/
    router/
      app_router.dart
    app_shell.dart
    app.dart
  core/
    compatibility/
      compatibility_engine.dart
      compatibility_ring.dart
    config/
      app_config.dart
      constants.dart
      env_loader.dart
    deep_links/
      deep_link_service.dart
    network/
      interceptors/
        auth_interceptor.dart
        error_interceptor.dart
      api_client.dart
      auth_token_provider.dart
      connectivity_monitor.dart
    notifications/
      notification_service.dart
    storage/
      app_preferences.dart
      auth_token_storage.dart
      image_upload_service.dart
      secure_kv_store.dart
    theme/
      app_palette.dart
      app_theme.dart
    utils/
      debouncer.dart
    providers.dart
  features/
    auth/
      data/
        auth_repository.dart
      presentation/
        enter_phone_page.dart
        login_page.dart
        otp_page.dart
        signup_page.dart
        splash_page.dart
      auth_controller.dart
    bootstrap/
      bootstrap_controller.dart
      catalog_helpers.dart
    chats/
      chat_thread_page.dart
      chats_repository.dart
      conversations_page.dart
      match_qna_nudge.dart
    discover/
      discover_page.dart
      discover_repository.dart
      flat_details_page.dart
      map_view_page.dart
      search_filters_page.dart
      share_listing_card.dart
    listings/
      create_listing_page.dart
      listing_under_review_page.dart
      listings_repository.dart
      manage_listing_page.dart
    notifications/
      notifications_page.dart
      notifications_repository.dart
    onboarding/
      basic_info_page.dart
      budget_timeline_page.dart
      lifestyle_quiz_page.dart
      location_selection_page.dart
      mode_selection_page.dart
      non_negotiables_page.dart
      onboarding_controller.dart
      onboarding_page.dart
      onboarding_splash_pages.dart
      preferences_page.dart
      profile_photo_page.dart
      waitlist_page.dart
    profile/
      edit_profile_page.dart
      help_safety_page.dart
      profile_page.dart
      profile_repository.dart
    settings/
      blocked_users_page.dart
      change_password_page.dart
      settings_controller.dart
      settings_page.dart
    shared/
      presentation/
        flatmates_ui.dart
    swipe/
      match_celebration_screen.dart
      match_qna_nudge.dart
      swipe_deck_page.dart
      swipe_repository.dart
    visits/
      schedule_visit_page.dart
      visits_page.dart
      visits_repository.dart
  bootstrap.dart
  main.dart
maestro/
  e2e.yaml
test/
  helpers/
    test_helpers.dart
  auth_test.dart
  compatibility_test.dart
  onboarding_test.dart
  settings_test.dart
  widget_test.dart
.env.example
.fvmrc
AGENTS.md
analysis_options.yaml
CLAUDE.md
DESIGN.md
l10n.yaml
pubspec.lock
pubspec.yaml
```

# Files

## File: lib/core/deep_links/deep_link_service.dart
````dart
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Parses incoming HTTP deep links and routes them via GoRouter.
///
/// Supported paths:
///   /flatmates/listing/{id}  → /flat-details/{id}
///   /flatmates/chat/{id}     → /chats/{id}
class DeepLinkService {
  DeepLinkService({required GoRouter router}) : _router = router;

  final GoRouter _router;
  StreamSubscription<Uri>? _linkSubscription;
  AppLinks? _appLinks;

  /// Start listening for incoming deep links.
  ///
  /// Call this once the widget tree is mounted (e.g. in `initState` of the
  /// root App widget). On web, AppLinks does not produce a stream, so we
  /// skip the listener to avoid runtime errors.
  void init() {
    if (kIsWeb) return;

    _appLinks = AppLinks();

    // Handle the initial link that opened the app (cold start).
    _appLinks!.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle links received while the app is already running (warm start).
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint('[DeepLinkService] Link stream error: $error');
      },
    );
  }

  /// Stop listening. Call from `dispose`.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// Map an incoming URI to an internal GoRouter path and navigate.
  void _handleDeepLink(Uri uri) {
    debugPrint('[DeepLinkService] Incoming deep link: $uri');
    final path = _mapPath(uri);
    if (path != null) {
      debugPrint('[DeepLinkService] Routing to: $path');
      _router.push(path);
    } else {
      debugPrint('[DeepLinkService] No mapping for path: ${uri.path}');
    }
  }

  /// Converts an external URI path to an internal GoRouter path.
  ///
  /// Returns `null` if the path does not match any known pattern.
  static String? _mapPath(Uri uri) {
    final pathSegments = uri.pathSegments;

    // /flatmates/listing/{id} → /flat-details/{id}
    if (pathSegments.length >= 3 &&
        pathSegments[0] == 'flatmates' &&
        pathSegments[1] == 'listing') {
      final id = pathSegments[2];
      if (_isNumeric(id)) return '/flat-details/$id';
    }

    // /flatmates/chat/{id} → /chats/{id}
    if (pathSegments.length >= 3 &&
        pathSegments[0] == 'flatmates' &&
        pathSegments[1] == 'chat') {
      final id = pathSegments[2];
      if (_isNumeric(id)) return '/chats/$id';
    }

    return null;
  }

  /// Builds a public deep link URL for a listing.
  static String listingUrl(int listingId) =>
      'https://the360ghar.com/flatmates/listing/$listingId';

  /// Builds a public deep link URL for a chat.
  static String chatUrl(int chatId) =>
      'https://the360ghar.com/flatmates/chat/$chatId';

  static bool _isNumeric(String s) => int.tryParse(s) != null;
}
````

## File: lib/core/network/connectivity_monitor.dart
````dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that streams connectivity changes and maps them to a boolean.
///
/// `true` means the device has at least one connected network
/// (WiFi, mobile, ethernet, etc.). `false` means none.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

/// A thin banner that appears at the top of the app when the device is offline.
///
/// Place it as the first child of a [Stack] wrapping [MaterialApp.router].
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.valueOrNull ?? true; // default to online

    if (isOnline) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Theme.of(context).colorScheme.error,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are offline. Check your connection.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/bootstrap/catalog_helpers.dart
````dart
import 'bootstrap_controller.dart';

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.label,
    this.meta = const {},
  });

  final String id;
  final String label;
  final Map<String, dynamic> meta;
}

extension FlatmatesCatalogs on BootstrapData {
  CatalogEntryModel? catalog(String key) {
    for (final entry in catalogs) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  List<CatalogOption> catalogOptions(String key) {
    final payload = catalog(key)?.payload;
    final rawItems = payload?['items'];
    if (rawItems is! List) return const [];

    return rawItems
        .map((item) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = (map['id'] ?? map['value'] ?? map['key'] ?? map['label'])
                ?.toString()
                .trim();
            final label = (map['label'] ?? map['name'] ?? id)
                ?.toString()
                .trim();
            if (id == null || id.isEmpty || label == null || label.isEmpty) {
              return null;
            }
            return CatalogOption(id: id, label: label, meta: map);
          }
          final label = item.toString().trim();
          return label.isEmpty ? null : CatalogOption(id: label, label: label);
        })
        .whereType<CatalogOption>()
        .toList(growable: false);
  }
}
````

## File: lib/features/discover/search_filters_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'discover_repository.dart';

class SearchFiltersPage extends ConsumerStatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  ConsumerState<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends ConsumerState<SearchFiltersPage> {
  final _searchController = TextEditingController();
  String? _selectedLocation;

  // Budget filter
  static const double _budgetMin = 5000;
  static const double _budgetMax = 100000;
  RangeValues _budgetValues = const RangeValues(5000, 50000);

  // Room type filter: null = Any
  String? _selectedRoomType; // 'private' | 'shared' | null

  // Furnishing filter: null = Any
  String? _selectedFurnishing; // 'furnished' | 'unfurnished' | null

  // Gender filter: null = Any
  String? _selectedGender; // 'male' | 'female' | null

  // Move-in filter: null = Anytime
  String? _selectedMoveIn; // 'immediate' | 'this_month' | 'next_month' | null

  // More filters
  String? _selectedPets; // 'yes' | 'no' | null (null = no preference)
  String? _selectedSmoking; // 'yes' | 'no' | null (null = no preference)

  /// Resolve a catalog's options as a list of (id, label) pairs.
  /// Falls back to hardcoded keys with localized labels when catalog is empty.
  List<({String id, String label})> _catalogOrFallback(
    String catalogKey,
    List<String> fallbackIds,
  ) {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(catalogKey);
    final locale = AppLocalizations.of(context);
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions
          .map((opt) => (id: opt.id, label: opt.label))
          .toList();
    }
    // Build fallback with localized labels
    return fallbackIds
        .map((id) => (id: id, label: _localizedLabel(locale, catalogKey, id)))
        .toList();
  }

  /// Resolve localized label for fallback filter option keys.
  String _localizedLabel(
    AppLocalizations locale,
    String catalogKey,
    String id,
  ) {
    switch (catalogKey) {
      case 'flatmates_room_types':
        return switch (id) {
          'any' => locale.roomTypeAny,
          'private' => locale.roomTypePrivate,
          'shared' => locale.roomTypeShared,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_furnishing':
        return switch (id) {
          'any' => locale.furnishingAny,
          'furnished' => locale.furnishingFurnished,
          'unfurnished' => locale.furnishingUnfurnished,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_gender_options':
        return switch (id) {
          'any' => locale.genderFilterAny,
          'male' => locale.genderFilterMale,
          'female' => locale.genderFilterFemale,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_move_in_timelines':
        return switch (id) {
          'any' => locale.moveInAnytime,
          'immediate' => locale.moveInImmediate,
          'this_month' => locale.moveInThisMonth,
          'next_month' => locale.moveInNextMonth,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_pets_options':
        return switch (id) {
          'no_preference' => locale.petsNoPreference,
          'yes' => locale.petsYes,
          'no' => locale.petsNo,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_smoking_options':
        return switch (id) {
          'no_preference' => locale.smokingNoPreference,
          'no' => locale.smokingNo,
          'yes' => locale.smokingYes,
          _ => humanizeFlatmatesToken(id),
        };
      default:
        return humanizeFlatmatesToken(id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatBudget(double value) {
    if (value >= 100000) {
      return '₹1,00,000+';
    }
    final intPart = value.round();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?=\d{3})($|\D))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted';
  }

  String? _roomTypeSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedRoomType == null) return locale.roomTypeAny;
    if (_selectedRoomType == 'private') return locale.roomTypePrivate;
    if (_selectedRoomType == 'shared') return locale.roomTypeShared;
    return null;
  }

  String? _furnishingSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedFurnishing == null) return locale.furnishingAny;
    if (_selectedFurnishing == 'furnished') return locale.furnishingFurnished;
    if (_selectedFurnishing == 'unfurnished') {
      return locale.furnishingUnfurnished;
    }
    return null;
  }

  String? _genderSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedGender == null) return locale.genderFilterAny;
    if (_selectedGender == 'male') return locale.genderFilterMale;
    if (_selectedGender == 'female') return locale.genderFilterFemale;
    return null;
  }

  String? _moveInSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedMoveIn == null) return locale.moveInAnytime;
    if (_selectedMoveIn == 'immediate') return locale.moveInImmediate;
    if (_selectedMoveIn == 'this_month') return locale.moveInThisMonth;
    if (_selectedMoveIn == 'next_month') return locale.moveInNextMonth;
    return null;
  }

  String? _petsSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedPets == null) return locale.petsNoPreference;
    if (_selectedPets == 'yes') return locale.petsYes;
    if (_selectedPets == 'no') return locale.petsNo;
    return null;
  }

  String? _smokingSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedSmoking == null) return locale.smokingNoPreference;
    if (_selectedSmoking == 'yes') return locale.smokingYes;
    if (_selectedSmoking == 'no') return locale.smokingNo;
    return null;
  }

  String? _normalizedSharingType() {
    return switch (_selectedRoomType) {
      'private' || 'private_room' || 'master_bedroom' => 'private_room',
      'shared' || 'shared_room' => 'shared_room',
      _ => null,
    };
  }

  String? _normalizedGenderPreference() {
    return switch (_selectedGender) {
      'male' || 'male_only' => 'male',
      'female' || 'female_only' => 'female',
      'any' || 'no_preference' => null,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(bootstrapControllerProvider).valueOrNull?.profile;
    final listings = ref.watch(discoverListingsProvider(profile));

    return Scaffold(
      body: SafeArea(
        child: listings.when(
          data: (items) {
            final locations =
                items
                    .map((item) => item.locality ?? item.city)
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Header row
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Search & Filters', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 18),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: locale.homeSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Filters', style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),

                // Location filter
                _CollapsibleFilterSection(
                  title: locale.cityLabel,
                  subtitle: _selectedLocation,
                  initiallyExpanded: true,
                  child: _ChipWrap(
                    values: locations,
                    selected: _selectedLocation,
                    onSelected: (value) => setState(() {
                      _selectedLocation = _selectedLocation == value
                          ? null
                          : value;
                    }),
                  ),
                ),

                // Budget filter
                _CollapsibleFilterSection(
                  title: locale.budgetFilterLabel,
                  subtitle: locale.budgetRangeLabel(
                    _formatBudget(_budgetValues.start),
                    _formatBudget(_budgetValues.end),
                  ),
                  initiallyExpanded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RangeSlider(
                        values: _budgetValues,
                        min: _budgetMin,
                        max: _budgetMax,
                        divisions: 19,
                        labels: RangeLabels(
                          _formatBudget(_budgetValues.start),
                          _formatBudget(_budgetValues.end),
                        ),
                        onChanged: (values) =>
                            setState(() => _budgetValues = values),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatBudget(_budgetMin),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatBudget(_budgetMax),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Room Type filter
                _CollapsibleFilterSection(
                  title: locale.roomTypeFilterLabel,
                  subtitle: _roomTypeSubtitle(),
                  initiallyExpanded: false,
                  child: _CatalogFilterChips(
                    options: _catalogOrFallback('flatmates_room_types', [
                      'any',
                      'private',
                      'shared',
                    ]),
                    selectedId: _selectedRoomType ?? 'any',
                    anyKey: 'any',
                    onSelected: (id) => setState(
                      () => _selectedRoomType = id == 'any' ? null : id,
                    ),
                  ),
                ),

                // Furnishing filter
                _CollapsibleFilterSection(
                  title: locale.furnishingFilterLabel,
                  subtitle: _furnishingSubtitle(),
                  initiallyExpanded: false,
                  child: _CatalogFilterChips(
                    options: _catalogOrFallback('flatmates_furnishing', [
                      'any',
                      'furnished',
                      'unfurnished',
                    ]),
                    selectedId: _selectedFurnishing ?? 'any',
                    anyKey: 'any',
                    onSelected: (id) => setState(
                      () => _selectedFurnishing = id == 'any' ? null : id,
                    ),
                  ),
                ),

                // Gender filter
                _CollapsibleFilterSection(
                  title: locale.genderFilterLabel,
                  subtitle: _genderSubtitle(),
                  initiallyExpanded: false,
                  child: _CatalogFilterChips(
                    options: _catalogOrFallback('flatmates_gender_options', [
                      'any',
                      'male',
                      'female',
                    ]),
                    selectedId: _selectedGender ?? 'any',
                    anyKey: 'any',
                    onSelected: (id) => setState(
                      () => _selectedGender = id == 'any' ? null : id,
                    ),
                  ),
                ),

                // Move-in filter
                _CollapsibleFilterSection(
                  title: locale.moveInFilterLabel,
                  subtitle: _moveInSubtitle(),
                  initiallyExpanded: false,
                  child: _CatalogFilterChips(
                    options: _catalogOrFallback('flatmates_move_in_timelines', [
                      'any',
                      'immediate',
                      'this_month',
                      'next_month',
                    ]),
                    selectedId: _selectedMoveIn ?? 'any',
                    anyKey: 'any',
                    onSelected: (id) => setState(
                      () => _selectedMoveIn = id == 'any' ? null : id,
                    ),
                  ),
                ),

                // More filters (expandable ExpansionTile with Pets & Smoking)
                ExpansionTile(
                  title: Text(
                    locale.moreFiltersLabel,
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    [
                      _petsSubtitle(),
                      _smokingSubtitle(),
                    ].where((s) => s != null).join(' · '),
                    style: theme.textTheme.bodyMedium,
                  ),
                  initiallyExpanded: false,
                  shape: const RoundedRectangleBorder(),
                  collapsedShape: const RoundedRectangleBorder(),
                  childrenPadding: const EdgeInsets.only(bottom: 14),
                  children: [
                    // Pets
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.petsLabel,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          _CatalogFilterChips(
                            options: _catalogOrFallback(
                              'flatmates_pets_options',
                              ['no_preference', 'yes', 'no'],
                            ),
                            selectedId: _selectedPets ?? 'no_preference',
                            anyKey: 'no_preference',
                            onSelected: (id) => setState(
                              () => _selectedPets = id == 'no_preference'
                                  ? null
                                  : id,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Smoking
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.smokingLabel,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        _CatalogFilterChips(
                          options: _catalogOrFallback(
                            'flatmates_smoking_options',
                            ['no_preference', 'no', 'yes'],
                          ),
                          selectedId: _selectedSmoking ?? 'no_preference',
                          anyKey: 'no_preference',
                          onSelected: (id) => setState(
                            () => _selectedSmoking = id == 'no_preference'
                                ? null
                                : id,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FlatmatesButton(
                    label: 'Show Results',
                    icon: Icons.filter_list_rounded,
                    onPressed: () {
                      ref
                          .read(discoverFiltersProvider.notifier)
                          .state = DiscoverFilters(
                        query: _searchController.text.trim().isEmpty
                            ? null
                            : _searchController.text.trim(),
                        location: _selectedLocation,
                        priceMin: _budgetValues.start == _budgetMin
                            ? null
                            : _budgetValues.start,
                        priceMax: _budgetValues.end == _budgetMax
                            ? null
                            : _budgetValues.end,
                        sharingType: _normalizedSharingType(),
                        genderPreference: _normalizedGenderPreference(),
                        features: [?_selectedFurnishing],
                      );
                      ref.invalidate(discoverListingsProvider(profile));
                      context.go('/discover');
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

/// Collapsible filter section using [ExpansionTile].
class _CollapsibleFilterSection extends StatelessWidget {
  const _CollapsibleFilterSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodyMedium)
          : null,
      initiallyExpanded: initiallyExpanded,
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      childrenPadding: const EdgeInsets.only(bottom: 14),
      children: [child],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(
        'No options available',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return FilterChip(
          label: Text(humanizeFlatmatesToken(value)),
          selected: selected == value,
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}

/// Filter chips built from catalog or fallback options.
class _CatalogFilterChips extends StatelessWidget {
  const _CatalogFilterChips({
    required this.options,
    required this.selectedId,
    required this.anyKey,
    required this.onSelected,
  });

  final List<({String id, String label})> options;
  final String selectedId;
  final String anyKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        'No options available',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return ChoiceChip(
          label: Text(opt.label),
          selected: selectedId == opt.id,
          onSelected: (_) => onSelected(opt.id),
        );
      }).toList(),
    );
  }
}
````

## File: lib/features/onboarding/location_selection_page.dart
````dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';

class LocationSelectionPage extends ConsumerStatefulWidget {
  const LocationSelectionPage({required this.onLocationSelected, super.key});

  final void Function(Map<String, String?> data) onLocationSelected;

  @override
  ConsumerState<LocationSelectionPage> createState() =>
      _LocationSelectionPageState();
}

class _LocationSelectionPageState extends ConsumerState<LocationSelectionPage> {
  final _searchController = TextEditingController();
  CatalogOption? _selectedCity;
  bool _locating = false;

  static const _fallbackCities = [
    CatalogOption(
      id: 'bangalore',
      label: 'Bangalore',
      meta: {'state': 'Karnataka', 'latitude': 12.9716, 'longitude': 77.5946},
    ),
    CatalogOption(
      id: 'hyderabad',
      label: 'Hyderabad',
      meta: {'state': 'Telangana', 'latitude': 17.3850, 'longitude': 78.4867},
    ),
    CatalogOption(
      id: 'pune',
      label: 'Pune',
      meta: {'state': 'Maharashtra', 'latitude': 18.5204, 'longitude': 73.8567},
    ),
    CatalogOption(
      id: 'chennai',
      label: 'Chennai',
      meta: {'state': 'Tamil Nadu', 'latitude': 13.0827, 'longitude': 80.2707},
    ),
    CatalogOption(
      id: 'mumbai',
      label: 'Mumbai',
      meta: {'state': 'Maharashtra', 'latitude': 19.0760, 'longitude': 72.8777},
    ),
    CatalogOption(
      id: 'gurgaon',
      label: 'Gurgaon',
      meta: {'state': 'Haryana', 'latitude': 28.4595, 'longitude': 77.0266},
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      // Check & request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to detect your city.',
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Find closest popular city by coordinates
      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final catalogCities =
          bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
      final cities = catalogCities.isNotEmpty ? catalogCities : _fallbackCities;

      CatalogOption? closest;
      double minDist = double.infinity;
      for (final city in cities) {
        final lat = (city.meta['latitude'] as num?)?.toDouble();
        final lng = (city.meta['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final d = _haversine(position.latitude, position.longitude, lat, lng);
        if (d < minDist) {
          minDist = d;
          closest = city;
        }
      }

      // If no coordinates in catalog, try matching by reverse-geocoded locality
      if (closest == null) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final locality = placemarks.first.locality?.toLowerCase() ?? '';
            final adminArea =
                placemarks.first.administrativeArea?.toLowerCase() ?? '';
            for (final city in cities) {
              final label = city.label.toLowerCase();
              if (locality.contains(label) ||
                  label.contains(locality) ||
                  adminArea.contains(label) ||
                  label.contains(adminArea)) {
                closest = city;
                break;
              }
            }
          }
        } catch (_) {
          // Geocoding may fail on some platforms; fall through to manual
        }
      }

      if (closest != null && mounted) {
        setState(() => _selectedCity = closest);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not find a matching city. Please select manually.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not detect your location. Please select manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Haversine distance in km.
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * asin(sqrt(a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogCities =
        bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
    final cities = catalogCities.isNotEmpty ? catalogCities : _fallbackCities;
    final query = _searchController.text.trim().toLowerCase();
    final visibleCities = query.isEmpty
        ? cities
        : cities
              .where((city) => city.label.toLowerCase().contains(query))
              .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: locale.backCta,
            ),
            const SizedBox(height: 28),
            Text(
              locale.locationSelectionTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            // Search bar — DESIGN.md spec: 48px height, 20px radius, 1px outlineVariant border
            SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: locale.searchLocationPlaceholder,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.outlineVariant,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _LocationActionRow(
              icon: Icons.my_location_outlined,
              title: _locating
                  ? locale.detectingLocation
                  : locale.useCurrentLocation,
              onTap: _locating ? () {} : _useCurrentLocation,
            ),
            const SizedBox(height: 18),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              locale.popularCitiesLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visibleCities.isEmpty
                  ? Center(
                      child: Text(
                        locale.noLocationsAvailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: visibleCities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final city = visibleCities[index];
                        final selected = _selectedCity?.id == city.id;
                        return _CityRow(
                          city: city,
                          selected: selected,
                          onTap: () => setState(() => _selectedCity = city),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28, top: 12),
              child: SizedBox(
                width: double.infinity,
                child: FlatmatesButton(
                  label: locale.modeContinue,
                  onPressed: _selectedCity == null
                      ? null
                      : () => widget.onLocationSelected({
                          'city': _selectedCity!.label,
                          'locality': null,
                        }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationActionRow extends StatelessWidget {
  const _LocationActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final CatalogOption city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(city.label, style: theme.textTheme.bodyLarge)),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/onboarding/preferences_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({required this.onComplete, super.key});

  final void Function(Map<String, dynamic> preferences) onComplete;

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  String _preferredGender = 'no_preference';
  String _allowedFlatmates = '1';
  String _foodHabits = 'no_preference';
  String _pets = 'no_preference';
  String _smoking = 'no';
  String _moveInTimeline = 'flexible';

  /// Resolve pill options from a catalog key, falling back to hardcoded values.
  List<_PillOption> _catalogPills(
    String catalogKey,
    List<_PillOption> fallback,
  ) {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(catalogKey);
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions
          .map(
            (opt) => _PillOption(
              key: _normalizeCatalogValue(catalogKey, opt.id),
              label: opt.label,
            ),
          )
          .toList();
    }
    return fallback;
  }

  String _normalizeCatalogValue(String catalogKey, String value) {
    if (catalogKey == 'flatmates_food_habits') {
      return switch (value) {
        'veg' => 'vegetarian',
        'non_veg' => 'non_vegetarian',
        _ => value,
      };
    }
    return value;
  }

  // --- Hardcoded fallback option lists ---

  static const _fallbackGenderOptions = [
    _PillOption(key: 'no_preference', label: ''), // resolved via locale
    _PillOption(key: 'male_only', label: ''),
    _PillOption(key: 'female_only', label: ''),
    _PillOption(key: 'other', label: ''),
  ];

  static const _fallbackFoodOptions = [
    _PillOption(key: 'vegetarian', label: ''),
    _PillOption(key: 'non_vegetarian', label: ''),
    _PillOption(key: 'eggetarian', label: ''),
    _PillOption(key: 'no_preference', label: ''),
  ];

  static const _fallbackPetsOptions = [
    _PillOption(key: 'yes', label: ''),
    _PillOption(key: 'no', label: ''),
    _PillOption(key: 'no_preference', label: ''),
  ];

  static const _fallbackSmokingOptions = [
    _PillOption(key: 'no', label: ''),
    _PillOption(key: 'yes', label: ''),
    _PillOption(key: 'no_preference', label: ''),
  ];

  static const _fallbackMoveInOptions = [
    _PillOption(key: 'immediate', label: ''),
    _PillOption(key: 'this_month', label: ''),
    _PillOption(key: 'next_month', label: ''),
    _PillOption(key: 'flexible', label: ''),
  ];

  /// Get gender options: catalog first, then localized fallback.
  List<_PillOption> get _genderOptions {
    final catalog = _catalogPills(
      'flatmates_gender_options',
      _fallbackGenderOptions,
    );
    // If catalog returned items with real labels, use them directly
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    // Otherwise use localized fallback labels
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
      _PillOption(key: 'male_only', label: locale.prefMaleOnly),
      _PillOption(key: 'female_only', label: locale.prefFemaleOnly),
      _PillOption(key: 'other', label: locale.prefOther),
    ];
  }

  List<_PillOption> get _foodOptions {
    final catalog = _catalogPills(
      'flatmates_food_habits',
      _fallbackFoodOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'vegetarian', label: locale.prefVeg),
      _PillOption(key: 'non_vegetarian', label: locale.prefNonVeg),
      _PillOption(key: 'eggetarian', label: locale.prefEggetarian),
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
    ];
  }

  List<_PillOption> get _petsOptions {
    final catalog = _catalogPills(
      'flatmates_pets_options',
      _fallbackPetsOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'yes', label: locale.prefYes),
      _PillOption(key: 'no', label: locale.prefNo),
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
    ];
  }

  List<_PillOption> get _smokingOptions {
    final catalog = _catalogPills(
      'flatmates_smoking_options',
      _fallbackSmokingOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'no', label: locale.prefNo),
      _PillOption(key: 'yes', label: locale.prefYes),
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
    ];
  }

  List<_PillOption> get _moveInOptions {
    final catalog = _catalogPills(
      'flatmates_move_in_timelines',
      _fallbackMoveInOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'immediate', label: locale.timelineImmediate),
      _PillOption(key: 'this_month', label: locale.timelineThisMonth),
      _PillOption(key: 'next_month', label: locale.timelineNextMonth),
      _PillOption(key: 'flexible', label: locale.timelineFlexible),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(locale.preferencesTitle, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              locale.preferencesSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // 1. Preferred Gender
            _PreferenceSection(
              icon: Icons.wc_outlined,
              title: locale.prefGenderLabel,
              children: [
                _pillOptions(
                  options: _genderOptions,
                  selectedKey: _preferredGender,
                  onSelected: (v) => setState(() => _preferredGender = v),
                ),
              ],
            ),

            // 2. Allowed Flatmates
            _PreferenceSection(
              icon: Icons.group_outlined,
              title: locale.prefFlatmatesLabel,
              children: [
                _pillOptions(
                  options: [
                    _PillOption(key: '1', label: '1'),
                    _PillOption(key: '2', label: '2'),
                    _PillOption(key: '3', label: '3'),
                    _PillOption(key: '4+', label: '4+'),
                  ],
                  selectedKey: _allowedFlatmates,
                  onSelected: (v) => setState(() => _allowedFlatmates = v),
                ),
              ],
            ),

            // 3. Food Habits
            _PreferenceSection(
              icon: Icons.restaurant_outlined,
              title: locale.prefFoodLabel,
              children: [
                _pillOptions(
                  options: _foodOptions,
                  selectedKey: _foodHabits,
                  onSelected: (v) => setState(() => _foodHabits = v),
                ),
              ],
            ),

            // 4. Pets
            _PreferenceSection(
              icon: Icons.pets_outlined,
              title: locale.prefPetsLabel,
              children: [
                _pillOptions(
                  options: _petsOptions,
                  selectedKey: _pets,
                  onSelected: (v) => setState(() => _pets = v),
                ),
              ],
            ),

            // 5. Smoking
            _PreferenceSection(
              icon: Icons.smoke_free_outlined,
              title: locale.prefSmokingLabel,
              children: [
                _pillOptions(
                  options: _smokingOptions,
                  selectedKey: _smoking,
                  onSelected: (v) => setState(() => _smoking = v),
                ),
              ],
            ),

            // 6. Move-in Timeline
            _PreferenceSection(
              icon: Icons.event_outlined,
              title: locale.prefMoveInLabel,
              children: [
                _pillOptions(
                  options: _moveInOptions,
                  selectedKey: _moveInTimeline,
                  onSelected: (v) => setState(() => _moveInTimeline = v),
                ),
              ],
            ),

            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_preferences_next'),
              label: locale.prefNext,
              onPressed: () => widget.onComplete({
                'preferred_gender': _preferredGender,
                'gender_preference': _preferredGender,
                'allowed_flatmates': _allowedFlatmates,
                'food_habits': _foodHabits,
                'pets': _pets,
                'smoking': _smoking,
                'move_in_timeline': _moveInTimeline,
              }),
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillOptions({
    required List<_PillOption> options,
    required String selectedKey,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selectedKey == opt.key;
        return ChoiceChip(
          key: Key('pref_${opt.key}'),
          label: Text(opt.label),
          selected: isSelected,
          onSelected: (_) => onSelected(opt.key),
          selectedColor: theme.colorScheme.primaryContainer,
        );
      }).toList(),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 20),
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: children,
    );
  }
}

class _PillOption {
  const _PillOption({required this.key, required this.label});

  final String key;
  final String label;
}
````

## File: lib/features/settings/blocked_users_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';

class BlockedUser {
  const BlockedUser({
    required this.blockedUserId,
    required this.name,
    this.imageUrl,
    this.location,
  });

  final int blockedUserId;
  final String name;
  final String? imageUrl;
  final String? location;

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? const {});
    final locationParts = [
      user['locality']?.toString(),
      user['city']?.toString(),
    ].where((value) => value != null && value.trim().isNotEmpty).toList();
    return BlockedUser(
      blockedUserId: (json['blocked_user_id'] as num?)?.toInt() ?? 0,
      name: user['full_name']?.toString().trim().isNotEmpty == true
          ? user['full_name'].toString()
          : 'Flatmate',
      imageUrl: user['profile_image_url']?.toString(),
      location: locationParts.isEmpty ? null : locationParts.join(', '),
    );
  }
}

final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/flatmates/blocks');
  final rows = response.data as List? ?? const [];
  return rows
      .map(
        (item) => BlockedUser.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
});

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final blockedUsers = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(locale.blockedUsersLabel),
      ),
      body: blockedUsers.when(
        data: (users) {
          if (users.isEmpty) {
            final theme = Theme.of(context);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      locale.noBlockedUsers,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.imageUrl == null
                        ? null
                        : NetworkImage(user.imageUrl!),
                    child: user.imageUrl == null
                        ? Text(user.name.characters.first.toUpperCase())
                        : null,
                  ),
                  title: Text(user.name),
                  subtitle: user.location == null ? null : Text(user.location!),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(apiClientProvider)
                            .delete('/flatmates/blocks/${user.blockedUserId}');
                        ref.invalidate(blockedUsersProvider);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locale.userUnblocked)),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locale.unblockFailed)),
                        );
                      }
                    },
                    child: Text(locale.unblockCta),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
````

## File: lib/features/settings/change_password_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/gen/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.passwordUpdated)));
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(locale.changePasswordLabel)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: locale.newPasswordLabel),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return locale.passwordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: locale.confirmPasswordLabel,
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return locale.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(locale.updatePasswordCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/swipe/match_qna_nudge.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// Bottom sheet that nudges the user to answer 3 ice-breaker Q&A questions
/// after a match, before they start chatting.
class MatchQnANudgeSheet extends ConsumerStatefulWidget {
  const MatchQnANudgeSheet({required this.conversationId, super.key});

  final int conversationId;

  @override
  ConsumerState<MatchQnANudgeSheet> createState() => _MatchQnANudgeSheetState();
}

class _MatchQnANudgeSheetState extends ConsumerState<MatchQnANudgeSheet> {
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  int _socialScale = 3; // 1–5, default middle
  bool _isSubmitting = false;

  @override
  void dispose() {
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/flatmates/conversations/${widget.conversationId}/qna',
            data: {
              'answers': [
                {
                  'question':
                      'What does your ideal flatmate situation look like?',
                  'answer': _q1Controller.text.trim(),
                },
                {
                  'question':
                      'How social are you at home on a typical weekday?',
                  'answer': _socialScaleValue,
                },
                {
                  'question': 'One thing you absolutely need in a flatmate?',
                  'answer': _q3Controller.text.trim(),
                },
              ],
            },
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        final locale = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.commonRetry)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _socialScaleValue {
    const labels = [
      'Very private',
      'Mostly private',
      'Balanced',
      'Mostly social',
      'Very social',
    ];
    return labels[_socialScale - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            locale.qnaNudgeTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Q1
          Text(
            locale.qnaQuestion1,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _q1Controller,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: locale.qnaQuestion1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Q2 (social scale)
          Text(
            locale.qnaQuestion2,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                locale.qnaVeryPrivate,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _socialScale.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _socialScaleValue,
                  onChanged: (v) => setState(() => _socialScale = v.round()),
                ),
              ),
              Text(
                locale.qnaVerySocial,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Q3
          Text(
            locale.qnaQuestion3,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _q3Controller,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: locale.qnaQuestion3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 24),

          // Share Answers button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitAnswers,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(locale.qnaShareAnswers),
            ),
          ),
          const SizedBox(height: 8),

          // Skip for now
          Center(
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(locale.qnaSkipForNow),
            ),
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/visits/schedule_visit_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../chats/chats_repository.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'visits_repository.dart';

class ScheduleVisitPage extends ConsumerStatefulWidget {
  const ScheduleVisitPage({
    required this.conversation,
    this.conversationId,
    super.key,
  });

  final ConversationSummaryModel? conversation;
  final int? conversationId;

  @override
  ConsumerState<ScheduleVisitPage> createState() => _ScheduleVisitPageState();
}

class _ScheduleVisitPageState extends ConsumerState<ScheduleVisitPage> {
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = 'afternoon';
  bool _submitting = false;
  ConversationSummaryModel? _conversation;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _scheduledDate {
    final hour = switch (_selectedSlot) {
      'morning' => 10,
      'evening' => 18,
      _ => 15,
    };
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
    );
  }

  Future<void> _submit() async {
    final conversation = widget.conversation ?? _conversation;
    final property = conversation?.contextProperty;
    if (conversation == null || property == null) return;
    final locale = AppLocalizations.of(context);

    setState(() => _submitting = true);
    try {
      await ref
          .read(visitsRepositoryProvider)
          .scheduleFlatmateVisit(
            propertyId: property.id,
            counterpartyUserId: conversation.peer.id,
            conversationId: conversation.id,
            scheduledDate: _scheduledDate,
            note: _noteController.text,
          );
      ref.invalidate(visitsProvider);
      await ref
          .read(chatsRepositoryProvider)
          .sendMessage(
            conversationId: conversation.id,
            messageType: 'text',
            body:
                'Visit requested for ${DateFormat('d MMM, h:mm a', locale.localeName).format(_scheduledDate.toLocal())}',
          );
      ref.invalidate(messagesProvider(conversation.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.contactRequestSent)));
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final fetchedConversation =
        widget.conversation == null && widget.conversationId != null
        ? ref.watch(conversationProvider(widget.conversationId!))
        : null;
    final conversation =
        widget.conversation ?? fetchedConversation?.valueOrNull;
    final property = conversation?.contextProperty;
    if (_conversation == null &&
        widget.conversation == null &&
        conversation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _conversation == null) {
          setState(() => _conversation = conversation);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: fetchedConversation?.isLoading == true
            ? const Center(child: CircularProgressIndicator())
            : fetchedConversation?.hasError == true
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fetchedConversation!.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        conversationProvider(widget.conversationId!),
                      ),
                      child: Text(locale.commonRetry),
                    ),
                  ],
                ),
              )
            : property == null
            ? Center(child: Text(locale.homeNoResults))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Spacer(),
                      const FlatmatesLogo(compact: true, centered: true),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          if (property.mainImageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                property.mainImageUrl!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (property.mainImageUrl == null)
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.apartment_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.title,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  conversation!.peer.fullName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (conversation.matchedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    locale.matchedOnDate(
                                      DateFormat(
                                        'd MMM yyyy',
                                      ).format(conversation.matchedAt!),
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    locale.scheduleVisitTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    onDateChanged: (date) =>
                        setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    locale.selectTimeSlot,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      _SlotChip(
                        label: locale.timeSlotMorning,
                        selected: _selectedSlot == 'morning',
                        onTap: () => setState(() => _selectedSlot = 'morning'),
                      ),
                      _SlotChip(
                        label: locale.timeSlotAfternoon,
                        selected: _selectedSlot == 'afternoon',
                        onTap: () =>
                            setState(() => _selectedSlot = 'afternoon'),
                      ),
                      _SlotChip(
                        label: locale.timeSlotEvening,
                        selected: _selectedSlot == 'evening',
                        onTap: () => setState(() => _selectedSlot = 'evening'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _noteController,
                    maxLength: 180,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: locale.addNoteOptional,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InfoPill(
                    icon: Icons.shield_outlined,
                    label: locale.visitPrivacyNote(conversation.peer.fullName),
                    highlighted: true,
                  ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: FlatmatesButton(
          label: _submitting ? locale.sendingLabel : locale.sendRequestCta,
          icon: Icons.send_rounded,
          onPressed: _submitting ? null : _submit,
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
````

## File: DESIGN.md
````markdown
# DESIGN.md — 360 Flatmates Design System

> **Source of truth** for all UI tokens, component specifications, and screen-by-screen
> implementation targets. Every visual change in this codebase should reference this file.

## Register

Product app. Design serves the product — clean, functional, trustworthy. The aesthetic is
warm-professional: approachable enough for flatmate discovery, polished enough for
financial transactions (rent, deposits).

**Physical scene:** A 26-year-old software engineer scrolling on their phone in a
Bangalore co-working space at 3 PM, natural daylight from floor-to-ceiling windows,
slightly distracted by Slack pings. They need to find a flatmate in the next two weeks
and are cautiously optimistic. The UI should feel like a helpful friend who knows design,
not a cold property portal.

---

## Color Tokens

### Primary Palette

| Token | Value | OKLCH (approx) | Usage |
|-------|-------|----------------|-------|
| **Primary** | `#5B4BCF` | oklch(0.45 0.2 270) | CTAs, active states, icons, progress bars, links |
| **Primary Light** | `#E8E4F6` | oklch(0.93 0.03 270) | Light purple bg tints, selected states |
| **Primary Container** | `#DDD8F0` | oklch(0.88 0.04 270) | Filled chip backgrounds, hover states |

### Neutral Scale

| Token | Value | Usage |
|-------|-------|-------|
| **Surface** | `#FFFFFF` | Card backgrounds, screen surfaces, input fills |
| **Surface Dim** | `#F8F9FA` | Page scaffold background |
| **Text Primary** | `#1A1A2E` | Headings, titles, important text, prices |
| **Text Secondary** | `#6B7280` | Body text, descriptions, subtitles |
| **Text Tertiary** | `#9CA3AF` | Timestamps, hints, placeholders, disabled text |
| **Border** | `#E5E7EB` | Dividers, card borders, input borders |
| **Outline Variant** | `D1D5DB` | Subtle borders, disabled outlines |

### Semantic Colors

| Token | Value | Usage |
|-------|-------|-------|
| **Success** | `#10B981` | Match % rings, confirmed states, online indicators |
| **Error / Destructive** | `#EF4444` | Logout, errors, delete actions, declined states |
| **Warning** | `#F59E0B` | Pending states, reminders, expiring-soon badges |
| **Info** | `#5B4BCF` (primary) | Informational badges, tips, links |

### Dark Mode Derivations

Dark mode uses `ColorScheme.fromSeed()` with `Brightness.dark`. Key overrides:
- Scaffold bg: `#0F1321`
- Surface: derived from dark scheme
- Text: lightened equivalents via `onSurface`, `onSurfaceVariant`

---

## Typography

### Font Families

- **Headlines:** Sora (Google Fonts) — geometric, modern, confident
- **Body:** Plus Jakarta Sans (Google Fonts) — clean, readable, slightly warm

### Type Scale

| Name | Size | Weight | Line Height | Letter Spacing | Usage |
|------|------|--------|-------------|----------------|-------|
| **Display** | 32sp | Bold (700) | 1.2 | -0.5 | Splash tagline, hero text |
| **H1** | 28sp | Bold (700) | 1.25 | -0.3 | Screen titles ("Profile", "Settings") |
| **H2** | 22sp | SemiBold (600) | 1.3 | -0.2 | Section heads ("Picked for You") |
| **H3** | 18-20sp | SemiBold (600) | 1.3 | -0.1 | Card titles, listing names |
| **Body Large** | 16sp | Medium (500) | 1.5 | 0 | Primary body text, greetings |
| **Body Medium** | 14sp | Medium (500) | 1.45 | 0 | Secondary text, descriptions |
| **Label Large** | 14sp | Bold (700) | 1.0 | 0.5 | Buttons, chip labels |
| **Label Medium** | 12sp | SemiBold (600) | 1.4 | 0.2 | Tags, badges, metadata |
| **Caption** | 12sp | Regular (400) | 1.4 | 0 | Timestamps, hints, placeholders |

### Rules

- Cap body line length at ~65-70 characters (Flutter's default wrapping handles this)
- Headline-to-body scale ratio >= 1.25 (we use 28/16 = 1.75 for H1/body)
- Never use em dashes; use commas, colons, or parentheses

---

## Border Radius

| Element | Radius | Notes |
|---------|--------|-------|
| **Cards (listing, notification, menu)** | 16px | Standard content cards |
| **Buttons (filled CTA)** | 12px | Primary action buttons |
| **Buttons (outline/secondary)** | 12px | Secondary actions |
| **Inputs / Text Fields** | 12px | Search bars, form fields |
| **Chips / Pills (filter, tag)** | 20px | Rounded but not fully circular |
| **Avatars** | 999px (circular) | User profile images |
| **Icon containers (menu item icon bg)** | 12px | Small square icon backgrounds |
| **Notification icon bg** | 999px (circular) | 48px circle for notification type icons |
| **Bottom sheet / dialog top** | 20px | Top corners only |
| **Snackbar / toast** | 16px | Notification toasts |
| **FAB / floating action** | 16px | Edit avatar overlay button |

---

## Spacing

| Token | Value | Usage |
|-------|-------|-------|
| **Screen edge padding** | 20-24px | Left/right margins for page content |
| **Section gap** | 24-28px | Vertical space between major sections |
| **Card internal padding** | 16px | Padding inside cards |
| **Element gap (tight)** | 8px | Between icon and label in a row |
| **Element gap (normal)** | 12px | Between form fields, list items |
| **Element gap (relaxed)** | 16px | Between heading and content |
| **Element gap (section)** | 24px | Between distinct content blocks |
| **List item vertical spacing** | 12-16px | Between items in a list |

---

## Shadows

| Element | Shadow | Usage |
|---------|--------|-------|
| **Cards** | `0 2px 8px rgba(0,0,0,0.06)` | Subtle elevation for content cards |
| **Elevated (FAB, dropdown)** | `0 4px 12px rgba(0,0,0,0.10)` | Floating elements |
| **Buttons (filled)** | `0 2px 8px rgba(91,75,207,0.18)` | Primary CTAs only |
| **Modal / Bottom Sheet** | `0 -4px 24px rgba(0,0,0,0.12)` | Overlay surfaces |
| **Navigation bar** | None (or minimal) | No elevation on bottom nav |

---

## Component Specifications

### Primary Button (Filled CTA)

- Background: solid `#5B4BCF` (NOT gradient)
- Text: white, 14sp bold (Label Large), center-aligned
- Padding: horizontal 24px, vertical 16px
- Border radius: 12px
- Height: 52px (standard), 56px (tall)
- Full-width variant: stretch to parent width
- Disabled: surfaceContainerHighest bg, onSurfaceVariant text
- Shadow: subtle primary-tinted shadow when enabled

### Secondary Button (Outline)

- Border: 1.5px solid #5B4BCF (or #E5E7EB for neutral)
- Text: #5B4BCF (or #1A1A2E for neutral)
- Same dimensions as filled button
- No shadow

### Tertiary Button (Text)

- Text only, #5B4BCF color, 14sp medium weight
- No border, no background, no shadow
- Used for Skip, "See all", links

### Listing Card (Home Feed — Horizontal Layout)

- Width: 300px, height: 370px
- Layout: Row with image left (148px wide), content right
- Image: aspect ratio 0.82, radius 16px, cover fit
- Image overlay: heart icon (top-right, 40px white circle bg)
- Price: 26sp bold, #1A1A2E color (NOT purple)
- Title: 18sp semiBold below price
- Location: row with pin icon + gray text
- Info pills: beds, baths, area as compact pills
- Feature pills: furnished, wifi, etc.
- Owner row: small avatar (34px) + name + interest count
- Description: 2-line max, truncated
- Footer: GradientActionButton → solid FlatmatesButton
- Compatibility ring: 32px, positioned above title

### Profile Grid Card (Likes Tab — 2-Column Grid)

- Layout: Column within fixed-width cell (~48% of screen width)
- Photo: top, 16px radius, 1:1 or 4:5 aspect ratio
- Match % circle: green ring, top-right corner of photo, 44px
- Name: 15sp bold, below photo
- Age + location: 12sp gray, below name
- Profession: 12sp gray, below location
- "Match" CTA: full-width, solid primary, 12px radius, 42px height

### Menu Item Row (Profile / Settings)

- Height: 56px
- Layout: Row with icon container (left), label (expanded), chevron (right)
- Icon container: 40x40px, rounded 12px, light tinted bg matching context
- Label: 15sp medium weight, #1A1A2E
- Chevron: 20px, tertiary color (#9CA3AF)
- Divider below each item (except last in group)
- Group spacing: 24px between groups

### Notification Card

- Padding: 16px horizontal, 14px vertical
- Layout: Row with icon container (left), content (center), time+dot (right)
- Icon container: 48px circle, pastel bg per type:
  - Booking confirmed: primary tint
  - New message: blue tint
  - Visit reminder: amber tint
  - Listing approved: green tint
- Title: 15sp semiBold, #1A1A2E
- Description: 13sp regular, #6B7280, 2 lines max
- Timestamp: 12sp, #9CA3AF, right-aligned
- Unread dot: 10px circle, #5B4BCF, below timestamp
- Card bg: white, 16px radius, subtle shadow

### Search Bar

- Height: 48px
- Border radius: 20px (slightly more rounded than standard inputs)
- Background: white (light mode) / surfaceContainer (dark mode)
- Border: 1px outlineVariant
- Leading icon: search, 20px, tertiary color
- Placeholder: 14sp regular, tertiary color
- Trailing icon: optional (location pin, clear, mic)

### Filter Chip

- Selected: primary container bg (#DDD8F0), primary text, optional primary border
- Unselected: surface bg, secondary text, outlineVariant border
- Radius: 20px (pill-shaped)
- Padding: horizontal 14px, vertical 8px
- Avatar/icon support: 16px icon before label

### Bottom Navigation Bar

- Height: 76px
- Background: surface color (white in light mode)
- Active: primary color (#5B4BCF) for icon + label
- Inactive: tertiary color (#9CA3AF) for icon + label
- Labels: always visible (labelBehavior.alwaysShow)
- No elevation / minimal top border
- Indicator: primary.withAlpha(0.14) background
- Mode-dependent destinations (see Navigation section below)

### Avatar

- Default size: 52px
- Shape: circular
- Fallback: gradient from primary to primary.withAlpha(0.72), white initials
- Shadow: subtle (blur 10, offset Y 4, primary at 18% alpha)
- With image: ClipOval + Image.network with error fallback

### Logo (36 FLATMATES)

- Compact mode: "36" at 28sp extra-bold + rotate_right icon (30px) + "FLATMATES" at 13sp
- Full mode: "36" at 38sp extra-bold + rotate_right icon (38px) + "FLATMATES" at 15sp
- Color: primary for all elements
- "36" letter-spacing: -1.4
- "FLATMATES" letter-spacing: +1.6

---

## Navigation Structure

### Mode-Dependent Bottom Navigation (PRD Section 4.1)

Every user has exactly one mode. Mode determines which bottom nav tabs they see.

| Tab | Room Poster | Co-Hunter | Open to Both |
|-----|------------|-----------|-------------|
| **1** | Home (Feed) | Home (Feed) | Home (Feed) |
| **2** | Post / Manage Property | Properties (Map View) | Properties (Map View) |
| **3** | Swipe | Swipe | Swipe |
| **4** | Likes & Chat | Likes & Chat | Likes & Chat |
| **5** | Profile | Profile | Profile |

**Tab Icons & Labels:**

| Tab | Icon (outlined / rounded) | Label |
|-----|--------------------------|-------|
| Home | home_outlined / home_rounded | Home |
| Post (Room Poster) | add_home_outlined / add_home_rounded | Post |
| Explore (Co-Hunter/Open) | map_outlined / map_rounded | Explore |
| Swipe | swap_horiz (same) | Swipe |
| Likes & Chat | favorite_border / favorite_rounded | Likes & Chat |
| Profile | person_outline / person_rounded | Profile |

**Note:** Notifications is accessed via a route (/notifications), not a tab.
The notification bell icon may appear in specific screen headers but not globally.

---

## Screen-by-Screen Specifications

### Screen 01 — Splash (`360f_01_splash.png`)

- White background
- Centered: 360 FLATMATES logo (full size)
- Tagline: "Find. Connect. Live Together." — Display/Bold, centered
- Subtitle: "The smarter way to find your flat and flatmates." — Body Medium, centered
- Illustration: Living room line art (sofa, plant, lamp, picture frame)
- Bottom: Thin progress bar (track: #E8E4F6, fill: #5B4BCF, height: 4px, width: 60%)

### Screen 02 — Onboarding (`360f_02_onboarding.png`)

- Background: very light lavender tint (#F8F6FC)
- Illustration: Two people at cafe table (colored, warm tones)
- Headline: "Find the **right** flat. The **right** flatmates." — H1, "**right**" words bold/emphasized
- Subtitle: "Verified homes. Compatible flatmates. Better living, together." — Body Medium
- Bottom row: Skip (text button, left) + Next (filled CTA with arrow icon, right)
- Page dots: 4 dots, outline style, active = filled primary circle, centered above buttons

### Screen 03 — Choose Role / Mode Selection (`360f_03_choose-role.png`)

- Back arrow: top-left
- Progress indicator: 4 dots connected by lines at top, first dot active (filled)
- Heading: "I am looking to" — H1 bold
- Subtitle: "Select the option that best describes you" — Body Medium
- **3 option cards** (vertical stack, 16px radius, white bg, subtle shadow):
  - Each: 56px light-purple circle with outline icon (left) + text column (center) + chevron (right)
  - Card 1: home icon + "Find a Flat / Flatmate" (H3) + "I want to find a place or a flatmate to stay with"
  - Card 2: group icon + "List My Flat / Find Flatmate" (H3) + "I want to list my flat or find a flatmate"
  - Card 3: swap_horiz icon + "Open to Both" (H3) + "I'm flexible — open to both finding a place and listing my flat"
- CTA: "Continue" — filled primary, full width, 12px radius

### Screen 04 — Location Selection (`360f_04_location.png`)

- Back arrow: top-left
- Heading: "Select your preferred location" — H1
- Search bar: "Search location" placeholder, search icon
- "Use my current location" row: location icon + purple text + chevron
- Divider
- "POPULAR CITIES" label: Caption uppercase, letter-spaced, tertiary color
- City rows (5): pin icon (purple) + city name + chevron, each in a rounded container (12px radius, light bg)
- Cities: Bangalore, Hyderabad, Pune, Chennai, Mumbai
- CTA: "Continue" — filled primary, full width

### Screen 05 — Home / Discover (`360f_05_home-discover.png`)

- Header row:
  - Left: Greeting "Hi, [Name]!" (H2 bold)
  - Below greeting: Location with dropdown chevron
  - Right: Notification bell icon + user avatar (52px)
- Search bar: "Search by location, name or landmark", 20px radius
- Filter chips row (horizontal scroll): Nearby, 1BHK, Furnished, Budget+ (with + icon)
- "Picked for You" section header + "See all >" link
- Listing cards: horizontal scroll, 300px wide each (horizontal layout per user decision)
- "New in [City]" section: subtitle + "Explore >" link
- Bottom nav: 5 tabs (mode-dependent)

### Screen 06 — Search & Filters (`360f_06_search-filters.png`)

- Back arrow (left) + filter/tune icon (right)
- Heading: "Search & Filters" — H1
- Search bar with location pin icon (right side of bar)
- "Filters" section label — H3
- Collapsible filter sections:
  - Location: label + "Select preferred areas" hint + selected chips (with X) + chevron
  - Budget: label + "Select your budget range" + selected range text + chevron
  - Room Type: label + "Select room configuration" + pills (Any/Private/Shared)
  - Furnishing: label + "Select furnishing type" + pills (Any/Furnished/Unfurnished)
  - Gender: label + "Select preferred gender" + pills (Any/Male/Female)
  - Move-in: label + "Select move-in date" + "Anytime" + chevron
  - More filters: expandable (chevron down/up)
- CTA: "Show Results" — filled primary, full width, with filter icon

### Screen 07 — Flat Details (`360f_07_flat-details.png`)

- Image carousel: full-width, ~220px tall, back/share/heart icon overlays (top)
- Title: "Modern 2BHK Flat" — H2 bold
- Price: "₹24,000 / month" — H3 bold, primary color
- Location: pin icon + "HSR Layout, Bangalore" — Body Medium
- Icon row (compact): Beds(2), Furnished, WiFi, High-Speed, 24/7 Security, Parking, Lift
- "About this Flat" section: description paragraph
- Availability grid: Available from (date) | Posted on (date) — 2 columns
- Action buttons: "Shortlist" (outline, left) + "Contact" (filled primary, right)
- Verified badge: checkmark + "Verified listing"

### Screen 08 — Chat Thread (`360f_08_chat.png`)

- App bar: back arrow + avatar (40px) + name + verified dot + role badge + phone icon + video icon + 3-dot menu
- Property card: thumbnail (88px) + title + price + owner + "View Listing" outlined button + time
- Message bubbles:
  - Sent: solid primary (#5B4BCF), white text, 16px radius, right-aligned
  - Received: #F3F4F6 bg, #1A1A2E text, 16px radius, left-aligned, avatar per message
- Timestamps: below each bubble, 11sp, tertiary color
- Read receipts: double-check marks
- Input bar: smiley icon (left) + "Type a message..." field + attachment + send circle (purple, right)

### Screen 09 — Likes & Chat (`360f_09_likes-chat.png`)

- Header: 360 logo (compact, left) + icons (search?, more?) + "Likes & Chat" (H1, bold)
- Toggle: "Likes" (filled primary pill) / "Chats" (outline pill)
- **Likes tab:** "People who liked you" (heart icon + text + "See all")
  - 2-column grid of profile cards (photo, name/age/location/profession, match % circle, Match CTA)
- **Chats tab:** Conversation list (avatar, name, preview, time)
- Safety banner: shield icon + "Safety first" + privacy note + chevron
- Bottom nav: 5 tabs

### Screen 10 — Schedule Visit (`360f_10_schedule-visit.png`)

- Back arrow (left) + 360 logo (top-center)
- Property card: image + title + matched date + owner avatar/name
- "Schedule Visit" — H2 bold
- Calendar picker: month navigation, date grid, selected date circled (primary)
- "Select Time Slot": Morning / Afternoon (selected, primary fill) / Evening pills
- "Add a Note (Optional)": textfield with character count
- Privacy note: shield icon + "Your visit request will be shared with [Owner]."
- CTA: "Send Request" — filled primary, full width, with paper plane icon
- Bottom nav: 5-6 tabs

### Screen 11 — Add Listing Step 1 (`360f_11_add-listing.png`)

- Back arrow (left) + 360 logo (top-center)
- "List Your Flat" — H1 bold
- "Step 1 of 7" + progress bar (thin, purple fill proportion)
- Form fields (white bg, no card wrappers):
  - Flat Details (dropdown with chevron)
  - Flat Title (text input, placeholder "E.g. 2BHK in Koramangala")
  - Location (dropdown with pin icon + chevron)
  - Rent (text input with ₹ prefix icon)
  - Room Type (dropdown with chevron)
  - Furnishing (dropdown with chevron)
- CTA: "Next" — filled primary, full width

### Screen 12 — Add Photos (`360f_12_photos.png`)

- Back arrow (left)
- "Add Photos" — H1 bold
- Tips toggle (right-aligned): "Tips" pill button
- Instruction: "Add clear photos of the room and common areas to get more matches."
- Uploaded photo cards: 3 shown, each with delete (X) icon overlay, 16px radius
- "+ Add More" link with plus icon
- Pagination dots: 3 dots, second active
- CTA: "Next" — filled primary, full width

### Screen 13 — Preferences (`360f_13_preferences.png`)

- Back arrow (left)
- Progress bar: 5 segments, third segment filled (step 3 of 5+)
- "Preferences" — H1 bold
- Subtitle: "Tell us what matters to you so we can find the right flatmates and homes."
- Collapsible sections (each with icon, label, hint, chevron):
  - Preferred Gender: pills (No Preference / Male Only / Female Only / Other)
  - Allowed Flatmates: number pills (1 / 2 / 3 / 4+)
  - Food Habits: pills (Veg / Non-Veg / Egggetarian / No Preference)
  - Pets: pills (Yes / No / No Preference)
  - Smoking: pills (No / Yes / No Preference)
  - Move-in Timeline: dropdown ("Within 1 Month")
- CTA: "Next →" — filled primary, full width, with arrow icon

### Screen 14 — Review & Publish (`360f_14_review-publish.png`)

- Back arrow (left)
- Progress bar: 5 segments, fourth filled (step 4 of 5)
- "Review Your Listing" — H1 bold
- Subtitle: "Please review all details before publishing."
- Property photo + details card (compact listing preview)
- Expandable sections (each with icon + label + edit chevron):
  - Preferences summary
  - Property Rules summary
  - Nearby & Notes summary
- Review notice banner: shield icon + "We'll review your listing" + approval note
- CTA: "Publish Listing" — filled primary, full width, with upload icon
- "Save as Draft" — text link, centered

### Screen 15 — Profile (`360f_15_profile.png`)

- Header: "Profile" (H1, left) + settings gear icon (top-right)
- Avatar: large circular photo with edit pencil FAB overlay (bottom-right, purple circle bg)
- Name: "Rahul Sharma" — H2 bold, centered
- Role badge: checkmark icon + "Co-Hunter" — outlined pill, primary color
- Location: pin icon + "Bengaluru, Karnataka" — Body Medium, centered
- Menu list (using FlatmatesMenuItem):
  1. My Bookings (calendar_month_outlined)
  2. Shortlisted (favorite_border)
  3. My Chats (chat_bubble_outline)
  4. Documents (description_outlined)
  5. Payment Methods (payment_outlined)
  6. Settings (settings_outlined)
  7. Help & Support (help_outline)
  8. Logout (logout, red color)
- Bottom nav: 5 tabs

### Screen 16 — Listing Under Review (`360f_16_listing-under-review.png`)

- 360 logo (top-left area)
- Clipboard/checkmark illustration (center-top)
- "Listing Under Review" — H1 bold
- "Thank you! Your listing has been submitted." — Body Medium
- "Review Listing" button — outlined primary
- "We'll review your listing within 24 hours" — highlighted text
- "What happens next?" — H3 + 3 numbered steps:
  1. Team reviews (quality + safety)
  2. Verify you (ID confirmation)
  3. Go live (flat connecting)
- Property preview card (small)
- CTAs: "Go to Home Feed" (filled, with home icon) + "View Listing" (outline, with eye icon)
- Bottom nav: 5-6 tabs

### Screen 17 — Notifications (`360f_17_notifications.png`)

- Header: "Notifications" (H1, left) + checkmark/mark-all-read icon (top-right)
- Notification cards (using FlatmatesNotificationCard):
  1. Booking Confirmed — calendar icon, "Your visit with Arjun is confirmed..."
  2. New Message from Priya — chat icon, "Hey! I'm interested..."
  3. Visit Reminder — bell icon, "You have a visit with Neha..."
  4. Listing Approved — verified icon, 'Your listing "2BHK..." is now live.'
- Each card: unread dot (purple) for unread items
- Bottom nav: 5 tabs, notifications tab highlighted if present

### Screen 18 — Help & Support (`360f_18_help-support.png`)

- Back arrow (left)
- "Help & Support" — H1 bold
- Search bar: "Search for help" placeholder
- Category rows (using FlatmatesMenuItem pattern):
  1. FAQ (?) — "Find answers to common questions"
  2. Popular Topics (fire) — "Explore trending help topics"
  3. Payments & Refunds (wallet) — "Payment issues, refunds and more"
  4. Booking & Agreements (clipboard) — "Bookings, agreements & policies"
  5. Account & Profile (person) — "Manage your account and profile"
  6. Contact Support (headset) — "Get in touch with our support team"
- CTA: "Chat with Us" — filled primary, full width, with chat icon
- Note: "We usually reply in a few minutes" with shield icon
- Bottom nav: 5 tabs

### Screen 19 — Settings (`360f_19_settings.png`)

- Back arrow (left)
- "Settings" — H1 bold, centered
- Groups using FlatmatesMenuItem:
  - **Account:**
    1. Edit Profile (person)
    2. Change Password (lock)
    3. Privacy & Security (shield)
    4. Preferences (tune)
  - **App:**
    5. Notification Settings (bell)
    6. Blocked Users (person_off)
  - **Legal:**
    7. About (info)
    8. Terms & Conditions (description)
  - **Standalone:**
    9. Logout (logout, red text + red icon)
- Bottom nav: 5 tabs, Settings active

### Screen 20 — Post & Manage Property (`360f_20_post-manage-property.png`)

- 360 logo (top-left) + icons (search?, more?)
- "Post & Manage Property" — H1 bold
- "New Listing" CTA: filled primary, full width, with grid icon + "New Listing" text
- Tab bar: "Active Listings (N)" / "Drafts (N)" / "Expired (N)" — segmented control
- Property cards:
  - Image + title + price + quick stats (beds/baths/sqft/wifi)
  - Owner info row
  - Stats grid (2 rows x 3 cols): Match Count (24) | Edit | Boost | View Stats (3.8k) | Review | Share
- Bottom nav: 5 tabs, Post/Manage active

---

## Animation Guidelines

| Animation | Duration | Curve | Notes |
|-----------|----------|-------|-------|
| Page transitions (route push/pop) | 250ms | ease-out-quart (decelerate) | Default Material transition |
| Tab switch (bottom nav) | 200ms | ease-out | Fade + slight scale |
| Button press (ripple/scale) | 150ms | ease-out-circ | Scale down to 0.97 on press |
| Card appear (staggered list) | 300ms | ease-out | 50ms stagger between items |
| Swipe card rotation | varies | spring physics | Max 15° rotation |
| Compatibility ring fill | 300ms | ease-out | Animated arc drawing |
| Match celebration | <600ms | ease-out-expo | Card flip + confetti |
| Filter chip select | 150ms | ease-out | Bg/color transition |
| Bottom sheet show/dismiss | 280ms | ease-out-quart | From bottom |
| FAB → expanded state | 250ms | ease-out-back | Slight overshoot |
| Skeleton shimmer | 1200ms | linear | Repeating gradient |

### Motion Rules

- Don't animate layout properties (use AnimatedSize/Position instead)
- Ease-out curves only (exponential: quart/quint/expo)
- No bounce, no elastic (except intentional FAB overshoot)
- Keep animations under 400ms for micro-interactions
- Respect `reduceAccessibility` / animation scale settings

---

## Dark Mode

All tokens above apply to both light and dark modes. Dark mode specifics:

- Backgrounds derive from `ColorScheme.fromSeed(brightness: Brightness.dark)`
- Text colors use `onSurface`, `onSurfaceVariant` automatically
- Cards use `surfaceContainerLow` instead of pure white
- Primary color stays the same (#5B4BCF) — it works well on dark
- Borders become slightly more visible (dark mode needs more contrast)
- Shadows are reduced (dark mode has inherent depth)
- All screens must be tested in dark mode after any light-mode changes

---

## Accessibility

- Minimum touch target: 44x44px for all interactive elements
- Color contrast ratio: minimum 4.5:1 for normal text, 3:1 for large text
- Don't convey information by color alone (always pair with icons/text)
- Screen reader labels on all interactive elements (via Semantics or Tooltip)
- Focus indication visible for keyboard/navigation users
- Reduced motion: disable/ simplify all animations when system setting is on
````

## File: .maestro/config.yaml
````yaml
appId: com.the360ghar.flatmates
````

## File: .maestro/flatmates_e2e.yaml
````yaml
appId: com.the360ghar.flatmates
---
- launchApp:
    clearState: true
- assertVisible: "Enter your phone number"
- tapOn:
    id: "enter_phone_password_cta"
- tapOn:
    id: "login_phone_input"
- eraseText
- inputText: ${MAESTRO_PHONE}
- tapOn:
    id: "login_password_input"
- inputText: ${MAESTRO_PASSWORD}
- tapOn:
    id: "login_submit_button"
- assertVisible: "Picked for You"
- tapOn:
    id: "nav_profile_tab"
- tapOn:
    id: "profile_edit_button"
- tapOn:
    id: "profile_city_input"
- inputText: ${MAESTRO_CITY}
- tapOn:
    id: "profile_locality_input"
- inputText: ${MAESTRO_LOCALITY}
- tapOn:
    id: "profile_budget_min_input"
- inputText: "12000"
- tapOn:
    id: "profile_budget_max_input"
- inputText: "18000"
- tapOn:
    id: "profile_bio_input"
- inputText: "Clean, respectful, and easy to coordinate with."
- tapOn:
    id: "profile_save_button"
- assertVisible:
    id: "profile_edit_button"
- tapOn:
    id: "nav_home_tab"
- tapOn: "Like listing"
- tapOn:
    id: "nav_likes_chat_tab"
- tapOn:
    id: "chats_tab_button"
- tapOn: ${MAESTRO_CONVERSATION_PEER}
- tapOn:
    id: "chat_message_input"
- inputText: "Hi, I am interested in the room and would like to schedule a visit."
- tapOn:
    id: "chat_send_button"
- back
- tapOn:
    id: "nav_profile_tab"
- tapOn:
    id: "profile_settings_button"
- tapOn:
    id: "theme_mode_dark_option"
- tapOn:
    id: "language_hindi_option"
- assertVisible: "सेटिंग्स"
- tapOn:
    id: "logout_button"
````

## File: docs/prd.md
````markdown
# 360 Flatmates
**Find your flatmate. Find your vibe.**
*Product Requirements Document | Version 1.0*


|                                                          |                                                      |
| -------------------------------------------------------- | ---------------------------------------------------- |
| **Status**: Draft — V1 Scope Locked                        | **Platform**: Flutter (iOS + Android)                  |
| **Target Market**: Pan-India — Young Professionals (22–32) | **Monetization**: None in V1 — freemium hooks prepared |

# **1. Executive Summary**

360 Flatmates is a swipe-based flatmate-finding app built for India's young professional demographic. Inspired by the interaction patterns of modern dating apps, 360 Flatmates combines rich property listings, lifestyle compatibility scoring, and a structured conversation system to make flatmate discovery fast, trustworthy, and personality-driven.

The Indian flatmate market is large, fragmented, and deeply broken. Current solutions — Facebook groups, broker networks, NoBroker listings — are transactional and treat flatmate finding like furniture shopping. They optimise for finding a room, not finding the right person to share it with. 360 Flatmates's thesis is that shared living is fundamentally a human compatibility problem, and the best UX paradigm for human compatibility at scale is the one dating apps perfected.

360 Flatmates addresses three distinct user intents under one roof: finding a co-hunter to flat-search with, advertising a spare room to a quality flatmate, and putting your profile out there for any of the above. The result is a two-sided marketplace with three user modes, a compatibility engine, structured listing templates, rich chat with visit scheduling, and a society insights layer — all built on Flutter for a single shared codebase across iOS and Android.

# **2. Goals & Success Metrics**

## **2.1 Product Goals**

- **Reduce time-to-flatmate** — from the current average of 3–6 weeks to under 10 days for active users.

- **Increase trust** — through structured profiles, lifestyle compatibility scoring, and manual listing review.

- **Drive organic growth** — via WhatsApp-shareable listing cards that create a viral referral loop without ad spend.

- **Build monetization headroom** — by establishing freemium UI patterns (boost slots, swipe caps) even before charging begins.

## **2.2 V1 Success Metrics**

|                                          |                   |                   |
| ---------------------------------------- | ----------------- | ----------------- |
| **Metric**                               | **30-Day Target** | **90-Day Target** |
| Onboarding completion rate               | **> 65%**         | **> 72%**         |
| Listing approval time (manual review)    | **< 24 hours**    | **< 12 hours**    |
| Swipe-to-match conversion rate           | **> 8%**          | **> 12%**         |
| Match-to-chat conversion rate            | **> 55%**         | **> 65%**         |
| Chat-to-visit-scheduled rate             | **> 20%**         | **> 30%**         |
| Listing share-to-install rate (WhatsApp) | **> 5%**          | **> 10%**         |
| D7 user retention                        | **> 35%**         | **> 45%**         |
| Average onboarding time                  | **< 4 minutes**   | **< 3.5 minutes** |

# **3. Target Users & Personas**

## **3.1 Primary Demographic**

- **Age** — 22–32 years

- **Occupation** — Young professionals — tech, finance, consulting, design, media

- **Location** — Pan-India, with density expected in Bangalore, Delhi NCR, Mumbai, Hyderabad, Pune

- **Device** — Mid-range to flagship Android (primary), iPhone (secondary)

- **Behaviour** — High WhatsApp usage, familiar with swipe UX, privacy-conscious, income-positive but time-poor

## **3.2 User Personas**

### **Persona A — Priya, 26, Bangalore**

Software engineer relocating from Chennai for a new job. Doesn't know anyone in Bangalore. Needs a room within 2 weeks in Koramangala or HSR. Introverted, non-smoker, vegetarian, WFH 3 days a week. Her biggest fear: ending up with a flatmate whose lifestyle is incompatible with hers.

Mode: Co-Hunter / Open to Both. Primary need: compatibility first, location second.

### **Persona B — Arjun, 29, Delhi NCR**

Works in a startup, currently in a 3BHK in Gurugram. One flatmate is moving out. Doesn't want to deal with brokers. Needs someone clean, professional, who won't throw parties on weekdays. Has a dog.

Mode: Room Poster. Primary need: find a trustworthy person fast, with minimum friction.

### **Persona C — Meera & Siddharth, 24 & 25, Mumbai**

College friends both starting new jobs in Mumbai. Want to co-hunt together but need a third person to make rent affordable. Looking for someone with a similar social vibe who won't mind occasional house parties on weekends.

Mode: Co-Hunter (group). Primary need: find a third person to join their flat-search.

# **4. User Modes**

Every 360 Flatmates user belongs to exactly one mode at any given time. Mode is selected during onboarding and can be changed from the Profile tab at any time. Mode determines which version of the bottom navigation bar the user sees and which listing type they create.

|                  |                                                                                      |                                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Mode**         | **Who They Are**                                                                     | **What They Create**                                                                                                                     |
| **Room Poster**  | Already residing in a flat. Wants to rent out one spare room to a compatible person. | A structured room listing with property details, existing flatmate profiles, amenities, pricing breakdown, and preferred-person profile. |
| **Co-Hunter**    | Looking for one or more people to flat-search with together and split rent.          | A personal profile with budget, preferred area, lifestyle tags, move-in timeline, and what kind of co-hunter they want.                  |
| **Open to Both** | Flexible — happy to move into an existing flat or co-hunt with someone from scratch. | A combined profile indicating both openness to existing rooms and willingness to co-hunt.                                                |

## **4.1 Bottom Navigation by Mode**

|         |                        |                       |                       |
| ------- | ---------------------- | --------------------- | --------------------- |
| **Tab** | **Room Poster**        | **Co-Hunter**         | **Open to Both**      |
| Tab 1   | Home (Feed)            | Home (Feed)           | Home (Feed)           |
| Tab 2   | Post / Manage Property | Properties (Map View) | Properties (Map View) |
| Tab 3   | Swipe                  | Swipe                 | Swipe                 |
| Tab 4   | Likes & Chat           | Likes & Chat          | Likes & Chat          |
| Tab 5   | Profile                | Profile               | Profile               |

# **5. Onboarding Flow**

The entire onboarding must be completable in under 4 minutes. Every screen has a single primary action. Progress is shown via a minimal dot/step indicator. Users can skip optional steps and complete them later from their profile.

## **5.1 Splash Screens (3 screens)**

Cinematic, full-bleed illustration screens. No feature bullet points. Convey the lifestyle and emotional promise of the product:

- Screen 1 — A warm, sunlit room. Headline: "Your perfect flat is out there."

- Screen 2 — Two people sharing a cup of coffee at a kitchen counter. Headline: "So is your perfect flatmate."

- Screen 3 — App mockup. Headline: "360 Flatmates finds both."

- CTA on Screen 3: Get Started

## **5.2 Phone Authentication**

- Single screen: phone number input + country code selector (India +91 default)

- OTP screen: 6-digit OTP auto-read via SMS listener on Android

- No email, no password, no social login in V1

## **5.3 Mode Selection**

Single screen with three large illustrated cards:

- I have a room to give — "I'm living in a flat and looking for a flatmate to fill a spare room."

- Looking for a flatmate to co-hunt with — "I'm looking for someone to flat-search alongside."

- I'm open to both — "I'll move into an existing flat or team up to find a new one."

## **5.4 Basic Information**

One screen. Fields:

- First name (required)

- Age (required — must be 18+)

- Profession / Job title (required)

- City (required — searchable dropdown, all Indian cities)

- Preferred locality / area within city (optional at onboarding, required before swiping)

## **5.5 Profile Photo**

- Minimum 1 photo required (enforced before proceeding)

- Nudge: "Add 3 photos — profiles with 3+ photos get 4x more matches"

- Camera or gallery upload. No crop enforcement in V1 (just center-crop for card thumbnails).

## **5.6 Lifestyle Quiz**

8 swipeable quiz cards — one question per card. Feels like a personality test, not a form. Each card has a large emoji, a short question, and 2–4 answer options (tappable chips or a slider). Required: all 8.

|                         |                                                                  |
| ----------------------- | ---------------------------------------------------------------- |
| **Question**            | **Answer Options**                                               |
| 🌙 Sleep schedule       | Early bird (before 10pm) / Night owl (after midnight) / Flexible |
| 🧹 Cleanliness standard | Minimal / Tidy / Spotless (slider scale)                         |
| 🍽️ Food habits         | Vegetarian / Vegan / Non-vegetarian / No preference              |
| 🚬 Smoking & drinking   | Neither / Smoke outside only / Drink occasionally / Both fine    |
| 👥 Guests policy        | No overnight guests / Occasional ok / Open house                 |
| 🎉 Parties at home      | Never / Occasional weekends / Party-friendly                     |
| 💻 Work style           | WFH mostly / Office mostly / Mixed                               |
| 🐾 Pets                 | No pets / Have pets / Pet-friendly (no own pets)                 |

## **5.7 Budget & Move-In Timeline**

One screen, three inputs:

- Monthly budget range — dual-handle slider (min: Rs 5,000 / max: Rs 1,00,000+)

- Preferred localities — multi-select chip picker within selected city

- Move-in timeline — four chips: Immediate / This Month / Next Month / Flexible

## **5.8 Room Poster Listing Builder (Room Poster mode only)**

Room Posters proceed through one additional step after budget/timeline: the structured listing builder. This is described in full in Section 7.2. After completion, the listing enters manual review (24-hour SLA). The user lands on the home feed immediately with a 'Listing Under Review' banner.

> **Design Principle:** Every onboarding screen has exactly one primary CTA button. The back button is always visible. Progress dots are shown at the top. Zero dark patterns — no 'skip and lose features' framing.

# **6. Information Architecture**

## **6.1 Tab 1 — Home (Feed)**

- Default landing screen after onboarding

- 'Picked for You' horizontal scroll row — rules-based recommendations (same locality, vibe, budget overlap, compatible non-negotiables). Label: "Based on your profile"

- 'New in \[City]' section — profiles added in the last 48 hours

- 'Moving Soon' section — listings with move-in date within 7 days (countdown badge)

- Vibe filter chips at top: All / Quiet & Focused / Social & Lively / Working Professionals / Students / Pet Household

- Move-in timeline filter: All / Immediate / This Month / Next Month / Flexible

## **6.2 Tab 2 — Properties (Map View) / Post & Manage (Room Poster)**

### **Map View (Co-Hunter & Open to Both)**

- Clustered pins by locality. Color: orange = Room Available, blue = Co-Hunter.

- Filter bar: Budget range slider, Room type (single/shared/entire flat), Move-in date, Gender preference toggle, Verified listing toggle

- Tap cluster -> bottom sheet with horizontal scroll of cards for that locality

- Tap pin -> expanded mini-card with key details and 'View Full Profile' button

### **Post & Manage (Room Poster)**

- Shortcut to listing builder for new posts

- List of active listings with status badges: Live / Under Review / Expired / Paused

- Each listing card shows: match count, profile views, days until expiry, quick actions (Edit, Pause, Renew, Boost slot — free in V1)

## **6.3 Tab 3 — Swipe**

The core discovery and matching screen. Detailed in Section 7.1.

## **6.4 Tab 4 — Likes & Chat**

- Two sub-tabs: Likes (people who swiped right on you) and Chats (mutual matches with conversation)

- Likes sub-tab: grid of blurred profile photos with a 'Match' button — tapping initiates the match and opens Q\&A nudge

- Chats sub-tab: chronological list of active matches. Each row shows: profile photo, name, last message preview, unread count badge, match mode badge

## **6.5 Tab 5 — Profile**

- Profile photo carousel + edit button

- Name, age, profession, city, mode badge

- Lifestyle tags (edit from here)

- Non-negotiables section (edit)

- Budget & timeline (edit)

- Switch mode option

- Settings: Notifications, Privacy (hide last name toggle, hide exact location toggle), Account, Help & Safety

# **7. Core Features**

## **7.1 Swipe Deck — Hybrid Card Experience**

### **7.1.1 Card States**

The swipe deck uses a custom Flutter PageView with custom physics, rotation, and shadow depth animations. No third-party swipe library — built bespoke for full control of the hybrid expand behaviour.

**Collapsed State (Swipe State)**

- Primary photo (fills \~60% of card height)

- Secondary photo strip (2 small thumbnails, swipeable within card)

- Mode badge: Room Available / Co-Hunter / Open to Both (colored chip, top-left)

- Verified badge if listing has passed manual review (top-right)

- Name, age, profession (bold name, smaller age/profession)

- City + Locality (e.g., Koramangala, Bangalore)

- Rent / Budget range

- Compatibility % (large ring indicator — green 70%+, amber 40–70%, red <40%)

- 3 lifestyle chips (highest-weight matches from compatibility engine)

- 'Tap to see more' affordance (subtle upward chevron at bottom)

**Expanded State (Tapped)**

The card expands into a scrollable bottom sheet with a sticky action bar. Hero animation from collapsed to expanded. Sections:

- Video tour autoplay (muted) if posted — unmutes on tap

- 🏨 The Society — location, locality, connectivity, amenities tags

- 🌳 The Room — furnishing, balcony, attached bath, sunlight, photos

- 🏠 The Flat & Flatmates — existing flatmate mini-profiles (name, age, profession, 2 lifestyle chips each)

- 💰 Costs Breakdown — rent, deposit, maintenance, cook, maid, electricity. Bottom line: 'Your estimated monthly cost: Rs XX,XXX'

- 🧬 About Me — free-text 'typical day' prompt + full lifestyle tag cloud

- 📅 Move-in date + countdown if within 7 days

- 🏘️ Society Insights — bachelor-friendly, parking, visitor-friendly, pet-friendly, quiet, active community (user-submitted, Phase 2)

- Compatibility breakdown: per-dimension match/mismatch summary

**Sticky Action Bar (visible in both states)**

- Pass (red X, left)

- Super Like (yellow star, center)

- Like (green heart, right)

Swipe gestures also work — left to pass, right to like, up to super like. Haptic feedback on each action.

## **7.2 Listing Builder (Room Poster)**

The listing builder is a structured multi-step form that produces a rich, formatted listing. Designed to feel like filling in a beautiful template rather than a data entry form.

**Step 1 — Property Location**

- Society / Building name (text + autocomplete from previously listed societies)

- Full address (used for geocoding — lat-lng stored, address blurred to locality level in public listing)

- Locality auto-populated from geocode

**Step 2 — The Society**

- Society type: Gated / Independent / Co-living / PG

- Society amenities (multi-select icon grid): Pool, Gym, Clubhouse, Sports Facilities, Parking, Power Backup, Water Backup, Security, Lift, CCTV, Visitor Entry System, Garden

- Society vibe tags (multi-select): Bachelor-friendly, Quiet, Active Community, Family-dominant, Pet-friendly, Visitor-friendly

**Step 3 — The Room**

- Room type: Single occupancy / Shared (2 people) / Master bedroom

- Room furnishing (icon checklist): Bed, Wardrobe, AC, Geyser, Study Table, Curtains

- Room features: Attached bathroom, Private balcony, Window with sunlight, Storage space

- Photo upload: minimum 2 photos of room (enforced), maximum 10

- Video tour: optional 15–30 second vertical video upload

**Step 4 — The Flat**

- Flat configuration: 1BHK / 2BHK / 3BHK / 4BHK+ / Studio

- Floor number + total floors in building

- Flat amenities (separate from society): WiFi, Washing Machine, Refrigerator, Microwave, TV, Dining Table, Sofa, Kitchen Fully Equipped

- Existing flatmates: add mini-profiles for each current resident (name, age, profession, 3 lifestyle tags). This is the 'bundled listing' feature.

**Step 5 — Costs**

- Monthly rent (Rs)

- Security deposit (Rs)

- Maintenance: included in rent / separate amount

- Electricity: included / separate (estimated monthly Rs)

- Cook cost if applicable (Rs/month)

- Maid cost if applicable (Rs/month)

- One-time setup cost if applicable

- Auto-calculated summary: 'Total monthly outflow: Rs XX,XXX' (rent + maintenance + electricity estimate + cook + maid)

**Step 6 — About You & Preferred Flatmate**

- Free-text 'typical day' prompt (100–300 chars)

- Gender of preferred flatmate: Female / Male / Any

- Age range preference: slider (18–40)

- Non-negotiables: select up to 3 deal-breakers from the standard list

- Move-in date: date picker + urgency toggle ('Flexible on this date')

## **7.3 Compatibility Engine**

The compatibility score is calculated on-device using the two users' lifestyle quiz answers. It is a weighted average across 6 dimensions, displayed as a single percentage with a color ring on every swipe card.

|                        |            |                                                                                      |
| ---------------------- | ---------- | ------------------------------------------------------------------------------------ |
| **Dimension**          | **Weight** | **Scoring Logic**                                                                    |
| **Sleep Schedule**     | **20%**    | Exact match = 100. Adjacent = 50. Opposite = 0.                                      |
| **Cleanliness**        | **20%**    | Difference on 3-point scale. 0 gap = 100, 1 gap = 50, 2 gap = 0.                     |
| **Food Habits**        | **15%**    | Veg/Vegan strict match = 100. Non-veg + non-veg = 100. Mismatch with strict veg = 0. |
| **Smoking / Drinking** | **20%**    | Non-smoker + non-smoker = 100. One smokes = 30. Both = 100.                          |
| **Guests Policy**      | **15%**    | Exact match = 100. One step apart = 60. Two steps = 20.                              |
| **Work Style**         | **10%**    | WFH + WFH = 100 (high home presence overlap). Office + Office = 100. Mixed = 70.     |

The expanded card shows the full breakdown: per-dimension icons with match (green checkmark) or mismatch (amber warning) indicators and a one-line plain-English summary per dimension. Example: 'You're both night owls ✓ — Cleanliness mismatch ⚠ — Same food habits ✓'

## **7.4 Non-Negotiables & Deal-Breaker Filters**

Non-negotiables are hard filters applied silently before the swipe deck is populated. Incompatible profiles never appear — they are not shown as 'already passed'. Users select up to 3 non-negotiables during onboarding and can update them in Profile settings.

**Available Non-Negotiable Categories**

- Food: Vegetarian flatmates only / Vegan flatmates only / No restriction

- Smoking: Non-smoker only / No smoking inside flat / No restriction

- Drinking: No alcohol at home / Occasional ok / No restriction

- Guests: No overnight guests / Occasional guests ok / Open

- Pets: No pets / Pet-friendly / No restriction

- Gender: Female only / Male only / Any

- Partying: No parties at home / Occasional ok / Party-friendly

- Hygiene/Cleanliness: Minimum tidy standard (filters out 'minimal' self-reported cleanliness)

## **7.5 Search by Vibe**

Vibe filters appear as horizontal chip row on the Home feed and Map View. Each vibe is a named preset filter bundle that maps to combinations of lifestyle tags:

- Quiet & Focused — Non-smoker, no parties, office or WFH, early bird or flexible, low guests

- Social & Lively — Party-friendly or occasional, guests open, flexible sleep schedule

- Working Professionals — Office-goer or WFH, professional age range (24–35), tidy minimum

- Students — Age range 18–25 flag, flexible on most lifestyle dimensions

- Pet Household — Has pets or pet-friendly flag set

## **7.6 Move-In Timeline Filters**

- Four filter chips: Immediate / This Month / Next Month / Flexible

- Applied across feed, swipe deck, and map view simultaneously

- Listings with move-in date within 7 days show a red countdown badge: 'Moving in 4 days'

- Listings with expired move-in dates are automatically paused and flagged for Room Poster review

## **7.7 Smart Recommendations ('Picked for You')**

V1 uses rules-based recommendations — no ML required. Logic:

- Track: profiles tapped to expand (scroll depth > 50%), profiles saved/liked, profiles where user spent 10+ seconds in expanded view

- Recommend: same or adjacent locality, overlapping budget range (within 20%), matching vibe tags (2+), zero non-negotiable conflicts

- Surface as 'Picked for You' horizontal scroll row on Home tab, refreshed every 12 hours

- Each card shows a 'Why this?' tooltip: 'You both prefer quiet homes in Koramangala under Rs 25k'

V2 will upgrade this to a collaborative filtering model once sufficient interaction data exists.

## **7.8 Society & Community Insights**

**Phase 1 — Self-Declared (V1)**

Room Posters declare society insights during listing creation via a checkbox group. Six tags:

- Bachelor-friendly society

- Easy parking

- Visitor-friendly

- Pet-friendly society

- Quiet neighbourhood

- Active community (events, common areas used)

**Phase 2 — Community Corrections (V1.5)**

- Any user who has visited or lived in a society can vote on existing tags

- Each tag shows a thumbs up / thumbs down below it in the expanded listing view

- Tag with 3+ downvotes is flagged for admin review and shown with a 'Community disputed' warning

- A 'Report inaccurate info' button is available on all society tags from V1

**Phase 3 — Society Pages (V2)**

- Once 5+ listings exist from the same building, auto-generate a Society Page

- Aggregated insights, all current listings, average rent, community rating

# **8. Chat & Communication System**

## **8.1 Match Flow**

1. User A likes User B

2. If User B has already liked User A: mutual match triggered

3. Match celebration screen: animated card flip, 'It's a Match!' with both photos

4. Soft Q\&A nudge appears (see 8.2)

5. Chat thread opens (with or without Q\&A completion)

## **8.2 Guided Q\&A (Pre-Chat Soft Nudge)**

On match, before the chat thread opens, a bottom sheet appears with the title: 'Break the ice first?' Two buttons: 'Answer 3 quick questions' (primary) and 'Skip for now' (ghost, smaller).

**The 3 Default Q\&A Questions**

- 'What does your ideal flatmate situation look like?' (free text, 100 char max)

- 'How social are you at home on a typical weekday?' (5-point scale: Very private to Very social)

- 'One thing you absolutely need in a flatmate?' (free text, 60 char max)

**Q\&A Display Logic**

- If both users complete Q\&A: their answers are shown to each other at the top of the chat thread with a 'Both answered' banner — strong trust signal

- If only one answers: the completed answers are shown to the other person with a prompt 'They answered — want to share yours?'

- Questions rotate from a bank of 10–12 across matches so they don't feel repetitive

- Q\&A answers are stored and visible on the full profile for context

## **8.3 Chat Thread Features**

**Core Messaging**

- Text messaging with read receipts: single tick (sent), double tick (delivered), blue tick (read)

- Photo sharing — 1-tap gallery access. Users share room photos, society photos, etc.

- Push notifications for new messages (foreground and background)

**Icebreaker Prompts**

Shown as tappable chips above the keyboard before the first message is sent. Chips disappear after first message.

- 'Tell me about the room 🏠'

- 'What are your flatmates like? 👥'

- 'Are you open to negotiating rent? 💰'

- 'What's the vibe of the society? 🏘️'

- 'What does a typical weekend look like for you? 🌞'

**Match Context Card**

- Pinned at top of every chat thread — shows listing thumbnail or profile photo, mode badge, locality, and rent/budget range

- Collapsible after first view

- Tapping reopens the full listing/profile in a bottom sheet without leaving chat

**Chat Safety**

- Report button (three-dot menu): Fake profile / Spam / Inappropriate content / Uncomfortable interaction / Other

- Unmatch — removes match, chat history retained locally for safety

- Block — removes match and prevents future appearance in swipe deck

## **8.4 Schedule a Visit**

A dedicated 'Schedule Visit' button in the chat toolbar (calendar icon, persistent). Flow:

6. Requester taps Schedule Visit

7. Date picker + time slot picker (morning / afternoon / evening, or specific time)

8. Optional note: 'Main gate, ask for Arjun'

9. Visit request card appears in chat thread for the other person to confirm or suggest alternative time

10. On confirmation: visit card in thread updates to 'Visit Confirmed'. Both parties receive push notification.

11. Optional: Google Calendar sync (one-tap, asks permission once)

> **V2 Addition:** An automated follow-up message 24 hours after a scheduled visit: 'How did the visit go? Did you find your match? 👍' — this drives review and match confirmation data.

# **9. Trust & Safety**

## **9.1 V1 Trust Stack**

- **Phone OTP** — All accounts created via verified phone number. Duplicate phone number registration blocked.

- **Manual Listing Review** — All Room Poster listings go through a 24-hour human review queue before going live. Profile posts (Co-Hunters) are auto-approved.

- **AI Pre-Screening** — Before entering the human queue, listings are auto-flagged if: photos missing, key fields empty, suspicious pricing (Rs 0 or Rs 10L+), or content keywords that suggest spam/inappropriate content. Estimated 60% reduction in queue volume.

- **Report & Block System** — In-chat report flows for all user types. Repeat-reported profiles are auto-paused pending admin review after 3 reports.

- **Address Privacy** — Listing location is blurred to locality level in public view. Full address is never shown to unmatched users. Revealed only in chat post-match at Room Poster's discretion.

## **9.2 Admin Review Queue (Flutter Web)**

Built as a Flutter Web application from the same codebase. Accessible to admin team only.

- Review queue sorted by submission time, oldest first

- Each listing shows: all photos, full listing content, Room Poster's profile, phone number (masked), AI flag reason if any

- Three actions: Approve / Request Edit (templated reason + free text) / Reject (templated reason)

- 'Request Edit' sends a push notification to the Room Poster with specific changes required. Listing re-enters queue on resubmission.

- 24-hour SLA tracked. Overdue listings flagged in red in the queue.

## **9.3 Data Stored for V2 Trust Features**

- Listing lat-lng coordinates stored on every listing creation (for V2 nearby essentials integration)

- Society tag vote counts (for V2 community corrections)

- Profile view duration per session (for V2 smart recommendations upgrade)

- Match + visit + resolution outcomes (for V2 success rate metrics and review system)

# **10. Growth Strategy**

## **10.1 WhatsApp Share Card (Primary Growth Channel)**

Every listing auto-generates a shareable image card. The card is generated on-device or server-side and formatted for WhatsApp / Instagram Stories sharing:

- Card dimensions: 1080x1920 (9:16 vertical) for Stories; 1080x1080 square for WhatsApp

- Card content: Primary room photo, Society name, Locality, Rent per month, Top 3 amenity icons, Move-in date, QR code, 360 Flatmates branding with App Store + Play Store links

- One-tap share to WhatsApp / Instagram / copy link

- Deep link in QR code and URL directs to: App Store/Play Store if not installed, or directly to the listing in-app if installed

- Room Posters are nudged to share their listing after approval: 'Your listing is live — share it to reach 5x more people'

## **10.2 Cold Start Strategy (Pan-India)**

Going pan-India from day one creates a density problem in smaller cities. Mitigation:

- **City counter** — Home screen shows 'X people looking in \[your city] right now'. Transparency over fake activity.

- **Waitlist mode** — In cities below a density threshold (< 50 active users), show a 'Notify me when more people join in \[city]' CTA instead of an empty swipe deck.

- **Broad search radius default** — Users in tier-2 cities default to a 30km search radius rather than 5km, increasing visible deck size.

- **Co-hunter matching boost** — Co-hunters see each other across a wider radius than Room Posters, since co-hunters need a person, not a specific location.

## **10.3 Freemium Hooks (V1 Preparation)**

No monetization in V1, but the following UI patterns are built in to train user behaviour and enable a frictionless paywall introduction in V2:

- **Boost slot** — The Room Poster's 'Manage Listing' screen already shows a 'Boost listing' button — free in V1, paid in V2. This slot in the UI trains Room Posters to see boosting as a normal action.

- **Swipe cap UI** — The swipe deck shows a faint 'X swipes remaining today' counter (but the cap is set to a high number like 100 in V1 so it's never actually hit). Trains users to see swipes as a resource.

- **Super Like scarcity** — Super Likes are capped at 3 per day in V1 (genuinely enforced). This establishes Super Like as a premium signal even before a paywall.

- **Profile boost on listing approval** — Notify Room Posters that 'Your listing has been boosted for 24 hours' on first approval — models paid boost value.

# **11. Technical Architecture**

## **11.1 Stack Overview**

|                           |                                                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Layer**                 | **Technology**                                                                                             |
| **Frontend (Mobile)**     | Flutter 3.x — single codebase for iOS and Android                                                          |
| **Frontend (Admin)**      | Flutter Web — same codebase, separate entry point                                                          |
| **State Management**      | Riverpod (recommended) or Bloc — decision at sprint 1                                                      |
| **Backend**               | Firebase (Auth, Firestore, Storage, Functions, FCM)                                                        |
| **Media Storage**         | Firebase Storage for photos and video tours                                                                |
| **Geocoding**             | Google Maps Geocoding API — called on listing save (lat-lng stored, not displayed in V1)                   |
| **OTP / Auth**            | Firebase Phone Auth                                                                                        |
| **Push Notifications**    | Firebase Cloud Messaging (FCM)                                                                             |
| **Share Card Generation** | flutter\_screenshot + share\_plus packages for on-device card generation                                   |
| **AI Pre-Screening**      | Firebase Cloud Function calling a simple keyword/completeness classifier (no external ML API needed in V1) |

## **11.2 Flutter Project Structure**

- lib/features/ — feature-first folder structure (auth, onboarding, swipe, listings, chat, profile, admin)

- lib/core/ — shared widgets, theme, routing, constants

- lib/models/ — Firestore data models (UserModel, ListingModel, MatchModel, MessageModel, VisitModel)

- lib/services/ — Firebase service wrappers (auth\_service, listing\_service, chat\_service, notification\_service)

## **11.3 Key Firestore Collections**

- users/{uid} — profile, lifestyle quiz answers, mode, budget, non-negotiables, locationPref

- listings/{listingId} — all listing fields, posterUid, status (pending/live/paused/expired), lat-lng, societyTags, amenities, costs, flatmates array

- swipes/{uid}/decisions/{targetId} — direction (like/pass/superlike), timestamp

- matches/{matchId} — uid1, uid2, listingId (if applicable), matchedAt, qaAnswers

- messages/{matchId}/msgs/{msgId} — senderId, text, photoUrl, type, timestamp, readAt

- visits/{visitId} — matchId, requesterId, date, time, note, status (requested/confirmed/completed)

- listings/{listingId}/societyVotes/{uid} — per-tag votes for community insights

## **11.4 Important Implementation Notes**

- **Lat-lng storage** — Always geocode and store lat-lng on every listing save, even in V1 where nearby essentials are not yet displayed. Firebase Function triggers on listing creation to call Geocoding API.

- **Compatibility calculation** — Calculated client-side from locally cached lifestyle data. No server call needed per swipe — fast and cost-free.

- **Deal-breaker filtering** — Applied as a Firestore query filter before swipe deck population. Non-negotiables stored as indexed fields on user documents to enable efficient querying.

- **Video tour** — Use Firebase Storage with streaming URL. Auto-play muted in expanded card. Size cap: 50MB, duration cap: 30 seconds (enforced client-side before upload).

- **WhatsApp share card** — Generated on-device using RenderRepaintBoundary — avoids any server-side image generation cost in V1.

# **12. Feature Priority Matrix — V1 vs V2**

|                                                               |        |        |               |
| ------------------------------------------------------------- | :----: | :----: | :-----------: |
| **Feature**                                                   | **V1** | **V2** | **Data Only** |
| Phone OTP authentication                                      |  **✅** |        |               |
| Three user modes (Room Poster, Co-Hunter, Open to Both)       |  **✅** |        |               |
| Onboarding flow (under 4 mins)                                |  **✅** |        |               |
| Lifestyle quiz (8 questions)                                  |  **✅** |        |               |
| Structured listing builder (6-step)                           |  **✅** |        |               |
| Amenities icon grid (room + society)                          |  **✅** |        |               |
| Existing flatmate mini-profiles (bundled listings)            |  **✅** |        |               |
| Pricing split calculator                                      |  **✅** |        |               |
| Video room tours (15–30 sec)                                  |  **✅** |        |               |
| Hybrid swipe card (collapsed + expanded)                      |  **✅** |        |               |
| Compatibility score (6-dimension, % + ring)                   |  **✅** |        |               |
| Deal-breaker hard filters (up to 3)                           |  **✅** |        |               |
| Move-in timeline filter (4 states)                            |  **✅** |        |               |
| Move-in countdown badge (7-day urgency)                       |  **✅** |        |               |
| Search by vibe (5 preset filter bundles)                      |  **✅** |        |               |
| Society tags — self-declared by Room Poster                   |  **✅** |        |               |
| Map view with clustered pins and filter bar                   |  **✅** |        |               |
| WhatsApp share card (deep link, QR)                           |  **✅** |        |               |
| Soft Q\&A nudge on match (3 questions)                        |  **✅** |        |               |
| Icebreaker chips in chat                                      |  **✅** |        |               |
| Full chat (text + photo + read receipts)                      |  **✅** |        |               |
| Schedule Visit in chat (date/time picker + confirmation card) |  **✅** |        |               |
| Match context card pinned in chat                             |  **✅** |        |               |
| Report / Unmatch / Block                                      |  **✅** |        |               |
| Push notifications (new match, message, visit)                |  **✅** |        |               |
| Manual listing review queue (Flutter Web admin)               |  **✅** |        |               |
| AI pre-screening before review queue                          |  **✅** |        |               |
| Freemium hook UI (boost slot, swipe counter, super like cap)  |  **✅** |        |               |
| Cold start: waitlist mode + city counter                      |  **✅** |        |               |
| Lat-lng storage on all listings                               |        |        |     **✅**     |
| Society tag vote counts (for community corrections)           |        |        |     **✅**     |
| Profile view duration tracking                                |        |        |     **✅**     |
| Smart recommendations — rules-based 'Picked for You'          |  **✅** |        |               |
| Smart recommendations — ML collaborative filtering upgrade    |        |  **✅** |               |
| Society insights — community votes & disputes                 |        |  **✅** |               |
| Society Pages (aggregated per-building view)                  |        |  **✅** |               |
| Nearby essentials (metro, gym, grocery, hospital)             |        |  **✅** |               |
| Roommate review system (post-move-in rating)                  |        |  **✅** |               |
| Roommate agreement PDF generator                              |        |  **✅** |               |
| Aadhaar / Govt ID verification                                |        |  **✅** |               |
| Paid boost / featured listing monetization                    |        |  **✅** |               |
| Google Calendar sync for visits                               |        |  **✅** |               |

# **13. Screen-by-Screen Flow Reference**

## **13.1 Room Poster Flow**

- Splash (3 screens) → Phone OTP → Mode Selection → Basic Info → Profile Photo → Lifestyle Quiz (8 cards) → Budget & Timeline → Listing Builder (6 steps) → Listing Under Review screen → Home Feed

* Tab 2 (Post/Manage): New Listing button → Listing Builder | Active listing card → View Stats, Edit, Pause, Share

* Tab 3 (Swipe): Swipe deck of Co-Hunters and Seekers. Like/Pass/Super Like. Tap to expand profile.

* Tab 4 (Likes & Chat): Likes sub-tab (blurred cards with Match button) → Match → Q\&A nudge → Chat thread

## **13.2 Co-Hunter Flow**

- Splash → OTP → Mode → Basic Info → Photo → Lifestyle Quiz → Budget & Timeline → Home Feed

* Tab 2 (Properties/Map): Clustered map → Tap cluster → Card carousel → Tap card → Expanded listing → Like from expanded view

* Tab 3 (Swipe): Swipe deck of Room Postings + other Co-Hunters. Hybrid card.

* Tab 4 (Likes & Chat): Same as above → Chat → Schedule Visit → Visit Confirmed

## **13.3 Chat Thread Screen Flow**

- Enter chat → Q\&A answers shown if available (or nudge to complete) → Match context card (collapsible) → Icebreaker chips if first message → Message thread → Schedule Visit (toolbar) → Visit card in thread → Confirm/Reschedule

## **13.4 Admin Queue Screen Flow**

- Login (admin accounts only, Firebase Auth with role claim) → Queue list (sorted by submission time) → Listing detail view (all photos, content, poster profile, AI flag reason) → Approve / Request Edit / Reject → Notification sent to Room Poster

# **14. Design Principles & UI Guidelines**

## **14.1 Design Philosophy**

- **Personality-first** — Lead with the person, not the property. Compatibility % appears before rent price on swipe cards.

- **Structured freedom** — Listings are structured enough to be scannable in 10 seconds but rich enough to tell a story. The emoji-section template (🏨 🌳 🏠 💰) makes even lazy users produce good posts.

- **Trust through transparency** — Show compatibility breakdowns, not just scores. Show why something is recommended. Show how many people are in the city right now.

- **Mobile-native** — Every interaction designed for one-handed phone use. No horizontal scroll for primary actions. Bottom sheet patterns over navigation pushes wherever possible.

## **14.2 Color System**

|                  |             |                                                             |
| ---------------- | ----------- | ----------------------------------------------------------- |
| **Token**        | **Hex**     | **Usage**                                                   |
| **Brand Purple** | **#5B4FCF** | Primary CTA, active tab, compatibility ring, mode badges    |
| **Brand Light**  | **#EDE9FF** | Card backgrounds, callout boxes, tag backgrounds            |
| **Accent Coral** | **#FF6B6B** | Pass button, error states, urgency badges                   |
| **Match Green**  | **#10B981** | Like button, compatibility match indicators, success states |
| **Super Yellow** | **#F59E0B** | Super Like, V2 feature badges, countdown urgency            |
| **Dark Navy**    | **#1A1A2E** | Primary text, headings                                      |
| **Body Gray**    | **#374151** | Body copy, secondary text                                   |
| **Light Gray**   | **#F3F4F6** | Screen backgrounds, alternate table rows                    |

## **14.3 Typography**

- **Font** — Inter (preferred) or system default (SF Pro on iOS, Roboto on Android) — do not import custom fonts for V1 to keep bundle size lean

- **Display / Names on cards** — 24sp, Bold

- **Body / Listing content** — 14sp, Regular, line height 1.5

- **Chips / Tags** — 12sp, Medium, rounded 100px border radius

- **Captions / Metadata** — 12sp, Regular, secondary text color

## **14.4 Animation Guidelines**

- Swipe card: PageView with custom physics. Rotation: max 15 degrees at full drag. Shadow deepens on lift. Snap-back on release below threshold (20% screen width).

- Card expand: Bottom sheet slides up with spring physics. Hero animation on primary photo.

- Match animation: Card flip + confetti burst (keep under 600ms total).

- Tab switching: Fade transition, 200ms. No slide transitions on tab bar.

- Compatibility ring: Animated fill on card appearance (300ms ease-out).

# **15. Open Questions & Decisions Deferred**

|                                                                              |                                                                                        |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Open Question**                                                            | **Notes**                                                                              |
| **State management: Riverpod vs Bloc?**                                      | Riverpod recommended for new projects. Bloc if team has existing Bloc expertise.       |
| **App name: '360 Flatmates' confirmed or placeholder?**                      | Name used throughout this doc. Confirm before domain / App Store registration.         |
| **Should Co-Hunters be able to form groups (2+ people searching together)?** | Described in personas but not scoped in V1 flows. Defer to V1.5.                       |
| **Should broker/agent accounts be allowed to post listings?**                | V1 assumes individual users only. Broker accounts are a monetization lever for V2.     |
| **What is the maximum swipe cap for V1?**                                    | Recommended: 100/day (effectively unlimited). Set lower cap in V2 paywall.             |
| **Video tour: Firebase Storage or third-party CDN?**                         | Firebase Storage sufficient for V1. Evaluate Cloudflare Stream or Mux at V2 scale.     |
| **Should users be able to change mode freely or once per 30 days?**          | Recommend: freely changeable in V1 to reduce friction. Add rate-limit in V2 if abused. |

---
**360 Flatmates — PRD v1.0**
*This document is confidential. All feature decisions subject to sprint review.*
````

## File: lib/core/compatibility/compatibility_engine.dart
````dart
import 'package:flutter/material.dart';

Color compatibilityScoreColor(double percentage) {
  if (percentage >= 70) return const Color(0xFF10B981);
  if (percentage >= 40) return const Color(0xFFF59E0B);
  return const Color(0xFFFF6B6B);
}

class CompatibilityDimension {
  const CompatibilityDimension({
    required this.key,
    required this.weight,
    required this.userValue,
    required this.peerValue,
    required this.score,
    required this.isMatch,
    required this.summary,
  });

  final String key;
  final double weight;
  final String userValue;
  final String peerValue;
  final double score;
  final bool isMatch;
  final String summary;
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.percentage,
    required this.dimensions,
    required this.topMatchChips,
  });

  final double percentage;
  final List<CompatibilityDimension> dimensions;
  final List<String> topMatchChips;
}

class CompatibilityEngine {
  const CompatibilityEngine._();

  static CompatibilityResult calculate({
    required Map<String, String> user,
    required Map<String, String> peer,
  }) {
    final dimensions = <CompatibilityDimension>[];

    dimensions.add(
      _sleepSchedule(
        _normalize('sleep_schedule', user['sleep_schedule'] ?? 'flexible'),
        _normalize('sleep_schedule', peer['sleep_schedule'] ?? 'flexible'),
      ),
    );
    dimensions.add(
      _cleanliness(
        _normalize('cleanliness', user['cleanliness'] ?? 'tidy'),
        _normalize('cleanliness', peer['cleanliness'] ?? 'tidy'),
      ),
    );
    dimensions.add(
      _foodHabits(
        _normalize('food_habits', user['food_habits'] ?? 'no_preference'),
        _normalize('food_habits', peer['food_habits'] ?? 'no_preference'),
      ),
    );
    dimensions.add(
      _smokingDrinking(
        _normalize('smoking_drinking', user['smoking_drinking'] ?? 'neither'),
        _normalize('smoking_drinking', peer['smoking_drinking'] ?? 'neither'),
      ),
    );
    dimensions.add(
      _guestsPolicy(
        _normalize('guests_policy', user['guests_policy'] ?? 'occasional_ok'),
        _normalize('guests_policy', peer['guests_policy'] ?? 'occasional_ok'),
      ),
    );
    dimensions.add(
      _workStyle(
        user['work_style'] ?? 'hybrid',
        peer['work_style'] ?? 'hybrid',
      ),
    );

    double weightedSum = 0;
    double weightTotal = 0;
    for (final dim in dimensions) {
      weightedSum += dim.score * dim.weight;
      weightTotal += dim.weight;
    }

    final percentage = weightTotal > 0
        ? (weightedSum / weightTotal) * 100.0
        : 0.0;

    // Sort dimensions by score (highest first) and take top 3 matches
    final sortedDimensions = List<CompatibilityDimension>.from(dimensions)
      ..sort((a, b) => b.score.compareTo(a.score));

    final topChips = <String>[];
    for (final dim in sortedDimensions) {
      if (dim.isMatch && topChips.length < 3) {
        topChips.add(dim.summary);
      }
    }

    return CompatibilityResult(
      percentage: percentage.clamp(0, 100),
      dimensions: dimensions,
      topMatchChips: topChips,
    );
  }

  static String _normalize(String key, String value) {
    return switch ((key, value)) {
      ('sleep_schedule', 'before_7') => 'early_bird',
      ('sleep_schedule', '7_to_9') => 'flexible',
      ('sleep_schedule', 'after_9') => 'night_owl',
      ('cleanliness', 'laid_back') => 'minimal',
      ('cleanliness', 'balanced') => 'tidy',
      ('cleanliness', 'meticulous') => 'spotless',
      ('food_habits', 'veg') => 'vegetarian',
      ('food_habits', 'non_veg') => 'non_vegetarian',
      ('smoking_drinking', 'never') => 'neither',
      ('smoking_drinking', 'occasionally') => 'drink_occasionally',
      ('smoking_drinking', 'regularly') => 'both_fine',
      ('guests_policy', 'rarely') => 'no_overnight_guests',
      ('guests_policy', 'occasionally') => 'occasional_ok',
      ('guests_policy', 'comfortable') => 'open_house',
      _ => value,
    };
  }

  static CompatibilityDimension _sleepSchedule(String a, String b) {
    const values = ['early_bird', 'flexible', 'night_owl'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    double score;
    if (ai == bi) {
      score = 100;
    } else if ((ai - bi).abs() == 1) {
      score = 50;
    } else {
      score = 0;
    }
    return CompatibilityDimension(
      key: 'sleep_schedule',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same sleep schedule' : 'Similar sleep habits',
    );
  }

  static CompatibilityDimension _cleanliness(String a, String b) {
    const values = ['minimal', 'tidy', 'spotless'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    final gap = (ai - bi).abs();
    final score = switch (gap) {
      0 => 100.0,
      1 => 50.0,
      _ => 0.0,
    };
    return CompatibilityDimension(
      key: 'cleanliness',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: gap <= 1,
      summary: score == 100 ? 'Same cleanliness level' : 'Similar cleanliness',
    );
  }

  static CompatibilityDimension _foodHabits(String a, String b) {
    // Handle no_preference cases
    if (a == 'no_preference' || b == 'no_preference') {
      return CompatibilityDimension(
        key: 'food_habits',
        weight: 0.15,
        userValue: a,
        peerValue: b,
        score: 100,
        isMatch: true,
        summary: 'Flexible food preferences',
      );
    }

    const strict = {'vegetarian', 'vegan'};
    double score;
    if (a == b) {
      score = 100;
    } else if (strict.contains(a) && strict.contains(b)) {
      // Both vegetarian/vegan - compatible
      score = 100;
    } else if (strict.contains(a) || strict.contains(b)) {
      // One is strict, other is not
      score = 0;
    } else {
      // Both non-vegetarian or flexible
      score = 100;
    }
    return CompatibilityDimension(
      key: 'food_habits',
      weight: 0.15,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same food habits' : 'Different food preferences',
    );
  }

  static CompatibilityDimension _smokingDrinking(String a, String b) {
    // Handle no_preference cases
    if (a == 'no_preference' || b == 'no_preference') {
      return CompatibilityDimension(
        key: 'smoking_drinking',
        weight: 0.20,
        userValue: a,
        peerValue: b,
        score: 100,
        isMatch: true,
        summary: 'Flexible lifestyle habits',
      );
    }

    const nonSmoker = {'neither', 'drink_occasionally'};
    const smoker = {'smoke_outside'};
    const drinker = {'drink_occasionally', 'both_fine'};

    double score;
    if (a == b) {
      score = 100;
    } else if (nonSmoker.contains(a) && nonSmoker.contains(b)) {
      // Both non-smokers (one or both may drink)
      score = 80;
    } else if (smoker.contains(a) && smoker.contains(b)) {
      // Both smoke - compatible
      score = 100;
    } else if ((smoker.contains(a) && !smoker.contains(b)) ||
        (!smoker.contains(a) && smoker.contains(b))) {
      // One smokes, other doesn't
      score = 30;
    } else if (drinker.contains(a) && drinker.contains(b)) {
      // Both okay with drinking
      score = 80;
    } else {
      // Mixed preferences
      score = 50;
    }
    return CompatibilityDimension(
      key: 'smoking_drinking',
      weight: 0.20,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score >= 80
          ? 'Very compatible habits'
          : score >= 50
          ? 'Compatible habits'
          : 'Lifestyle differences',
    );
  }

  static CompatibilityDimension _guestsPolicy(String a, String b) {
    const values = ['no_overnight_guests', 'occasional_ok', 'open_house'];
    final ai = values.indexOf(a);
    final bi = values.indexOf(b);
    final gap = (ai - bi).abs();
    final score = switch (gap) {
      0 => 100.0,
      1 => 60.0,
      _ => 20.0,
    };
    return CompatibilityDimension(
      key: 'guests_policy',
      weight: 0.15,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: gap <= 1,
      summary: score == 100 ? 'Same guest policy' : 'Similar guest policy',
    );
  }

  static CompatibilityDimension _workStyle(String a, String b) {
    double score;
    if (a == b) {
      score = 100;
    } else if ((a == 'wfh' && b == 'office') || (a == 'office' && b == 'wfh')) {
      score = 40;
    } else {
      score = 70;
    }
    return CompatibilityDimension(
      key: 'work_style',
      weight: 0.10,
      userValue: a,
      peerValue: b,
      score: score,
      isMatch: score >= 50,
      summary: score == 100 ? 'Same work style' : 'Different work styles',
    );
  }
}
````

## File: lib/core/compatibility/compatibility_ring.dart
````dart
import 'dart:math' as math show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../compatibility/compatibility_engine.dart';

class CompatibilityRing extends ConsumerStatefulWidget {
  const CompatibilityRing({
    required this.percentage,
    this.size = 72,
    this.strokeWidth = 5,
    super.key,
  });

  final double percentage;
  final double size;
  final double strokeWidth;

  @override
  ConsumerState<CompatibilityRing> createState() => _CompatibilityRingState();
}

class _CompatibilityRingState extends ConsumerState<CompatibilityRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CompatibilityRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _color() => compatibilityScoreColor(widget.percentage);

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final animatedValue =
                  (widget.percentage / 100) * _animation.value;
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ArcPainter(
                  progress: animatedValue.clamp(0.0, 1.0),
                  color: color,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              );
            },
          ),
          Text(
            '${widget.percentage.round()}%',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: widget.size * 0.22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws an animated arc (circular progress).
class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class CompatibilityBreakdown extends StatelessWidget {
  const CompatibilityBreakdown({required this.result, super.key});

  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: result.dimensions.map((dim) {
        final icon = dim.isMatch
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded;
        final color = dim.isMatch
            ? compatibilityScoreColor(100)
            : compatibilityScoreColor(40);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dim.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dim.score.round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
````

## File: lib/core/config/app_config.dart
````dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, staging, prod }

bool? _parseBool(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) return null;
  if (value == 'true' || value == '1' || value == 'yes') return true;
  if (value == 'false' || value == '0' || value == 'no') return false;
  return null;
}

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableDebugLogs,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableDebugLogs;

  static AppEnvironment _parseEnvironment(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'stage':
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.dev;
    }
  }

  factory AppConfig.fromEnvironment() {
    const envDefine = String.fromEnvironment('APP_ENV');
    final environment = _parseEnvironment(
      envDefine.trim().isNotEmpty
          ? envDefine
          : (dotenv.env['APP_ENV'] ?? 'dev'),
    );

    const apiDefine = String.fromEnvironment('API_BASE_URL');
    var apiBaseUrl = apiDefine.trim().isNotEmpty
        ? apiDefine
        : (dotenv.env['API_BASE_URL'] ?? '');

    const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
    var supabaseUrl = supabaseUrlDefine.trim().isNotEmpty
        ? supabaseUrlDefine
        : (dotenv.env['SUPABASE_URL'] ?? '');

    const supabaseKeyDefine = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    var supabaseAnonKey = supabaseKeyDefine.trim().isNotEmpty
        ? supabaseKeyDefine
        : (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '');

    const debugLogsDefine = String.fromEnvironment('ENABLE_DEBUG_LOGS');
    final enableDebugLogs =
        _parseBool(
          debugLogsDefine.trim().isNotEmpty
              ? debugLogsDefine
              : dotenv.env['ENABLE_DEBUG_LOGS'],
        ) ??
        !kReleaseMode;

    if (apiBaseUrl.trim().isEmpty) {
      throw StateError(
        'API_BASE_URL is required. Set it via .env, --dart-define, or environment variable.',
      );
    }
    if (supabaseUrl.trim().isEmpty || supabaseAnonKey.trim().isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY configuration.',
      );
    }

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableDebugLogs: enableDebugLogs,
    );
  }
}
````

## File: lib/core/config/constants.dart
````dart
const kPrivacyPolicyUrl = 'https://the360ghar.com/privacy';
const kTermsOfServiceUrl = 'https://the360ghar.com/terms';
const kSupportEmail = 'support@the360ghar.com';

/// Apple App Store ID — MUST be replaced with the real ID before iOS release.
/// Used for deep-linking to the App Store review / download page.
/// While the placeholder is still set, [appStoreUrl] returns an empty string
/// to avoid producing invalid App Store URLs.
const kAppStoreId = 'REPLACE_WITH_APP_STORE_ID';

/// Google Play Store ID — update this when the app is published.
const kPlayStoreId = 'com.the360ghar.flatmates';

/// Constructs the App Store deep link URL using [kAppStoreId].
/// Returns an empty string if [kAppStoreId] is still the placeholder value.
String get appStoreUrl {
  if (kAppStoreId == 'REPLACE_WITH_APP_STORE_ID') return '';
  return 'https://apps.apple.com/app/id$kAppStoreId';
}

/// Constructs the Play Store deep link URL using [kPlayStoreId].
String get playStoreUrl =>
    'https://play.google.com/store/apps/details?id=$kPlayStoreId';
````

## File: lib/core/network/interceptors/auth_interceptor.dart
````dart
import 'dart:async';

import 'package:dio/dio.dart';

import '../auth_token_provider.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required AuthTokenProvider tokenProvider, required Dio dio})
    : _tokenProvider = tokenProvider,
      _dio = dio;

  final AuthTokenProvider _tokenProvider;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_QueuedRequest> _queuedRequests = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        // Queue this request while a refresh is in progress
        final completer = Completer<void>();
        _queuedRequests.add(
          _QueuedRequest(
            completer: completer,
            handler: handler,
            requestOptions: err.requestOptions,
          ),
        );
        await completer.future;
        return;
      }

      _isRefreshing = true;
      try {
        final newToken = await _tokenProvider.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          _isRefreshing = false;
          handler.resolve(response);
          _processQueue(newToken);
          return;
        }
        _isRefreshing = false;
        _failQueue();
      } catch (_) {
        _isRefreshing = false;
        _failQueue();
      }
      await _tokenProvider.clearSession();
    } else {
      handler.next(err);
    }
  }

  Future<void> _processQueue(String token) async {
    final queued = List<_QueuedRequest>.from(_queuedRequests);
    _queuedRequests.clear();
    for (final item in queued) {
      try {
        item.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch(item.requestOptions);
        item.handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          item.handler.next(e);
        } else {
          item.handler.next(
            DioException(requestOptions: item.requestOptions, error: e),
          );
        }
      }
      item.completer.complete();
    }
  }

  void _failQueue() {
    final queued = List<_QueuedRequest>.from(_queuedRequests);
    _queuedRequests.clear();
    for (final item in queued) {
      item.completer.complete();
    }
  }
}

class _QueuedRequest {
  const _QueuedRequest({
    required this.completer,
    required this.handler,
    required this.requestOptions,
  });

  final Completer<void> completer;
  final ErrorInterceptorHandler handler;
  final RequestOptions requestOptions;
}
````

## File: lib/core/network/interceptors/error_interceptor.dart
````dart
import 'package:dio/dio.dart';

final class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final friendlyMessage = _mapToUserMessage(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: friendlyMessage,
        message: friendlyMessage,
      ),
    );
  }

  String _mapToUserMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
      case DioExceptionType.badResponse:
        return _mapStatusCode(err.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        if (err.error.toString().contains('SocketException')) {
          return 'No internet connection. Please check your network settings.';
        }
        return 'Something went wrong. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';
    }
  }

  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please sign in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. The data may have changed.';
      case 422:
        return 'Invalid data provided. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
````

## File: lib/core/network/api_client.dart
````dart
import 'package:dio/dio.dart';

import 'auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

final class ApiClient {
  ApiClient({
    required String baseUrl,
    required AuthTokenProvider tokenProvider,
    required bool enableLogging,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 30),
           sendTimeout: const Duration(seconds: 30),
           headers: const {'Accept': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(
      AuthInterceptor(tokenProvider: tokenProvider, dio: _dio),
    );
    _dio.interceptors.add(ErrorInterceptor());
    if (enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(path, data: data, queryParameters: queryParameters);
  }
}
````

## File: lib/core/network/auth_token_provider.dart
````dart
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../storage/auth_token_storage.dart';

abstract interface class AuthTokenProvider {
  Future<String?> getAccessToken();

  Future<void> clearSession();
}

final class RefreshingAuthTokenProvider implements AuthTokenProvider {
  RefreshingAuthTokenProvider(this._storage);

  final AuthTokenStorage _storage;

  @override
  Future<String?> getAccessToken() async {
    late final supabase.SupabaseClient client;
    try {
      client = supabase.Supabase.instance.client;
    } catch (_) {
      await _storage.clear();
      return null;
    }

    var session = client.auth.currentSession;
    if (session == null) {
      await _storage.clear();
      return null;
    }

    if (session.isExpired || _isJwtExpired(session.accessToken)) {
      try {
        final refreshed = await client.auth.refreshSession();
        session = refreshed.session ?? client.auth.currentSession;
      } catch (_) {
        await _storage.clear();
        return null;
      }
    }

    final token = session?.accessToken;
    if (token != null && token.isNotEmpty) {
      await _storage.save(token);
      return token;
    }

    await _storage.clear();
    return null;
  }

  @override
  Future<void> clearSession() async {
    await _storage.clear();
    try {
      await supabase.Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore SDK cleanup failures.
    }
  }
}

bool _isJwtExpired(
  String token, {
  Duration skew = const Duration(seconds: 10),
}) {
  final parts = token.split('.');
  if (parts.length < 2) return false;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return false;
    final exp = payload['exp'];
    final expiry = exp is num
        ? exp.toInt()
        : int.tryParse(exp?.toString() ?? '');
    if (expiry == null) return false;
    return DateTime.now()
        .add(skew)
        .isAfter(DateTime.fromMillisecondsSinceEpoch(expiry * 1000));
  } catch (_) {
    return false;
  }
}
````

## File: lib/core/storage/app_preferences.dart
````dart
import 'package:shared_preferences/shared_preferences.dart';

abstract final class PrefKeys {
  static const themeMode = 'theme_mode';
  static const palette = 'theme_palette';
  static const localeLanguageCode = 'locale_language_code';
  static const localeCountryCode = 'locale_country_code';
  static const hideLastName = 'privacy_hide_last_name';
  static const hideExactLocation = 'privacy_hide_exact_location';
}

final class AppPreferences {
  AppPreferences._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences._(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);

  bool getBool(String key) => _prefs.getBool(key) ?? false;

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
}
````

## File: lib/core/storage/auth_token_storage.dart
````dart
import 'dart:async';

import 'secure_kv_store.dart';

final class AuthTokenStorage {
  AuthTokenStorage(this._store);

  static const _tokenKey = 'auth_token';

  final SecureKvStore _store;
  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();

  Stream<String?> get changes => _changes.stream;

  Future<String?> read() => _store.readString(_tokenKey);

  Future<void> save(String token) async {
    await _store.writeString(key: _tokenKey, value: token);
    _changes.add(token);
  }

  Future<void> clear() async {
    await _store.delete(_tokenKey);
    _changes.add(null);
  }
}
````

## File: lib/core/storage/image_upload_service.dart
````dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  const ImageUploadService();

  Future<List<File>> pickImages({int limit = 10}) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return [];
    return images.take(limit).map((x) => File(x.path)).toList();
  }

  Future<File?> pickFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<File?> pickVideo({
    Duration maxDuration = const Duration(seconds: 30),
  }) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
    if (video == null) return null;
    return File(video.path);
  }

  Future<VideoValidationResult> validateVideo(File file) async {
    final size = await file.length();
    if (size > 50 * 1024 * 1024) {
      return VideoValidationResult(tooLarge: true, tooLong: false);
    }
    return const VideoValidationResult(tooLarge: false, tooLong: false);
  }

  Future<String?> uploadProfilePhoto(File file) async {
    return _upload(file, 'profile-photos');
  }

  Future<String?> uploadListingPhoto(File file) async {
    return _upload(file, 'listing-photos');
  }

  Future<String?> uploadChatPhoto(File file) async {
    return _upload(file, 'chat-photos');
  }

  Future<String?> uploadVideoTour(File file) async {
    return _upload(file, 'listing-videos');
  }

  Future<String?> _upload(File file, String bucket) async {
    final supabase = Supabase.instance.client;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    try {
      await supabase.storage.from(bucket).upload(fileName, file);
      return supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}

class VideoValidationResult {
  const VideoValidationResult({required this.tooLarge, required this.tooLong});
  final bool tooLarge;
  final bool tooLong;
  bool get isValid => !tooLarge && !tooLong;
}

final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => const ImageUploadService(),
);
````

## File: lib/core/storage/secure_kv_store.dart
````dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureKvStore {
  const SecureKvStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> writeString({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) => _storage.delete(key: key);
}
````

## File: lib/core/theme/app_palette.dart
````dart
import 'package:flutter/material.dart';

// Semantic colors used across the app
const kDarkHeading = Color(0xFF1A1A2E);
const kMutedText = Color(0xFF555555);
const kLavenderBg = Color(0xFFF8F6FC);
const kPeerBubbleBg = Color(0xFFF3F4F6);
const kSuccessBg = Color(0xFFECFDF5);
const kSuccessText = Color(0xFF065F46);

enum AppPalette { electricIndigo, emberCoral, monsoonTeal }

extension AppPaletteX on AppPalette {
  Color get seedColor {
    switch (this) {
      case AppPalette.electricIndigo:
        return const Color(0xFF5B4BCF);
      case AppPalette.emberCoral:
        return const Color(0xFFFF6B4A);
      case AppPalette.monsoonTeal:
        return const Color(0xFF147D78);
    }
  }

  String get storageValue {
    switch (this) {
      case AppPalette.electricIndigo:
        return 'electric_indigo';
      case AppPalette.emberCoral:
        return 'ember_coral';
      case AppPalette.monsoonTeal:
        return 'monsoon_teal';
    }
  }

  String get label {
    switch (this) {
      case AppPalette.electricIndigo:
        return 'Electric Indigo';
      case AppPalette.emberCoral:
        return 'Ember Coral';
      case AppPalette.monsoonTeal:
        return 'Monsoon Teal';
    }
  }

  static AppPalette fromStorage(String? value) {
    return AppPalette.values.firstWhere(
      (palette) => palette.storageValue == value,
      orElse: () => AppPalette.electricIndigo,
    );
  }
}
````

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

abstract final class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: brightness,
    );
    final primary = palette.seedColor;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.sora(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: scheme.onSurface,
      ),
      headlineLarge: GoogleFonts.sora(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: scheme.onSurface,
      ),
      headlineMedium: GoogleFonts.sora(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.sora(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: scheme.onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0F1321)
          : const Color(0xFFF8F9FA),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: brightness == Brightness.dark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        color: brightness == Brightness.dark
            ? scheme.surfaceContainerLow
            : scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF14192A)
            : scheme.surface,
        indicatorColor: primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : const Color(0xFF6B7280),
            size: selected ? 26 : 24,
          );
        }),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
````

## File: lib/core/utils/debouncer.dart
````dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class ActionDebouncer {
  ActionDebouncer({this.duration = const Duration(milliseconds: 500)});
  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
````

## File: lib/core/providers.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'network/auth_token_provider.dart';
import 'storage/app_preferences.dart';
import 'storage/auth_token_storage.dart';
import 'storage/secure_kv_store.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('AppConfig override is required'),
);

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => throw UnimplementedError('AppPreferences override is required'),
);

final secureStoreProvider = Provider<SecureKvStore>(
  (ref) => throw UnimplementedError('SecureKvStore override is required'),
);

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => AuthTokenStorage(ref.watch(secureStoreProvider)),
);

final authTokenProviderProvider = Provider<AuthTokenProvider>(
  (ref) => RefreshingAuthTokenProvider(ref.watch(authTokenStorageProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    tokenProvider: ref.watch(authTokenProviderProvider),
    enableLogging: ref.watch(appConfigProvider).enableDebugLogs,
  ),
);
````

## File: lib/features/auth/data/auth_repository.dart
````dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_storage.dart';

final class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> requestOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  Future<void> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after sign in.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get('/users/me');
  }

  Future<void> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await _supabase.auth.signUp(
      phone: phone,
      password: password,
      data: {
        'full_name': fullName,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after sign up.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get('/users/me');
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after OTP verification.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get('/users/me');
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _tokenStorage.clear();
  }
}
````

## File: lib/features/auth/presentation/login_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../../../l10n/gen/app_localizations.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({required this.phone, super.key});

  final String? phone;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone ?? '+91');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.loginTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('login_phone_input'),
              controller: _phoneController,
              decoration: InputDecoration(labelText: locale.phoneNumberLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('login_password_input'),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: locale.passwordLabel),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              key: const Key('login_submit_button'),
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithPassword(
                            phone: _phoneController.text.trim(),
                            password: _passwordController.text,
                          );
                    },
              child: Text(locale.signInCta),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/auth/presentation/signup_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../../../l10n/gen/app_localizations.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({required this.phone, super.key});

  final String? phone;

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone ?? '+91');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.signupTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('signup_name_input'),
              controller: _nameController,
              decoration: InputDecoration(labelText: locale.fullNameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup_email_input'),
              controller: _emailController,
              decoration: InputDecoration(labelText: locale.emailLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup_phone_input'),
              controller: _phoneController,
              decoration: InputDecoration(labelText: locale.phoneNumberLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup_password_input'),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: locale.passwordLabel),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              key: const Key('signup_submit_button'),
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signUpWithPassword(
                            fullName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            password: _passwordController.text,
                            email: _emailController.text.trim(),
                          );
                    },
              child: Text(locale.createAccountCta),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/auth/presentation/splash_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_ui.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                const FlatmatesLogo(centered: true),
                const SizedBox(height: 28),
                Text(
                  locale.splashTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: kDarkHeading,
                    fontSize: 32,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  locale.splashSubtagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF555555),
                    fontSize: 15,
                  ),
                ),
                const Spacer(flex: 2),
                Image.asset(
                  'assets/illustrations/splash_living_room.png',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 92,
            child: bootstrap.when(
              data: (_) => _SplashProgress(color: theme.colorScheme.primary),
              loading: () => _SplashProgress(color: theme.colorScheme.primary),
              error: (error, _) => Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(bootstrapControllerProvider.notifier).load(),
                      child: Text(locale.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: LinearProgressIndicator(
          minHeight: 4,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: const Color(0xFFE8E4F6),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
````

## File: lib/features/auth/auth_controller.dart
````dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import 'data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated, submitting, error }

class AuthState {
  const AuthState({required this.status, this.phone, this.errorMessage});

  const AuthState.checking() : this(status: AuthStatus.checking);

  const AuthState.unauthenticated({String? phone})
    : this(status: AuthStatus.unauthenticated, phone: phone);

  const AuthState.authenticated({String? phone})
    : this(status: AuthStatus.authenticated, phone: phone);

  const AuthState.submitting({String? phone})
    : this(status: AuthStatus.submitting, phone: phone);

  const AuthState.error(String message, {String? phone})
    : this(status: AuthStatus.error, errorMessage: message, phone: phone);

  final AuthStatus status;
  final String? phone;
  final String? errorMessage;

  bool get isLoggedIn => status == AuthStatus.authenticated;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._repository)
    : super(const AuthState.checking()) {
    _watchTokenClears();
    Future<void>.microtask(checkSession);
  }

  final Ref _ref;
  final AuthRepository _repository;
  final StreamController<AuthState> _changes =
      StreamController<AuthState>.broadcast();
  StreamSubscription<String?>? _tokenSubscription;

  void _watchTokenClears() {
    try {
      _tokenSubscription = _ref.read(authTokenStorageProvider).changes.listen((
        token,
      ) {
        if (token == null && state.isLoggedIn) {
          state = const AuthState.unauthenticated();
        }
      });
    } catch (_) {}
  }

  @override
  Stream<AuthState> get stream => _changes.stream;

  @override
  set state(AuthState value) {
    super.state = value;
    _changes.add(value);
  }

  Future<void> checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    state = AuthState.authenticated(phone: session.user.phone);
  }

  Future<void> requestOtp(String phone) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.requestOtp(phone);
      state = AuthState.unauthenticated(phone: phone);
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
    }
  }

  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.signInWithPassword(phone: phone, password: password);
      state = AuthState.authenticated(phone: phone);
      return true;
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
      return false;
    }
  }

  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.signUpWithPassword(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email,
      );
      state = AuthState.authenticated(phone: phone);
      return true;
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.verifyOtp(phone: phone, otp: otp);
      state = AuthState.authenticated(phone: phone);
      return true;
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _ref.read(notificationServiceProvider).clearToken();
    } catch (_) {}
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _changes.close();
    super.dispose();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  ),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref, ref.watch(authRepositoryProvider)),
);
````

## File: lib/features/chats/match_qna_nudge.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class MatchQnANudge extends ConsumerStatefulWidget {
  const MatchQnANudge({
    required this.peerName,
    required this.onComplete,
    super.key,
  });

  final String peerName;
  final void Function(Map<String, String> answers) onComplete;

  @override
  ConsumerState<MatchQnANudge> createState() => _MatchQnANudgeState();
}

class _MatchQnANudgeState extends ConsumerState<MatchQnANudge> {
  final _q1Controller = TextEditingController();
  int _q2Value = 2; // 1-5 scale, default middle
  final _q3Controller = TextEditingController();

  static const _q2Labels = [
    'Very private',
    'Private',
    'Mixed',
    'Social',
    'Very social',
  ];

  @override
  void dispose() {
    _q1Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.qnaNudgeTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            locale.qnaNudgeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(locale.qnaQuestion1, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _q1Controller,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: locale.qnaQuestion1Hint,
              counterStyle: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(locale.qnaQuestion2, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Slider(
            value: _q2Value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _q2Labels[_q2Value - 1],
            onChanged: (v) => setState(() => _q2Value = v.round()),
          ),
          const SizedBox(height: 16),
          Text(locale.qnaQuestion3, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _q3Controller,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: locale.qnaQuestion3Hint,
              counterStyle: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GradientActionButton(
                  label: locale.qnaAnswerCta,
                  onPressed: () {
                    widget.onComplete({
                      'q1': _q1Controller.text.trim(),
                      'q2': _q2Value.toString(),
                      'q3': _q3Controller.text.trim(),
                    });
                    Navigator.pop(context);
                  },
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.qnaSkipCta),
            ),
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/discover/flat_details_page.dart
````dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/theme/app_palette.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'discover_repository.dart';
import 'share_listing_card.dart';

class FlatDetailsPage extends ConsumerStatefulWidget {
  const FlatDetailsPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<FlatDetailsPage> createState() => _FlatDetailsPageState();
}

class _FlatDetailsPageState extends ConsumerState<FlatDetailsPage> {
  int _currentImageIndex = 0;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final listingState = ref.watch(propertyListingProvider(widget.listingId));
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return listingState.when(
      data: (listing) {
        final images = listing.imageUrls;

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _HeroImageCarousel(
                      images: images,
                      currentIndex: _currentImageIndex,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      title: listing.title,
                      onBack: () => context.pop(),
                      onShare: () => _showShareSheet(listing),
                      onFavorite: () => _handleShortlist(),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  listing.title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (listing.monthlyRent != null)
                                Text(
                                  '₹${listing.monthlyRent!.toStringAsFixed(0)} / month',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  [
                                    listing.locality,
                                    listing.city,
                                  ].whereType<String>().join(', '),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                if (listing.bedrooms != null)
                                  _IconTextItem(
                                    icon: Icons.bed_outlined,
                                    text: '${listing.bedrooms} Beds',
                                  ),
                                if (listing.features.any(
                                  (f) => f.toLowerCase().contains('furnished'),
                                ))
                                  _IconTextItem(
                                    icon: Icons.chair_outlined,
                                    text: locale.featureFurnished,
                                  ),
                                if (listing.features.any(
                                  (f) =>
                                      f.toLowerCase().contains('wifi') ||
                                      f.toLowerCase().contains('wi_fi'),
                                ))
                                  _IconTextItem(
                                    icon: Icons.wifi_outlined,
                                    text: 'WiFi',
                                  ),
                                if (listing.features.any(
                                  (f) => f.toLowerCase().contains('parking'),
                                ))
                                  _IconTextItem(
                                    icon: Icons.local_parking_outlined,
                                    text: 'Parking',
                                  ),
                                if (listing.features.any(
                                  (f) =>
                                      f.toLowerCase().contains('lift') ||
                                      f.toLowerCase().contains('elevator'),
                                ))
                                  _IconTextItem(
                                    icon: Icons.elevator_outlined,
                                    text: 'Lift',
                                  ),
                                if (listing.features.any(
                                  (f) => f.toLowerCase().contains('security'),
                                ))
                                  _IconTextItem(
                                    icon: Icons.security_outlined,
                                    text: '24/7 Security',
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          FlatmatesSectionHeader(
                            title: locale.aboutThisFlatSection,
                          ),
                          const SizedBox(height: 8),
                          if (listing.description != null &&
                              listing.description!.trim().isNotEmpty)
                            Text(
                              listing.description!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            )
                          else
                            Text(
                              'No description available.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child: _AvailabilityTile(
                                  label: locale.availableFromLabel,
                                  value: listing.availableFrom != null
                                      ? DateFormat.yMMMd(
                                          locale.localeName,
                                        ).format(listing.availableFrom!)
                                      : 'Flexible',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AvailabilityTile(
                                  label: locale.postedOnLabel,
                                  value: listing.createdAt != null
                                      ? DateFormat.yMMMd(
                                          locale.localeName,
                                        ).format(listing.createdAt!)
                                      : 'Recently',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          if (listing.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: kSuccessBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 20,
                                    color: compatibilityScoreColor(100),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    locale.verifiedListingLabel,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: kSuccessText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 100), // space for bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _handleShortlist();
                          },
                          icon: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 20,
                          ),
                          label: Text(
                            locale.shortlistCta,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: FlatmatesButton(
                        label: locale.contactCta,
                        onPressed: _handleContact,
                        icon: Icons.chat_bubble_outline_rounded,
                        height: 52,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _showShareSheet(PropertyListing listing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: ShareListingCard(listing: listing),
      ),
    );
  }

  Future<void> _handleShortlist() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    try {
      await ref.read(discoverRepositoryProvider).likeListing(widget.listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileMenuShortlisted),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Action failed. Please try again.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }

  Future<void> _handleContact() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    try {
      final conversationId = await ref
          .read(discoverRepositoryProvider)
          .likeListing(widget.listingId);
      if (mounted && conversationId != null) {
        context.push('/chats/$conversationId');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).contactRequestSent),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Action failed. Please try again.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }
}

class _HeroImageCarousel extends StatelessWidget {
  const _HeroImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
  });

  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const heroHeight = 220.0;

    return Column(
      children: [
        SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: images.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.9),
                              theme.colorScheme.primary.withValues(alpha: 0.35),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initialsFromName(title),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 48,
                            ),
                          ),
                        ),
                      )
                    : PageView.builder(
                        itemCount: images.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, index) => Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.9,
                                  ),
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initialsFromName(title),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 4,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onBack,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Material(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: onShare,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.share_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: onFavorite,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (images.length > 1)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentIndex == index ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: currentIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact icon + text item for the horizontal feature row.
class _IconTextItem extends StatelessWidget {
  const _IconTextItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Availability tile for the 2-column grid.
class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/discover/map_view_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  double _budgetMin = 5000;
  double _budgetMax = 100000;
  String _roomType = 'all';
  String _moveInFilter = 'all';
  String _genderPref = 'any';
  bool _verifiedOnly = false;

  /// Cache for cluster marker icons keyed by count.
  final Map<int, BitmapDescriptor> _clusterIconCache = {};

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final profile = bootstrap.valueOrNull?.profile;
    final listings = ref.watch(discoverListingsProvider(profile));
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FilterBar(
              budgetMin: _budgetMin,
              budgetMax: _budgetMax,
              roomType: _roomType,
              moveInFilter: _moveInFilter,
              genderPref: _genderPref,
              verifiedOnly: _verifiedOnly,
              onBudgetChanged: (min, max) => setState(() {
                _budgetMin = min;
                _budgetMax = max;
              }),
              onRoomTypeChanged: (v) => setState(() => _roomType = v),
              onMoveInChanged: (v) => setState(() => _moveInFilter = v),
              onGenderChanged: (v) => setState(() => _genderPref = v),
              onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
            ),
            Expanded(
              child: listings.when(
                data: (items) {
                  final filtered = _applyFilters(items);
                  final markers = _buildClusteredMarkers(filtered, theme);
                  final firstPosition = markers.isEmpty
                      ? null
                      : markers.first.position;
                  if (firstPosition == null) {
                    return Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(locale.noListingsMatchFilters),
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: firstPosition,
                          zoom: 12,
                        ),
                        markers: markers,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      if (filtered.isEmpty)
                        Center(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                items.isEmpty
                                    ? locale.emptyListings
                                    : locale.noListingsMatchFilters,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Groups listings by locality and creates individual or cluster markers.
  ///
  /// - Listings with a null locality are grouped by rounded lat/lng (~0.01°).
  /// - Single-item groups get a normal marker.
  /// - Multi-item groups get a cluster marker with a count badge.
  Set<Marker> _buildClusteredMarkers(
    List<PropertyListing> items,
    ThemeData theme,
  ) {
    // Step 1: Group by locality (or by rounded coordinates as fallback).
    final groups = <String, List<PropertyListing>>{};
    for (final item in items) {
      if (item.latitude == null || item.longitude == null) continue;
      final key = item.locality?.trim().isNotEmpty == true
          ? item.locality!.trim().toLowerCase()
          : '${(item.latitude! * 100).round() / 100},${(item.longitude! * 100).round() / 100}';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final markers = <Marker>{};

    for (final entry in groups.entries) {
      final groupItems = entry.value;

      if (groupItems.length == 1) {
        // Single listing — normal marker.
        final item = groupItems.first;
        final isRoom = item.ownerId != null;
        markers.add(
          Marker(
            markerId: MarkerId('listing_${item.id}'),
            position: LatLng(item.latitude!, item.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isRoom ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: item.title,
              snippet: item.monthlyRent != null
                  ? '₹${item.monthlyRent!.toStringAsFixed(0)}/mo'
                  : null,
            ),
            onTap: () => _showListingSheet(item),
          ),
        );
      } else {
        // Cluster marker — use average position of all items in group.
        final avgLat =
            groupItems.map((i) => i.latitude!).reduce((a, b) => a + b) /
            groupItems.length;
        final avgLng =
            groupItems.map((i) => i.longitude!).reduce((a, b) => a + b) /
            groupItems.length;

        markers.add(
          Marker(
            markerId: MarkerId('cluster_${entry.key}'),
            position: LatLng(avgLat, avgLng),
            icon: _getClusterIcon(groupItems.length),
            infoWindow: InfoWindow(
              title:
                  '${groupItems.length} ${groupItems.first.locality ?? 'listings'}',
              snippet: AppLocalizations.of(
                context,
              ).clusterListingsCount(groupItems.length),
            ),
            onTap: () => _showClusterSheet(groupItems),
          ),
        );
      }
    }

    return markers;
  }

  /// Returns a [BitmapDescriptor] for a cluster marker with the given count.
  ///
  /// Uses a default marker hue as base; the count is shown in the infoWindow.
  /// For a richer visual, a custom bitmap could be generated, but the default
  /// marker with a distinct hue is sufficient for V1.
  BitmapDescriptor _getClusterIcon(int count) {
    // Use a distinct violet hue for cluster markers to differentiate them.
    return _clusterIconCache.putIfAbsent(
      count,
      () => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );
  }

  /// Shows a bottom sheet with all listings in a cluster.
  void _showClusterSheet(List<PropertyListing> clusterItems) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      clusterItems.first.locality ??
                          locale.clusterListingsTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      locale.clusterListingsCount(clusterItems.length),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: clusterItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = clusterItems[index];
                  return _ClusterListingCard(
                    listing: item,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showListingSheet(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PropertyListing> _applyFilters(List<PropertyListing> items) {
    return items.where((item) {
      // Budget filter
      if (item.monthlyRent != null) {
        if (item.monthlyRent! < _budgetMin || item.monthlyRent! > _budgetMax) {
          return false;
        }
      }

      // Room type filter
      if (_roomType != 'all') {
        if (item.sharingType != _roomType) return false;
      }

      // Gender preference filter
      if (_genderPref != 'any') {
        if (item.genderPreference != null &&
            item.genderPreference != 'any' &&
            item.genderPreference != _genderPref) {
          return false;
        }
      }

      // Move-in / availability filter
      if (_moveInFilter == 'immediate') {
        if (item.availableFrom != null &&
            item.availableFrom!.isAfter(
              DateTime.now().add(const Duration(days: 7)),
            )) {
          return false;
        }
      }

      // Verified filter
      if (_verifiedOnly) {
        final isVerified =
            item.features.contains('verified') ||
            item.features.contains('is_verified');
        if (!isVerified) return false;
      }

      return true;
    }).toList();
  }

  void _showListingSheet(PropertyListing item) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.mainImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.mainImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.apartment_rounded),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.apartment_rounded),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.monthlyRent != null)
                          Text(
                            '₹${item.monthlyRent!.toStringAsFixed(0)}/mo',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (item.locality != null)
                          Text(
                            item.locality!,
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.bedrooms != null)
                    InfoPill(
                      icon: Icons.bed_outlined,
                      label: locale.homeBedsValue(item.bedrooms!),
                    ),
                  if (item.bathrooms != null)
                    InfoPill(
                      icon: Icons.bathtub_outlined,
                      label: locale.homeBathsValue(item.bathrooms!),
                    ),
                  if (item.genderPreference != null)
                    InfoPill(
                      icon: Icons.group_outlined,
                      label: localizedFlatmatesGenderLabel(
                        locale,
                        item.genderPreference!,
                      ),
                    ),
                  if (item.sharingType != null)
                    InfoPill(
                      icon: Icons.meeting_room_outlined,
                      label: localizedFlatmatesSharingTypeLabel(
                        locale,
                        item.sharingType!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GradientActionButton(
                label: locale.likeListingCta,
                onPressed: () async {
                  final conversationId = await ref
                      .read(discoverRepositoryProvider)
                      .likeListing(item.id);
                  ref.invalidate(
                    discoverListingsProvider(
                      ref
                          .watch(bootstrapControllerProvider)
                          .valueOrNull
                          ?.profile,
                    ),
                  );
                  ref.invalidate(conversationsProvider);
                  if (!context.mounted) return;
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        conversationId == null
                            ? locale.contactRequestSent
                            : locale.contactRequestWithConversation(
                                conversationId,
                              ),
                      ),
                    ),
                  );
                },
                icon: Icons.favorite_border_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.currency_rupee_rounded, size: 16),
              label: Text(
                '₹${budgetMin.toStringAsFixed(0)}-₹${budgetMax.toStringAsFixed(0)}',
              ),
              onPressed: () => _showBudgetDialog(context),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.sharingPrivateRoom),
              selected: roomType == 'private_room',
              onSelected: (_) => onRoomTypeChanged(
                roomType == 'private_room' ? 'all' : 'private_room',
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.sharingSharedRoom),
              selected: roomType == 'shared_room',
              onSelected: (_) => onRoomTypeChanged(
                roomType == 'shared_room' ? 'all' : 'shared_room',
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.genderAny),
              selected: genderPref == 'any',
              onSelected: (_) => onGenderChanged('any'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.timelineImmediate),
              selected: moveInFilter == 'immediate',
              onSelected: (_) => onMoveInChanged(
                moveInFilter == 'immediate' ? 'all' : 'immediate',
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(Icons.verified_outlined, size: 16),
              label: Text(locale.verifiedFilterLabel),
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
            FilledButton(
              onPressed: () {
                onBudgetChanged(min, max);
                Navigator.pop(ctx);
              },
              child: Text(locale.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact listing card shown inside a cluster bottom sheet.
class _ClusterListingCard extends StatelessWidget {
  const _ClusterListingCard({required this.listing, required this.onTap});

  final PropertyListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = listing;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              if (l.mainImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    l.mainImageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, size: 24),
                    ),
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded, size: 24),
                ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (l.monthlyRent != null)
                      Text(
                        '₹${l.monthlyRent!.toStringAsFixed(0)}/mo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (l.bedrooms != null || l.sharingType != null)
                      Text(
                        [
                          if (l.bedrooms != null)
                            locale.homeBedsValue(l.bedrooms!),
                          if (l.sharingType != null)
                            localizedFlatmatesSharingTypeLabel(
                              locale,
                              l.sharingType!,
                            ),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/listings/create_listing_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/storage/image_upload_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'listings_repository.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  int _step = 0;
  bool _submitting = false;

  // Step 1 - Location
  final _societyController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();

  // Step 2 - Society
  String _societyType = 'gated';
  final _societyAmenities = <String>{};
  final _societyVibeTags = <String>{};

  // Step 3 - Room
  String _roomType = 'private_room';
  final _roomFurnishing = <String>{};
  final _roomFeatures = <String>{};
  final _roomPhotoUrls = <String>[];
  String? _videoTourUrl;
  bool _videoUploading = false;

  // Step 4 - Flat
  String _flatConfig = '2BHK';
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _flatAmenities = <String>{};

  // Step 5 - Costs
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  String _electricityIncluded = 'separate';
  final _electricityEstController = TextEditingController();
  final _cookCostController = TextEditingController();
  final _maidCostController = TextEditingController();
  final _setupCostController = TextEditingController();

  // Step 6 - About & Preferred Flatmate
  final _typicalDayController = TextEditingController();
  String _genderPreference = 'any';
  double _ageMin = 18;
  double _ageMax = 40;
  final _nonNegotiables = <String>{};
  DateTime? _availableFrom;

  static const totalSteps = 8;

  List<CatalogOption> _catalog(String key) {
    return ref
            .watch(bootstrapControllerProvider)
            .valueOrNull
            ?.catalogOptions(key) ??
        const [];
  }

  String _catalogLabel(String key, String id) {
    for (final option in _catalog(key)) {
      if (option.id == id) return option.label;
    }
    return humanizeFlatmatesToken(id);
  }

  IconData _iconForOption(String id) {
    return switch (id) {
      'wifi' => Icons.wifi_outlined,
      'parking' => Icons.local_parking_outlined,
      'security' => Icons.security_outlined,
      'lift' => Icons.elevator_outlined,
      'washing_machine' => Icons.local_laundry_service_outlined,
      'attached_bathroom' => Icons.bathtub_outlined,
      'balcony' || 'private_balcony' => Icons.balcony_outlined,
      'ac' => Icons.ac_unit_outlined,
      'pet_friendly' => Icons.pets_outlined,
      _ => Icons.check_circle_outline,
    };
  }

  @override
  void dispose() {
    for (final c in [
      _societyController,
      _addressController,
      _cityController,
      _localityController,
      _floorController,
      _totalFloorsController,
      _rentController,
      _depositController,
      _maintenanceController,
      _electricityEstController,
      _cookCostController,
      _maidCostController,
      _setupCostController,
      _typicalDayController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _canProceed() {
    return switch (_step) {
      0 =>
        _societyController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _localityController.text.trim().isNotEmpty,
      1 => true,
      2 => true,
      3 => _roomPhotoUrls.length >= 2,
      4 => true,
      5 =>
        _rentController.text.trim().isNotEmpty &&
            double.tryParse(_rentController.text.trim()) != null,
      6 => true,
      7 => true,
      _ => false,
    };
  }

  double get _totalMonthlyOutflow {
    double rent = double.tryParse(_rentController.text.trim()) ?? 0;
    double maintenance =
        double.tryParse(_maintenanceController.text.trim()) ?? 0;
    double electricity = _electricityIncluded == 'separate'
        ? (double.tryParse(_electricityEstController.text.trim()) ?? 0)
        : 0;
    double cook = double.tryParse(_cookCostController.text.trim()) ?? 0;
    double maid = double.tryParse(_maidCostController.text.trim()) ?? 0;
    return rent + maintenance + electricity + cook + maid;
  }

  Future<void> _pickRoomPhotos() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 10 - _roomPhotoUrls.length);
    if (files.isEmpty) return;
    for (final file in files) {
      final url = await service.uploadListingPhoto(file);
      if (url != null) setState(() => _roomPhotoUrls.add(url));
    }
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      // Build features list, adding video_tour tag if video tour exists
      final features = [
        ..._roomFurnishing,
        ..._roomFeatures,
        ..._flatAmenities,
        ..._societyAmenities,
      ];
      if (_videoTourUrl != null && !features.contains('video_tour')) {
        features.add('video_tour');
      }

      var request = ListingCreateRequest(
        title: '$_flatConfig in ${_societyController.text.trim()}',
        description: _typicalDayController.text.trim().isEmpty
            ? null
            : _typicalDayController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        locality: _localityController.text.trim().isEmpty
            ? null
            : _localityController.text.trim(),
        subLocality: _societyController.text.trim().isEmpty
            ? null
            : _societyController.text.trim(),
        monthlyRent: double.parse(_rentController.text.trim()),
        securityDeposit: double.tryParse(_depositController.text.trim()),
        maintenanceCharges: double.tryParse(_maintenanceController.text.trim()),
        areaSqft: null,
        bedrooms: _flatConfig.contains('1')
            ? 1
            : _flatConfig.contains('3')
            ? 3
            : _flatConfig.contains('4')
            ? 4
            : 2,
        bathrooms: 1,
        features: features,
        mainImageUrl: _roomPhotoUrls.isNotEmpty ? _roomPhotoUrls.first : null,
        availableFrom: _availableFrom,
        genderPreference: _genderPreference,
        sharingType: _roomType,
        videoTourUrl: _videoTourUrl,
      );

      final listingId = await ref
          .read(listingsRepositoryProvider)
          .createListing(request);
      ref.invalidate(
        discoverListingsProvider(
          ref.watch(bootstrapControllerProvider).valueOrNull?.profile,
        ),
      );
      await ref.read(bootstrapControllerProvider.notifier).load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.postListingSuccess)));
      if (listingId != null) {
        context.go('/listing-review/$listingId');
      } else {
        context.go('/discover');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const FlatmatesLogo(compact: true, centered: true),
                        Text(
                          locale.listingBuilderTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // balance back button
                ],
              ),
            ),

            // Progress bar area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // "Step X of 7" text
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${locale.stepLabel} ${_step + 1} ${locale.stepOfLabel} ${totalSteps.toString()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Thin linear progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / totalSteps,
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _stepTitle(locale, _step),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form content — clean white background, no Card wrappers
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                children: [_buildStep(_step)],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(locale.backCta),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: _step > 0 ? 2 : 1,
              child: FlatmatesButton(
                key: Key(
                  _step < totalSteps - 1
                      ? 'listing_next_step'
                      : 'listing_submit_button',
                ),
                label: _submitting
                    ? locale.postingInProgress
                    : (_step < totalSteps - 1
                          ? locale.onboardingNext
                          : locale.publishListingCta),
                onPressed: _submitting
                    ? null
                    : (_step < totalSteps - 1
                          ? (_canProceed()
                                ? () => setState(() => _step++)
                                : null)
                          : _submit),
                icon: _step < totalSteps - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.add_home_work_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(AppLocalizations locale, int step) {
    return switch (step) {
      0 => locale.listingStepLocation,
      1 => locale.listingStepSociety,
      2 => locale.listingStepRoom,
      3 => locale.addPhotosTitle,
      4 => locale.listingStepFlat,
      5 => locale.listingStepCosts,
      6 => locale.listingStepAbout,
      7 => locale.reviewTitle,
      _ => '',
    };
  }

  Widget _buildStep(int step) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return switch (step) {
      0 => _buildLocationStep(theme, locale),
      1 => _buildSocietyStep(theme, locale),
      2 => _buildRoomStep(theme, locale),
      3 => _buildPhotosStep(theme, locale),
      4 => _buildFlatStep(theme, locale),
      5 => _buildCostsStep(theme, locale),
      6 => _buildAboutStep(theme, locale),
      7 => _buildReviewStep(theme, locale),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLocationStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('listing_society_input'),
          controller: _societyController,
          decoration: InputDecoration(
            labelText: locale.societyBuildingLabel,
            hintText: locale.societyBuildingHint,
            prefixIcon: const Icon(Icons.apartment_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _addressController,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: locale.fullAddressLabel,
            hintText: locale.fullAddressHint,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('listing_city_input'),
                controller: _cityController,
                decoration: InputDecoration(labelText: locale.cityLabel),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                key: const Key('listing_locality_input'),
                controller: _localityController,
                decoration: InputDecoration(labelText: locale.localityLabel),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocietyStep(ThemeData theme, AppLocalizations locale) {
    final societyTypes = _catalog('flatmates_society_types');
    final amenities = _catalog('flatmates_listing_amenities');
    final vibes = _catalog('flatmates_vibe_tags');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.societyTypeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: societyTypes.map((type) {
            return ChoiceChip(
              label: Text(type.label),
              selected: _societyType == type.id,
              onSelected: (_) => setState(() => _societyType = type.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          locale.societyAmenitiesLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((opt) {
            final key = opt.id;
            final selected = _societyAmenities.contains(key);
            return FilterChip(
              avatar: Icon(_iconForOption(key), size: 16),
              label: Text(opt.label),
              selected: selected,
              onSelected: (v) => setState(() {
                v ? _societyAmenities.add(key) : _societyAmenities.remove(key);
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          locale.societyVibeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vibes.map((opt) {
            final key = opt.id;
            final selected = _societyVibeTags.contains(key);
            return FilterChip(
              avatar: Icon(_iconForOption(key), size: 16),
              label: Text(opt.label),
              selected: selected,
              onSelected: (v) => setState(() {
                v ? _societyVibeTags.add(key) : _societyVibeTags.remove(key);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRoomStep(ThemeData theme, AppLocalizations locale) {
    final roomTypes = _catalog('flatmates_room_types');
    final amenities = _catalog('flatmates_listing_amenities');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.roomTypeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roomTypes.map((type) {
            return ChoiceChip(
              label: Text(type.label),
              selected: _roomType == type.id,
              onSelected: (_) => setState(() => _roomType = type.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          locale.furnishingLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((opt) {
            final selected = _roomFurnishing.contains(opt.id);
            return FilterChip(
              avatar: Icon(_iconForOption(opt.id), size: 16),
              label: Text(opt.label),
              selected: selected,
              onSelected: (v) => setState(() {
                v
                    ? _roomFurnishing.add(opt.id)
                    : _roomFurnishing.remove(opt.id);
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          locale.roomFeaturesLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((opt) {
            final selected = _roomFeatures.contains(opt.id);
            return FilterChip(
              avatar: Icon(_iconForOption(opt.id), size: 16),
              label: Text(opt.label),
              selected: selected,
              onSelected: (v) => setState(() {
                v ? _roomFeatures.add(opt.id) : _roomFeatures.remove(opt.id);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _showPhotoTips = false;

  Widget _buildPhotosStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tips toggle (top-right aligned)
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _showPhotoTips = !_showPhotoTips),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _showPhotoTips
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: _showPhotoTips
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    locale.addPhotosTips,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _showPhotoTips
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Instruction text
        Text(
          locale.addPhotosInstruction,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Tips content (collapsible)
        if (_showPhotoTips) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📸 ${locale.addPhotosTips}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Use natural lighting — open curtains before shooting',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '• Show the full room from corner to corner',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '• Include bathroom and balcony if available',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '• Clean up before taking photos',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Min photos required indicator
        Row(
          children: [
            Text(
              locale.roomPhotosLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_roomPhotoUrls.length < 2)
              InfoPill(label: locale.minPhotosRequired, highlighted: true),
          ],
        ),
        const SizedBox(height: 12),

        // Photo cards at full width with delete X overlay
        ..._roomPhotoUrls.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    e.value,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: theme.colorScheme.error,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _roomPhotoUrls.removeAt(e.key)),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Add More link
        if (_roomPhotoUrls.length < 10)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickRoomPhotos,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          locale.addMorePhotosLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Pagination dots showing photo progress
        if (_roomPhotoUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate((_roomPhotoUrls.length / 3).ceil(), (i) {
                final isActive = i == 0;
                return Container(
                  width: isActive ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

        const SizedBox(height: 16),

        // Video tour section
        Text(
          locale.videoTourLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          locale.videoTourHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (_videoUploading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_videoTourUrl != null)
          Row(
            children: [
              Icon(
                Icons.videocam_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locale.videoTourAdded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _videoTourUrl = null),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          )
        else
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickVideoTour,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_call_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        locale.addVideoCta,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickVideoTour() async {
    final service = ref.read(imageUploadServiceProvider);
    final file = await service.pickVideo();
    if (file == null) return;

    final validation = await service.validateVideo(file);
    if (!validation.isValid) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validation.tooLarge ? locale.videoTooLarge : locale.videoTooLong,
          ),
        ),
      );
      return;
    }

    setState(() => _videoUploading = true);
    final url = await service.uploadVideoTour(file);
    setState(() {
      _videoTourUrl = url;
      _videoUploading = false;
    });
  }

  Widget _buildFlatStep(ThemeData theme, AppLocalizations locale) {
    final configs = _catalog('flatmates_flat_configs');
    final amenities = _catalog('flatmates_listing_amenities');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.flatConfigLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: configs.map((config) {
            return ChoiceChip(
              label: Text(config.label),
              selected: _flatConfig == config.id,
              onSelected: (_) => setState(() => _flatConfig = config.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _floorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: locale.floorLabel),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _totalFloorsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: locale.totalFloorsLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          locale.flatAmenitiesLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((opt) {
            final selected = _flatAmenities.contains(opt.id);
            return FilterChip(
              avatar: Icon(_iconForOption(opt.id), size: 16),
              label: Text(opt.label),
              selected: selected,
              onSelected: (v) => setState(() {
                v ? _flatAmenities.add(opt.id) : _flatAmenities.remove(opt.id);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCostsStep(ThemeData theme, AppLocalizations locale) {
    // Estimate total flatmates from flat config: number of bedrooms + 1 for the user
    final bedrooms = _flatConfig.contains('1')
        ? 1
        : _flatConfig.contains('3')
        ? 3
        : _flatConfig.contains('4')
        ? 4
        : 2;
    final totalFlatmates = bedrooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('listing_rent_input'),
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: locale.monthlyRentInputLabel,
                  hintText: locale.monthlyRentHint,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: locale.securityDepositLabel,
                  hintText: locale.securityDepositHint,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maintenanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: locale.maintenanceLabel,
                  hintText: locale.maintenanceHint,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.electricityLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'included',
                        label: Text(locale.includedLabel),
                      ),
                      ButtonSegment(
                        value: 'separate',
                        label: Text(locale.separateLabel),
                      ),
                    ],
                    selected: {_electricityIncluded},
                    onSelectionChanged: (v) =>
                        setState(() => _electricityIncluded = v.first),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_electricityIncluded == 'separate') ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: _electricityEstController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: locale.electricityEstLabel,
              hintText: locale.electricityEstHint,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cookCostController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: locale.cookCostLabel,
                  hintText: locale.cookCostHint,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maidCostController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: locale.maidCostLabel,
                  hintText: locale.maidCostHint,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 20),
        TextFormField(
          controller: _setupCostController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: locale.setupCostLabel,
            hintText: locale.setupCostHint,
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
          ),
        ),
        const SizedBox(height: 20),
        if (_totalMonthlyOutflow > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      locale.totalMonthlyOutflow(
                        '₹${_totalMonthlyOutflow.toStringAsFixed(0)}',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (totalFlatmates > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${locale.perPersonCostLabel} ₹${(_totalMonthlyOutflow / totalFlatmates).toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAboutStep(ThemeData theme, AppLocalizations locale) {
    final nonNegotiables = _catalog('flatmates_non_negotiables');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.typicalDayLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _typicalDayController,
          minLines: 3,
          maxLines: 5,
          maxLength: 300,
          decoration: InputDecoration(hintText: locale.typicalDayHint),
        ),
        const SizedBox(height: 24),
        Text(
          locale.genderPreferenceLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'any', label: Text(locale.genderAny)),
            ButtonSegment(value: 'male', label: Text(locale.genderMale)),
            ButtonSegment(value: 'female', label: Text(locale.genderFemale)),
          ],
          selected: {_genderPreference},
          onSelectionChanged: (v) =>
              setState(() => _genderPreference = v.first),
        ),
        const SizedBox(height: 20),
        Text(
          locale.ageRangeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_ageMin, _ageMax),
          min: 18,
          max: 50,
          divisions: 32,
          labels: RangeLabels('${_ageMin.round()}', '${_ageMax.round()}'),
          onChanged: (v) => setState(() {
            _ageMin = v.start;
            _ageMax = v.end;
          }),
        ),
        const SizedBox(height: 24),
        Text(
          locale.nonNegotiablesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nonNegotiables.map((option) {
            final key = option.id;
            final selected = _nonNegotiables.contains(key);
            return FilterChip(
              label: Text(option.label),
              selected: selected,
              onSelected: selected
                  ? (_) => setState(() => _nonNegotiables.remove(key))
                  : _nonNegotiables.length < 3
                  ? (_) => setState(() => _nonNegotiables.add(key))
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.availableFromLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _availableFrom == null
                        ? locale.availableFromUnset
                        : DateFormat(
                            'd MMM yyyy',
                            locale.localeName,
                          ).format(_availableFrom!),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  initialDate:
                      _availableFrom ??
                      DateTime.now().add(const Duration(days: 1)),
                );
                if (date != null) setState(() => _availableFrom = date);
              },
              child: Text(locale.selectDateCta),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewCard(
          title: locale.reviewLocation,
          icon: Icons.location_on_outlined,
          onEdit: () => setState(() => _step = 0),
          editLabel: locale.editStep,
          children: [
            if (_societyController.text.trim().isNotEmpty)
              Text(
                _societyController.text.trim(),
                style: theme.textTheme.bodyLarge,
              ),
            if (_addressController.text.trim().isNotEmpty)
              Text(
                _addressController.text.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              [
                _cityController.text.trim(),
                _localityController.text.trim(),
              ].where((s) => s.isNotEmpty).join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          title: locale.reviewSociety,
          icon: Icons.apartment_outlined,
          onEdit: () => setState(() => _step = 1),
          editLabel: locale.editStep,
          children: [
            Text(
              _catalogLabel('flatmates_society_types', _societyType),
              style: theme.textTheme.bodyLarge,
            ),
            if (_societyAmenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _societyAmenities
                    .map(
                      (a) => Chip(
                        label: Text(
                          _catalogLabel('flatmates_listing_amenities', a),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            if (_societyVibeTags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _societyVibeTags
                    .map(
                      (v) => Chip(
                        label: Text(
                          _catalogLabel('flatmates_vibe_tags', v),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          title: locale.reviewRoom,
          icon: Icons.bedroom_parent_outlined,
          onEdit: () => setState(() => _step = 2),
          editLabel: locale.editStep,
          children: [
            Text(
              _catalogLabel('flatmates_room_types', _roomType),
              style: theme.textTheme.bodyLarge,
            ),
            if (_roomFurnishing.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _roomFurnishing
                    .map(
                      (f) => Chip(
                        label: Text(
                          _catalogLabel('flatmates_listing_amenities', f),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            if (_roomFeatures.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _roomFeatures
                    .map(
                      (f) => Chip(
                        label: Text(
                          _catalogLabel('flatmates_listing_amenities', f),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          title: locale.addPhotosTitle,
          icon: Icons.add_photo_alternate_outlined,
          onEdit: () => setState(() => _step = 3),
          editLabel: locale.editStep,
          children: [
            Text(
              '${_roomPhotoUrls.length} photo${_roomPhotoUrls.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodyLarge,
            ),
            if (_videoTourUrl != null)
              Text(
                locale.videoTourAdded,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          title: locale.reviewFlat,
          icon: Icons.home_work_outlined,
          onEdit: () => setState(() => _step = 4),
          editLabel: locale.editStep,
          children: [
            Text(_flatConfig, style: theme.textTheme.bodyLarge),
            if (_floorController.text.trim().isNotEmpty ||
                _totalFloorsController.text.trim().isNotEmpty)
              Text(
                'Floor ${_floorController.text.trim()} / ${_totalFloorsController.text.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (_flatAmenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _flatAmenities
                    .map(
                      (a) => Chip(
                        label: Text(
                          _catalogLabel('flatmates_listing_amenities', a),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          title: locale.reviewCosts,
          icon: Icons.currency_rupee_rounded,
          onEdit: () => setState(() => _step = 5),
          editLabel: locale.editStep,
          children: [
            if (_rentController.text.trim().isNotEmpty)
              Text(
                'Rent: ₹${_rentController.text.trim()}/mo',
                style: theme.textTheme.bodyLarge,
              ),
            if (_depositController.text.trim().isNotEmpty)
              Text(
                'Deposit: ₹${_depositController.text.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (_maintenanceController.text.trim().isNotEmpty)
              Text(
                'Maintenance: ₹${_maintenanceController.text.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (_totalMonthlyOutflow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  locale.totalMonthlyOutflow(
                    '₹${_totalMonthlyOutflow.toStringAsFixed(0)}',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          title: locale.reviewAbout,
          icon: Icons.person_outline,
          onEdit: () => setState(() => _step = 6),
          editLabel: locale.editStep,
          children: [
            if (_typicalDayController.text.trim().isNotEmpty)
              Text(
                _typicalDayController.text.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            Text(
              'Gender: ${_genderPreference == 'any'
                  ? locale.genderAny
                  : _genderPreference == 'male'
                  ? locale.genderMale
                  : locale.genderFemale}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Age: ${_ageMin.round()} - ${_ageMax.round()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_nonNegotiables.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _nonNegotiables
                    .map(
                      (n) => Chip(
                        label: Text(
                          _catalogLabel('flatmates_non_negotiables', n),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            if (_availableFrom != null)
              Text(
                'Move-in: ${DateFormat('d MMM yyyy', locale.localeName).format(_availableFrom!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.editLabel,
    required this.children,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final String editLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(onPressed: onEdit, child: Text(editLabel)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
````

## File: lib/features/listings/listing_under_review_page.dart
````dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class ListingUnderReviewPage extends ConsumerStatefulWidget {
  const ListingUnderReviewPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<ListingUnderReviewPage> createState() =>
      _ListingUnderReviewPageState();
}

class _ListingUnderReviewPageState
    extends ConsumerState<ListingUnderReviewPage> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Refresh status every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.invalidate(
          discoverListingsProvider(
            ref.read(bootstrapControllerProvider).valueOrNull?.profile,
          ),
        );
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final profile = bootstrap.valueOrNull?.profile;
    final listings = ref.watch(discoverListingsProvider(profile));
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: listings.when(
          data: (items) {
            final listing = items
                .where((i) => i.id == widget.listingId)
                .firstOrNull;
            final isRejected = listing?.isRejected ?? false;

            return Column(
              children: [
                // Custom header — logo at top-left, no separate back arrow (per design spec Screen 16)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      const FlatmatesLogo(compact: true, centered: true),
                      const SizedBox(height: 8),
                      Text(
                        locale.listingUnderReviewTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // Illustration / icon area
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRejected
                                ? theme.colorScheme.error.withValues(alpha: 0.1)
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                          ),
                          child: Icon(
                            isRejected ? Icons.error_outline : Icons.task_alt,
                            size: 44,
                            color: isRejected
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status message
                      Center(
                        child: Text(
                          isRejected
                              ? locale.listingRejectedMessage
                              : locale.reviewSubmittedMessage,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      if (!isRejected) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            locale.reviewSupportText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Please review the reason below and resubmit.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // "Review Listing" button (outlined for non-rejected)
                      if (!isRejected)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/flat-details/${widget.listingId}',
                            ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: Text(locale.reviewListingCta),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      if (isRejected) ...[
                        // Rejection reason card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rejection reason',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'The listing did not meet our community guidelines. '
                                'Please ensure all information is accurate and photos are clear.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      const SizedBox(height: 28),

                      // ETA highlight banner
                      if (!isRejected)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  locale.etaHighlight,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 28),

                      // "What happens next?" section
                      if (!isRejected) ...[
                        Text(
                          locale.whatHappensNext,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _StepItem(
                          number: 1,
                          text: locale.step1Text,
                          theme: theme,
                        ),
                        _StepItem(
                          number: 2,
                          text: locale.step2Text,
                          theme: theme,
                        ),
                        _StepItem(
                          number: 3,
                          text: locale.step3Text,
                          theme: theme,
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Property preview card
                      if (listing != null) ...[
                        Text(
                          locale.yourListingLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                if (listing.mainImageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      listing.mainImageUrl!,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.apartment_rounded,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.apartment_rounded),
                                  ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.title,
                                        style: theme.textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (listing.monthlyRent != null)
                                        Text(
                                          '\u{20B9}${listing.monthlyRent!.toStringAsFixed(0)}/mo',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // CTAs
                      if (isRejected)
                        FlatmatesButton(
                          label: locale.editResubmit,
                          onPressed: () => context.push('/post'),
                          icon: Icons.edit_outlined,
                        )
                      else ...[
                        FlatmatesButton(
                          label: locale.goToHomeFeed,
                          onPressed: () => context.go('/discover'),
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push(
                              '/flat-details/${widget.listingId}',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(locale.viewListing),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

/// A single numbered step item in the "What happens next?" section.
class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.text,
    required this.theme,
  });

  final int number;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/listings/listings_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../discover/discover_repository.dart';

class ListingCreateRequest {
  const ListingCreateRequest({
    required this.title,
    required this.description,
    required this.city,
    required this.locality,
    required this.subLocality,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.maintenanceCharges,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.mainImageUrl,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
    this.videoTourUrl,
  });

  final String title;
  final String? description;
  final String? city;
  final String? locality;
  final String? subLocality;
  final double monthlyRent;
  final double? securityDeposit;
  final double? maintenanceCharges;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final String? mainImageUrl;
  final DateTime? availableFrom;
  final String genderPreference;
  final String sharingType;
  final String? videoTourUrl;

  Map<String, dynamic> toJson() {
    final fullAddress = [
      if (subLocality != null && subLocality!.trim().isNotEmpty)
        subLocality!.trim(),
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
    ].join(', ');

    final preferences = <String, dynamic>{
      'gender_preference': genderPreference,
      'sharing_type': sharingType,
    };

    if (videoTourUrl != null) {
      preferences['video_tour_url'] = videoTourUrl;
    }

    return {
      'title': title,
      'description': description,
      'property_type': 'flatmate',
      'purpose': 'rent',
      'base_price': monthlyRent,
      'monthly_rent': monthlyRent,
      'city': city,
      'locality': locality,
      'sub_locality': subLocality,
      'full_address': fullAddress.isEmpty ? null : fullAddress,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'security_deposit': securityDeposit,
      'maintenance_charges': maintenanceCharges,
      'features': features.isEmpty ? null : features,
      'main_image_url': mainImageUrl,
      'available_from': availableFrom?.toUtc().toIso8601String(),
      'listing_preferences': preferences,
    };
  }
}

class ListingsRepository {
  const ListingsRepository(this._ref);

  final Ref _ref;

  Future<int?> createListing(ListingCreateRequest request) async {
    final response = await _ref
        .watch(apiClientProvider)
        .post('/properties', data: request.toJson());
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return (data['id'] as num?)?.toInt();
  }

  Future<List<PropertyListing>> fetchMyListings() async {
    final response = await _ref.watch(apiClientProvider).get('/properties/me');
    final rows = response.data as List? ?? const [];
    return rows
        .map(
          (item) =>
              PropertyListing.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .where((listing) {
          final type = listing.propertyType;
          return type == null || type == 'flatmate' || type == 'pg';
        })
        .toList(growable: false);
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(ref),
);

final myListingsProvider = FutureProvider<List<PropertyListing>>(
  (ref) => ref.watch(listingsRepositoryProvider).fetchMyListings(),
);
````

## File: lib/features/notifications/notifications_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'notifications_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      locale.notificationsTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markAllAsRead();
                      ref.invalidate(notificationsProvider);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: locale.markAllRead,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Scrollable content
            Expanded(
              child: notifications.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            locale.notificationEmpty,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final notification = items[index];
                        return FlatmatesNotificationCard(
                          title: notification.title,
                          body: notification.body,
                          time: _formatTime(notification.createdAt),
                          icon: _iconForType(notification.type),
                          iconBgColor: _colorForType(
                            notification.type,
                            theme.colorScheme,
                          ),
                          isRead: notification.isRead,
                          onTap: () => _handleTap(context, ref, notification),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(notificationsProvider),
                        child: Text(locale.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    if (!notification.isRead) {
      await ref
          .read(notificationsRepositoryProvider)
          .markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
    }

    if (!context.mounted) return;

    final route = notification.route;
    if (route != null && route.startsWith('/')) {
      context.push(route);
      return;
    }

    switch (notification.type) {
      case 'new_match':
      case 'flatmate_new_match':
      case 'new_message':
      case 'flatmate_new_message':
        if (notification.referenceId != null) {
          context.push('/chats/${notification.referenceId}');
        }
        break;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        if (notification.referenceId != null) {
          context.push('/flat-details/${notification.referenceId}');
        } else {
          context.go('/post');
        }
        break;
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        context.go('/visits');
        break;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_match':
      case 'flatmate_new_match':
        return Icons.favorite_rounded;
      case 'new_message':
      case 'flatmate_new_message':
        return Icons.chat_bubble_outline;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        return Icons.verified_outlined;
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
        return Icons.notifications_outlined;
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        return Icons.calendar_month;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'new_match':
      case 'flatmate_new_match':
        return colorScheme.primary;
      case 'new_message':
      case 'flatmate_new_message':
        return const Color(0xFF3B82F6);
      case 'listing_approved':
      case 'flatmate_listing_approved':
        return const Color(0xFF10B981);
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
        return const Color(0xFFF59E0B);
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        return colorScheme.primary;
      default:
        return colorScheme.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      // Same day — show time
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final displayHour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      return '$displayHour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day} ${_monthAbbrev(dateTime.month)}';
    }
  }

  String _monthAbbrev(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
````

## File: lib/features/notifications/notifications_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
    this.route,
  });

  final String id;
  final String
  type; // 'new_match', 'new_message', 'listing_approved', 'visit_scheduled', 'visit_confirmed'
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final int? referenceId; // conversation_id, listing_id, visit_id etc.
  final String? route;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      referenceId: (json['reference_id'] as num?)?.toInt(),
      route: json['route']?.toString(),
    );
  }
}

class NotificationsRepository {
  const NotificationsRepository(this._ref);

  final Ref _ref;

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _ref
        .read(apiClientProvider)
        .get('/flatmates/notifications');
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _ref
        .read(apiClientProvider)
        .put(
          '/flatmates/notifications/$notificationId',
          data: {'is_read': true},
        );
  }

  Future<void> markAllAsRead() async {
    await _ref
        .read(apiClientProvider)
        .put('/flatmates/notifications', data: {'mark_all_read': true});
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref),
);

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationsRepositoryProvider).fetchNotifications();
});
````

## File: lib/features/onboarding/basic_info_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

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
    return _nameController.text.trim().isNotEmpty &&
        _ageController.text.trim().isNotEmpty &&
        int.tryParse(_ageController.text.trim()) != null &&
        int.parse(_ageController.text.trim()) >= 18 &&
        _professionController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(locale.basicInfoTitle, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              locale.basicInfoSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding_locality'),
              controller: _localityController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: locale.localityLabel,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_basic_info_next'),
              label: locale.onboardingNext,
              onPressed: _isValid
                  ? () => widget.onNext({
                      'full_name': _nameController.text.trim(),
                      'age': int.parse(_ageController.text.trim()),
                      'profession': _professionController.text.trim(),
                      'city': _cityController.text.trim(),
                      'locality': _localityController.text.trim().isEmpty
                          ? null
                          : _localityController.text.trim(),
                    })
                  : null,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/onboarding/budget_timeline_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';

class BudgetTimelinePage extends ConsumerStatefulWidget {
  const BudgetTimelinePage({required this.onComplete, super.key});

  final void Function(Map<String, dynamic> data) onComplete;

  @override
  ConsumerState<BudgetTimelinePage> createState() => _BudgetTimelinePageState();
}

class _BudgetTimelinePageState extends ConsumerState<BudgetTimelinePage> {
  double _budgetMin = 5000;
  double _budgetMax = 25000;
  String _moveInTimeline = 'flexible';

  /// Hardcoded fallback timeline options used when the backend catalog is unavailable.
  static const _fallbackTimelineOptions = [
    _TimelineOption(key: 'immediate', icon: Icons.flash_on_rounded),
    _TimelineOption(
      key: 'this_month',
      icon: Icons.calendar_view_month_outlined,
    ),
    _TimelineOption(key: 'next_month', icon: Icons.event_outlined),
    _TimelineOption(key: 'flexible', icon: Icons.all_inclusive_rounded),
  ];

  /// Resolve timeline options: try backend catalog first, fall back to hardcoded.
  List<_TimelineOption> get _timelineOptions {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_move_in_timelines',
    );
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions.map((opt) {
        final iconName = opt.meta['icon']?.toString() ?? '';
        return _TimelineOption(key: opt.id, icon: _iconFromName(iconName));
      }).toList();
    }
    return _fallbackTimelineOptions;
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'flash_on_rounded' => Icons.flash_on_rounded,
      'calendar_view_month_outlined' => Icons.calendar_view_month_outlined,
      'event_outlined' => Icons.event_outlined,
      'all_inclusive_rounded' => Icons.all_inclusive_rounded,
      _ => Icons.schedule_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              locale.budgetTimelineTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.budgetTimelineSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.monthlyBudgetLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_budgetMin.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '₹${_budgetMax.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      key: const Key('onboarding_budget_slider'),
                      values: RangeValues(_budgetMin, _budgetMax),
                      min: 5000,
                      max: 100000,
                      divisions: 19,
                      labels: RangeLabels(
                        '₹${_budgetMin.toStringAsFixed(0)}',
                        '₹${_budgetMax.toStringAsFixed(0)}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _budgetMin = values.start;
                          _budgetMax = values.end;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.moveInTimelineLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _timelineOptions.map((opt) {
                        final selected = _moveInTimeline == opt.key;
                        return ChoiceChip(
                          key: Key('timeline_${opt.key}'),
                          avatar: Icon(opt.icon, size: 18),
                          label: Text(_timelineLabel(locale, opt.key)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _moveInTimeline = opt.key);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_budget_next'),
              label: locale.onboardingNext,
              onPressed: () => widget.onComplete({
                'budget_min': _budgetMin,
                'budget_max': _budgetMax,
                'move_in_timeline': _moveInTimeline,
              }),
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _timelineLabel(AppLocalizations locale, String key) {
    // Try to find the label from the catalog first
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_move_in_timelines',
    );
    if (catalogOptions != null) {
      for (final opt in catalogOptions) {
        if (opt.id == key) return opt.label;
      }
    }
    // Fall back to localized hardcoded labels
    switch (key) {
      case 'immediate':
        return locale.timelineImmediate;
      case 'this_month':
        return locale.timelineThisMonth;
      case 'next_month':
        return locale.timelineNextMonth;
      default:
        return locale.timelineFlexible;
    }
  }
}

class _TimelineOption {
  const _TimelineOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}
````

## File: lib/features/onboarding/lifestyle_quiz_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';

class LifestyleQuizPage extends ConsumerStatefulWidget {
  const LifestyleQuizPage({required this.onComplete, super.key});

  final void Function(Map<String, String> answers) onComplete;

  @override
  ConsumerState<LifestyleQuizPage> createState() => _LifestyleQuizPageState();
}

class _LifestyleQuizPageState extends ConsumerState<LifestyleQuizPage> {
  final _answers = <String, String>{};

  /// Hardcoded fallback questions used when the backend catalog is unavailable.
  static final _fallbackQuestions = [
    _QuizQuestion(
      key: 'sleep_schedule',
      emoji: '🌙',
      title: (l) => l.quizSleepSchedule,
      options: [
        _QuizOption(key: 'early_bird', label: (l) => l.quizEarlyBird),
        _QuizOption(key: 'flexible', label: (l) => l.quizFlexible),
        _QuizOption(key: 'night_owl', label: (l) => l.quizNightOwl),
      ],
    ),
    _QuizQuestion(
      key: 'cleanliness',
      emoji: '🧹',
      title: (l) => l.quizCleanliness,
      options: [
        _QuizOption(key: 'minimal', label: (l) => l.quizCleanMinimal),
        _QuizOption(key: 'tidy', label: (l) => l.quizCleanTidy),
        _QuizOption(key: 'spotless', label: (l) => l.quizCleanSpotless),
      ],
    ),
    _QuizQuestion(
      key: 'food_habits',
      emoji: '🍽️',
      title: (l) => l.quizFoodHabits,
      options: [
        _QuizOption(key: 'vegetarian', label: (l) => l.quizVegetarian),
        _QuizOption(key: 'vegan', label: (l) => l.quizVegan),
        _QuizOption(key: 'non_vegetarian', label: (l) => l.quizNonVegetarian),
        _QuizOption(key: 'no_preference', label: (l) => l.quizNoFoodPref),
      ],
    ),
    _QuizQuestion(
      key: 'smoking_drinking',
      emoji: '🚬',
      title: (l) => l.quizSmokingDrinking,
      options: [
        _QuizOption(key: 'neither', label: (l) => l.quizNeither),
        _QuizOption(key: 'smoke_outside', label: (l) => l.quizSmokeOutside),
        _QuizOption(
          key: 'drink_occasionally',
          label: (l) => l.quizDrinkOccasionally,
        ),
        _QuizOption(key: 'both_fine', label: (l) => l.quizBothFine),
      ],
    ),
    _QuizQuestion(
      key: 'guests_policy',
      emoji: '👥',
      title: (l) => l.quizGuestsPolicy,
      options: [
        _QuizOption(key: 'no_overnight_guests', label: (l) => l.quizNoGuests),
        _QuizOption(key: 'occasional_ok', label: (l) => l.quizOccasionalGuests),
        _QuizOption(key: 'open_house', label: (l) => l.quizOpenHouse),
      ],
    ),
    _QuizQuestion(
      key: 'parties_at_home',
      emoji: '🎉',
      title: (l) => l.quizParties,
      options: [
        _QuizOption(key: 'never', label: (l) => l.quizPartiesNever),
        _QuizOption(
          key: 'occasional_weekends',
          label: (l) => l.quizPartiesWeekends,
        ),
        _QuizOption(key: 'party_friendly', label: (l) => l.quizPartyFriendly),
      ],
    ),
    _QuizQuestion(
      key: 'work_style',
      emoji: '💻',
      title: (l) => l.quizWorkStyle,
      options: [
        _QuizOption(key: 'wfh', label: (l) => l.quizWfh),
        _QuizOption(key: 'office', label: (l) => l.quizOffice),
        _QuizOption(key: 'hybrid', label: (l) => l.quizHybrid),
      ],
    ),
    _QuizQuestion(
      key: 'pets',
      emoji: '🐾',
      title: (l) => l.quizPets,
      options: [
        _QuizOption(key: 'no_pets', label: (l) => l.quizNoPets),
        _QuizOption(key: 'have_pets', label: (l) => l.quizHavePets),
        _QuizOption(key: 'pet_friendly', label: (l) => l.quizPetFriendly),
      ],
    ),
  ];

  /// Resolve quiz questions: try backend catalog first, fall back to hardcoded.
  List<_QuizQuestion> get _questions {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogQuestions = bootstrap?.catalogOptions(
      'flatmates_lifestyle_quiz',
    );
    if (catalogQuestions != null && catalogQuestions.isNotEmpty) {
      // Build questions from catalog. Each CatalogOption represents a question
      // with options nested in its meta map under the 'options' key.
      return catalogQuestions.map((q) {
        final rawOptions = q.meta['options'];
        final optionList = <_QuizOption>[];
        if (rawOptions is List) {
          for (final raw in rawOptions) {
            if (raw is Map) {
              final map = Map<String, dynamic>.from(raw);
              final id = (map['id'] ?? map['value'] ?? map['key'] ?? '')
                  .toString()
                  .trim();
              final label = (map['label'] ?? map['name'] ?? id)
                  .toString()
                  .trim();
              if (id.isNotEmpty && label.isNotEmpty) {
                optionList.add(_QuizOption(key: id, label: (_) => label));
              }
            }
          }
        }
        if (optionList.isEmpty) {
          // Fallback: if no nested options, try to use the question label
          // as a single option (shouldn't happen with a well-formed catalog).
          optionList.add(_QuizOption(key: q.id, label: (_) => q.label));
        }
        return _QuizQuestion(
          key: q.id,
          emoji: q.meta['emoji']?.toString() ?? '❓',
          title: (_) => q.label,
          options: optionList,
        );
      }).toList();
    }
    return _fallbackQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = _questions;
    final answeredCount = _answers.length;
    final totalQuestions = questions.length;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    locale.quizProgress(answeredCount, totalQuestions),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: answeredCount / totalQuestions,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: questions.map((q) {
                  final selected = _answers[q.key];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  q.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q.title(locale),
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: q.options.map((opt) {
                                final isSelected = selected == opt.key;
                                return ChoiceChip(
                                  key: Key('quiz_${q.key}_${opt.key}'),
                                  label: Text(opt.label(locale)),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _answers[q.key] = opt.key;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            GradientActionButton(
              key: const Key('onboarding_quiz_next'),
              label: locale.onboardingNext,
              onPressed: answeredCount == totalQuestions
                  ? () => widget.onComplete(Map.from(_answers))
                  : null,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.key,
    required this.emoji,
    required this.title,
    required this.options,
  });

  final String key;
  final String emoji;
  final String Function(AppLocalizations) title;
  final List<_QuizOption> options;
}

class _QuizOption {
  const _QuizOption({required this.key, required this.label});

  final String key;
  final String Function(AppLocalizations) label;
}
````

## File: lib/features/onboarding/mode_selection_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';

class ModeSelectionPage extends ConsumerStatefulWidget {
  const ModeSelectionPage({required this.onModeSelected, super.key});

  final void Function(String mode) onModeSelected;

  @override
  ConsumerState<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends ConsumerState<ModeSelectionPage> {
  String? _selectedMode;

  static const _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogModes =
        bootstrap?.catalogOptions('flatmates_modes') ?? const [];
    final modes = catalogModes.isNotEmpty
        ? catalogModes
        : [
            CatalogOption(
              id: 'co_hunter',
              label: locale.modeCoHunter,
              meta: {'description': locale.modeCoHunterDesc},
            ),
            CatalogOption(
              id: 'room_poster',
              label: locale.modeRoomPoster,
              meta: {'description': locale.modeRoomPosterDesc},
            ),
            CatalogOption(
              id: 'open_to_both',
              label: locale.modeOpenToBoth,
              meta: {'description': locale.modeOpenToBothDesc},
            ),
          ];

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Back arrow ---
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Back',
            ),
            const SizedBox(height: 12),
            // --- Progress indicator (4 dots connected by lines) ---
            _buildProgressDots(theme),
            const SizedBox(height: 28),
            // --- Heading & subtitle ---
            Text(
              locale.modeSelectionTitle,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              locale.modeSelectionSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            // --- Option cards ---
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...modes.map((mode) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ModeCard(
                          key: Key('mode_${mode.id}'),
                          icon: _iconForMode(mode.id),
                          title: mode.label,
                          description:
                              mode.meta['description']?.toString() ?? '',
                          isSelected: _selectedMode == mode.id,
                          onTap: () => setState(() => _selectedMode = mode.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- CTA ---
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FlatmatesButton(
                key: const Key('mode_continue'),
                label: locale.modeContinue,
                onPressed: _selectedMode != null
                    ? () => widget.onModeSelected(_selectedMode!)
                    : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForMode(String mode) {
    return switch (mode) {
      'room_poster' => Icons.home_outlined,
      'open_to_both' => Icons.swap_horiz,
      _ => Icons.group_outlined,
    };
  }

  Widget _buildProgressDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (i) {
        final active = i == 0;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: active ? 10 : 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              if (i < _totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
      ),
      elevation: isSelected ? 2 : 0.5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left: circle with icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 16),
              // Center: title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Right: chevron
              Icon(Icons.chevron_right, color: theme.colorScheme.tertiary),
            ],
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/onboarding/non_negotiables_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';

class NonNegotiablesPage extends ConsumerStatefulWidget {
  const NonNegotiablesPage({required this.onComplete, super.key});

  final void Function(List<String> nonNegotiables) onComplete;

  @override
  ConsumerState<NonNegotiablesPage> createState() => _NonNegotiablesPageState();
}

class _NonNegotiablesPageState extends ConsumerState<NonNegotiablesPage> {
  final _selected = <String>{};

  /// Hardcoded fallback options used when the backend catalog is unavailable.
  static const _fallbackOptions = [
    _NonNegOption(key: 'food_veg_only', icon: Icons.restaurant_outlined),
    _NonNegOption(key: 'food_vegan_only', icon: Icons.eco_outlined),
    _NonNegOption(key: 'no_smoking', icon: Icons.smoke_free_outlined),
    _NonNegOption(key: 'no_drinking', icon: Icons.no_drinks_outlined),
    _NonNegOption(key: 'no_overnight_guests', icon: Icons.bed_outlined),
    _NonNegOption(key: 'no_pets', icon: Icons.pets_outlined),
    _NonNegOption(key: 'gender_female_only', icon: Icons.female_outlined),
    _NonNegOption(key: 'gender_male_only', icon: Icons.male_outlined),
    _NonNegOption(key: 'no_parties', icon: Icons.music_off_outlined),
    _NonNegOption(key: 'min_tidy', icon: Icons.cleaning_services_outlined),
  ];

  /// Resolve options: try backend catalog first, fall back to hardcoded.
  List<_NonNegOption> get _options {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_non_negotiables',
    );
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions.map((opt) {
        final iconName = opt.meta['icon']?.toString() ?? '';
        return _NonNegOption(key: opt.id, icon: _iconFromName(iconName));
      }).toList();
    }
    return _fallbackOptions;
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'restaurant_outlined' => Icons.restaurant_outlined,
      'eco_outlined' => Icons.eco_outlined,
      'smoke_free_outlined' => Icons.smoke_free_outlined,
      'no_drinks_outlined' => Icons.no_drinks_outlined,
      'bed_outlined' => Icons.bed_outlined,
      'pets_outlined' => Icons.pets_outlined,
      'female_outlined' => Icons.female_outlined,
      'male_outlined' => Icons.male_outlined,
      'music_off_outlined' => Icons.music_off_outlined,
      'cleaning_services_outlined' => Icons.cleaning_services_outlined,
      _ => Icons.block_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              locale.nonNegotiablesTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.nonNegotiablesSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            InfoPill(
              icon: Icons.info_outline,
              label: locale.nonNegotiablesLimit,
              highlighted: true,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _options.map((opt) {
                final isSelected = _selected.contains(opt.key);
                return FilterChip(
                  key: Key('non_neg_${opt.key}'),
                  avatar: Icon(opt.icon, size: 18),
                  label: Text(_label(locale, opt.key)),
                  selected: isSelected,
                  onSelected: isSelected
                      ? (_) => setState(() => _selected.remove(opt.key))
                      : _selected.length < 3
                      ? (_) => setState(() => _selected.add(opt.key))
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            GradientActionButton(
              key: const Key('onboarding_non_neg_done'),
              label: locale.onboardingComplete,
              onPressed: () => widget.onComplete(_selected.toList()),
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppLocalizations locale, String key) {
    // Try to find the label from the catalog first
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_non_negotiables',
    );
    if (catalogOptions != null) {
      for (final opt in catalogOptions) {
        if (opt.id == key) return opt.label;
      }
    }
    // Fall back to localized hardcoded labels
    switch (key) {
      case 'food_veg_only':
        return locale.nonNegVegOnly;
      case 'food_vegan_only':
        return locale.nonNegVeganOnly;
      case 'no_smoking':
        return locale.nonNegNoSmoking;
      case 'no_drinking':
        return locale.nonNegNoDrinking;
      case 'no_overnight_guests':
        return locale.nonNegNoGuests;
      case 'no_pets':
        return locale.nonNegNoPets;
      case 'gender_female_only':
        return locale.nonNegFemaleOnly;
      case 'gender_male_only':
        return locale.nonNegMaleOnly;
      case 'no_parties':
        return locale.nonNegNoParties;
      case 'min_tidy':
        return locale.nonNegMinTidy;
      default:
        return key;
    }
  }
}

class _NonNegOption {
  const _NonNegOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}
````

## File: lib/features/onboarding/onboarding_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import 'budget_timeline_page.dart';
import 'lifestyle_quiz_page.dart';
import 'location_selection_page.dart';
import 'mode_selection_page.dart';
import 'non_negotiables_page.dart';
import 'onboarding_controller.dart';
import 'onboarding_splash_pages.dart';
import 'preferences_page.dart';
import 'profile_photo_page.dart';
import 'basic_info_page.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (state.isComplete) {
      Future.microtask(() {
        if (context.mounted) context.go('/discover');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.isSubmitting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(locale.onboardingSubmitting),
            ],
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    controller.submitNonNegotiables(state.nonNegotiables),
                child: Text(locale.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    final progress = state.completionPercentage / 100;

    final stepWidget = switch (state.step) {
      OnboardingStep.splash => OnboardingSplashPages(
        onComplete: controller.completeSplash,
      ),
      OnboardingStep.modeSelection => ModeSelectionPage(
        onModeSelected: controller.setMode,
      ),
      OnboardingStep.locationSelection => LocationSelectionPage(
        onLocationSelected: controller.setLocation,
      ),
      OnboardingStep.basicInfo => BasicInfoPage(
        onNext: controller.setBasicInfo,
        initialCity: state.city,
        initialLocality: state.locality,
      ),
      OnboardingStep.profilePhoto => ProfilePhotoPage(
        onComplete: controller.setPhotoUrls,
      ),
      OnboardingStep.lifestyleQuiz => LifestyleQuizPage(
        onComplete: controller.setLifestyleAnswers,
      ),
      OnboardingStep.budgetTimeline => BudgetTimelinePage(
        onComplete: controller.setBudgetTimeline,
      ),
      OnboardingStep.preferences => PreferencesPage(
        onComplete: controller.setPreferences,
      ),
      OnboardingStep.nonNegotiables => NonNegotiablesPage(
        onComplete: controller.submitNonNegotiables,
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (state.step != OnboardingStep.splash)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile Setup',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.completionPercentage.toInt()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            // Step content
            Expanded(child: stepWidget),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/onboarding/onboarding_splash_pages.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class OnboardingSplashPages extends ConsumerStatefulWidget {
  const OnboardingSplashPages({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingSplashPages> createState() =>
      _OnboardingSplashPagesState();
}

class _OnboardingSplashPagesState extends ConsumerState<OnboardingSplashPages> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: kLavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _SplashContent(
                  illustrationAsset:
                      'assets/illustrations/onboarding_illustration.png',
                  headline: switch (index) {
                    0 => locale.onboardingHeadline1,
                    1 => locale.onboardingHeadline2,
                    2 => locale.onboardingHeadline3,
                    _ => locale.onboardingHeadline4,
                  },
                  subheadline: switch (index) {
                    0 => locale.onboardingSubheadline1,
                    1 => locale.onboardingSubheadline2,
                    2 => locale.onboardingSubheadline3,
                    _ => locale.onboardingSubheadline4,
                  },
                ),
              ),
            ),
            // --- Page dots ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  final active = i == _page;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
            // --- Action buttons ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: isLast
                  ? FlatmatesButton(
                      key: const Key('onboarding_get_started'),
                      label: locale.onboardingGetStarted,
                      onPressed: widget.onComplete,
                      icon: Icons.arrow_forward_rounded,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          key: const Key('onboarding_skip'),
                          onPressed: widget.onComplete,
                          child: Text(
                            locale.onboardingSkip,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        FlatmatesButton(
                          key: const Key('onboarding_next'),
                          label: locale.onboardingNext,
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                          icon: Icons.arrow_forward_rounded,
                          height: 44,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.illustrationAsset,
    required this.headline,
    required this.subheadline,
  });

  final String illustrationAsset;
  final String headline;
  final String subheadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(illustrationAsset, fit: BoxFit.contain, height: 280),
          const SizedBox(height: 36),
          // Headline with bold emphasis on "right" words
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: _buildStyledHeadline(headline, theme)),
          ),
          const SizedBox(height: 12),
          Text(
            subheadline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: kMutedText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Splits headline by **bold** markers and returns styled spans.
  List<InlineSpan> _buildStyledHeadline(String raw, ThemeData theme) {
    final parts = raw.split(RegExp(r'\*\*'));
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i.isOdd;
      spans.add(
        TextSpan(
          text: parts[i],
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: kDarkHeading,
          ),
        ),
      );
    }
    // If no ** markers found, render entire text as normal bold
    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: raw,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: kDarkHeading,
          ),
        ),
      );
    }
    return spans;
  }
}
````

## File: lib/features/onboarding/profile_photo_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/image_upload_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class ProfilePhotoPage extends ConsumerStatefulWidget {
  const ProfilePhotoPage({required this.onComplete, super.key});

  final void Function(List<String> urls) onComplete;

  @override
  ConsumerState<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends ConsumerState<ProfilePhotoPage> {
  final _photoUrls = <String>[];
  bool _uploading = false;

  Future<void> _pickFromGallery() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 5 - _photoUrls.length);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    for (final file in files) {
      final url = await service.uploadProfilePhoto(file);
      if (url != null) _photoUrls.add(url);
    }
    setState(() => _uploading = false);
  }

  Future<void> _pickFromCamera() async {
    final service = ref.read(imageUploadServiceProvider);
    final file = await service.pickFromCamera();
    if (file == null) return;
    setState(() => _uploading = true);
    final url = await service.uploadProfilePhoto(file);
    if (url != null) _photoUrls.add(url);
    setState(() => _uploading = false);
  }

  void _removePhoto(int index) {
    setState(() => _photoUrls.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              locale.profilePhotoTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.profilePhotoSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_photoUrls.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InfoPill(
                  icon: Icons.lightbulb_outline,
                  label: locale.profilePhotoNudge,
                  highlighted: true,
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                ..._photoUrls.asMap().entries.map((entry) {
                  return _PhotoTile(
                    imageUrl: entry.value,
                    onRemove: () => _removePhoto(entry.key),
                  );
                }),
                if (_photoUrls.length < 5)
                  _AddPhotoTile(
                    onGallery: _pickFromGallery,
                    onCamera: _pickFromCamera,
                  ),
              ],
            ),
            const SizedBox(height: 32),
            if (_uploading)
              const Center(child: CircularProgressIndicator())
            else
              GradientActionButton(
                key: const Key('onboarding_photo_next'),
                label: locale.onboardingNext,
                onPressed: () => widget.onComplete(_photoUrls),
                icon: Icons.arrow_forward_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.imageUrl, required this.onRemove});

  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            imageUrl,
            width: 130,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 130,
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Material(
            color: Theme.of(context).colorScheme.error,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onGallery, required this.onCamera});

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onGallery,
        onLongPress: onCamera,
        child: SizedBox(
          width: 130,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).addPhotoCta,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/onboarding/waitlist_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class WaitlistPage extends ConsumerStatefulWidget {
  const WaitlistPage({required this.city, super.key});

  final String city;

  @override
  ConsumerState<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<WaitlistPage> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        theme.colorScheme.primary.withValues(alpha: 0.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🏗️', style: TextStyle(fontSize: 52)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  locale.waitlistTitle,
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  locale.waitlistSubtitle(widget.city),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_notified)
                  InfoPill(
                    icon: Icons.check_circle_rounded,
                    label: locale.waitlistConfirmed,
                    highlighted: true,
                  )
                else
                  GradientActionButton(
                    label: locale.waitlistNotifyCta,
                    onPressed: () async {
                      try {
                        await ref
                            .read(apiClientProvider)
                            .put(
                              '/flatmates/profile',
                              data: {'waitlist_city': widget.city},
                            );
                      } catch (_) {}
                      setState(() => _notified = true);
                    },
                    icon: Icons.notifications_active_outlined,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/profile/edit_profile_page.dart
````dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import 'profile_repository.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _bioController = TextEditingController();
  String _mode = 'open_to_both';
  String _workStyle = 'hybrid';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;
    if (profile != null && _cityController.text.isEmpty) {
      _cityController.text = profile.city ?? '';
      _localityController.text = profile.locality ?? '';
      _budgetMinController.text = profile.budgetMin?.toStringAsFixed(0) ?? '';
      _budgetMaxController.text = profile.budgetMax?.toStringAsFixed(0) ?? '';
      _bioController.text = profile.bio ?? '';
      _mode = profile.mode ?? _mode;
      _workStyle = profile.workStyle ?? _workStyle;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _localityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Build mode dropdown items from catalog, falling back to hardcoded values.
  List<DropdownMenuItem<String>> _buildModeItems() {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogModes = bootstrap?.catalogOptions('flatmates_modes');
    if (catalogModes != null && catalogModes.isNotEmpty) {
      return catalogModes
          .map((opt) => DropdownMenuItem(value: opt.id, child: Text(opt.label)))
          .toList();
    }
    // Hardcoded fallback
    return const [
      DropdownMenuItem(value: 'room_poster', child: Text('Room Poster')),
      DropdownMenuItem(value: 'seeker', child: Text('Seeker')),
      DropdownMenuItem(value: 'co_hunter', child: Text('Co-Hunter')),
      DropdownMenuItem(value: 'open_to_both', child: Text('Open To Both')),
    ];
  }

  /// Build work style dropdown items from catalog, falling back to hardcoded values.
  List<DropdownMenuItem<String>> _buildWorkStyleItems() {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogStyles = bootstrap?.catalogOptions('flatmates_work_styles');
    if (catalogStyles != null && catalogStyles.isNotEmpty) {
      return catalogStyles
          .map((opt) => DropdownMenuItem(value: opt.id, child: Text(opt.label)))
          .toList();
    }
    // Hardcoded fallback
    return const [
      DropdownMenuItem(value: 'office', child: Text('Office')),
      DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
      DropdownMenuItem(value: 'wfh', child: Text('WFH')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    String? nullableText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return Scaffold(
      appBar: AppBar(title: Text(locale.editProfileCta)),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              key: const Key('profile_mode_input'),
              initialValue: _mode,
              decoration: InputDecoration(labelText: locale.modeTitle),
              items: _buildModeItems(),
              onChanged: (value) {
                if (value != null) setState(() => _mode = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_city_input'),
              controller: _cityController,
              decoration: InputDecoration(labelText: locale.cityLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_locality_input'),
              controller: _localityController,
              decoration: InputDecoration(labelText: locale.localityLabel),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('profile_budget_min_input'),
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: locale.budgetMinLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('profile_budget_max_input'),
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: locale.budgetMaxLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('profile_work_style_input'),
              initialValue: _workStyle,
              decoration: InputDecoration(labelText: locale.workStyleTitle),
              items: _buildWorkStyleItems(),
              onChanged: (value) {
                if (value != null) setState(() => _workStyle = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profile_bio_input'),
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(labelText: locale.bioLabel),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('profile_save_button'),
              onPressed: () async {
                try {
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfile(
                        payload: {
                          'mode': _mode,
                          'city': nullableText(_cityController),
                          'locality': nullableText(_localityController),
                          'budget_min': double.tryParse(
                            _budgetMinController.text.trim(),
                          ),
                          'budget_max': double.tryParse(
                            _budgetMaxController.text.trim(),
                          ),
                          'work_style': _workStyle,
                          'bio': nullableText(_bioController),
                          'onboarding_completed': true,
                        },
                      );
                  await ref.read(bootstrapControllerProvider.notifier).load();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is DioException
                              ? e.error.toString()
                              : 'Failed to save profile. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(locale.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/profile/profile_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';

class ProfileRepository {
  const ProfileRepository(this._ref);

  final Ref _ref;

  Future<FlatmatesProfileModel> updateProfile({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _ref
        .watch(apiClientProvider)
        .put('/flatmates/profile', data: payload);
    return FlatmatesProfileModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<FlatmatesProfileModel> fetchProfile() async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/profile');
    return FlatmatesProfileModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref),
);
````

## File: lib/features/settings/settings_controller.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme/app_palette.dart';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.palette,
    required this.locale,
    required this.loaded,
    required this.hideLastName,
    required this.hideExactLocation,
  });

  SettingsState.initial()
    : themeMode = ThemeMode.light,
      palette = AppPalette.electricIndigo,
      locale = const Locale('en'),
      loaded = false,
      hideLastName = false,
      hideExactLocation = false;

  final ThemeMode themeMode;
  final AppPalette palette;
  final Locale? locale;
  final bool loaded;
  final bool hideLastName;
  final bool hideExactLocation;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppPalette? palette,
    Locale? locale,
    bool clearLocale = false,
    bool? loaded,
    bool? hideLastName,
    bool? hideExactLocation,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      locale: clearLocale ? null : (locale ?? this.locale),
      loaded: loaded ?? this.loaded,
      hideLastName: hideLastName ?? this.hideLastName,
      hideExactLocation: hideExactLocation ?? this.hideExactLocation,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(SettingsState.initial()) {
    Future<void>.microtask(load);
  }

  final AppPreferences _prefs;

  Future<void> load() async {
    final themeRaw = _prefs.getString(PrefKeys.themeMode);
    final paletteRaw = _prefs.getString(PrefKeys.palette);
    final languageCode = _prefs.getString(PrefKeys.localeLanguageCode);
    final countryCode = _prefs.getString(PrefKeys.localeCountryCode);

    state = state.copyWith(
      themeMode: switch (themeRaw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      palette: AppPaletteX.fromStorage(paletteRaw),
      locale: languageCode == null
          ? const Locale('en')
          : Locale(languageCode, countryCode),
      hideLastName: _prefs.getBool(PrefKeys.hideLastName),
      hideExactLocation: _prefs.getBool(PrefKeys.hideExactLocation),
      loaded: true,
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(PrefKeys.themeMode, raw);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updatePalette(AppPalette palette) async {
    await _prefs.setString(PrefKeys.palette, palette.storageValue);
    state = state.copyWith(palette: palette);
  }

  Future<void> updateLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(PrefKeys.localeLanguageCode);
      await _prefs.remove(PrefKeys.localeCountryCode);
      state = state.copyWith(clearLocale: true);
      return;
    }

    await _prefs.setString(PrefKeys.localeLanguageCode, locale.languageCode);
    if (locale.countryCode != null) {
      await _prefs.setString(PrefKeys.localeCountryCode, locale.countryCode!);
    }
    state = state.copyWith(locale: locale);
  }

  Future<void> updateHideLastName(bool value) async {
    await _prefs.setBool(PrefKeys.hideLastName, value);
    state = state.copyWith(hideLastName: value);
  }

  Future<void> updateHideExactLocation(bool value) async {
    await _prefs.setBool(PrefKeys.hideExactLocation, value);
    state = state.copyWith(hideExactLocation: value);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
      (ref) => SettingsController(ref.watch(appPreferencesProvider)),
    );
````

## File: lib/features/shared/presentation/flatmates_ui.dart
````dart
import 'package:flutter/material.dart';

import '../../../core/compatibility/compatibility_engine.dart';
import '../../../l10n/gen/app_localizations.dart';

String initialsFromName(String? name) {
  final raw = name?.trim();
  if (raw == null || raw.isEmpty) {
    return 'FM';
  }
  final parts = raw
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'FM';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, (parts.first.length < 2) ? parts.first.length : 2)
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class FlatmatesAvatar extends StatelessWidget {
  const FlatmatesAvatar({
    required this.name,
    super.key,
    this.imageUrl,
    this.size = 52,
  });

  final String? name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = initialsFromName(name);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.95),
            theme.colorScheme.primary.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _AvatarFallback(initials: initials, size: size),
              ),
            )
          : _AvatarFallback(initials: initials, size: size),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Brand logo: "36" + rotate_right icon (acts as the "0") + "FLATMATES".
///
/// This is intentional per DESIGN.md — the rotate_right icon visually
/// represents the "0" in "360", making the logo read as "360 FLATMATES".
/// Do NOT change "36" to "360" or replace the icon with a literal "0".
class FlatmatesLogo extends StatelessWidget {
  const FlatmatesLogo({super.key, this.compact = false, this.centered = false});

  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberSize = compact ? 28.0 : 38.0;
    final labelSize = compact ? 13.0 : 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '36',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: Offset(0, compact ? -2 : -4),
                  child: Icon(
                    Icons.rotate_right_rounded,
                    color: theme.colorScheme.primary,
                    size: compact ? 30 : 38,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          'FLATMATES',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: labelSize,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Primary CTA button — solid fill (no gradient), matching DESIGN.md spec.
class FlatmatesButton extends StatelessWidget {
  const FlatmatesButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? theme.colorScheme.primary : null,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legacy alias — now delegates to solid FlatmatesButton.
/// Prefer using FlatmatesButton directly in new code.
class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FlatmatesButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      height: height,
    );
  }
}

class FlatmatesSectionHeader extends StatelessWidget {
  const FlatmatesSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    required this.label,
    super.key,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.colorScheme.surfaceContainerLowest;
    final foreground = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized menu row for Profile and Settings screens.
/// Matches screenshot #15 / #19 menu item pattern.
class FlatmatesMenuItem extends StatelessWidget {
  const FlatmatesMenuItem({
    required this.label,
    required this.icon,
    super.key,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? theme.colorScheme.error.withValues(alpha: 0.08)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification list item card — matches screenshot #17 pattern.
class FlatmatesNotificationCard extends StatelessWidget {
  const FlatmatesNotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    super.key,
    this.isRead = false,
    this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconBgColor;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconBgColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile grid card for Likes tab — matches screenshot #9 2-column grid pattern.
class FlatmatesProfileGridCard extends StatelessWidget {
  const FlatmatesProfileGridCard({
    required this.name,
    required this.location,
    required this.profession,
    required this.matchPercentage,
    required this.imageUrl,
    required this.onMatchTap,
    super.key,
    this.age,
  });

  final String name;
  final int? age;
  final String location;
  final String profession;
  final double? matchPercentage;
  final String? imageUrl;
  final VoidCallback onMatchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchColor = compatibilityScoreColor(matchPercentage ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (matchPercentage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: matchColor, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${matchPercentage!.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: matchColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          age == null ? name : '$name, $age',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (location.trim().isNotEmpty)
          Text(
            location,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (profession.trim().isNotEmpty)
          Text(
            profession,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            onPressed: onMatchTap,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Match',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Localization helpers ────────────────────────────────────────────────

String localizedFlatmatesModeLabel(AppLocalizations locale, String mode) {
  switch (mode.trim().toLowerCase()) {
    case 'room_poster':
      return locale.modeRoomPoster;
    case 'seeker':
      return locale.modeSeeker;
    case 'co_hunter':
      return locale.modeCoHunter;
    case 'open_to_both':
      return locale.modeOpenToBoth;
    default:
      return humanizeFlatmatesToken(mode);
  }
}

String localizedFlatmatesGenderLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'any':
      return locale.genderAny;
    case 'male':
      return locale.genderMale;
    case 'female':
      return locale.genderFemale;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesSharingTypeLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'private_room':
      return locale.sharingPrivateRoom;
    case 'shared_room':
      return locale.sharingSharedRoom;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesVisitStatusLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'scheduled':
      return locale.visitStatusScheduled;
    case 'confirmed':
      return locale.visitStatusConfirmed;
    case 'completed':
      return locale.visitStatusCompleted;
    case 'cancelled':
    case 'canceled':
      return locale.visitStatusCancelled;
    case 'requested':
      return locale.visitStatusRequested;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesFeatureLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'furnished':
      return locale.featureFurnished;
    case 'semi_furnished':
      return locale.featureSemiFurnished;
    case 'wifi':
    case 'wi_fi':
    case 'wi-fi':
    case 'high_speed_wifi':
    case 'fast_wifi':
      return locale.featureWifi;
    case 'balcony':
      return locale.featureBalcony;
    case 'attached_bathroom':
      return locale.featureAttachedBathroom;
    case 'parking':
      return locale.featureParking;
    case 'ac':
    case 'air_conditioning':
      return locale.featureAc;
    case 'washing_machine':
      return locale.featureWashingMachine;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String humanizeFlatmatesToken(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
````

## File: lib/features/swipe/match_celebration_screen.dart
````dart
import 'dart:math' as math show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../shared/presentation/flatmates_ui.dart';

class MatchCelebrationScreen extends StatefulWidget {
  const MatchCelebrationScreen({
    required this.userName,
    required this.userImageUrl,
    required this.peerName,
    required this.peerImageUrl,
    required this.onOpenChat,
    required this.onKeepSwiping,
    super.key,
  });

  final String userName;
  final String? userImageUrl;
  final String peerName;
  final String? peerImageUrl;
  final VoidCallback onOpenChat;
  final VoidCallback onKeepSwiping;

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              Color(0xFF5B4BCF), // primary
              Color(0xFF10B981), // green/success
              Color(0xFFF59E0B), // gold/warning
            ],
            createParticlePath: null,
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      '🎉',
                      style: const TextStyle(fontSize: 64),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      "It's a Match!",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 36,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You and ${widget.peerName} liked each other',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MatchAvatar(
                          name: widget.userName,
                          imageUrl: widget.userImageUrl,
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _MatchAvatar(
                          name: widget.peerName,
                          imageUrl: widget.peerImageUrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('match_open_chat'),
                            onPressed: widget.onOpenChat,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Send a message'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: const Key('match_keep_swiping'),
                            onPressed: widget.onKeepSwiping,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Keep swiping'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary, width: 3),
        gradient: hasImage
            ? null
            : LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.9),
                  theme.colorScheme.primary.withValues(alpha: 0.5),
                ],
              ),
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarInitials(name: name),
              ),
            )
          : _AvatarInitials(name: name),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initialsFromName(name),
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
````

## File: lib/features/visits/visits_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'visits_repository.dart';

class VisitsPage extends ConsumerStatefulWidget {
  const VisitsPage({super.key});

  @override
  ConsumerState<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends ConsumerState<VisitsPage> {
  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: visits.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Text(locale.emptyVisits));
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(visitsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  FlatmatesSectionHeader(
                    title: locale.scheduleTitle,
                    subtitle: locale.scheduleSubtitle,
                  ),
                  const SizedBox(height: 18),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.55,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.event_available_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.propertyTitle,
                                          style: theme.textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'd MMM yyyy, h:mm a',
                                            locale.localeName,
                                          ).format(
                                            item.scheduledDate.toLocal(),
                                          ),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  InfoPill(
                                    label: localizedFlatmatesVisitStatusLabel(
                                      locale,
                                      item.status,
                                    ),
                                    highlighted:
                                        item.status == 'scheduled' ||
                                        item.status == 'confirmed',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  InfoPill(
                                    icon: Icons.meeting_room_outlined,
                                    label: item.visitContext == 'flatmate_meet'
                                        ? locale.flatmateMeetLabel
                                        : locale.propertyTourLabel,
                                  ),
                                  InfoPill(
                                    icon: Icons.calendar_month_outlined,
                                    label: DateFormat(
                                      'EEEE',
                                      locale.localeName,
                                    ).format(item.scheduledDate.toLocal()),
                                  ),
                                ],
                              ),
                              if (_hasActions(item.status)) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: _buildActions(item, locale, theme),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(visitsProvider),
                  child: Text(locale.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasActions(String status) {
    return status == 'requested' ||
        status == 'scheduled' ||
        status == 'confirmed';
  }

  List<Widget> _buildActions(
    VisitItem item,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    final actions = <Widget>[];

    if (item.status == 'requested') {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: () => _confirmVisit(item),
            child: Text(locale.visitConfirmTitle),
          ),
        ),
      );
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelVisit(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(locale.visitCancelCta),
          ),
        ),
      );
    } else if (item.status == 'scheduled' || item.status == 'confirmed') {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rescheduleVisit(item),
            child: Text(locale.visitRescheduleCta),
          ),
        ),
      );
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelVisit(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(locale.visitCancelCta),
          ),
        ),
      );
    }

    return actions;
  }

  Future<void> _confirmVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    try {
      await ref.read(visitsRepositoryProvider).confirmVisit(item.id);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitConfirmed)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancelVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.visitCancelCta),
        content: Text(locale.visitCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(locale.visitCancelCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(visitsRepositoryProvider).cancelVisit(item.id);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitCancelled)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _rescheduleVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: item.scheduledDate.isAfter(DateTime.now())
          ? item.scheduledDate
          : DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.scheduledDate.toLocal()),
    );
    if (time == null || !mounted) return;

    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await ref
          .read(visitsRepositoryProvider)
          .rescheduleVisit(item.id, newDate);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitRescheduleCta)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
````

## File: lib/features/visits/visits_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class VisitItem {
  const VisitItem({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.scheduledDate,
    required this.visitContext,
  });

  final int id;
  final String propertyTitle;
  final String status;
  final DateTime scheduledDate;
  final String visitContext;

  factory VisitItem.fromJson(Map<String, dynamic> json) {
    final property = Map<String, dynamic>.from(
      json['property'] as Map? ?? const {},
    );
    return VisitItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      propertyTitle: property['title'] as String? ?? 'Visit',
      status: json['status'] as String? ?? 'scheduled',
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      visitContext: json['visit_context'] as String? ?? 'property_tour',
    );
  }
}

class VisitsRepository {
  const VisitsRepository(this._ref);

  final Ref _ref;

  Future<List<VisitItem>> fetchVisits() async {
    final response = await _ref.watch(apiClientProvider).get('/visits');
    final data = Map<String, dynamic>.from(response.data as Map);
    final visits = (data['visits'] as List? ?? const []);
    return visits
        .map(
          (item) => VisitItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> scheduleFlatmateVisit({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    String? note,
  }) async {
    await _ref
        .watch(apiClientProvider)
        .post(
          '/visits',
          data: {
            'property_id': propertyId,
            'scheduled_date': scheduledDate.toUtc().toIso8601String(),
            'visit_context': 'flatmate_meet',
            'counterparty_user_id': counterpartyUserId,
            'conversation_id': conversationId,
            if (note != null && note.trim().isNotEmpty)
              'special_requirements': note.trim(),
          },
        );
  }

  Future<void> confirmVisit(int visitId) async {
    await _ref
        .watch(apiClientProvider)
        .put('/visits/$visitId', data: {'status': 'confirmed'});
  }

  Future<void> rescheduleVisit(int visitId, DateTime newDate) async {
    await _ref
        .watch(apiClientProvider)
        .put(
          '/visits/$visitId',
          data: {
            'scheduled_date': newDate.toUtc().toIso8601String(),
            'status': 'requested',
          },
        );
  }

  Future<void> cancelVisit(int visitId) async {
    await _ref
        .watch(apiClientProvider)
        .put('/visits/$visitId', data: {'status': 'cancelled'});
  }
}

final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(ref),
);

final visitsProvider = FutureProvider<List<VisitItem>>(
  (ref) => ref.watch(visitsRepositoryProvider).fetchVisits(),
);
````

## File: lib/main.dart
````dart
import 'bootstrap.dart';

Future<void> main() async {
  await bootstrap();
}
````

## File: test/helpers/test_helpers.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/config/app_config.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/network/auth_token_provider.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/core/storage/auth_token_storage.dart';
import 'package:flatmates_app/core/storage/secure_kv_store.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/data/auth_repository.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// A minimal [AppConfig] for tests.
AppConfig fakeAppConfig() => const AppConfig(
  environment: AppEnvironment.dev,
  apiBaseUrl: 'https://api.test.example.com',
  supabaseUrl: 'https://test.supabase.co',
  supabaseAnonKey: 'test-anon-key',
  enableDebugLogs: false,
);

// ---------------------------------------------------------------------------
// No-op infrastructure fakes
// ---------------------------------------------------------------------------

/// A no-op [AuthTokenProvider] for tests.
class FakeAuthTokenProvider implements AuthTokenProvider {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> clearSession() async {}
}

ApiClient _fakeApiClient() => ApiClient(
  baseUrl: 'https://test.example.com',
  tokenProvider: FakeAuthTokenProvider(),
  enableLogging: false,
);

AuthTokenStorage _fakeAuthTokenStorage() => AuthTokenStorage(SecureKvStore());

AuthRepository _fakeAuthRepository() => AuthRepository(
  apiClient: _fakeApiClient(),
  tokenStorage: _fakeAuthTokenStorage(),
);

// ---------------------------------------------------------------------------
// Fake controllers
// ---------------------------------------------------------------------------

/// A fake [AuthController] that overrides every method to avoid Supabase.
class FakeAuthController extends AuthController {
  FakeAuthController(Ref ref) : super(ref, _fakeAuthRepository());

  @override
  Future<void> checkSession() async {
    state = const AuthState.unauthenticated();
  }

  @override
  Future<void> requestOtp(String phone) async {
    state = AuthState.unauthenticated(phone: phone);
  }

  @override
  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState.authenticated(phone: phone);
    return true;
  }

  @override
  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    state = AuthState.authenticated(phone: phone);
    return true;
  }

  @override
  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = AuthState.authenticated(phone: phone);
    return true;
  }

  @override
  Future<void> signOut() async {
    state = const AuthState.unauthenticated();
  }
}

/// A fake [SettingsController] that overrides load to avoid disk I/O.
class FakeSettingsController extends SettingsController {
  FakeSettingsController(super.prefs);

  @override
  Future<void> load() async {
    state = state.copyWith(loaded: true);
  }
}

BootstrapData fakeBootstrapData() => BootstrapData(
  profile: const FlatmatesProfileModel(
    id: 1,
    fullName: 'Test User',
    phone: '+919999999999',
    email: 'test@example.com',
    profileImageUrl: null,
    mode: 'co_hunter',
    profileStatus: 'active',
    onboardingCompleted: true,
    bio: null,
    age: 25,
    profession: 'Engineer',
    budgetMin: null,
    budgetMax: null,
    moveInTimeline: null,
    city: 'Bangalore',
    state: 'Karnataka',
    locality: 'Koramangala',
    sleepSchedule: null,
    cleanliness: null,
    foodHabits: null,
    smokingDrinking: null,
    guestsPolicy: null,
    workStyle: null,
    gender: null,
    genderPreference: null,
    preferences: {},
  ),
  catalogs: const [
    CatalogEntryModel(
      key: 'flatmates_modes',
      version: 1,
      payload: {
        'items': [
          {
            'id': 'co_hunter',
            'label': 'Find a Flat / Flatmate',
            'description': 'I want to find a place or a flatmate to stay with',
          },
          {
            'id': 'room_poster',
            'label': 'List My Flat / Find Flatmate',
            'description': 'I want to list my flat or find a flatmate',
          },
          {
            'id': 'open_to_both',
            'label': 'Open to Both',
            'description': 'Flexible to find or list',
          },
        ],
      },
    ),
    CatalogEntryModel(
      key: 'flatmates_popular_cities',
      version: 1,
      payload: {
        'items': [
          {'id': 'bangalore', 'label': 'Bangalore'},
        ],
      },
    ),
  ],
  activeListingCount: 0,
  conversationCount: 0,
  unreadMessageCount: 0,
);

class FakeBootstrapController extends BootstrapController {
  FakeBootstrapController(super.ref) {
    state = AsyncValue.data(fakeBootstrapData());
  }

  @override
  Future<void> load() async {
    state = AsyncValue.data(fakeBootstrapData());
  }
}

// ---------------------------------------------------------------------------
// Cached AppPreferences instance (created once per test isolate)
// ---------------------------------------------------------------------------

AppPreferences? _cachedPrefs;

/// Returns a cached [AppPreferences] for tests.
/// Must be called after `SharedPreferences.setMockInitialValues({})`.
Future<AppPreferences> get testAppPreferences async {
  if (_cachedPrefs != null) return _cachedPrefs!;
  _cachedPrefs = await AppPreferences.create();
  return _cachedPrefs!;
}

// ---------------------------------------------------------------------------
// Testable widget helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in a [ProviderScope] and [MaterialApp] with fake providers.
///
/// For tests that need settings functionality, use [testableWidgetAsync] instead.
Widget testableWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authControllerProvider.overrideWith((ref) => FakeAuthController(ref)),
      bootstrapControllerProvider.overrideWith(
        (ref) => FakeBootstrapController(ref),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

/// Async variant of [testableWidget] that also sets up the settings provider.
/// Must be awaited because it creates [AppPreferences] asynchronously.
///
/// Call `SharedPreferences.setMockInitialValues({})` in `setUp` first.
Future<Widget> testableWidgetAsync({
  required Widget child,
  List<Override> overrides = const [],
}) async {
  final prefs = await testAppPreferences;
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith((ref) => FakeAuthController(ref)),
      bootstrapControllerProvider.overrideWith(
        (ref) => FakeBootstrapController(ref),
      ),
      settingsControllerProvider.overrideWith(
        (ref) => FakeSettingsController(ref.watch(appPreferencesProvider)),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}
````

## File: test/auth_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/auth/presentation/otp_page.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EnterPhonePage', () {
    testWidgets('renders phone input and OTP CTA', (tester) async {
      await tester.pumpWidget(testableWidget(child: const EnterPhonePage()));
      await tester.pump();
      await tester.pump();

      // Should show the phone text field.
      expect(find.byKey(const Key('enter_phone_input')), findsOneWidget);

      // Should show the OTP CTA (always visible).
      expect(find.byKey(const Key('enter_phone_otp_cta')), findsOneWidget);

      // The password CTA and signup CTA are gated behind enableDebugLogs
      // in the production widget, so they won't appear with our test config.
    });

    testWidgets('starts with +91 prefix in phone field', (tester) async {
      await tester.pumpWidget(testableWidget(child: const EnterPhonePage()));
      await tester.pump();
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('enter_phone_input')),
      );
      expect(textField.controller?.text, '+91');
    });
  });

  group('OtpPage', () {
    testWidgets('renders 6 OTP digit fields and submit button', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: const OtpPage(phone: '+919876543210')),
      );
      await tester.pump();
      await tester.pump();

      // Should show 6 individual digit text fields.
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('otp_digit_$i')), findsOneWidget);
      }

      // Should show the submit button.
      expect(find.byKey(const Key('otp_submit_button')), findsOneWidget);
    });

    testWidgets('submit button is enabled when not submitting', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: const OtpPage(phone: '+919876543210')),
      );
      await tester.pump();
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('otp_submit_button')),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
````

## File: test/compatibility_test.dart
````dart
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';

void main() {
  group('CompatibilityEngine', () {
    test('exact match on all dimensions yields 100%', () {
      final user = <String, String>{
        'sleep_schedule': 'early_bird',
        'cleanliness': 'tidy',
        'food_habits': 'vegetarian',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };

      final result = CompatibilityEngine.calculate(user: user, peer: user);

      expect(result.percentage, 100.0);
      expect(result.dimensions.every((d) => d.score == 100), isTrue);
      // All dimensions are matches, so we should get up to 3 top match chips.
      expect(result.topMatchChips.length, 3);
    });

    test('opposite sleep schedule yields lower sleep score', () {
      final earlyBird = {'sleep_schedule': 'early_bird'};
      final nightOwl = {'sleep_schedule': 'night_owl'};

      final result = CompatibilityEngine.calculate(
        user: earlyBird,
        peer: nightOwl,
      );

      // early_bird and night_owl differ by 2 positions (gap = 2), score = 0.
      final sleepDim = result.dimensions.firstWhere(
        (d) => d.key == 'sleep_schedule',
      );
      expect(sleepDim.score, 0.0);
      expect(sleepDim.isMatch, isFalse);
    });

    test('strict veg + non-veg yields low food score', () {
      final user = <String, String>{'food_habits': 'vegetarian'};
      final peer = <String, String>{'food_habits': 'non_vegetarian'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      // vegetarian (strict) + non_vegetarian (non-strict) => score = 0.
      expect(foodDim.score, 0.0);
      expect(foodDim.isMatch, isFalse);
    });

    test('vegan + non-veg also yields low food score', () {
      final user = <String, String>{'food_habits': 'vegan'};
      final peer = <String, String>{'food_habits': 'non_vegetarian'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 0.0);
    });

    test('two non-strict diets get full food score', () {
      final user = <String, String>{'food_habits': 'non_vegetarian'};
      final peer = <String, String>{'food_habits': 'no_preference'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      // Both are non-strict => score = 100.
      expect(foodDim.score, 100.0);
    });

    test('same food habits yields 100 food score', () {
      final user = <String, String>{'food_habits': 'vegetarian'};
      final peer = <String, String>{'food_habits': 'vegetarian'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final foodDim = result.dimensions.firstWhere(
        (d) => d.key == 'food_habits',
      );
      expect(foodDim.score, 100.0);
    });

    test('weights are correctly applied', () {
      // All dimensions identical => 100% regardless of weights.
      final profile = <String, String>{
        'sleep_schedule': 'flexible',
        'cleanliness': 'tidy',
        'food_habits': 'no_preference',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };

      final result = CompatibilityEngine.calculate(
        user: profile,
        peer: profile,
      );
      expect(result.percentage, 100.0);

      // Verify weight sum.
      final weightSum = result.dimensions.fold<double>(
        0.0,
        (sum, d) => sum + d.weight,
      );
      // 0.20 + 0.20 + 0.15 + 0.20 + 0.15 + 0.10 = 1.0
      expect(weightSum, closeTo(1.0, 0.001));
    });

    test('defaults to flexible/tidy when keys are missing', () {
      final result = CompatibilityEngine.calculate(
        user: <String, String>{},
        peer: <String, String>{},
      );

      // Both default to same values, so all scores should be 100.
      expect(result.percentage, 100.0);
    });

    test('wfh + office yields lower work style score', () {
      final user = <String, String>{'work_style': 'wfh'};
      final peer = <String, String>{'work_style': 'office'};

      final result = CompatibilityEngine.calculate(user: user, peer: peer);

      final workDim = result.dimensions.firstWhere(
        (d) => d.key == 'work_style',
      );
      expect(workDim.score, 40.0);
    });

    test('topMatchChips limits to at most 3', () {
      final profile = <String, String>{
        'sleep_schedule': 'flexible',
        'cleanliness': 'tidy',
        'food_habits': 'no_preference',
        'smoking_drinking': 'neither',
        'guests_policy': 'occasional_ok',
        'work_style': 'hybrid',
      };

      final result = CompatibilityEngine.calculate(
        user: profile,
        peer: profile,
      );
      // All 6 dimensions match, but chips are capped at 3.
      expect(result.topMatchChips.length, 3);
    });
  });
}
````

## File: test/onboarding_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/features/onboarding/mode_selection_page.dart';
import 'package:flatmates_app/features/onboarding/basic_info_page.dart';
import 'package:flatmates_app/features/onboarding/onboarding_controller.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('OnboardingController', () {
    test('completing splash moves a new user to mode selection', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(onboardingControllerProvider.notifier);
      await controller.completeSplash();

      final state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.modeSelection);
      expect(state.mode, isNull);
    });
  });

  group('ModeSelectionPage', () {
    testWidgets('renders exactly three mode options', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: ModeSelectionPage(onModeSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mode_room_poster')), findsOneWidget);
      expect(find.byKey(const Key('mode_co_hunter')), findsOneWidget);
      expect(find.byKey(const Key('mode_open_to_both')), findsOneWidget);
    });

    testWidgets('selecting a mode and pressing continue calls onModeSelected', (
      tester,
    ) async {
      String? selectedMode;
      await tester.pumpWidget(
        testableWidget(
          child: ModeSelectionPage(
            onModeSelected: (mode) => selectedMode = mode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select a mode card
      await tester.tap(find.byKey(const Key('mode_co_hunter')));
      await tester.pumpAndSettle();

      // Continue button should now be enabled — tap it
      await tester.tap(find.byKey(const Key('mode_continue')));
      expect(selectedMode, 'co_hunter');
    });
  });

  group('BasicInfoPage', () {
    testWidgets('next button is disabled when fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<GradientActionButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is disabled when age is under 18', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'John Doe',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '17');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Engineer',
      );
      await tester.enterText(find.byKey(const Key('onboarding_city')), 'Delhi');
      await tester.pump();

      final button = tester.widget<GradientActionButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('next button is enabled when all fields valid and age >= 18', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Jane Doe',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '25');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Designer',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Mumbai',
      );
      await tester.pump();

      final button = tester.widget<GradientActionButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('age of exactly 18 is accepted', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: BasicInfoPage(onNext: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name')),
        'Test User',
      );
      await tester.enterText(find.byKey(const Key('onboarding_age')), '18');
      await tester.enterText(
        find.byKey(const Key('onboarding_profession')),
        'Student',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_city')),
        'Bangalore',
      );
      await tester.pump();

      final button = tester.widget<GradientActionButton>(
        find.byKey(const Key('onboarding_basic_info_next')),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
````

## File: test/settings_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/theme/app_palette.dart';
import 'package:flatmates_app/features/settings/settings_page.dart';

import 'helpers/test_helpers.dart';

/// Opens the Preferences bottom sheet by tapping the menu item.
Future<void> openPreferencesSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('preferences_menu_item')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsPage', () {
    testWidgets('renders theme mode segmented button in preferences sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_system_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_light_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_dark_option')), findsOneWidget);
    });

    testWidgets('renders palette choice chips for all palettes', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      for (final palette in AppPalette.values) {
        expect(
          find.byKey(Key('palette_${palette.storageValue}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('tapping dark theme option updates state', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      await tester.tap(find.byKey(const Key('theme_mode_dark_option')));
      await tester.pumpAndSettle();

      final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmentedButton.selected, contains(ThemeMode.dark));
    });

    testWidgets('tapping a palette chip updates state', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      await tester.tap(find.byKey(const Key('palette_ember_coral')));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('palette_ember_coral')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('renders privacy toggles in preferences sheet', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      // Scroll the bottom sheet's scrollable to reveal privacy toggles.
      final sheetScrollable = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('setting_hide_last_name')),
        200,
        scrollable: sheetScrollable,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('setting_hide_location')),
        200,
        scrollable: sheetScrollable,
      );

      expect(find.byKey(const Key('setting_hide_last_name')), findsOneWidget);
      expect(find.byKey(const Key('setting_hide_location')), findsOneWidget);
    });

    testWidgets('renders logout button on main page', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal the logout button.
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout_button')),
        400,
        scrollable: find.byType(Scrollable),
      );

      expect(find.byKey(const Key('logout_button')), findsOneWidget);
    });
  });
}
````

## File: test/widget_test.dart
````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_palette.dart';

void main() {
  test(
    'AppPalette falls back to electric indigo for unknown storage values',
    () {
      expect(
        AppPaletteX.fromStorage('unknown-value'),
        AppPalette.electricIndigo,
      );
    },
  );
}
````

## File: .env.example
````
# Required: Your backend API URL (e.g., https://api.the360ghar.com/api/v1)
API_BASE_URL=
# Required: Your Supabase project URL (e.g., https://xxxxx.supabase.co)
SUPABASE_URL=
# Required: Your Supabase anon/public key
SUPABASE_PUBLISHABLE_KEY=
# Optional: google maps API key for map features
GOOGLE_MAPS_API_KEY=
# Optional: debug logging
ENABLE_DEBUG_LOGS=true
````

## File: .fvmrc
````
{
  "flutter": "3.41.6"
}
````

## File: AGENTS.md
````markdown
# AGENTS.md

## Repo Purpose

This repository contains the dedicated Flutter mobile client for 360 FlatMates. It is not a general-purpose 360 Ghar client and it must stay aligned to the backend monolith and the flatmates-specific app surface.

## Core Rules

- Use real backend APIs only. Do not introduce mock repositories, fake payloads, or hardcoded business catalogs.
- Keep the app mobile-first and maintain parity between iOS and Android.
- Treat `../backend` as the source of truth for product data contracts.
- Keep business metadata server-driven through `/api/v1/flatmates/catalogs` whenever the data affects product behavior.

## Architecture Boundaries

- `lib/core` is for app-wide technical plumbing only.
- `lib/features` owns product behavior and presentation.
- Avoid leaking feature logic into `core`.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.

## Riverpod Guidance

- Prefer Riverpod providers over singleton services.
- Keep async fetching in providers or focused notifiers.
- Invalidate feature providers after write operations instead of manually syncing widget trees.
- Avoid global mutable state outside provider-controlled objects.

## Networking Guidance

- Use the shared Dio client from `core`.
- All authenticated requests must flow through the shared auth interceptor.
- Do not bypass the shared client for ad hoc HTTP calls.
- Keep backend paths centralized by usage, not by hardcoded duplication of base URLs.

## UI Guidance

- Maintain support for light, dark, and system theme modes (default: Light).
- Preserve palette switching as a first-class product capability.
- Keep English and Hindi localization coverage in sync for all primary user flows (default: English).
- Use meaningful keys on major interactive widgets so Maestro coverage can remain stable.
- All visual tokens (colors, radii, spacing, typography, shadows, components) must match [DESIGN.md](DESIGN.md). Do not introduce values that contradict the design system.

## Testing Guidance

- Keep `flutter analyze` clean.
- Keep at least one fast local Flutter test in the repo.
- Maintain a single end-to-end Maestro flow that exercises the real product loop.
- Update Maestro when route names, button labels, or login flow behavior changes.

## Documentation Triggers

Update the docs in `docs/` when any of the following change:

- Backend API surface consumed by the app
- Repo architecture or folder layout
- Theme and localization strategy
- Auth bootstrap flow
- Maestro prerequisites or seeded-data assumptions

## Cross-Repo Discipline

- If a change requires new backend fields or endpoints, implement or coordinate that work in `../backend`.
- If moderation or review workflows are required, plan or implement them in `../real-estate-admin-dashboard`.
- Do not fork the contract locally in the Flutter app to avoid touching the backend.
````

## File: analysis_options.yaml
````yaml
# This file configures the analyzer, which statically analyzes Dart code to
# check for errors, warnings, and lints.
#
# The issues identified by the analyzer are surfaced in the UI of Dart-enabled
# IDEs (https://dart.dev/tools#ides-and-editors). The analyzer can also be
# invoked from the command line by running `flutter analyze`.

# The following line activates a set of recommended lints for Flutter apps,
# packages, and plugins designed to encourage good coding practices.
include: package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
  # section below to disable rules from the `package:flutter_lints/flutter.yaml`
  # included above or to enable additional rules. A list of all available lints
  # and their documentation is published at https://dart.dev/lints.
  #
  # Instead of disabling a lint rule for the entire project in the
  # section below, it can also be suppressed for a single line of code
  # or a specific dart file by using the `// ignore: name_of_lint` and
  # `// ignore_for_file: name_of_lint` syntax on the line or in the file
  # producing the lint.
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule

# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
````

## File: CLAUDE.md
````markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

360 FlatMates — a Flutter mobile client for flatmate-finding in India. Uses Supabase for auth/storage and a FastAPI backend monolith at `../backend` for all business logic and product data.

- **Flutter:** 3.35.2 (pinned via FVM in `.fvmrc`)
- **Dart SDK:** ^3.11.0
- **App ID:** `com.the360ghar.flatmates`

## Commands

```bash
# Setup
cp .env.example .env          # then fill in SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, API_BASE_URL
flutter pub get

# Run
flutter run

# Quality
flutter analyze
flutter test

# Localization (auto-generated on build, but can be triggered manually)
flutter gen-l10n

# Maestro E2E (requires MAESTRO_PHONE, MAESTRO_PASSWORD, etc. env vars)
maestro test .maestro/flatmates_e2e.yaml
maestro test maestro/e2e.yaml
```

## Architecture

### Feature-first structure under `lib/`

```
lib/
  main.dart                     → entry point
  bootstrap.dart                → DI setup, Supabase init, ProviderScope
  app/
    app.dart                    → MaterialApp.router
    app_shell.dart              → bottom nav shell (5 visible tabs)
    router/app_router.dart      → GoRouter with auth/bootstrap redirects
  core/                         → app-wide plumbing only (no feature logic)
    providers.dart              → global Riverpod providers
    config/                     → AppConfig, constants, env loader
    network/                    → Dio client, auth/error interceptors
    notifications/              → Firebase Messaging
    storage/                    → SharedPreferences, secure storage, image upload
    theme/                      → Material 3 theme with palette switching
    compatibility/              → client-side matching algorithm (6 weighted dimensions)
  features/                     → each feature owns its controller, repo, models, pages
    auth/                       → Supabase auth (phone+password, OTP)
    bootstrap/                  → loads /flatmates/bootstrap (profile + catalogs + counts)
    onboarding/                 → multi-step state machine (mode → info → photo → quiz → budget → dealbreakers)
    discover/                   → listing feed + map view
    swipe/                      → Tinder-like card deck
    chats/                      → conversations + messages (polling, no realtime)
    listings/                   → create/manage listings
    visits/                     → schedule/confirm/reschedule visits
    notifications/              → notification list
    profile/                    → profile view/edit
    settings/                   → theme mode, palette, locale, privacy
    shared/presentation/        → FlatmatesAvatar, GradientActionButton, InfoPill, etc.
```

### State management — Riverpod

- `StateNotifierProvider` for controllers with complex state (`AuthController`, `BootstrapController`, `OnboardingController`, `SettingsController`)
- `Provider` for repositories and services (injected via `ref.watch`)
- `FutureProvider` / `FutureProvider.family` for async data fetching (discover listings, swipe profiles, chats, notifications, visits)
- Three providers overridden at `ProviderScope` root: `appConfigProvider`, `appPreferencesProvider`, `secureStoreProvider`
- After write operations, **invalidate** the relevant provider rather than manually syncing widget state

### Routing — GoRouter

- `StatefulShellRoute.indexedStack` with 6 branches: `/discover`, `/swipe`, `/chats`, `/visits` (hidden tab, accessed from profile), `/post`, `/profile`
- Auth redirect chain: checking → `/splash`, unauthenticated → `/enter-phone`, onboarding incomplete → `/onboarding`
- Router refreshes on `authControllerProvider` and `bootstrapControllerProvider` changes

### Networking

- Shared `Dio` client from `core/network/api_client.dart` — all authenticated requests go through this
- `AuthInterceptor` attaches Bearer token, handles 401 with automatic token refresh (Supabase session)
- `ErrorInterceptor` maps DioException types to user-friendly messages
- Backend paths are relative to `AppConfig.apiBaseUrl` (set via `.env` or `--dart-define`)

### Auth flow

1. Phone input → password login or OTP via Supabase
2. After auth, `GET /users/me` validates user exists in backend
3. `BootstrapController` fetches `/flatmates/bootstrap` for profile + catalogs
4. If `onboardingCompleted == false`, router redirects to onboarding flow

### Theme and localization

- Material 3 via `ColorScheme.fromSeed()` with 3 palettes: electric indigo (default), ember coral, monsoon teal
- Google Fonts: Sora (headlines), Plus Jakarta Sans (body)
- Light/dark/system theme modes, persisted to SharedPreferences (defaults: **Light mode**, **English** locale)
- ARB-based l10n: English (`app_en.arb`, template) and Hindi (`app_hi.arb`), generated to `lib/l10n/gen/`

### Design system

The canonical design tokens, component specifications, and screen-by-screen
implementation targets are documented in [DESIGN.md](DESIGN.md). All UI work
should reference DESIGN.md as the source of truth for colors, typography,
spacing, border radii, component behavior, and per-screen layout specs.

### Key patterns

- No code generation (no freezed, no json_serializable). Models are hand-written with `fromJson` factories.
- Image uploads go to Supabase Storage via `ImageUploadService` (supports photos and video tours up to 50MB).
- Compatibility scoring runs client-side in `core/compatibility/` with 6 weighted dimensions.
- No realtime/WebSocket — chat uses polling via `FutureProvider`.

## Cross-repo dependencies

- **`../backend`** — FastAPI monolith, source of truth for API contracts. If new fields/endpoints are needed, implement there first.
- **`../real-estate-admin-dashboard`** — admin dashboard for moderation workflows.
- Do not fork API contracts locally in the Flutter app.

## Rules from AGENTS.md

- Use real backend APIs only — no mock repositories, fake payloads, or hardcoded catalogs.
- Keep business metadata server-driven via `/api/v1/flatmates/catalogs`.
- `lib/core` is for technical plumbing only — don't leak feature logic there.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.
- All authenticated requests must flow through the shared Dio client and auth interceptor.
- Maintain light/dark/system theme support and palette switching.
- Keep English and Hindi localization in sync for primary flows.
- Use meaningful `Key` values on interactive widgets for Maestro stability.
- Update `docs/` when API surface, architecture, theme/localization strategy, auth flow, or Maestro assumptions change.
````

## File: l10n.yaml
````yaml
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-dir: lib/l10n/gen
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
````

## File: lib/app/router/app_router.dart
````dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_shell.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/presentation/enter_phone_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/bootstrap/bootstrap_controller.dart';
import '../../features/chats/chat_thread_page.dart';
import '../../features/chats/chats_repository.dart';
import '../../features/chats/conversations_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/discover/flat_details_page.dart';
import '../../features/discover/map_view_page.dart';
import '../../features/discover/search_filters_page.dart';
import '../../features/listings/create_listing_page.dart';
import '../../features/listings/listing_under_review_page.dart';
import '../../features/listings/manage_listing_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/help_safety_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/blocked_users_page.dart';
import '../../features/settings/change_password_page.dart';
import '../../features/swipe/swipe_deck_page.dart';
import '../../features/visits/schedule_visit_page.dart';
import '../../features/visits/visits_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    refreshNotifier.refresh();
  });
  ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
    previous,
    next,
  ) {
    refreshNotifier.refresh();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final bootstrap = ref.read(bootstrapControllerProvider);
      final location = state.uri.path;
      final isSplash = location == '/splash';
      final isAuthRoute =
          location == '/enter-phone' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/otp';
      final isOnboarding = location == '/onboarding';
      final isDeepLink =
          location.startsWith('/chats/') ||
          location.startsWith('/flat-details/') ||
          location.startsWith('/listing-review/') ||
          location == '/visits' ||
          location == '/post' ||
          location == '/post/new' ||
          location == '/notifications' ||
          location == '/schedule-visit' ||
          location == '/search-filters' ||
          location == '/help-safety' ||
          location == '/change-password' ||
          location == '/map';

      if (auth.status == AuthStatus.checking) {
        return isSplash ? null : '/splash';
      }

      if (!auth.isLoggedIn) {
        return isAuthRoute ? null : '/enter-phone';
      }

      if (bootstrap.isLoading || bootstrap.valueOrNull == null) {
        return isSplash ? null : '/splash';
      }

      final profile = bootstrap.valueOrNull?.profile;
      if (profile != null && !profile.onboardingCompleted && !isOnboarding) {
        return '/onboarding';
      }

      if (isSplash || isAuthRoute) {
        return '/discover';
      }

      // Allow deep link paths through when user is authenticated
      if (isDeepLink) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/enter-phone',
        builder: (context, state) => const EnterPhonePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginPage(phone: state.uri.queryParameters['phone']),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) =>
            SignupPage(phone: state.uri.queryParameters['phone']),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) =>
            OtpPage(phone: state.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/flat-details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            FlatDetailsPage(listingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/search-filters',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchFiltersPage(),
      ),
      GoRoute(
        path: '/schedule-visit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ScheduleVisitPage(
          conversation: state.extra as ConversationSummaryModel?,
          conversationId: int.tryParse(
            state.uri.queryParameters['conversationId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/help-safety',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpSafetyPage(),
      ),
      GoRoute(
        path: '/change-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/blocked-users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BlockedUsersPage(),
      ),
      GoRoute(
        path: '/listing-review/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ListingUnderReviewPage(
          listingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapViewPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/swipe',
                builder: (context, state) => const SwipeDeckPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ConversationsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ChatThreadPage(
                      conversationId: int.parse(state.pathParameters['id']!),
                      conversation: state.extra as ConversationSummaryModel?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/post',
                builder: (context, state) => const ManageListingPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateListingPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visits',
                builder: (context, state) => const VisitsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
````

## File: lib/app/app_shell.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import '../features/bootstrap/bootstrap_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final mode = bootstrap?.profile.mode ?? 'co_hunter';

    // Build destination list based on user mode (PRD section 4.1)
    final destinations = _buildDestinations(mode, locale, theme);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: _mapToVisibleIndex(navigationShell.currentIndex, mode),
        onDestinationSelected: (index) {
          final branchIndex = _mapToBranchIndex(index, mode);
          navigationShell.goBranch(branchIndex);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: theme.colorScheme.surface,
        destinations: destinations,
      ),
    );
  }

  /// Build the 5 NavigationDestinations for the current user mode.
  ///
  /// Per PRD 4.1:
  /// - Room Poster: Home | Post/Manage | Swipe | Likes&Chat | Profile
  /// - Co-Hunter:   Home | Explore(Map) | Swipe | Likes&Chat | Profile
  /// - Open to Both: same as Co-Hunter
  List<NavigationDestination> _buildDestinations(
    String mode,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    final isRoomPoster = mode.trim().toLowerCase() == 'room_poster';

    return [
      // Tab 1: Home (always)
      NavigationDestination(
        icon: _navIcon('nav_home_tab', Icons.home_outlined),
        selectedIcon: _navIcon('nav_home_tab_selected', Icons.home_rounded),
        label: locale.navHome,
      ),

      // Tab 2: Mode-dependent
      if (isRoomPoster)
        NavigationDestination(
          icon: _navIcon('nav_post_tab', Icons.add_home_outlined),
          selectedIcon: _navIcon(
            'nav_post_tab_selected',
            Icons.add_home_rounded,
          ),
          label: locale.navPost,
        )
      else
        NavigationDestination(
          icon: _navIcon('nav_explore_tab', Icons.map_outlined),
          selectedIcon: _navIcon('nav_explore_tab_selected', Icons.map_rounded),
          label: locale.navExplore,
        ),

      // Tab 3: Swipe (always)
      NavigationDestination(
        icon: _navIcon('nav_swipe_tab', Icons.swap_horiz_rounded),
        selectedIcon: _navIcon(
          'nav_swipe_tab_selected',
          Icons.swap_horiz_rounded,
        ),
        label: locale.navSwipe,
      ),

      // Tab 4: Likes & Chat (always)
      NavigationDestination(
        icon: _navIcon('nav_likes_chat_tab', Icons.favorite_border_rounded),
        selectedIcon: _navIcon(
          'nav_likes_chat_tab_selected',
          Icons.favorite_rounded,
        ),
        label: locale.navLikesChat,
      ),

      // Tab 5: Profile (always)
      NavigationDestination(
        icon: _navIcon('nav_profile_tab', Icons.person_outline),
        selectedIcon: _navIcon(
          'nav_profile_tab_selected',
          Icons.person_rounded,
        ),
        label: locale.navProfile,
      ),
    ];
  }

  Widget _navIcon(String identifier, IconData icon) {
    return Semantics(
      identifier: identifier,
      child: Icon(icon, key: ValueKey(identifier)),
    );
  }

  /// Maps from the visible tab index (0-4) to the actual shell branch index.
  int _mapToBranchIndex(int visibleIndex, String mode) {
    final isRoomPoster = mode.trim().toLowerCase() == 'room_poster';

    if (isRoomPoster) {
      return [0, 4, 2, 3, 6][visibleIndex];
    }
    return [0, 1, 2, 3, 6][visibleIndex];
  }

  /// Maps from the actual shell branch index to the visible tab index.
  int _mapToVisibleIndex(int branchIndex, String mode) {
    final isRoomPoster = mode.trim().toLowerCase() == 'room_poster';

    if (isRoomPoster) {
      final mapping = {0: 0, 4: 1, 2: 2, 3: 3, 6: 4};
      return mapping[branchIndex] ?? 0;
    }
    final mapping = {0: 0, 1: 1, 2: 2, 3: 3, 6: 4};
    return mapping[branchIndex] ?? 0;
  }
}
````

## File: lib/core/config/env_loader.dart
````dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final class EnvLoader {
  const EnvLoader._();

  /// Loads environment variables from a `.env` file.
  ///
  /// Uses flutter_dotenv's asset-bundle loading with `isOptional: true` so
  /// that `dotenv.env` is always safe to read (empty on failure). Callers
  /// should fall back to `--dart-define` values or `String.fromEnvironment`.
  static Future<bool> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName, isOptional: true);
      if (dotenv.env.isNotEmpty) return true;
    } catch (_) {}

    debugPrint(
      '[EnvLoader] $fileName not found in asset bundle – falling back '
      'to --dart-define / environment variables.',
    );
    return false;
  }
}
````

## File: lib/core/notifications/notification_service.dart
````dart
import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../providers.dart';

class NotificationService {
  NotificationService(this._ref);

  static bool messagingEnabled = false;

  final Ref _ref;
  bool _initialized = false;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'flatmates_messages',
          'Messages & Matches',
          description: 'Notifications for new messages, matches, and visits',
          importance: Importance.high,
        ),
      );
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route == null || route.isEmpty) return;
    _pendingRoute = route;
  }

  static String? _pendingRoute;

  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!messagingEnabled) return;
    _initialized = true;

    try {
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _onMessageSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageTap,
      );

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        _sendTokenToServer,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      _initialized = false;
      debugPrint('NotificationService.initialize() failed: $e');
    }
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedAppSub = null;
    _onTokenRefreshSub = null;
    _initialized = false;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    String? title;
    String? body;

    if (notification != null) {
      title = notification.title;
      body = notification.body;
    } else if (message.data.isNotEmpty) {
      // Data-only message: extract title/body from data payload.
      title = message.data['title'] ?? '360 FlatMates';
      body = message.data['body'] ?? message.data['message'];
    }

    if (title == null && body == null) return;

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flatmates_messages',
          'Messages & Matches',
          channelDescription:
              'Notifications for new messages, matches, and visits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && route.isNotEmpty) {
      _pendingRoute = route;
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _ref
          .read(apiClientProvider)
          .post(
            '/notifications/devices/register',
            data: {
              'token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
            },
          );
    } catch (_) {
      // Token sync is best-effort; do not block UX.
    }
  }

  Future<void> clearToken() async {
    if (!messagingEnabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _ref
          .read(apiClientProvider)
          .delete(
            '/notifications/devices/unregister',
            queryParameters: {'token': token},
          );
    } catch (_) {
      // Best-effort
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref),
);
````

## File: lib/features/auth/presentation/enter_phone_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../../../core/providers.dart';
import '../../../l10n/gen/app_localizations.dart';

class EnterPhonePage extends ConsumerStatefulWidget {
  const EnterPhonePage({super.key});

  @override
  ConsumerState<EnterPhonePage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends ConsumerState<EnterPhonePage> {
  final _controller = TextEditingController(text: '+91');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.enterPhoneTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(locale.enterPhoneSubtitle),
            const SizedBox(height: 24),
            TextField(
              key: const Key('enter_phone_input'),
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: locale.phoneNumberLabel),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              key: const Key('enter_phone_otp_cta'),
              onPressed: () async {
                final phone = _controller.text.trim();
                await ref
                    .read(authControllerProvider.notifier)
                    .requestOtp(phone);
                if (!context.mounted) return;
                context.push('/otp?phone=${Uri.encodeComponent(phone)}');
              },
              child: Text(locale.continueWithOtp),
            ),
            if (config.enableDebugLogs) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('enter_phone_password_cta'),
                onPressed: () {
                  context.push(
                    '/login?phone=${Uri.encodeComponent(_controller.text.trim())}',
                  );
                },
                child: Text(locale.loginWithPassword),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.push(
                    '/signup?phone=${Uri.encodeComponent(_controller.text.trim())}',
                  );
                },
                child: Text(locale.createAccountCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/auth/presentation/otp_page.dart
````dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../l10n/gen/app_localizations.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> with CodeAutoFill {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  String _currentOtp = '';
  bool _isListening = false;

  // Resend countdown
  static const _resendCooldownSeconds = 60;
  int _countdownSeconds = _resendCooldownSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startListeningForSms();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SmsAutoFill().unregisterListener();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _fillOtp(code!);
    }
  }

  Future<void> _startListeningForSms() async {
    try {
      SmsAutoFill().listenForCode;
      if (mounted) {
        setState(() => _isListening = true);
      }
    } catch (_) {
      // SMS auto-fill not available on this platform (e.g. iOS simulator).
      // The user will enter the OTP manually.
    }
  }

  void _startCountdown() {
    _countdownSeconds = _resendCooldownSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _fillOtp(String otp) {
    _currentOtp = otp;
    for (var i = 0; i < 6; i++) {
      if (i < otp.length) {
        _otpControllers[i].text = otp[i];
      } else {
        _otpControllers[i].clear();
      }
    }
    // Move focus to the last filled field or unfocus if complete.
    if (otp.length == 6) {
      _focusNodes[5].unfocus();
      _submitOtp();
    } else if (otp.length < 6) {
      _focusNodes[otp.length].requestFocus();
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    // If a digit was entered and it's more than one char, take only the last.
    if (value.length > 1) {
      final lastChar = value.substring(value.length - 1);
      _otpControllers[index].text = lastChar;
      value = lastChar;
    }

    // Build the full OTP string.
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(_otpControllers[i].text);
    }
    _currentOtp = buffer.toString();

    // Auto-advance focus.
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are filled.
    if (_currentOtp.length == 6) {
      _focusNodes[5].unfocus();
      _submitOtp();
    }
  }

  void _onOtpDigitDeleted(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
    // Rebuild current otp.
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(_otpControllers[i].text);
    }
    _currentOtp = buffer.toString();
  }

  void _submitOtp() {
    if (_currentOtp.length != 6) return;
    ref
        .read(authControllerProvider.notifier)
        .verifyOtp(phone: widget.phone, otp: _currentOtp);
  }

  void _resendOtp() {
    if (_countdownSeconds > 0) return;
    ref.read(authControllerProvider.notifier).requestOtp(widget.phone);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.otpTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(locale.otpSubtitle(widget.phone)),
            if (_isListening) ...[
              const SizedBox(height: 8),
              Text(
                locale.otpAutoReadHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // 6-digit OTP input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      // Handle backspace to move focus backward.
                      if (event.logicalKey.keyLabel == 'Backspace' ||
                          event.logicalKey.keyLabel == 'Delete') {
                        _onOtpDigitDeleted(index);
                      }
                    },
                    child: TextField(
                      key: Key('otp_digit_$index'),
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onOtpDigitChanged(index, value),
                    ),
                  ),
                );
              }),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const Spacer(),
            // Resend OTP button with countdown.
            Center(
              child: _countdownSeconds > 0
                  ? Text(
                      locale.resendOtpCountdown(_countdownSeconds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : TextButton(
                      onPressed: auth.status == AuthStatus.submitting
                          ? null
                          : _resendOtp,
                      child: Text(locale.resendOtpCta),
                    ),
            ),
            const SizedBox(height: 16),
            // Verify button.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('otp_submit_button'),
                onPressed: auth.status == AuthStatus.submitting
                    ? null
                    : _submitOtp,
                child: auth.status == AuthStatus.submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(locale.verifyOtpCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/bootstrap/bootstrap_controller.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class CatalogEntryModel {
  const CatalogEntryModel({
    required this.key,
    required this.version,
    required this.payload,
  });

  final String key;
  final int version;
  final Map<String, dynamic> payload;

  factory CatalogEntryModel.fromJson(Map<String, dynamic> json) {
    return CatalogEntryModel(
      key: json['key'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    );
  }
}

class FlatmatesProfileModel {
  const FlatmatesProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.profileImageUrl,
    required this.mode,
    required this.profileStatus,
    required this.onboardingCompleted,
    required this.bio,
    required this.age,
    required this.profession,
    required this.budgetMin,
    required this.budgetMax,
    required this.moveInTimeline,
    required this.city,
    required this.state,
    required this.locality,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.foodHabits,
    required this.smokingDrinking,
    required this.guestsPolicy,
    required this.workStyle,
    required this.gender,
    required this.genderPreference,
    required this.preferences,
  });

  final int id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? profileImageUrl;
  final String? mode;
  final String profileStatus;
  final bool onboardingCompleted;
  final String? bio;
  final int? age;
  final String? profession;
  final double? budgetMin;
  final double? budgetMax;
  final String? moveInTimeline;
  final String? city;
  final String? state;
  final String? locality;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final String? workStyle;
  final String? gender;
  final String? genderPreference;
  final Map<String, dynamic> preferences;

  factory FlatmatesProfileModel.fromJson(Map<String, dynamic> json) {
    final preferences = Map<String, dynamic>.from(
      json['preferences'] as Map? ?? const {},
    );
    return FlatmatesProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      profileStatus: json['profile_status'] as String? ?? 'draft',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      bio: json['bio'] as String?,
      age: (json['age'] as num?)?.toInt(),
      profession:
          json['profession'] as String? ?? preferences['profession'] as String?,
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      moveInTimeline: json['move_in_timeline'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      sleepSchedule: json['sleep_schedule'] as String?,
      cleanliness: json['cleanliness'] as String?,
      foodHabits: json['food_habits'] as String?,
      smokingDrinking: json['smoking_drinking'] as String?,
      guestsPolicy: json['guests_policy'] as String?,
      workStyle: json['work_style'] as String?,
      gender: json['gender'] as String?,
      genderPreference: json['gender_preference'] as String?,
      preferences: preferences,
    );
  }
}

class BootstrapData {
  const BootstrapData({
    required this.profile,
    required this.catalogs,
    required this.activeListingCount,
    required this.conversationCount,
    required this.unreadMessageCount,
  });

  final FlatmatesProfileModel profile;
  final List<CatalogEntryModel> catalogs;
  final int activeListingCount;
  final int conversationCount;
  final int unreadMessageCount;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      profile: FlatmatesProfileModel.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      catalogs: ((json['catalogs'] as List?) ?? const [])
          .map(
            (item) => CatalogEntryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      activeListingCount: (json['active_listing_count'] as num?)?.toInt() ?? 0,
      conversationCount: (json['conversation_count'] as num?)?.toInt() ?? 0,
      unreadMessageCount: (json['unread_message_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class BootstrapController extends StateNotifier<AsyncValue<BootstrapData?>> {
  BootstrapController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _ref
          .watch(apiClientProvider)
          .get('/flatmates/bootstrap');
      return BootstrapData.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final bootstrapControllerProvider =
    StateNotifierProvider<BootstrapController, AsyncValue<BootstrapData?>>(
      (ref) => BootstrapController(ref),
    );
````

## File: lib/features/chats/chat_thread_page.dart
````dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/storage/image_upload_service.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'chats_repository.dart';
import 'match_qna_nudge.dart';

class ChatThreadPage extends ConsumerStatefulWidget {
  const ChatThreadPage({
    required this.conversationId,
    required this.conversation,
    super.key,
  });

  final int conversationId;
  final ConversationSummaryModel? conversation;

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final _messageController = TextEditingController();
  bool _hasSentFirstMessage = false;
  bool _showQnANudge = false;
  ConversationSummaryModel? _conversation;
  late final Timer _pollTimer;
  final _sendDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 300),
  );

  static const _fallbackIcebreakers = [
    'Tell me about the room 🏠',
    'What are your flatmates like? 👥',
    'Are you open to negotiating rent? 💰',
    "What's the vibe of the society? 🏘️",
    'What does a typical weekend look like? 🌞',
  ];

  /// Hardcoded fallback report reasons.
  static const _fallbackReportReasons = [
    _ReportReason(value: 'fake_profile'),
    _ReportReason(value: 'spam'),
    _ReportReason(value: 'inappropriate'),
    _ReportReason(value: 'uncomfortable'),
    _ReportReason(value: 'other'),
  ];

  /// Resolve icebreakers: try backend catalog first, fall back to hardcoded.
  List<String> get _icebreakers {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions('flatmates_icebreakers');
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions.map((opt) => opt.label).toList();
    }
    return _fallbackIcebreakers;
  }

  /// Resolve report reasons: try backend catalog first, fall back to hardcoded.
  List<_ReportReason> get _reportReasons {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_report_reasons',
    );
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions
          .map((opt) => _ReportReason(value: opt.id, catalogLabel: opt.label))
          .toList();
    }
    return _fallbackReportReasons;
  }

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _checkExistingMessages();
    _markMessagesAsRead();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/flatmates/conversations/${widget.conversationId}/mark-read');
    } catch (_) {}
  }

  void _checkExistingMessages() {
    final messages = ref
        .read(messagesProvider(widget.conversationId))
        .valueOrNull;
    _hasSentFirstMessage = messages != null && messages.isNotEmpty;
    // Show Q&A nudge for new matches with no messages yet,
    // unless the user already dismissed/completed it for this conversation.
    final source = _conversation?.source;
    final isNewMatch = source == 'match' || source == 'profile_match';
    final prefs = ref.read(appPreferencesProvider);
    final alreadyDismissed = prefs.getBool(
      'qna_nudge_dismissed_${widget.conversationId}',
    );
    _showQnANudge = isNewMatch && !_hasSentFirstMessage && !alreadyDismissed;
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    _messageController.dispose();
    _sendDebouncer.dispose();
    super.dispose();
  }

  Future<void> _scheduleVisit(BuildContext context) async {
    final conversation = _conversation;
    if (conversation?.contextProperty == null) return;
    await context.push(
      '/schedule-visit?conversationId=${widget.conversationId}',
      extra: conversation,
    );
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;

    try {
      await ref
          .read(chatsRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, body: body);
      _messageController.clear();
      setState(() => _hasSentFirstMessage = true);
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to send message. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendPhoto() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 1);
    if (files.isEmpty) return;

    try {
      final url = await service.uploadChatPhoto(files.first);
      if (url == null) return;

      await ref
          .read(chatsRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            body: null,
            attachmentUrl: url,
            messageType: 'image',
          );
      setState(() => _hasSentFirstMessage = true);
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to send photo. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _blockUser() async {
    final locale = AppLocalizations.of(context);
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.blockConfirmTitle),
        content: Text(locale.blockConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(locale.blockCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .post('/flatmates/blocks', data: {'blocked_user_id': peerId});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.userBlocked)));
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to block user. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _reportUser() async {
    final locale = AppLocalizations.of(context);
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;

    String? selectedReason;
    final reasons = _reportReasons;
    final reasonLabels = reasons.map((r) => r.resolvedLabel(locale)).toList();

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(locale.reportTitle),
          content: RadioGroup<String>(
            groupValue: selectedReason,
            onChanged: (v) => setDialogState(() => selectedReason = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(reasons.length, (idx) {
                return ListTile(
                  title: Text(reasonLabels[idx]),
                  leading: Radio<String>(value: reasons[idx].value),
                  onTap: () =>
                      setDialogState(() => selectedReason = reasons[idx].value),
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.cancelCta),
            ),
            FilledButton(
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, selectedReason)
                  : null,
              child: Text(locale.reportCta),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/flatmates/reports',
            data: {
              'reported_user_id': peerId,
              'reason': confirmed,
              'conversation_id': widget.conversationId,
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.reportSubmitted)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to report user. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _unmatch() async {
    final locale = AppLocalizations.of(context);
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.unmatchConfirmTitle),
        content: Text(locale.unmatchConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(locale.unmatchCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/flatmates/blocks',
            data: {'blocked_user_id': peerId, 'unmatch_only': true},
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to unmatch. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitQnA(Map<String, String> answers) async {
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/flatmates/conversations/${widget.conversationId}/qna',
            data: answers,
          );
    } catch (_) {
      // Best-effort; don't block the user if Q&A save fails
    }
    _markQnANudgeDismissed();
    if (mounted) {
      setState(() => _showQnANudge = false);
    }
  }

  void _markQnANudgeDismissed() {
    ref
        .read(appPreferencesProvider)
        .setBool('qna_nudge_dismissed_${widget.conversationId}', true);
  }

  void _showQnABottomSheet() {
    final peerName = _conversation?.peer.fullName ?? 'Flatmate';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MatchQnANudge(
        peerName: peerName,
        onComplete: (answers) {
          _submitQnA(answers);
        },
      ),
    ).whenComplete(() {
      // Mark dismissed whether the user completed the Q&A or skipped it
      _markQnANudgeDismissed();
      if (mounted) {
        setState(() => _showQnANudge = false);
      }
    });
  }

  void _showChatMenu() {
    final locale = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(locale.reportCta),
              onTap: () {
                Navigator.pop(ctx);
                _reportUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_off_outlined),
              title: Text(locale.unmatchCta),
              onTap: () {
                Navigator.pop(ctx);
                _unmatch();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.block_outlined,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                locale.blockCta,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _blockUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final fetchedConversation = _conversation == null
        ? ref.watch(conversationProvider(widget.conversationId))
        : null;
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conversation = _conversation ?? fetchedConversation?.valueOrNull;
    final currentUserId =
        ref.watch(bootstrapControllerProvider).valueOrNull?.profile.id ?? -1;

    if (_conversation == null && fetchedConversation != null) {
      if (fetchedConversation.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (fetchedConversation.hasError) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fetchedConversation.error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    conversationProvider(widget.conversationId),
                  ),
                  child: Text(locale.commonRetry),
                ),
              ],
            ),
          ),
        );
      }
      if (conversation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _conversation != null) return;
          setState(() {
            _conversation = conversation;
            _checkExistingMessages();
          });
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            FlatmatesAvatar(
              name: conversation?.peer.fullName,
              imageUrl: conversation?.peer.profileImageUrl,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation?.peer.fullName ?? locale.chatsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: compatibilityScoreColor(100),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  if (conversation?.peer.mode != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        localizedFlatmatesModeLabel(
                          locale,
                          conversation!.peer.mode!,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('chat_call_button'),
            onPressed: () async {
              final phone = conversation?.peer.phoneNumber;
              if (phone != null && phone.isNotEmpty) {
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(locale.phoneNotAvailable)),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(locale.phoneNotAvailable)),
                );
              }
            },
            icon: Icon(
              Icons.call_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          if (conversation?.contextProperty != null)
            IconButton(
              key: const Key('chat_schedule_visit_button'),
              onPressed: () => _scheduleVisit(context),
              icon: Icon(
                Icons.event_available_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          IconButton(
            key: const Key('chat_video_button'),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(locale.comingSoon)));
            },
            icon: Icon(
              Icons.videocam_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          IconButton(
            key: const Key('chat_more_button'),
            onPressed: _showChatMenu,
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (conversation?.contextProperty != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (conversation!.contextProperty!.mainImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            conversation.contextProperty!.mainImageUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _PropertyContextFallback(
                              title: conversation.contextProperty!.title,
                            ),
                          ),
                        )
                      else
                        _PropertyContextFallback(
                          title: conversation.contextProperty!.title,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.contextProperty!.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (conversation.contextProperty!.monthlyRent !=
                                null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '₹${conversation.contextProperty!.monthlyRent!.toStringAsFixed(0)} / month',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                            if (conversation.contextProperty!.ownerName !=
                                null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (conversation
                                          .contextProperty!
                                          .ownerImageUrl !=
                                      null)
                                    FlatmatesAvatar(
                                      name: conversation
                                          .contextProperty!
                                          .ownerName,
                                      imageUrl: conversation
                                          .contextProperty!
                                          .ownerImageUrl,
                                      size: 20,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        size: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    conversation.contextProperty!.ownerName!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                            if (conversation.matchedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'MMM d, y',
                                  locale.localeName,
                                ).format(conversation.matchedAt!.toLocal()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push(
                                  '/flat-details/${conversation.contextProperty!.id}',
                                );
                              },
                              icon: Icon(Icons.open_in_new, size: 16),
                              label: Text(locale.viewListing),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_hasSentFirstMessage)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showQnANudge) ...[
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _showQnABottomSheet,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.qnaNudgeTitle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      locale.qnaNudgeSubtitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    locale.icebreakerTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icebreakers.map((prompt) {
                      return ActionChip(
                        label: Text(prompt),
                        onPressed: () {
                          _messageController.text = prompt;
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(locale.chatReady));
                }
                _hasSentFirstMessage = items.any(
                  (m) => m.senderId == currentUserId,
                );
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                locale.todayLabel,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final item = items[index - 1];
                    final isMine = item.senderId == currentUserId;
                    return _MessageBubble(
                      message: item,
                      isMine: isMine,
                      peerName: conversation?.peer.fullName,
                      peerImageUrl: conversation?.peer.profileImageUrl,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                IconButton(
                  key: const Key('chat_emoji_button'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale.emojiPickerComingSoon),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: TextField(
                      key: const Key('chat_message_input'),
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: locale.chatInputHint,
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('chat_attachment_button'),
                  onPressed: _sendPhoto,
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _sendDebouncer.run(_sendMessage),
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.peerImageUrl,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerName;
  final String? peerImageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final time = DateFormat(
      'h:mm a',
      locale.localeName,
    ).format(message.createdAt.toLocal());

    if (message.messageType == 'visit_request') {
      return _VisitRequestCard(
        message: message,
        isMine: isMine,
        peerName: peerName,
        peerImageUrl: peerImageUrl,
        time: time,
      );
    }

    if (message.messageType == 'image' && message.attachmentUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMine) ...[
              FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
              const SizedBox(width: 10),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  message.attachmentUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 200,
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 40,
                      ),
                    ),
                  ),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 150,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 32),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isMine ? theme.colorScheme.primary : kPeerBubbleBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Text(
                      message.body ??
                          AppLocalizations.of(context).messageAttachment,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isMine
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine)
                      const SizedBox(width: 40) // align with avatar width
                    else
                      const SizedBox.shrink(),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Icon(
                        message.readAt != null
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: message.readAt != null
                            ? Theme.of(context).colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRequestCard extends StatelessWidget {
  const _VisitRequestCard({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.peerImageUrl,
    required this.time,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerName;
  final String? peerImageUrl;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locale.scheduleVisitCta,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.body ?? locale.visitRequested,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                locale.visitStatusRequested,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyContextFallback extends StatelessWidget {
  const _PropertyContextFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.88),
            theme.colorScheme.primary.withValues(alpha: 0.34),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(title),
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _ReportReason {
  const _ReportReason({required this.value, this.catalogLabel});

  final String value;
  final String? catalogLabel;

  /// Resolve display label: use catalog label if available, otherwise localize.
  String resolvedLabel(AppLocalizations locale) {
    if (catalogLabel != null && catalogLabel!.isNotEmpty) {
      return catalogLabel!;
    }
    return switch (value) {
      'fake_profile' => locale.reportFakeProfile,
      'spam' => locale.reportSpam,
      'inappropriate' => locale.reportInappropriate,
      'uncomfortable' => locale.reportUncomfortable,
      _ => locale.reportOther,
    };
  }
}
````

## File: lib/features/chats/chats_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ChatPeer {
  const ChatPeer({
    required this.id,
    required this.fullName,
    required this.profileImageUrl,
    required this.mode,
    required this.city,
    required this.locality,
    required this.age,
    required this.profession,
    required this.matchPercentage,
    this.phoneNumber,
  });

  final int id;
  final String fullName;
  final String? profileImageUrl;
  final String? mode;
  final String? city;
  final String? locality;
  final int? age;
  final String? profession;
  final double? matchPercentage;
  final String? phoneNumber;

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    return ChatPeer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? 'Flatmate',
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      age: (json['age'] as num?)?.toInt(),
      profession: json['profession'] as String?,
      matchPercentage: (json['match_percentage'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
    );
  }
}

class ChatPropertyContext {
  const ChatPropertyContext({
    required this.id,
    required this.title,
    required this.locality,
    required this.city,
    required this.monthlyRent,
    required this.mainImageUrl,
    this.ownerName,
    this.ownerImageUrl,
  });

  final int id;
  final String title;
  final String? locality;
  final String? city;
  final double? monthlyRent;
  final String? mainImageUrl;
  final String? ownerName;
  final String? ownerImageUrl;

  factory ChatPropertyContext.fromJson(Map<String, dynamic> json) {
    return ChatPropertyContext(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Listing',
      locality: json['locality'] as String?,
      city: json['city'] as String?,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      mainImageUrl: json['main_image_url'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerImageUrl: json['owner_image_url'] as String?,
    );
  }
}

class ConversationSummaryModel {
  const ConversationSummaryModel({
    required this.id,
    required this.source,
    required this.status,
    required this.peer,
    required this.contextProperty,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
    this.matchedAt,
  });

  final int id;
  final String source;
  final String status;
  final ChatPeer peer;
  final ChatPropertyContext? contextProperty;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime? matchedAt;

  factory ConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'listing_interest',
      status: json['status'] as String? ?? 'active',
      peer: ChatPeer.fromJson(
        Map<String, dynamic>.from(json['peer'] as Map? ?? const {}),
      ),
      contextProperty: json['context_property'] == null
          ? null
          : ChatPropertyContext.fromJson(
              Map<String, dynamic>.from(json['context_property'] as Map),
            ),
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: DateTime.tryParse(
        json['last_message_at']?.toString() ?? '',
      ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      matchedAt: DateTime.tryParse(json['matched_at']?.toString() ?? ''),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.messageType,
    required this.createdAt,
    this.readAt,
    this.attachmentUrl,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String? body;
  final String messageType;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? attachmentUrl;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      body: json['body'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      attachmentUrl: json['attachment_url'] as String?,
    );
  }
}

class ChatsRepository {
  const ChatsRepository(this._ref);

  final Ref _ref;

  Future<List<ConversationSummaryModel>> fetchConversations() async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/conversations');
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) => ConversationSummaryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<ConversationSummaryModel> fetchConversation(int conversationId) async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/conversations/$conversationId');
    return ConversationSummaryModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/conversations/$conversationId/messages');
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> sendMessage({
    required int conversationId,
    String? body,
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    await _ref
        .watch(apiClientProvider)
        .post(
          '/flatmates/conversations/$conversationId/messages',
          data: {
            // ignore: use_null_aware_elements
            if (body != null) 'body': body,
            // ignore: use_null_aware_elements
            if (attachmentUrl != null) 'attachment_url': attachmentUrl,
            'message_type': messageType,
          },
        );
  }
}

final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => ChatsRepository(ref),
);

final conversationsProvider = FutureProvider<List<ConversationSummaryModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchConversations(),
);

final conversationProvider =
    FutureProvider.family<ConversationSummaryModel, int>(
      (ref, conversationId) =>
          ref.watch(chatsRepositoryProvider).fetchConversation(conversationId),
    );

final messagesProvider = FutureProvider.family<List<ChatMessage>, int>(
  (ref, conversationId) =>
      ref.watch(chatsRepositoryProvider).fetchMessages(conversationId),
);
````

## File: lib/features/chats/conversations_page.dart
````dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'chats_repository.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  bool _showLikes = true;

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: conversations.when(
          data: (items) {
            final likes = items
                .where(
                  (item) =>
                      (item.lastMessagePreview == null ||
                      item.lastMessagePreview!.isEmpty),
                )
                .toList();
            final chats = items
                .where(
                  (item) =>
                      item.lastMessagePreview != null &&
                      item.lastMessagePreview!.isNotEmpty,
                )
                .toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  // Header row: logo + title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const FlatmatesLogo(compact: true),
                      const Spacer(),
                      Text(
                        locale.likesChatTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      // Balance the header with an invisible spacer
                      const SizedBox(width: 80),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Toggle tabs — solid primary when selected, outline otherwise
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            key: const Key('likes_tab_button'),
                            label: locale.likesTabLabel,
                            selected: _showLikes,
                            onTap: () => setState(() => _showLikes = true),
                          ),
                        ),
                        Expanded(
                          child: _SegmentButton(
                            key: const Key('chats_tab_button'),
                            label: locale.chatsTabLabel,
                            selected: !_showLikes,
                            onTap: () => setState(() => _showLikes = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LIKES TAB — 2-column GridView of profile cards
                  if (_showLikes) ...[
                    if (likes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Center(child: Text(locale.emptyLikes)),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: likes.length,
                        itemBuilder: (context, index) {
                          final item = likes[index];
                          final location = [
                            if (item.peer.locality != null &&
                                item.peer.locality!.trim().isNotEmpty)
                              item.peer.locality!.trim(),
                            if (item.peer.city != null &&
                                item.peer.city!.trim().isNotEmpty)
                              item.peer.city!.trim(),
                          ].join(', ');
                          return FlatmatesProfileGridCard(
                            name: item.peer.fullName,
                            age: item.peer.age,
                            location: location,
                            profession:
                                item.peer.profession ??
                                (item.peer.mode == null
                                    ? ''
                                    : localizedFlatmatesModeLabel(
                                        locale,
                                        item.peer.mode!,
                                      )),
                            matchPercentage: item.peer.matchPercentage,
                            imageUrl: item.peer.profileImageUrl,
                            onMatchTap: () =>
                                context.push('/chats/${item.id}', extra: item),
                          );
                        },
                      ),

                    // Safety banner for likes tab
                    const SizedBox(height: 12),
                    _buildSafetyBanner(context, theme, locale),
                  ],

                  // CHATS TAB — existing conversation list
                  if (!_showLikes) ...[
                    if (chats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Center(child: Text(locale.emptyChats)),
                      )
                    else
                      ...chats.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ConversationCard(
                            item: item,
                            highlightMode: false,
                            onTap: () =>
                                context.push('/chats/${item.id}', extra: item),
                          ),
                        ),
                      ),
                    // Safety banner for chats tab
                    const SizedBox(height: 12),
                    _buildSafetyBanner(context, theme, locale),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(conversationsProvider),
                  child: Text(locale.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyBanner(
    BuildContext context,
    ThemeData theme,
    AppLocalizations locale,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () => context.push('/help-safety'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.safetyFirstTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locale.safetyFirstSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.item,
    required this.highlightMode,
    required this.onTap,
  });

  final ConversationSummaryModel item;
  final bool highlightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final location = [
      if (item.peer.locality != null && item.peer.locality!.trim().isNotEmpty)
        item.peer.locality!.trim(),
      if (item.peer.city != null && item.peer.city!.trim().isNotEmpty)
        item.peer.city!.trim(),
    ].join(', ');
    final timestamp = item.lastMessageAt == null
        ? locale.chatReady
        : DateFormat(
            'd MMM, h:mm a',
            locale.localeName,
          ).format(item.lastMessageAt!.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  highlightMode && item.peer.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(58 / 2),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: FlatmatesAvatar(
                              name: item.peer.fullName,
                              imageUrl: item.peer.profileImageUrl,
                              size: 58,
                            ),
                          ),
                        )
                      : FlatmatesAvatar(
                          name: item.peer.fullName,
                          imageUrl: item.peer.profileImageUrl,
                          size: 58,
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.peer.fullName,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            if (item.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${item.unreadCount}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (item.peer.mode != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            localizedFlatmatesModeLabel(
                              locale,
                              item.peer.mode!,
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (item.contextProperty != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      if (item.contextProperty!.mainImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.contextProperty!.mainImageUrl!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _PropertyPreviewFallback(
                              title: item.contextProperty!.title,
                            ),
                          ),
                        )
                      else
                        _PropertyPreviewFallback(
                          title: item.contextProperty!.title,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.contextProperty!.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (item.contextProperty!.monthlyRent != null)
                              Text(
                                locale.monthlyRentLabel(
                                  item.contextProperty!.monthlyRent!
                                      .toStringAsFixed(0),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.lastMessagePreview ?? locale.likesIncomingLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(timestamp, style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 14),
              highlightMode
                  ? GradientActionButton(
                      label: locale.openConversationCta,
                      onPressed: onTap,
                      icon: Icons.chat_bubble_outline_rounded,
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onTap,
                        child: Text(locale.openConversationCta),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyPreviewFallback extends StatelessWidget {
  const _PropertyPreviewFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(title),
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
````

## File: lib/features/discover/discover_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/compatibility/compatibility_ring.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'discover_repository.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchController = TextEditingController();
  int? _selectedBedrooms;
  String? _selectedFeature;
  String? _selectedVibe;
  final _likeDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _likeDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = bootstrap?.profile;
    final listings = ref.watch(discoverListingsProvider(profile));
    final currentLocation = [
      if (profile?.locality != null && profile!.locality!.trim().isNotEmpty)
        profile.locality!.trim(),
      if (profile?.city != null && profile!.city!.trim().isNotEmpty)
        profile.city!.trim(),
    ].join(', ');

    return Scaffold(
      body: SafeArea(
        child: listings.when(
          data: (items) {
            final visibleItems = items
                .where((item) => item.ownerId != profile?.id)
                .toList();
            final bedroomOptions =
                visibleItems
                    .map((item) => item.bedrooms)
                    .whereType<int>()
                    .toSet()
                    .toList()
                  ..sort();
            final featureOptions =
                visibleItems
                    .expand((item) => item.features)
                    .map(
                      (feature) =>
                          localizedFlatmatesFeatureLabel(locale, feature),
                    )
                    .where((feature) => feature.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            final query = _searchController.text.trim().toLowerCase();
            final filtered = visibleItems.where((item) {
              final matchesBedrooms =
                  _selectedBedrooms == null ||
                  item.bedrooms == _selectedBedrooms;
              final matchesFeature =
                  _selectedFeature == null ||
                  item.features
                      .map(
                        (feature) =>
                            localizedFlatmatesFeatureLabel(locale, feature),
                      )
                      .contains(_selectedFeature);
              final searchable = [
                item.title,
                item.locality,
                item.subLocality,
                item.city,
                item.description,
                item.ownerName,
                ...item.tags,
                ...item.features,
              ].whereType<String>().join(' ').toLowerCase();
              final matchesQuery = query.isEmpty || searchable.contains(query);
              return matchesBedrooms && matchesFeature && matchesQuery;
            }).toList();

            if (visibleItems.isEmpty) {
              return Center(child: Text(locale.emptyListings));
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(discoverListingsProvider(profile)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.homeGreeting(
                                profile?.fullName ?? locale.profileFallbackName,
                              ),
                              style: theme.textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    currentLocation.isEmpty
                                        ? locale.homeLocationFallback
                                        : currentLocation,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const Key('discover_notifications_button'),
                            onPressed: () => context.push('/notifications'),
                            icon: const Icon(Icons.notifications_outlined),
                            tooltip: 'Notifications',
                          ),
                          FlatmatesAvatar(
                            name: profile?.fullName,
                            imageUrl: profile?.profileImageUrl,
                            size: 52,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: locale.homeSearchHint,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () => context.push('/search-filters'),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Vibe preset filter chips
                        ...[
                          (
                            key: 'quiet',
                            icon: Icons.bedtime_outlined,
                            label: locale.vibeQuiet,
                          ),
                          (
                            key: 'social',
                            icon: Icons.celebration_outlined,
                            label: locale.vibeSocial,
                          ),
                          (
                            key: 'professional',
                            icon: Icons.work_outlined,
                            label: locale.vibeProfessional,
                          ),
                          (
                            key: 'student',
                            icon: Icons.school_outlined,
                            label: locale.vibeStudent,
                          ),
                          (
                            key: 'pet',
                            icon: Icons.pets_outlined,
                            label: locale.vibePet,
                          ),
                        ].map((vibe) {
                          final selected = _selectedVibe == vibe.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(vibe.label),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedVibe = selected ? null : vibe.key;
                                });
                              },
                              avatar: Icon(vibe.icon, size: 18),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            label: Text(locale.nearbyChipLabel),
                            selected: false,
                            onSelected: (_) {},
                            avatar: const Icon(
                              Icons.near_me_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            label: Text(locale.budgetPlusChipLabel),
                            selected: false,
                            onSelected: (_) {},
                            avatar: const Icon(Icons.add_outlined, size: 18),
                          ),
                        ),
                        if (currentLocation.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(currentLocation),
                              selected: false,
                              onSelected: (_) {},
                              avatar: const Icon(
                                Icons.near_me_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ...bedroomOptions.map((value) {
                          final selected = _selectedBedrooms == value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(locale.homeBedroomsChip(value)),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedBedrooms = selected ? null : value;
                                });
                              },
                            ),
                          );
                        }),
                        ...featureOptions.take(4).map((feature) {
                          final selected = _selectedFeature == feature;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(feature),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedFeature = selected ? null : feature;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (visibleItems.length < 5 && profile?.city != null)
                    _WaitlistNudgeCard(
                      city: profile!.city!,
                      listingCount: visibleItems.length,
                    ),
                  if (visibleItems.length < 5 && profile?.city != null)
                    const SizedBox(height: 20),
                  FlatmatesSectionHeader(
                    title: locale.homePickedForYou,
                    subtitle: locale.homePickedSubtitle,
                    actionLabel: filtered.length > 2 ? locale.seeAllCta : null,
                    onActionTap: () => context.push('/search-filters'),
                  ),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(locale.homeNoResults),
                      ),
                    )
                  else
                    SizedBox(
                      height: 370,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final badgeLabel = switch (index) {
                            0 => locale.badgeNew,
                            1 => locale.badgePopular,
                            _ =>
                              item.interestCount > 1
                                  ? locale.badgeTrending
                                  : null,
                          };
                          return SizedBox(
                            width: 300,
                            child: _DiscoverCard(
                              item: item,
                              badgeLabel: badgeLabel,
                              onLike: () {
                                _likeDebouncer.run(() {
                                  ref
                                      .read(discoverRepositoryProvider)
                                      .likeListing(item.id)
                                      .then((conversationId) {
                                        ref.invalidate(
                                          discoverListingsProvider(profile),
                                        );
                                        ref.invalidate(conversationsProvider);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              conversationId == null
                                                  ? locale.contactRequestSent
                                                  : locale
                                                        .contactRequestWithConversation(
                                                          conversationId,
                                                        ),
                                            ),
                                          ),
                                        );
                                      });
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  if (profile?.city != null) ...[
                    const SizedBox(height: 28),
                    FlatmatesSectionHeader(
                      title: locale.homeNewInCity(profile!.city!),
                    ),
                    const SizedBox(height: 18),
                    _NewInCitySection(
                      items: filtered,
                      onExplore: () => context.go('/map'),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(discoverListingsProvider(profile)),
                  child: Text(locale.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.item,
    required this.onLike,
    this.badgeLabel,
  });

  final PropertyListing item;
  final VoidCallback onLike;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ProviderScope.containerOf(
      context,
    ).read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;

    CompatibilityResult? compatibility;
    final prefs = item.preferences;
    if (userProfile != null &&
        prefs != null &&
        prefs.containsKey('sleep_schedule')) {
      compatibility = CompatibilityEngine.calculate(
        user: {
          'sleep_schedule': userProfile.sleepSchedule ?? 'flexible',
          'cleanliness': userProfile.cleanliness ?? 'tidy',
          'food_habits': userProfile.foodHabits ?? 'no_preference',
          'smoking_drinking': userProfile.smokingDrinking ?? 'neither',
          'guests_policy': userProfile.guestsPolicy ?? 'occasional_ok',
          'work_style': userProfile.workStyle ?? 'hybrid',
        },
        peer: {
          'sleep_schedule': prefs['sleep_schedule'] ?? 'flexible',
          'cleanliness': prefs['cleanliness'] ?? 'tidy',
          'food_habits': prefs['food_habits'] ?? 'no_preference',
          'smoking_drinking': prefs['smoking_drinking'] ?? 'neither',
          'guests_policy': prefs['guests_policy'] ?? 'occasional_ok',
          'work_style': prefs['work_style'] ?? 'hybrid',
        },
      );
    }

    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImage(imageUrl: item.mainImageUrl, title: item.title),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compatibility != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            CompatibilityRing(
                              percentage: compatibility.percentage,
                              size: 32,
                              strokeWidth: 4,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${compatibility.percentage.toInt()}% match',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: compatibilityScoreColor(
                                        compatibility.percentage,
                                      ),
                                    ),
                                  ),
                                  if (compatibility.topMatchChips.isNotEmpty)
                                    Text(
                                      compatibility.topMatchChips.first,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (badgeLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InfoPill(label: badgeLabel!, highlighted: true),
                      ),
                    Text(
                      item.monthlyRent == null
                          ? item.title
                          : locale.monthlyRentHeadline(
                              item.monthlyRent!.toStringAsFixed(0),
                            ),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        color: kDarkHeading,
                      ),
                    ),
                    if (item.monthlyRent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    if (titleLocation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              titleLocation,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.bedrooms != null)
                          InfoPill(
                            icon: Icons.bed_outlined,
                            label: locale.homeBedsValue(item.bedrooms!),
                          ),
                        if (item.bathrooms != null)
                          InfoPill(
                            icon: Icons.bathtub_outlined,
                            label: locale.homeBathsValue(item.bathrooms!),
                          ),
                        if (item.areaSqft != null)
                          InfoPill(
                            icon: Icons.straighten_outlined,
                            label: locale.homeAreaValue(
                              item.areaSqft!.toStringAsFixed(0),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FlatmatesAvatar(name: item.ownerName, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.ownerName ?? locale.ownerFallbackLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.interestCount > 0)
                          Text(
                            locale.homeInterestCount(item.interestCount),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (item.description != null &&
                        item.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.features.isNotEmpty)
                          InfoPill(
                            icon: Icons.chair_outlined,
                            label: localizedFlatmatesFeatureLabel(
                              locale,
                              item.features.first,
                            ),
                            highlighted: item.isFurnished,
                          ),
                        if (item.availableFrom != null)
                          InfoPill(
                            icon: Icons.event_outlined,
                            label: locale.homeMoveInValue(
                              DateFormat(
                                'd MMM',
                                locale.localeName,
                              ).format(item.availableFrom!.toLocal()),
                            ),
                          ),
                        if (item.genderPreference != null)
                          InfoPill(
                            icon: Icons.group_outlined,
                            label: localizedFlatmatesGenderLabel(
                              locale,
                              item.genderPreference!,
                            ),
                          ),
                        if (item.sharingType != null)
                          InfoPill(
                            icon: Icons.meeting_room_outlined,
                            label: localizedFlatmatesSharingTypeLabel(
                              locale,
                              item.sharingType!,
                            ),
                          ),
                        if (item.availableFrom != null) ...[
                          () {
                            final daysUntilMoveIn = item.availableFrom!
                                .difference(DateTime.now())
                                .inDays;
                            if (daysUntilMoveIn == 0) {
                              return InfoPill(
                                icon: Icons.event_outlined,
                                label: locale.moveInToday,
                                highlighted: true,
                              );
                            } else if (daysUntilMoveIn >= 1 &&
                                daysUntilMoveIn <= 7) {
                              return InfoPill(
                                icon: Icons.event_outlined,
                                label: locale.moveInCountdownBadge(
                                  daysUntilMoveIn,
                                ),
                                highlighted: true,
                              );
                            }
                            return const SizedBox.shrink();
                          }(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    FlatmatesButton(
                      key: Key('discover_like_${item.id}'),
                      label: locale.likeListingCta,
                      onPressed: onLike,
                      icon: Icons.favorite_border_rounded,
                      height: 44,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 148,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _ListingImageFallback(title: title),
                )
              else
                _ListingImageFallback(title: title),
              Positioned(
                right: 12,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImageFallback extends StatelessWidget {
  const _ListingImageFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NewInCitySection extends StatelessWidget {
  const _NewInCitySection({required this.items, required this.onExplore});

  final List<PropertyListing> items;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        onTap: onExplore,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.homeNewInCity(items.first.city ?? ''),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locale.cityCounter(items.length, items.first.city ?? ''),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onExplore,
                child: Text(locale.navExplore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitlistNudgeCard extends StatefulWidget {
  const _WaitlistNudgeCard({required this.city, required this.listingCount});

  final String city;
  final int listingCount;

  @override
  State<_WaitlistNudgeCard> createState() => _WaitlistNudgeCardState();
}

class _WaitlistNudgeCardState extends State<_WaitlistNudgeCard> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.group_add_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.waitlistNudgeTitle(widget.city),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locale.waitlistNudgeSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // City counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locale.cityCounterShort(widget.listingCount, widget.city),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Notify Me button
              if (_notified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        locale.waitlistConfirmed,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                FlatmatesButton(
                  key: const Key('waitlist_notify_me_button'),
                  label: locale.waitlistNotifyMe,
                  onPressed: () {
                    setState(() => _notified = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale.waitlistConfirmed),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icons.notifications_active_outlined,
                  height: 40,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/discover/discover_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';

class DiscoverFilters {
  const DiscoverFilters({
    this.query,
    this.location,
    this.priceMin,
    this.priceMax,
    this.sharingType,
    this.genderPreference,
    this.features = const [],
  });

  final String? query;
  final String? location;
  final double? priceMin;
  final double? priceMax;
  final String? sharingType;
  final String? genderPreference;
  final List<String> features;

  bool get isEmpty =>
      (query == null || query!.trim().isEmpty) &&
      (location == null || location!.trim().isEmpty) &&
      priceMin == null &&
      priceMax == null &&
      sharingType == null &&
      genderPreference == null &&
      features.isEmpty;
}

class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.ownerId,
    required this.propertyType,
    required this.title,
    required this.description,
    required this.city,
    required this.state,
    required this.locality,
    required this.subLocality,
    required this.latitude,
    required this.longitude,
    required this.monthlyRent,
    required this.mainImageUrl,
    required this.imageUrls,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.tags,
    required this.ownerName,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
    this.videoTourUrl,
    required this.interestCount,
    required this.viewCount,
    required this.likeCount,
    required this.isAvailable,
    this.createdAt,
    this.preferences,
    this.status,
    this.propertyStatus,
    this.expiresAt,
  });

  final int id;
  final int? ownerId;
  final String? propertyType;
  final String title;
  final String? description;
  final String? city;
  final String? state;
  final String? locality;
  final String? subLocality;
  final double? latitude;
  final double? longitude;
  final double? monthlyRent;
  final String? mainImageUrl;
  final List<String> imageUrls;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final List<String> tags;
  final String? ownerName;
  final DateTime? availableFrom;
  final String? genderPreference;
  final String? sharingType;
  final String? videoTourUrl;
  final int interestCount;
  final int viewCount;
  final int likeCount;
  final bool isAvailable;
  final DateTime? createdAt;
  final Map<String, dynamic>? preferences;
  final String? status;
  final String? propertyStatus;
  final DateTime? expiresAt;

  bool get isUnderReview =>
      status == 'pending_review' || status == 'under_review';
  bool get isRejected => status == 'rejected';
  bool get isLive => status == 'live' || status == 'approved';

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    final preferences = Map<String, dynamic>.from(
      json['listing_preferences'] as Map? ?? const {},
    );
    final rawFeatures = json['features'];
    final features = rawFeatures is List
        ? rawFeatures.map((item) => item.toString()).toList()
        : rawFeatures is Map
        ? rawFeatures.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList()
        : <String>[];

    return PropertyListing(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      propertyType: json['property_type']?.toString(),
      title: json['title'] as String? ?? 'Listing',
      description: json['description'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      subLocality: json['sub_locality'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      mainImageUrl: json['main_image_url'] as String?,
      imageUrls: _parseImageUrls(json),
      areaSqft: (json['area_sqft'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      features: features,
      tags: (json['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      ownerName: json['owner_name'] as String?,
      availableFrom: DateTime.tryParse(
        json['available_from']?.toString() ?? '',
      ),
      genderPreference: preferences['gender_preference'] as String?,
      sharingType: preferences['sharing_type'] as String?,
      videoTourUrl:
          preferences['video_tour_url'] as String? ??
          json['video_tour_url'] as String?,
      interestCount: (json['interest_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      preferences: preferences,
      status:
          preferences['moderation_status'] as String? ??
          json['status'] as String?,
      propertyStatus: json['status'] as String?,
      expiresAt: DateTime.tryParse(
        (json['expires_at'] ?? preferences['expires_at'])?.toString() ?? '',
      ),
    );
  }

  bool get isFurnished =>
      features.any((feature) => feature.toLowerCase().contains('furnished'));

  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    final raw = json['image_urls'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) => item.toString()).toList();
    }
    final imageRows = json['images'];
    if (imageRows is List && imageRows.isNotEmpty) {
      final urls = imageRows
          .whereType<Map>()
          .map((item) => item['image_url']?.toString())
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
      if (urls.isNotEmpty) return urls;
    }
    final main = json['main_image_url'] as String?;
    if (main != null && main.isNotEmpty) return [main];
    return const [];
  }
}

class DiscoverRepository {
  const DiscoverRepository(this._ref);

  final Ref _ref;

  Future<List<PropertyListing>> fetchListings({
    int offset = 0,
    int limit = 20,
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
  }) async {
    final queryParameters = <String, dynamic>{
      'property_type': 'flatmate',
      'purpose': 'rent',
      'offset': offset,
      'limit': limit,
    };
    if (filters != null && !filters.isEmpty) {
      final query = [
        filters.query,
        filters.location,
      ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
      if (query.isNotEmpty) {
        queryParameters['q'] = query;
      }
      if (filters.priceMin != null) {
        queryParameters['price_min'] = filters.priceMin;
      }
      if (filters.priceMax != null) {
        queryParameters['price_max'] = filters.priceMax;
      }
      if (filters.sharingType != null) {
        queryParameters['sharing_type'] = filters.sharingType;
      }
      if (filters.genderPreference != null) {
        queryParameters['gender_preference'] = filters.genderPreference;
      }
      if (filters.features.isNotEmpty) {
        queryParameters['features'] = filters.features;
      }
    }
    final response = await _ref
        .watch(apiClientProvider)
        .get('/properties', queryParameters: queryParameters);
    final data = Map<String, dynamic>.from(response.data as Map);
    final properties = (data['properties'] as List? ?? const []);
    final listings = properties
        .map(
          (item) =>
              PropertyListing.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    if (currentUser != null) {
      final userNonNegotiables = _extractUserNonNegotiables(
        currentUser.preferences,
      );
      return _applyDealBreakerFilter(listings, userNonNegotiables, currentUser);
    }

    return listings;
  }

  Future<PropertyListing> fetchListing(int propertyId) async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/properties/$propertyId');
    return PropertyListing.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  List<String> _extractUserNonNegotiables(Map<String, dynamic>? preferences) {
    if (preferences == null) return const [];
    final raw = preferences['non_negotiables'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<PropertyListing> _applyDealBreakerFilter(
    List<PropertyListing> listings,
    List<String> userNonNegotiables,
    FlatmatesProfileModel? user,
  ) {
    if (userNonNegotiables.isEmpty) return listings;

    return listings.where((listing) {
      for (final neg in userNonNegotiables) {
        switch (neg) {
          case 'food_veg_only':
          case 'food_vegan_only':
            final listingFood =
                listing.preferences?['food_habits'] ?? 'no_preference';
            if (listingFood == 'non_vegetarian' || listingFood == 'non_veg') {
              return false;
            }
            break;
          case 'no_smoking':
            final listingSD =
                listing.preferences?['smoking_drinking'] ?? 'neither';
            if (listingSD == 'smoke_outside' || listingSD == 'both_fine') {
              return false;
            }
            break;
          case 'no_drinking':
            final listingSD =
                listing.preferences?['smoking_drinking'] ?? 'neither';
            if (listingSD == 'drink_occasionally' || listingSD == 'both_fine') {
              return false;
            }
            break;
          case 'no_overnight_guests':
            final listingGuests =
                listing.preferences?['guests_policy'] ?? 'occasional_ok';
            if (listingGuests == 'open_house' ||
                listingGuests == 'comfortable') {
              return false;
            }
            break;
          case 'no_pets':
            final hasPets =
                listing.preferences?['has_pets'] == true ||
                listing.preferences?['pets'] == true;
            if (hasPets) return false;
            break;
          case 'gender_female_only':
            if (listing.genderPreference != null &&
                listing.genderPreference != 'female' &&
                listing.genderPreference != 'any') {
              return false;
            }
            break;
          case 'gender_male_only':
            if (listing.genderPreference != null &&
                listing.genderPreference != 'male' &&
                listing.genderPreference != 'any') {
              return false;
            }
            break;
          case 'no_parties':
            final listingParties =
                listing.preferences?['parties'] ?? 'occasional';
            if (listingParties == 'party_friendly') return false;
            break;
          case 'min_tidy':
            final listingCleanliness =
                listing.preferences?['cleanliness'] ?? 'tidy';
            if (listingCleanliness == 'minimal') return false;
            break;
        }
      }
      return true;
    }).toList();
  }

  Future<int?> likeListing(int propertyId) async {
    final response = await _ref
        .watch(apiClientProvider)
        .post(
          '/flatmates/swipes',
          data: {
            'target_type': 'property',
            'action': 'like',
            'property_id': propertyId,
          },
        );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['conversation_id'] as num?)?.toInt();
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref),
);

final discoverFiltersProvider = StateProvider<DiscoverFilters?>((ref) => null);

final discoverListingsProvider =
    FutureProvider.family<List<PropertyListing>, FlatmatesProfileModel?>(
      (ref, currentUser) => ref
          .watch(discoverRepositoryProvider)
          .fetchListings(
            currentUser: currentUser,
            filters: ref.watch(discoverFiltersProvider),
          ),
    );

final propertyListingProvider = FutureProvider.family<PropertyListing, int>(
  (ref, propertyId) =>
      ref.watch(discoverRepositoryProvider).fetchListing(propertyId),
);
````

## File: lib/features/discover/share_listing_card.dart
````dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class ShareListingCard extends ConsumerStatefulWidget {
  const ShareListingCard({required this.listing, super.key});

  final PropertyListing listing;

  @override
  ConsumerState<ShareListingCard> createState() => _ShareListingCardState();
}

class _ShareListingCardState extends ConsumerState<ShareListingCard> {
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final l = widget.listing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.95),
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (l.mainImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          l.mainImageUrl!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.apartment_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    const SizedBox(width: 10),
                    const Text(
                      '360 FLATMATES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (l.monthlyRent != null)
                  Text(
                    '₹${l.monthlyRent!.toStringAsFixed(0)}/month',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (l.locality != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.locality!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: l.features.take(3).map((f) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        localizedFlatmatesFeatureLabel(locale, f),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (l.availableFrom != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Move-in: ${l.availableFrom!.toLocal().day}/${l.availableFrom!.toLocal().month}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // QR code of the listing deep link
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: DeepLinkService.listingUrl(l.id),
                      version: QrVersions.auto,
                      size: 120,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: theme.colorScheme.primary,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    locale.scanToOpen,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Download 360 FlatMates to connect',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareToWhatsApp,
                icon: const Icon(Icons.chat_rounded),
                label: Text(locale.shareToWhatsapp),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FlatmatesButton(
                label: locale.shareListingCta,
                onPressed: _share,
                icon: Icons.share_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _share() async {
    final deepLink = DeepLinkService.listingUrl(widget.listing.id);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flatmates_share_card.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this listing on 360 FlatMates! $deepLink');
    } catch (_) {
      // Fallback to text-only share if image capture fails
      final l = widget.listing;
      final text = StringBuffer();
      text.writeln(l.title);
      if (l.monthlyRent != null) {
        text.writeln('Rs ${l.monthlyRent!.toStringAsFixed(0)}/month');
      }
      if (l.locality != null) {
        text.writeln(l.locality);
      }
      text.writeln();
      text.writeln('Find your flatmate on 360 FlatMates!');
      text.writeln(deepLink);
      await Share.share(text.toString());
    }
  }

  Future<void> _shareToWhatsApp() async {
    final deepLink = DeepLinkService.listingUrl(widget.listing.id);
    final l = widget.listing;
    final text = StringBuffer();
    text.writeln(l.title);
    if (l.monthlyRent != null) {
      text.writeln('Rs ${l.monthlyRent!.toStringAsFixed(0)}/month');
    }
    if (l.locality != null) text.writeln(l.locality);
    text.writeln();
    text.writeln('Find your flatmate on 360 FlatMates!');
    text.writeln(deepLink);

    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(text.toString())}',
    );
    final canLaunch = await canLaunchUrl(whatsappUrl);
    if (canLaunch) {
      await launchUrl(whatsappUrl);
    } else {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.whatsappNotInstalled)));
    }
  }
}
````

## File: lib/features/listings/manage_listing_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'listings_repository.dart';

class ManageListingPage extends ConsumerStatefulWidget {
  const ManageListingPage({super.key});

  @override
  ConsumerState<ManageListingPage> createState() => _ManageListingPageState();
}

class _ManageListingPageState extends ConsumerState<ManageListingPage> {
  int _selectedTab = 0; // 0 = Active, 1 = Drafts, 2 = Expired
  final _pausedListingIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(myListingsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const FlatmatesLogo(compact: true),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                  ),
                  IconButton(
                    onPressed: () => context.go('/chats'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Chat',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  locale.manageListingTitle,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),

            // "New Listing" CTA — full width button, not FAB
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FlatmatesButton(
                label: locale.postListingTitle,
                onPressed: () => context.push('/post/new'),
                icon: Icons.add_home_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            _buildTabBar(theme, locale, listings.valueOrNull ?? const []),

            const SizedBox(height: 12),

            // Listings content
            Expanded(
              child: listings.when(
                data: (items) {
                  final myListings = items.where(_matchesSelectedTab).toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_home_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            locale.emptyListings,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(myListingsProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      children: myListings.map((listing) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PropertyCard(
                            listing: listing,
                            isPaused: _pausedListingIds.contains(listing.id),
                            onTogglePause: (listingId, currentlyPaused) =>
                                _togglePause(listingId, currentlyPaused),
                            onShare: () => Share.share(
                              'Check out this flat on 360 FlatMates: ${listing.title} at ₹${listing.monthlyRent?.toStringAsFixed(0) ?? "N/A"}/mo in ${listing.locality ?? listing.city ?? ""}\n${DeepLinkService.listingUrl(listing.id)}',
                            ),
                            onEdit: () => context.push(
                              '/post/new?listingId=${listing.id}',
                            ),
                            onViewStats: () => _showStatsDialog(listing),
                            onReview: () =>
                                context.push('/listing-review/${listing.id}'),
                            theme: theme,
                            locale: locale,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(
    ThemeData theme,
    AppLocalizations locale,
    List<dynamic> listings,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabItem(
            label:
                '${locale.activeListingsLabel} (${_countForTab(listings, 0)})',
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
            theme: theme,
          ),
          _TabItem(
            label: '${locale.draftsLabel} (${_countForTab(listings, 1)})',
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
            theme: theme,
          ),
          _TabItem(
            label: '${locale.expiredLabel} (${_countForTab(listings, 2)})',
            isSelected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
            theme: theme,
          ),
        ],
      ),
    );
  }

  int _countForTab(List<dynamic> listings, int tab) {
    return listings.where((listing) => _matchesTab(listing, tab)).length;
  }

  bool _matchesSelectedTab(dynamic listing) =>
      _matchesTab(listing, _selectedTab);

  bool _matchesTab(dynamic listing, int tab) {
    final status = (listing.status ?? listing.propertyStatus ?? '').toString();
    final expired =
        listing.expiresAt != null &&
        listing.expiresAt!.isBefore(DateTime.now());
    return switch (tab) {
      0 =>
        !expired &&
            listing.isAvailable == true &&
            !{'draft', 'expired', 'rejected'}.contains(status),
      1 => status == 'draft' || status == 'pending_review',
      2 => expired || status == 'expired' || listing.isAvailable == false,
      _ => false,
    };
  }

  void _showStatsDialog(dynamic listing) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(listing.title ?? 'Listing Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              icon: Icons.visibility_outlined,
              label: 'Views',
              value: _formatCount(listing.viewCount ?? 0),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.favorite_outline,
              label: 'Likes',
              value: _formatCount(listing.likeCount ?? 0),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.handshake_outlined,
              label: 'Matches',
              value: _formatCount(listing.interestCount ?? 0),
              theme: theme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Future<void> _togglePause(int listingId, bool currentlyPaused) async {
    try {
      await ref
          .read(apiClientProvider)
          .put(
            '/properties/$listingId',
            data: {'status': currentlyPaused ? 'live' : 'paused'},
          );
      setState(() {
        if (currentlyPaused) {
          _pausedListingIds.remove(listingId);
        } else {
          _pausedListingIds.add(listingId);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update listing status.')),
        );
      }
    }
  }
}

/// Tab item for the segmented control bar.
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Property card with image, info row, owner info, and stats action grid.
class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.listing,
    required this.isPaused,
    required this.onTogglePause,
    required this.onShare,
    required this.onEdit,
    required this.onViewStats,
    required this.onReview,
    required this.theme,
    required this.locale,
  });

  final dynamic listing;
  final bool isPaused;
  final void Function(int listingId, bool currentlyPaused) onTogglePause;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onViewStats;
  final VoidCallback onReview;
  final ThemeData theme;
  final AppLocalizations locale;

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width image at top
          if (listing.mainImageUrl != null)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(
                listing.mainImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildPlaceholderImage(fullWidth: true),
              ),
            )
          else
            _buildPlaceholderImage(fullWidth: true),

          // Info below image
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (listing.monthlyRent != null)
                  Text(
                    '\u{20B9}${listing.monthlyRent!.toStringAsFixed(0)}/mo',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 8),
                // Quick info row
                Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      listing.bedrooms == null
                          ? '-- Beds'
                          : '${listing.bedrooms} Beds',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.bathtub_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      listing.bathrooms == null
                          ? '-- Baths'
                          : '${listing.bathrooms} Baths',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.square_foot_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${listing.areaSqft ?? '--'} sqft',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.wifi_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Owner info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    (listing.ownerName != null && listing.ownerName!.isNotEmpty)
                        ? listing.ownerName![0].toUpperCase()
                        : 'O',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  listing.ownerName ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Stats action grid (2 rows x 3 cols)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Row 1
                Row(
                  children: [
                    Expanded(
                      child: _StatActionItem(
                        icon: Icons.favorite_border_rounded,
                        label: 'Match Count (${listing.interestCount})',
                        onTap: () {},
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: _StatActionItem(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: onEdit,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: _StatActionItem(
                        icon: Icons.rocket_launch_outlined,
                        label: 'Boost',
                        onTap: () {},
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2
                Row(
                  children: [
                    Expanded(
                      child: _StatActionItem(
                        icon: Icons.bar_chart_outlined,
                        label:
                            'View Stats (${_formatCount(listing.viewCount ?? 0)})',
                        onTap: onViewStats,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: _StatActionItem(
                        icon: Icons.rate_review_outlined,
                        label: 'Review',
                        onTap: onReview,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: _StatActionItem(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: onShare,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage({bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : 80,
      height: fullWidth ? 160 : 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(fullWidth ? 0 : 14),
      ),
      child: const Icon(Icons.apartment_rounded),
    );
  }
}

/// Individual stat/action item in the grid.
class _StatActionItem extends StatelessWidget {
  const _StatActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 3),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Row inside the stats dialog showing a single stat.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
````

## File: lib/features/onboarding/onboarding_controller.dart
````dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap/bootstrap_controller.dart';
import '../profile/profile_repository.dart';

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState()) {
    _loadSavedState();
  }

  final Ref _ref;
  static const String _prefsKey = 'onboarding_state';

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null) {
        final savedData = jsonDecode(savedJson) as Map<String, dynamic>;
        final savedStep = OnboardingStep.values.firstWhere(
          (e) => e.name == savedData['step'],
          orElse: () => OnboardingStep.splash,
        );

        // Only restore if onboarding is not complete
        if (!(savedData['isComplete'] as bool? ?? false)) {
          state = OnboardingState(
            step: savedStep,
            mode: savedData['mode'] as String?,
            fullName: savedData['full_name'] as String?,
            age: savedData['age'] as int?,
            profession: savedData['profession'] as String?,
            city: savedData['city'] as String?,
            locality: savedData['locality'] as String?,
            photoUrls:
                (savedData['photo_urls'] as List?)?.cast<String>() ?? const [],
            lifestyleAnswers: Map<String, String>.from(
              savedData['lifestyle_answers'] as Map? ?? const {},
            ),
            budgetMin: (savedData['budget_min'] as num?)?.toDouble(),
            budgetMax: (savedData['budget_max'] as num?)?.toDouble(),
            moveInTimeline: savedData['move_in_timeline'] as String?,
            preferences: Map<String, dynamic>.from(
              savedData['preferences'] as Map? ?? const {},
            ),
            nonNegotiables:
                (savedData['non_negotiables'] as List?)?.cast<String>() ??
                const [],
          );
        }
      }
    } catch (e) {
      // Ignore errors, start fresh
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'step': state.step.name,
        'mode': state.mode,
        'full_name': state.fullName,
        'age': state.age,
        'profession': state.profession,
        'city': state.city,
        'locality': state.locality,
        'photo_urls': state.photoUrls,
        'lifestyle_answers': state.lifestyleAnswers,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'move_in_timeline': state.moveInTimeline,
        'preferences': state.preferences,
        'non_negotiables': state.nonNegotiables,
        'isComplete': state.isComplete,
      };
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> _clearSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> setMode(String mode) async {
    state = state.copyWith(mode: mode, step: OnboardingStep.locationSelection);
    await _saveState();
  }

  Future<void> completeSplash() async {
    state = state.copyWith(step: OnboardingStep.modeSelection);
    await _saveState();
  }

  Future<void> setLocation(Map<String, String?> data) async {
    state = state.copyWith(
      city: data['city'],
      locality: data['locality'],
      step: OnboardingStep.basicInfo,
    );
    await _saveState();
  }

  Future<void> setBasicInfo(Map<String, dynamic> data) async {
    state = state.copyWith(
      fullName: data['full_name'] as String?,
      age: data['age'] as int?,
      profession: data['profession'] as String?,
      city: data['city'] as String? ?? state.city,
      locality: data['locality'] as String? ?? state.locality,
      step: OnboardingStep.profilePhoto,
    );
    await _saveState();
  }

  Future<void> setPhotoUrls(List<String> urls) async {
    state = state.copyWith(photoUrls: urls, step: OnboardingStep.lifestyleQuiz);
    await _saveState();
  }

  Future<void> setLifestyleAnswers(Map<String, String> answers) async {
    state = state.copyWith(
      lifestyleAnswers: answers,
      step: OnboardingStep.budgetTimeline,
    );
    await _saveState();
  }

  Future<void> setBudgetTimeline(Map<String, dynamic> data) async {
    state = state.copyWith(
      budgetMin: data['budget_min'] as double?,
      budgetMax: data['budget_max'] as double?,
      moveInTimeline: data['move_in_timeline'] as String?,
      step: OnboardingStep.preferences,
    );
    await _saveState();
  }

  Future<void> setPreferences(Map<String, dynamic> data) async {
    state = state.copyWith(
      preferences: data,
      step: OnboardingStep.nonNegotiables,
    );
    await _saveState();
  }

  Future<void> submitNonNegotiables(List<String> nonNegotiables) async {
    state = state.copyWith(nonNegotiables: nonNegotiables, isSubmitting: true);
    await _saveState();

    try {
      final lifestyleAnswers = _normalizeLifestyleAnswers(
        state.lifestyleAnswers,
      );
      final preferences = _normalizePreferences(state.preferences);
      final payload = <String, dynamic>{
        'mode': state.mode,
        'full_name': state.fullName,
        'age': state.age,
        'city': state.city,
        'locality': state.locality,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'move_in_timeline': state.moveInTimeline,
        'onboarding_completed': true,
        'preferences': {
          'profession': state.profession,
          'photo_urls': state.photoUrls,
          'non_negotiables': state.nonNegotiables,
          ...lifestyleAnswers,
          ...preferences,
        },
      };

      payload.addAll(lifestyleAnswers);
      if (preferences['gender_preference'] != null) {
        payload['gender_preference'] = preferences['gender_preference'];
      }

      if (state.photoUrls.isNotEmpty) {
        payload['profile_image_url'] = state.photoUrls.first;
      }

      await _ref
          .read(profileRepositoryProvider)
          .updateProfile(payload: payload);
      await _ref.read(bootstrapControllerProvider.notifier).load();
      state = state.copyWith(isSubmitting: false, isComplete: true);
      await _clearSavedState();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      await _saveState();
    }
  }
}

Map<String, String> _normalizeLifestyleAnswers(Map<String, String> answers) {
  return answers.map((key, value) {
    return MapEntry(key, _normalizeFlatmateValue(key, value));
  });
}

Map<String, dynamic> _normalizePreferences(Map<String, dynamic> preferences) {
  return preferences.map((key, value) {
    if (value is! String) return MapEntry(key, value);
    final normalizedKey = key == 'preferred_gender' ? 'gender_preference' : key;
    return MapEntry(
      normalizedKey,
      _normalizeFlatmateValue(normalizedKey, value),
    );
  });
}

String _normalizeFlatmateValue(String key, String value) {
  return switch ((key, value)) {
    ('food_habits', 'veg') => 'vegetarian',
    ('food_habits', 'non_veg') => 'non_vegetarian',
    ('gender_preference', 'no_preference') => 'any',
    ('gender_preference', 'male_only') => 'male',
    ('gender_preference', 'female_only') => 'female',
    ('pets', 'yes') => 'have_pets',
    ('pets', 'no') => 'no_pets',
    ('smoking', 'no') => 'neither',
    ('smoking', 'yes') => 'smoke_outside',
    _ => value,
  };
}

enum OnboardingStep {
  splash,
  modeSelection,
  locationSelection,
  basicInfo,
  profilePhoto,
  lifestyleQuiz,
  budgetTimeline,
  preferences,
  nonNegotiables,
}

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.splash,
    this.mode,
    this.fullName,
    this.age,
    this.profession,
    this.city,
    this.locality,
    this.photoUrls = const [],
    this.lifestyleAnswers = const {},
    this.budgetMin,
    this.budgetMax,
    this.moveInTimeline,
    this.preferences = const {},
    this.nonNegotiables = const [],
    this.isSubmitting = false,
    this.isComplete = false,
    this.error,
  });

  final OnboardingStep step;
  final String? mode;
  final String? fullName;
  final int? age;
  final String? profession;
  final String? city;
  final String? locality;
  final List<String> photoUrls;
  final Map<String, String> lifestyleAnswers;
  final double? budgetMin;
  final double? budgetMax;
  final String? moveInTimeline;
  final Map<String, dynamic> preferences;
  final List<String> nonNegotiables;
  final bool isSubmitting;
  final bool isComplete;
  final String? error;

  double get completionPercentage {
    int completed = 0;
    int total = 9; // Total steps

    if (mode != null && mode!.isNotEmpty) completed++;
    if (fullName != null && fullName!.isNotEmpty) completed++;
    if (age != null && age! >= 18) completed++;
    if (city != null && city!.isNotEmpty) completed++;
    if (photoUrls.isNotEmpty) completed++;
    if (lifestyleAnswers.isNotEmpty && lifestyleAnswers.length >= 8) {
      completed++;
    }
    if (budgetMin != null && budgetMax != null) completed++;
    if (moveInTimeline != null && moveInTimeline!.isNotEmpty) completed++;
    if (preferences.isNotEmpty) completed++;
    if (nonNegotiables.isNotEmpty) completed++;

    // Cap at 100%
    return ((completed / total) * 100).clamp(0, 100);
  }

  OnboardingState copyWith({
    OnboardingStep? step,
    String? mode,
    String? fullName,
    int? age,
    String? profession,
    String? city,
    String? locality,
    List<String>? photoUrls,
    Map<String, String>? lifestyleAnswers,
    double? budgetMin,
    double? budgetMax,
    String? moveInTimeline,
    Map<String, dynamic>? preferences,
    List<String>? nonNegotiables,
    bool? isSubmitting,
    bool? isComplete,
    String? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      mode: mode ?? this.mode,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      profession: profession ?? this.profession,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      photoUrls: photoUrls ?? this.photoUrls,
      lifestyleAnswers: lifestyleAnswers ?? this.lifestyleAnswers,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      moveInTimeline: moveInTimeline ?? this.moveInTimeline,
      preferences: preferences ?? this.preferences,
      nonNegotiables: nonNegotiables ?? this.nonNegotiables,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
      (ref) => OnboardingController(ref),
    );
````

## File: lib/features/profile/help_safety_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class HelpSafetyPage extends ConsumerWidget {
  const HelpSafetyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      locale.helpSafetyTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // balance back button
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar — DESIGN.md spec: 48px height, 20px radius, 1px outlineVariant border
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 48,
                child: TextField(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: locale.searchHelpPlaceholder,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.outlineVariant,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_outlined,
                      size: 20,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          )
                        : theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  // FAQ
                  FlatmatesMenuItem(
                    icon: Icons.help_outline,
                    label: locale.faqTitle,
                    subtitle: locale.faqSubtitle,
                    onTap: () => _navigateToSubPage(context, '/help-faq'),
                  ),

                  // Popular Topics
                  FlatmatesMenuItem(
                    icon: Icons.local_fire_department,
                    label: locale.popularTopicsLabel,
                    subtitle: locale.popularTopicsSubtitle,
                    onTap: () =>
                        _navigateToSubPage(context, '/help-popular-topics'),
                  ),

                  // Payments & Refunds
                  FlatmatesMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: locale.paymentsLabel,
                    subtitle: locale.paymentsSubtitle,
                    onTap: () => _navigateToSubPage(context, '/help-payments'),
                  ),

                  // Booking & Agreements
                  FlatmatesMenuItem(
                    icon: Icons.assignment_outlined,
                    label: locale.bookingAgreementsLabel,
                    subtitle: locale.bookingAgreementsSubtitle,
                    onTap: () => _navigateToSubPage(context, '/help-bookings'),
                  ),

                  // Account & Profile
                  FlatmatesMenuItem(
                    icon: Icons.person_outline,
                    label: locale.accountProfileLabel,
                    subtitle: locale.accountProfileSubtitle,
                    onTap: () => _navigateToSubPage(context, '/help-account'),
                  ),

                  // Contact Support
                  FlatmatesMenuItem(
                    icon: Icons.headset_mic,
                    label: locale.contactSupport,
                    subtitle: locale.contactSupportSubtitle,
                    onTap: () => _navigateToSubPage(context, '/help-contact'),
                  ),

                  const SizedBox(height: 28),

                  // CTA: Chat with Us
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FlatmatesButton(
                      label: locale.chatWithUsCta,
                      onPressed: () {
                        // TODO: open chat with support
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locale.comingSoon)),
                        );
                      },
                      icon: Icons.chat,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Note below CTA
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            locale.replyTimeNote,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSubPage(BuildContext context, String route) {
    context.push(route);
  }
}
````

## File: lib/features/profile/profile_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: bootstrap.when(
          data: (data) {
            final profile = data?.profile;
            final city = profile?.city;
            final state = profile?.state;
            final location = [
              if (city != null && city.trim().isNotEmpty) city.trim(),
              if (state != null && state.trim().isNotEmpty) state.trim(),
            ].join(', ');
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                // --- Header row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.profilePageTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                    IconButton(
                      key: const Key('profile_settings_button'),
                      onPressed: () => context.push('/profile/settings'),
                      icon: const Icon(Icons.settings),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // --- Avatar with edit FAB ---
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FlatmatesAvatar(
                        name: profile.fullName,
                        imageUrl: profile.profileImageUrl,
                        size: 130,
                      ),
                      Positioned(
                        right: -4,
                        bottom: 4,
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            key: const Key('profile_edit_button'),
                            onTap: () => context.push('/profile/edit'),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // --- Name ---
                Text(
                  profile.fullName ?? locale.profileFallbackName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // --- Role badge ---
                if (profile.mode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          localizedFlatmatesModeLabel(locale, profile.mode!),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (profile.mode != null) const SizedBox(height: 10),
                // --- Location ---
                if (location.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          location,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                // --- Menu items ---
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.calendar_month_outlined,
                        label: locale.profileMenuVisits,
                        onTap: () => context.go('/visits'),
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        icon: Icons.favorite_border,
                        label: locale.profileMenuShortlisted,
                        onTap: () => context.go('/chats'),
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: locale.profileMenuChats,
                        onTap: () => context.go('/chats'),
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        icon: Icons.description_outlined,
                        label: locale.profileMenuDocuments,
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        icon: Icons.payment_outlined,
                        label: locale.profileMenuPaymentMethods,
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        icon: Icons.settings_outlined,
                        label: locale.settingsTitle,
                        onTap: () => context.push('/profile/settings'),
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        icon: Icons.help_outline,
                        label: locale.helpSafetyTitle,
                        onTap: () => context.push('/help-safety'),
                      ),
                      const Divider(height: 1, indent: 68, endIndent: 16),
                      FlatmatesMenuItem(
                        key: const Key('logout_button'),
                        icon: Icons.logout,
                        label: locale.logoutCta,
                        isDestructive: true,
                        onTap: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}
````

## File: lib/features/settings/settings_page.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/constants.dart';
import '../../core/theme/app_palette.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'settings_controller.dart';
import '../shared/presentation/flatmates_ui.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      locale.settingsTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // balance the back button
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  // Account group
                  _SectionHeader(label: locale.settingsGroupAccount),
                  FlatmatesMenuItem(
                    icon: Icons.person_outline,
                    label: locale.editProfileCta,
                    onTap: () => context.push('/profile/edit'),
                  ),
                  FlatmatesMenuItem(
                    icon: Icons.lock_outline,
                    label: locale.changePasswordLabel,
                    onTap: () => context.push('/change-password'),
                  ),
                  FlatmatesMenuItem(
                    icon: Icons.shield_outlined,
                    label: locale.privacySecurityLabel,
                    onTap: () => context.push('/help-safety'),
                  ),
                  FlatmatesMenuItem(
                    key: const Key('preferences_menu_item'),
                    icon: Icons.tune,
                    label: locale.preferencesLabel,
                    onTap: () => _showPreferences(context, ref, theme),
                  ),

                  const SizedBox(height: 12),

                  // App group
                  _SectionHeader(label: locale.settingsGroupApp),
                  FlatmatesMenuItem(
                    icon: Icons.notifications_outlined,
                    label: locale.notificationSettingsLabel,
                    onTap: () => context.push('/notifications'),
                  ),
                  FlatmatesMenuItem(
                    icon: Icons.person_off_outlined,
                    label: locale.blockedUsersLabel,
                    onTap: () => context.push('/blocked-users'),
                  ),

                  const SizedBox(height: 12),

                  // Legal group
                  _SectionHeader(label: locale.settingsGroupLegal),
                  FlatmatesMenuItem(
                    icon: Icons.info_outline,
                    label: locale.aboutLabel,
                    onTap: () => _showAboutDialog(context),
                  ),
                  FlatmatesMenuItem(
                    icon: Icons.description_outlined,
                    label: locale.termsAndConditionsLabel,
                    onTap: () => _launchTermsOfService(),
                  ),

                  const SizedBox(height: 24),

                  // Standalone Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FlatmatesMenuItem(
                      key: const Key('logout_button'),
                      icon: Icons.logout,
                      label: locale.logoutCta,
                      isDestructive: true,
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferences(BuildContext context, WidgetRef ref, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PreferencesSheet(ref: ref),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final locale = AppLocalizations.of(context);
    showAboutDialog(
      context: context,
      applicationName: locale.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 32),
    );
  }

  Future<void> _launchTermsOfService() async {
    final uri = Uri.parse(kTermsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Bottom sheet for Preferences — holds theme mode, palette, and language
/// selectors that were moved out of the main settings page.
class _PreferencesSheet extends ConsumerStatefulWidget {
  const _PreferencesSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends ConsumerState<_PreferencesSheet> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                locale.preferencesLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Theme Mode
                  Text(
                    locale.themeModeTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(
                          locale.themeSystem,
                          key: const Key('theme_mode_system_option'),
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(
                          locale.themeLight,
                          key: const Key('theme_mode_light_option'),
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(
                          locale.themeDark,
                          key: const Key('theme_mode_dark_option'),
                        ),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateThemeMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Palette
                  Text(locale.paletteTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppPalette.values.map((palette) {
                      final selected = settings.palette == palette;
                      return ChoiceChip(
                        key: Key('palette_${palette.storageValue}'),
                        label: Text(_paletteLabel(locale, palette)),
                        selected: selected,
                        onSelected: (_) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updatePalette(palette);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Language
                  Text(
                    locale.languageTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'en',
                        label: Text(
                          locale.languageEnglish,
                          key: const Key('language_english_option'),
                        ),
                      ),
                      ButtonSegment(
                        value: 'hi',
                        label: Text(
                          locale.languageHindi,
                          key: const Key('language_hindi_option'),
                        ),
                      ),
                    ],
                    selected: {settings.locale?.languageCode ?? 'en'},
                    onSelectionChanged: (selection) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateLocale(Locale(selection.first));
                    },
                  ),
                  const SizedBox(height: 24),

                  // Privacy toggles
                  SwitchListTile(
                    key: const Key('setting_hide_last_name'),
                    secondary: Icon(
                      Icons.person_off_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(locale.hideLastNameLabel),
                    value: settings.hideLastName,
                    onChanged: (v) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateHideLastName(v);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    key: const Key('setting_hide_location'),
                    secondary: Icon(
                      Icons.location_off_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(locale.hideExactLocationLabel),
                    value: settings.hideExactLocation,
                    onChanged: (v) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateHideExactLocation(v);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

String _paletteLabel(AppLocalizations locale, AppPalette palette) {
  switch (palette) {
    case AppPalette.electricIndigo:
      return locale.paletteElectricIndigo;
    case AppPalette.emberCoral:
      return locale.paletteEmberCoral;
    case AppPalette.monsoonTeal:
      return locale.paletteMonsoonTeal;
  }
}

/// Section group header with a divider line above and bold label.
/// Matches DESIGN.md Screen 19 group pattern.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/swipe/swipe_deck_page.dart
````dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/compatibility/compatibility_ring.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'match_celebration_screen.dart';
import 'match_qna_nudge.dart';
import 'swipe_repository.dart';

class SwipeDeckPage extends ConsumerStatefulWidget {
  const SwipeDeckPage({super.key});

  @override
  ConsumerState<SwipeDeckPage> createState() => _SwipeDeckPageState();
}

class _SwipeDeckPageState extends ConsumerState<SwipeDeckPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpanded = false;
  bool _isAnimating = false;
  int _superLikesRemaining = 3;
  int _swipesToday = 0;
  static const _swipesPerDayCap = 100;
  static const _prefKeySwipesDate = 'swipe_cap_date';
  static const _prefKeySwipesCount = 'swipe_cap_count';
  static const _prefKeySuperLikes = 'swipe_super_likes_remaining';
  final _swipeDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 300),
  );

  // --- Swipe gesture state ---
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  // Animation controllers
  late final AnimationController _flyOffController;
  late final AnimationController _snapBackController;
  late final AnimationController _cardEntranceController;

  // Fly-off animation values
  Offset _flyOffStartOffset = Offset.zero;
  late Animation<double> _flyOffAnimation;

  // Snap-back animation values
  Offset _snapBackStartOffset = Offset.zero;
  late Animation<double> _snapBackAnimation;

  // Card entrance animation
  late Animation<double> _cardScaleAnimation;

  // Direction for fly-off: 1 = right, -1 = left, 0 = up (super like)
  int _flyOffDirectionX = 0;
  int _flyOffDirectionY = 0;

  static const double _maxRotationDegrees = 15;
  static const Duration _snapBackDuration = Duration(milliseconds: 300);
  static const Duration _flyOffDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _loadSwipeCaps();

    // Fly-off controller (card exits screen)
    _flyOffController = AnimationController(
      vsync: this,
      duration: _flyOffDuration,
    );
    _flyOffAnimation = CurvedAnimation(
      parent: _flyOffController,
      curve: Curves.easeIn,
    );
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);

    // Snap-back controller (card returns to center)
    _snapBackController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOut,
    );
    _snapBackController.addListener(_onSnapBackTick);

    // Card entrance controller (next card scales up)
    _cardEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _cardScaleAnimation = CurvedAnimation(
      parent: _cardEntranceController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadSwipeCaps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_prefKeySwipesDate);
    if (savedDate == today) {
      _swipesToday = prefs.getInt(_prefKeySwipesCount) ?? 0;
    } else {
      _swipesToday = 0;
      await prefs.setString(_prefKeySwipesDate, today);
      await prefs.setInt(_prefKeySwipesCount, 0);
    }
    _superLikesRemaining = prefs.getInt(_prefKeySuperLikes) ?? 3;
    if (mounted) setState(() {});
  }

  Future<void> _saveSwipeCaps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeySwipesCount, _swipesToday);
    await prefs.setInt(_prefKeySuperLikes, _superLikesRemaining);
  }

  @override
  void dispose() {
    _flyOffController.dispose();
    _snapBackController.dispose();
    _cardEntranceController.dispose();
    super.dispose();
  }

  // --- Gesture handlers ---

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || _isExpanded) return;
    _snapBackController.stop();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _isAnimating) return;
    _isDragging = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.20;
    final dx = _dragOffset.dx;

    // Check for super like (upward swipe)
    if (_dragOffset.dy < -threshold) {
      _triggerFlyOff(superLike: true);
      return;
    }

    // Check for left/right swipe
    if (dx.abs() > threshold) {
      _triggerFlyOff(superLike: false);
      return;
    }

    // Snap back to center
    _triggerSnapBack();
  }

  void _triggerSnapBack() {
    _snapBackStartOffset = _dragOffset;
    _snapBackController.forward(from: 0);
  }

  void _onSnapBackTick() {
    final t = _snapBackAnimation.value;
    setState(() {
      _dragOffset = Offset.lerp(_snapBackStartOffset, Offset.zero, t)!;
    });
    if (_snapBackController.isCompleted) {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _triggerFlyOff({required bool superLike}) {
    // Determine direction
    if (superLike) {
      _flyOffDirectionX = 0;
      _flyOffDirectionY = -1;
    } else {
      _flyOffDirectionX = _dragOffset.dx > 0 ? 1 : -1;
      _flyOffDirectionY = 0;
    }

    _flyOffStartOffset = _dragOffset;

    _isAnimating = true;
    _flyOffController.forward(from: 0);
  }

  void _onFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = Offset(
      _flyOffDirectionX != 0 ? _flyOffDirectionX * screenSize.width * 1.5 : 0.0,
      _flyOffDirectionY != 0
          ? _flyOffDirectionY * screenSize.height * 1.5
          : 0.0,
    );

    setState(() {
      _dragOffset = Offset.lerp(_flyOffStartOffset, targetOffset, t)!;
    });
  }

  void _onFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    // Determine the action from the fly-off direction
    String action;
    if (_flyOffDirectionY < 0) {
      action = 'super_like';
    } else if (_flyOffDirectionX > 0) {
      action = 'like';
    } else {
      action = 'pass';
    }

    // Reset drag state before processing
    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);

    setState(() {
      _dragOffset = Offset.zero;
    });

    // Process the swipe action (API call, state update)
    _processSwipeAction(action);
  }

  Future<void> _processSwipeAction(String action) async {
    // Check caps
    if (action == 'super_like' && _superLikesRemaining <= 0) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.superLikeCapLabel(0))));
      _resetAfterSwipe();
      return;
    }

    if (_swipesToday >= _swipesPerDayCap) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.swipeCounterLabel(0))));
      _resetAfterSwipe();
      return;
    }

    final profiles = ref.read(swipeProfilesProvider).valueOrNull ?? [];
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;
    final visible = profiles.where((i) => i.id != userProfile?.id).toList();

    if (_currentIndex >= visible.length) {
      _resetAfterSwipe();
      return;
    }

    final item = visible[_currentIndex];

    // Haptic feedback on completed swipe
    HapticFeedback.mediumImpact();

    SwipeResult? swipeResult;
    try {
      swipeResult = await ref
          .read(swipeRepositoryProvider)
          .swipeProfile(targetUserId: item.id, action: action);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Action failed. Please try again.',
            ),
          ),
        );
      }
      _resetAfterSwipe();
      return;
    }

    if (!mounted) return;

    setState(() {
      _currentIndex++;
      _isExpanded = false;
      _swipesToday++;
      if (action == 'super_like') _superLikesRemaining--;
    });
    _saveSwipeCaps();

    // Show match celebration if a mutual like was detected
    final isLikeAction = action == 'like' || action == 'super_like';
    if (isLikeAction && swipeResult.didMatch) {
      _showMatchCelebration(
        peerName: item.fullName ?? 'Flatmate',
        peerImageUrl: item.profileImageUrl,
        conversationId: swipeResult.conversationId,
      );
    }

    // Animate next card entrance
    _cardEntranceController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });

    // Re-attach listeners
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);

    ref.invalidate(swipeProfilesProvider);
  }

  void _showMatchCelebration({
    required String peerName,
    required String? peerImageUrl,
    required int? conversationId,
  }) {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchCelebrationScreen(
          userName: userProfile?.fullName ?? 'You',
          userImageUrl: userProfile?.profileImageUrl,
          peerName: peerName,
          peerImageUrl: peerImageUrl,
          onOpenChat: () {
            Navigator.of(context).pop();
            if (conversationId != null) {
              context.push('/chats/$conversationId');
              // Show Q&A nudge bottom sheet after navigating to chat
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) =>
                        MatchQnANudgeSheet(conversationId: conversationId),
                  );
                }
              });
            } else {
              context.go('/chats');
            }
          },
          onKeepSwiping: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _resetAfterSwipe() {
    setState(() {
      _dragOffset = Offset.zero;
      _isAnimating = false;
    });
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
  }

  double get _currentRotation {
    if (_dragOffset.dx == 0) return 0;
    final screenWidth = MediaQuery.of(context).size.width;
    // Rotation proportional to horizontal drag, max _maxRotationDegrees
    final rotationFactor = (_dragOffset.dx / screenWidth).clamp(-1.0, 1.0);
    return rotationFactor * _maxRotationDegrees * 3.14159265 / 180;
  }

  double get _dragProgress {
    // 0.0 at center, 1.0 at threshold distance
    final screenWidth = MediaQuery.of(context).size.width;
    return (_dragOffset.dx.abs() / (screenWidth * 0.20)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(swipeProfilesProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return profiles.when(
      data: (items) {
        if (items.isEmpty) {
          return Scaffold(body: Center(child: Text(locale.emptySwipeDeck)));
        }

        final userProfile = bootstrap.valueOrNull?.profile;
        final visible = items.where((i) => i.id != userProfile?.id).toList();

        if (visible.isEmpty || _currentIndex >= visible.length) {
          return Scaffold(body: Center(child: Text(locale.emptySwipeDeck)));
        }

        final item = visible[_currentIndex];
        final compatibility = CompatibilityEngine.calculate(
          user: {
            'sleep_schedule': userProfile?.sleepSchedule ?? 'flexible',
            'cleanliness': userProfile?.cleanliness ?? 'tidy',
            'food_habits': userProfile?.foodHabits ?? 'no_preference',
            'smoking_drinking': userProfile?.smokingDrinking ?? 'neither',
            'guests_policy': userProfile?.guestsPolicy ?? 'occasional_ok',
            'work_style': userProfile?.workStyle ?? 'hybrid',
          },
          peer: {
            'sleep_schedule': item.sleepSchedule ?? 'flexible',
            'cleanliness': item.cleanliness ?? 'tidy',
            'food_habits': item.foodHabits ?? 'no_preference',
            'smoking_drinking': item.smokingDrinking ?? 'neither',
            'guests_policy': item.guestsPolicy ?? 'occasional_ok',
            'work_style': item.workStyle ?? 'hybrid',
          },
        );

        // Compute next card compatibility if available
        final hasNextCard = _currentIndex + 1 < visible.length;
        final nextItem = hasNextCard ? visible[_currentIndex + 1] : null;
        final nextCompatibility = hasNextCard
            ? CompatibilityEngine.calculate(
                user: {
                  'sleep_schedule': userProfile?.sleepSchedule ?? 'flexible',
                  'cleanliness': userProfile?.cleanliness ?? 'tidy',
                  'food_habits': userProfile?.foodHabits ?? 'no_preference',
                  'smoking_drinking': userProfile?.smokingDrinking ?? 'neither',
                  'guests_policy': userProfile?.guestsPolicy ?? 'occasional_ok',
                  'work_style': userProfile?.workStyle ?? 'hybrid',
                },
                peer: {
                  'sleep_schedule': nextItem!.sleepSchedule ?? 'flexible',
                  'cleanliness': nextItem.cleanliness ?? 'tidy',
                  'food_habits': nextItem.foodHabits ?? 'no_preference',
                  'smoking_drinking': nextItem.smokingDrinking ?? 'neither',
                  'guests_policy': nextItem.guestsPolicy ?? 'occasional_ok',
                  'work_style': nextItem.workStyle ?? 'hybrid',
                },
              )
            : null;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FlatmatesLogo(compact: true),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            locale.swipeCounterLabel(
                              _swipesPerDayCap - _swipesToday,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.superLikeCapLabel(_superLikesRemaining),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildCardStack(
                    item: item,
                    compatibility: compatibility,
                    nextItem: nextItem,
                    nextCompatibility: nextCompatibility,
                  ),
                ),
                _ActionBar(
                  onPass: () =>
                      _swipeDebouncer.run(() => _handleActionButton('pass')),
                  onSuperLike: () => _swipeDebouncer.run(
                    () => _handleActionButton('super_like'),
                  ),
                  onLike: () =>
                      _swipeDebouncer.run(() => _handleActionButton('like')),
                  isAnimating: _isAnimating,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(swipeProfilesProvider),
                child: Text(locale.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack({
    required SwipeProfile item,
    required CompatibilityResult compatibility,
    required SwipeProfile? nextItem,
    required CompatibilityResult? nextCompatibility,
  }) {
    final progress = _dragProgress;

    // Background card (next card) - slightly scaled and offset behind
    final Widget backgroundCard = nextItem != null && nextCompatibility != null
        ? Positioned(
            top: 8,
            left: 20,
            right: 20,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5 + 0.5 * progress,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * progress,
                  child: _CollapsedCard(
                    item: nextItem,
                    compatibility: nextCompatibility,
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    // Current card (topmost, draggable)
    final Widget currentCard = Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: () {
          if (!_isAnimating) {
            setState(() => _isExpanded = !_isExpanded);
          }
        },
        child: AnimatedBuilder(
          animation: _cardScaleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _currentRotation,
                child: Transform.scale(
                  scale: _cardScaleAnimation.value,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.08 + 0.15 * progress,
                              ),
                              blurRadius: 12 + 20 * progress,
                              spreadRadius: 2 + 6 * progress,
                              offset: Offset(0, 4 + 8 * progress),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      // Directional color tint overlay during drag
                      if (_isDragging && _dragOffset.dx != 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: _dragOffset.dx > 0
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: _dragProgress * 0.12)
                                    : const Color(
                                        0xFFFF6B6B,
                                      ).withValues(alpha: _dragProgress * 0.12),
                              ),
                            ),
                          ),
                        ),
                      // LIKE overlay (top-right, green)
                      if (_dragOffset.dx > 0)
                        Positioned(
                          top: 40,
                          right: 24,
                          child: Opacity(
                            opacity: _dragProgress,
                            child: Transform.rotate(
                              angle: 0.15,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'LIKE',
                                  style: TextStyle(
                                    color: const Color(0xFF10B981),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // NOPE overlay (top-left, red)
                      if (_dragOffset.dx < 0)
                        Positioned(
                          top: 40,
                          left: 24,
                          child: Opacity(
                            opacity: _dragProgress,
                            child: Transform.rotate(
                              angle: -0.15,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFFF6B6B),
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'NOPE',
                                  style: TextStyle(
                                    color: const Color(0xFFFF6B6B),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: _isExpanded
              ? _ExpandedCard(item: item, compatibility: compatibility)
              : _CollapsedCard(item: item, compatibility: compatibility),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [backgroundCard, currentCard],
    );
  }

  Future<void> _handleActionButton(String action) async {
    if (_isAnimating) return;

    // Haptic feedback on action bar button press
    HapticFeedback.lightImpact();

    if (action == 'super_like' && _superLikesRemaining <= 0) {
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.superLikeCapLabel(0))));
      return;
    }

    if (_swipesToday >= _swipesPerDayCap) {
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.swipeCounterLabel(0))));
      return;
    }

    // Determine fly-off direction
    switch (action) {
      case 'like':
        _flyOffDirectionX = 1;
        _flyOffDirectionY = 0;
        break;
      case 'pass':
        _flyOffDirectionX = -1;
        _flyOffDirectionY = 0;
        break;
      case 'super_like':
        _flyOffDirectionX = 0;
        _flyOffDirectionY = -1;
        break;
    }

    _flyOffStartOffset = Offset.zero;
    _dragOffset = Offset.zero;

    setState(() {
      _isAnimating = true;
    });

    // Detach listeners during button-triggered fly-off so we control the flow
    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);
    _flyOffController.addListener(_onButtonFlyOffTick);
    _flyOffController.addStatusListener(_onButtonFlyOffStatus);
    _flyOffController.forward(from: 0);
  }

  void _onButtonFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = Offset(
      _flyOffDirectionX != 0 ? _flyOffDirectionX * screenSize.width * 1.5 : 0.0,
      _flyOffDirectionY != 0
          ? _flyOffDirectionY * screenSize.height * 1.5
          : 0.0,
    );

    setState(() {
      _dragOffset = Offset.lerp(Offset.zero, targetOffset, t)!;
    });
  }

  void _onButtonFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    // Determine the action
    String action;
    if (_flyOffDirectionY < 0) {
      action = 'super_like';
    } else if (_flyOffDirectionX > 0) {
      action = 'like';
    } else {
      action = 'pass';
    }

    _flyOffController.removeListener(_onButtonFlyOffTick);
    _flyOffController.removeStatusListener(_onButtonFlyOffStatus);

    setState(() {
      _dragOffset = Offset.zero;
    });

    // Process the swipe action
    _processSwipeAction(action);
  }
}

class _CollapsedCard extends StatelessWidget {
  const _CollapsedCard({required this.item, required this.compatibility});

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: item.profileImageUrl != null
                          ? Image.network(
                              item.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _PhotoFallback(name: item.fullName),
                            )
                          : _PhotoFallback(name: item.fullName),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: InfoPill(
                        label: localizedFlatmatesModeLabel(
                          locale,
                          item.mode ?? 'open_to_both',
                        ),
                        highlighted: true,
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: CompatibilityRing(
                        percentage: compatibility.percentage,
                        size: 56,
                      ),
                    ),
                    if (item.listingDetails['verified'] == true)
                      Positioned(
                        right: 14,
                        top: 76,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fullName ?? '',
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (item.age != null || item.profession != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${item.age != null ? '${item.age}' : ''} ${item.profession ?? ''}'
                                .trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              [
                                item.locality,
                                item.city,
                              ].whereType<String>().join(', '),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        if (item.budgetMin != null ||
                            item.budgetMax != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...compatibility.topMatchChips.map((chip) {
                    return InfoPill(
                      icon: Icons.check_circle_outline,
                      label: chip,
                    );
                  }),
                  if (item.listingDetails['available_from'] != null) ...[
                    () {
                      final availableFrom = DateTime.tryParse(
                        item.listingDetails['available_from'].toString(),
                      );
                      if (availableFrom != null) {
                        final daysUntilMoveIn = availableFrom
                            .difference(DateTime.now())
                            .inDays;
                        if (daysUntilMoveIn == 0) {
                          return InfoPill(
                            icon: Icons.event_outlined,
                            label: locale.moveInToday,
                            highlighted: true,
                          );
                        } else if (daysUntilMoveIn >= 1 &&
                            daysUntilMoveIn <= 7) {
                          return InfoPill(
                            icon: Icons.event_outlined,
                            label: locale.moveInCountdownBadge(daysUntilMoveIn),
                            highlighted: true,
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    }(),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locale.tapToSeeMore,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _ExpandedCard extends StatelessWidget {
  const _ExpandedCard({required this.item, required this.compatibility});

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final details = item.listingDetails;

    // Helpers to read typed values from listingDetails.
    String? str(String key) {
      final v = details[key];
      return v is String ? v : null;
    }

    List<String> strList(String key) {
      final v = details[key];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    double? dbl(String key) {
      final v = details[key];
      if (v is num) return v.toDouble();
      return null;
    }

    List<Map<String, String>> flatmates() {
      final v = details['existing_flatmates'];
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map(
            (m) => Map<String, String>.from(
              m.map((k, val) => MapEntry(k.toString(), val?.toString() ?? '')),
            ),
          )
          .toList();
    }

    final societyAmenities = strList('society_amenities');
    final societyVibes = strList('society_vibes');
    final furnishing = strList('furnishing');
    final roomFeatures = strList('room_features');
    final flatAmenities = strList('flat_amenities');
    final existingFlatmates = flatmates();

    final monthlyRent = dbl('monthly_rent') ?? item.budgetMin;
    final securityDeposit = dbl('security_deposit');
    final maintenance = dbl('maintenance');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Header row: avatar + name + compatibility
            Row(
              children: [
                FlatmatesAvatar(
                  name: item.fullName,
                  imageUrl: item.profileImageUrl,
                  size: 64,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName ?? '',
                        style: theme.textTheme.headlineMedium,
                      ),
                      InfoPill(
                        label: localizedFlatmatesModeLabel(
                          locale,
                          item.mode ?? 'open_to_both',
                        ),
                        highlighted: true,
                      ),
                    ],
                  ),
                ),
                CompatibilityRing(percentage: compatibility.percentage),
              ],
            ),
            const SizedBox(height: 20),

            // About Me
            FlatmatesSectionHeader(title: locale.aboutMeSection),
            const SizedBox(height: 8),
            if (item.bio != null && item.bio!.isNotEmpty)
              Text(item.bio!, style: theme.textTheme.bodyLarge)
            else
              Text(locale.noBioYet, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // Compatibility Breakdown
            FlatmatesSectionHeader(title: locale.compatibilityBreakdown),
            const SizedBox(height: 12),
            CompatibilityBreakdown(result: compatibility),
            const SizedBox(height: 20),

            // --- The Society ---
            FlatmatesSectionHeader(title: locale.societySectionTitle),
            const SizedBox(height: 8),
            if (item.locality != null || item.city != null)
              _DetailRow(
                icon: Icons.location_on_outlined,
                text: [item.locality, item.city].whereType<String>().join(', '),
              ),
            if (str('society_name') != null)
              _DetailRow(
                icon: Icons.apartment_outlined,
                text: str('society_name')!,
              ),
            if (societyAmenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: societyAmenities
                      .map(
                        (a) => InfoPill(
                          icon: Icons.check_circle_outline,
                          label: humanizeFlatmatesToken(a),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (societyVibes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: societyVibes
                      .map(
                        (v) => InfoPill(
                          icon: Icons.wb_sunny_outlined,
                          label: humanizeFlatmatesToken(v),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (item.locality == null &&
                item.city == null &&
                str('society_name') == null &&
                societyAmenities.isEmpty &&
                societyVibes.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- The Room ---
            FlatmatesSectionHeader(title: locale.roomSectionTitle),
            const SizedBox(height: 8),
            if (str('room_type') != null)
              _DetailRow(
                icon: Icons.bed_outlined,
                text: humanizeFlatmatesToken(str('room_type')!),
              ),
            if (furnishing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: furnishing
                      .map(
                        (f) => InfoPill(
                          icon: Icons.chair_outlined,
                          label: humanizeFlatmatesToken(f),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (roomFeatures.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roomFeatures
                      .map(
                        (f) => InfoPill(
                          icon: Icons.window_outlined,
                          label: humanizeFlatmatesToken(f),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (str('room_type') == null &&
                furnishing.isEmpty &&
                roomFeatures.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- The Flat & Flatmates ---
            FlatmatesSectionHeader(title: locale.flatAndFlatmatesSectionTitle),
            const SizedBox(height: 8),
            if (str('flat_config') != null)
              _DetailRow(icon: Icons.home_outlined, text: str('flat_config')!),
            if (str('floor') != null)
              _DetailRow(icon: Icons.stairs_outlined, text: str('floor')!),
            if (flatAmenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: flatAmenities
                      .map(
                        (a) => InfoPill(
                          icon: Icons.kitchen_outlined,
                          label: humanizeFlatmatesToken(a),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (existingFlatmates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                locale.existingFlatmatesLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...existingFlatmates.map(
                (fm) => _FlatmateMiniProfile(
                  name: fm['name'] ?? '',
                  profession: fm['profession'] ?? '',
                  lifestyleChips:
                      fm['lifestyle_chips']
                          ?.split(',')
                          .where((c) => c.trim().isNotEmpty)
                          .toList() ??
                      const [],
                ),
              ),
            ],
            if (str('flat_config') == null &&
                flatAmenities.isEmpty &&
                existingFlatmates.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- Costs Breakdown ---
            FlatmatesSectionHeader(title: locale.costsBreakdownSectionTitle),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (monthlyRent != null)
                      _CostRow(
                        label: locale.monthlyRentRow,
                        value: '₹${monthlyRent.toStringAsFixed(0)}',
                      ),
                    if (securityDeposit != null)
                      _CostRow(
                        label: locale.securityDepositRow,
                        value: '₹${securityDeposit.toStringAsFixed(0)}',
                      ),
                    if (maintenance != null)
                      _CostRow(
                        label: locale.maintenanceRow,
                        value: '₹${maintenance.toStringAsFixed(0)}',
                      ),
                    if (monthlyRent != null) ...[
                      const Divider(height: 20),
                      _CostRow(
                        label: locale.estimatedTotalRow,
                        value:
                            '₹${(monthlyRent + (maintenance ?? 0)).toStringAsFixed(0)}',
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budget (original section, kept for budget range)
            if (item.budgetMin != null || item.budgetMax != null) ...[
              FlatmatesSectionHeader(title: locale.budgetLabel),
              const SizedBox(height: 8),
              InfoPill(
                icon: Icons.currency_rupee_rounded,
                label:
                    '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}/mo',
              ),
              const SizedBox(height: 20),
            ],
            if (item.moveInTimeline != null) ...[
              InfoPill(
                icon: Icons.event_outlined,
                label: localizedFlatmatesMoveInTimeline(
                  locale,
                  item.moveInTimeline!,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  locale.tapToCollapse,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single icon + text row used inside expanded card sections.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Cost row with label on left and value on right.
class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isBold ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini profile card for an existing flatmate shown in the expanded card.
class _FlatmateMiniProfile extends StatelessWidget {
  const _FlatmateMiniProfile({
    required this.name,
    required this.profession,
    required this.lifestyleChips,
  });
  final String name;
  final String profession;
  final List<String> lifestyleChips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          FlatmatesAvatar(name: name, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (profession.isNotEmpty)
                  Text(profession, style: theme.textTheme.bodySmall),
                if (lifestyleChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: lifestyleChips
                          .map((c) => InfoPill(label: c))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.isAnimating,
  });

  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            key: const Key('swipe_pass'),
            icon: Icons.close_rounded,
            color: const Color(0xFFFF6B6B),
            size: 60,
            onPressed: isAnimating ? null : onPass,
          ),
          _ActionButton(
            key: const Key('swipe_super_like'),
            icon: Icons.star_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            size: 50,
            onPressed: isAnimating ? null : onSuperLike,
          ),
          _ActionButton(
            key: const Key('swipe_like'),
            icon: Icons.favorite_rounded,
            color: const Color(0xFF10B981),
            size: 60,
            onPressed: isAnimating ? null : onLike,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(name),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 48,
          ),
        ),
      ),
    );
  }
}

String localizedFlatmatesMoveInTimeline(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'immediate':
      return locale.timelineImmediate;
    case 'this_month':
      return locale.timelineThisMonth;
    case 'next_month':
      return locale.timelineNextMonth;
    case 'flexible':
      return locale.timelineFlexible;
    default:
      return humanizeFlatmatesToken(value);
  }
}
````

## File: lib/features/swipe/swipe_repository.dart
````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';

class SwipeProfile {
  const SwipeProfile({
    required this.id,
    required this.fullName,
    required this.profileImageUrl,
    required this.mode,
    required this.city,
    required this.locality,
    required this.bio,
    required this.budgetMin,
    required this.budgetMax,
    required this.moveInTimeline,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.foodHabits,
    required this.smokingDrinking,
    required this.guestsPolicy,
    required this.workStyle,
    required this.gender,
    required this.nonNegotiables,
    required this.hasPets,
    required this.partyHabit,
    required this.listingDetails,
    this.age,
    this.profession,
  });

  final int id;
  final String? fullName;
  final String? profileImageUrl;
  final String? mode;
  final String? city;
  final String? locality;
  final String? bio;
  final double? budgetMin;
  final double? budgetMax;
  final String? moveInTimeline;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final String? workStyle;
  final String? gender;
  final List<String> nonNegotiables;
  final bool hasPets;
  final String? partyHabit;
  final int? age;
  final String? profession;

  /// Extra listing detail fields from the API response.
  /// Expected keys:
  ///   - 'society_name' (`String`)
  ///   - 'society_type' (`String`)
  ///   - 'society_amenities' (`List<String>`)
  ///   - 'society_vibes' (`List<String>`)
  ///   - 'room_type' (`String`)
  ///   - 'furnishing' (`List<String>`)
  ///   - 'room_features' (`List<String>`)
  ///   - 'flat_config' (`String`, e.g. "2 BHK")
  ///   - 'floor' (`String`)
  ///   - 'total_floors' (`String`)
  ///   - 'flat_amenities' (`List<String>`)
  ///   - 'monthly_rent' (`double`)
  ///   - 'security_deposit' (`double`)
  ///   - 'maintenance' (`double`)
  ///   - 'existing_flatmates' (`List<Map<String, String>>`)
  ///     each with keys: 'name', 'profession', 'lifestyle_chips'
  final Map<String, dynamic> listingDetails;

  factory SwipeProfile.fromJson(Map<String, dynamic> json) {
    // Extract known listing detail keys from the JSON response, if present.
    final listingKeys = <String>[
      'society_name',
      'society_type',
      'society_amenities',
      'society_vibes',
      'room_type',
      'furnishing',
      'room_features',
      'flat_config',
      'floor',
      'total_floors',
      'flat_amenities',
      'monthly_rent',
      'security_deposit',
      'maintenance',
      'existing_flatmates',
      'available_from',
    ];
    final details = <String, dynamic>{};
    for (final key in listingKeys) {
      if (json.containsKey(key)) {
        details[key] = json[key];
      }
    }

    return SwipeProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      bio: json['bio'] as String?,
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      moveInTimeline: json['move_in_timeline'] as String?,
      sleepSchedule: json['sleep_schedule'] as String?,
      cleanliness: json['cleanliness'] as String?,
      foodHabits: json['food_habits'] as String?,
      smokingDrinking: json['smoking_drinking'] as String?,
      guestsPolicy: json['guests_policy'] as String?,
      workStyle: json['work_style'] as String?,
      gender: json['gender'] as String?,
      nonNegotiables:
          (json['non_negotiables'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hasPets: json['has_pets'] as bool? ?? false,
      partyHabit: json['party_habit'] as String?,
      listingDetails: details,
      age: (json['age'] as num?)?.toInt(),
      profession: json['profession'] as String?,
    );
  }
}

class SwipeResult {
  const SwipeResult({required this.didMatch, this.conversationId});

  final bool didMatch;
  final int? conversationId;
}

class SwipeRepository {
  const SwipeRepository(this._ref);

  final Ref _ref;

  Future<List<SwipeProfile>> fetchSwipeProfiles() async {
    final bootstrap = _ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;
    final userNonNegotiables = _extractUserNonNegotiables(
      userProfile?.preferences,
    );

    final queryParams = <String, dynamic>{};
    if (userNonNegotiables.isNotEmpty) {
      queryParams['non_negotiables'] = userNonNegotiables.join(',');
    }
    if (userProfile?.genderPreference != null &&
        userProfile!.genderPreference != 'any') {
      queryParams['gender_preference'] = userProfile.genderPreference;
    }

    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/profiles', queryParameters: queryParams);
    final rows = (response.data as List? ?? const []);
    final profiles = rows
        .map(
          (item) =>
              SwipeProfile.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    return _applyDealBreakerFilter(profiles, userNonNegotiables, userProfile);
  }

  /// Extract non-negotiables from user preferences map stored in bootstrap.
  List<String> _extractUserNonNegotiables(Map<String, dynamic>? preferences) {
    if (preferences == null) return const [];
    final raw = preferences['non_negotiables'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Filter out profiles that conflict with the current user's non-negotiables.
  List<SwipeProfile> _applyDealBreakerFilter(
    List<SwipeProfile> profiles,
    List<String> userNonNegotiables,
    FlatmatesProfileModel? user,
  ) {
    if (userNonNegotiables.isEmpty) return profiles;

    return profiles.where((peer) {
      for (final neg in userNonNegotiables) {
        switch (neg) {
          // Food: vegetarian/vegan user cannot match with non-vegetarian peer
          case 'food_veg_only':
          case 'food_vegan_only':
            final peerFood = peer.foodHabits ?? 'no_preference';
            if (peerFood == 'non_vegetarian' || peerFood == 'non_veg') {
              return false;
            }
            break;
          // Smoking: user requires non-smoker, peer smokes
          case 'no_smoking':
            final peerSD = peer.smokingDrinking ?? 'neither';
            if (peerSD == 'smoke_outside' || peerSD == 'both_fine') {
              return false;
            }
            break;
          // Drinking: user requires no alcohol, peer drinks
          case 'no_drinking':
            final peerSD = peer.smokingDrinking ?? 'neither';
            if (peerSD == 'drink_occasionally' || peerSD == 'both_fine') {
              return false;
            }
            break;
          // Guests: user requires no overnight guests, peer has open house
          case 'no_overnight_guests':
            if (peer.guestsPolicy == 'open_house' ||
                peer.guestsPolicy == 'comfortable') {
              return false;
            }
            break;
          // Pets: user requires no pets, peer has pets
          case 'no_pets':
            if (peer.hasPets) return false;
            break;
          // Gender: user requires specific gender
          case 'gender_female_only':
            if (peer.gender != null && peer.gender != 'female') return false;
            break;
          case 'gender_male_only':
            if (peer.gender != null && peer.gender != 'male') return false;
            break;
          // Partying: user requires no parties, peer is party-friendly
          case 'no_parties':
            if (peer.partyHabit == 'party_friendly') return false;
            break;
          // Hygiene: user requires minimum tidy, peer is minimal
          case 'min_tidy':
            if (peer.cleanliness == 'minimal') return false;
            break;
        }
      }
      return true;
    }).toList();
  }

  Future<SwipeResult> swipeProfile({
    required int targetUserId,
    required String action,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          '/flatmates/swipes',
          data: {
            'target_type': 'user',
            'action': action,
            'target_user_id': targetUserId,
          },
        );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return SwipeResult(
      didMatch: data['did_match'] as bool? ?? false,
      conversationId: (data['conversation_id'] as num?)?.toInt(),
    );
  }
}

final swipeRepositoryProvider = Provider<SwipeRepository>(
  (ref) => SwipeRepository(ref),
);

final swipeProfilesProvider = FutureProvider<List<SwipeProfile>>((ref) {
  return ref.watch(swipeRepositoryProvider).fetchSwipeProfiles();
});
````

## File: maestro/e2e.yaml
````yaml
# 360 FlatMates — Maestro E2E Flow
# Prerequisites:
#   - Seeded Supabase user: phone +91 9999999999, OTP: 123456
#   - At least 1 flatmate listing in the backend
#   - App installed on iOS Simulator or Android Emulator

appId: com.the360ghar.flatmates
---
- launchApp
- assertVisible: "Get Started"
- tapOn: "Get Started"

# Mode selection
- assertVisible: "Room Poster"
- tapOn: "Co-Hunter"

# Basic info
- assertVisible: "Full name"
- tapOn: "Full name"
- inputText: "Test User"
- tapOn: "Age"
- inputText: "25"
- tapOn: "Profession"
- inputText: "Software Engineer"
- tapOn: "City"
- inputText: "Bangalore"
- tapOn: "Next"

# Profile photo (skip — no gallery in CI)
- tapOn: "Next"

# Lifestyle quiz — select first option for each
- tapOn:
    text: "Early bird"
    optional: true
- tapOn:
    text: "Tidy"
    optional: true
- tapOn:
    text: "Vegetarian"
    optional: true
- tapOn:
    text: "Neither"
    optional: true
- tapOn:
    text: "Occasional guests are ok"
    optional: true
- tapOn:
    text: "Never"
    optional: true
- tapOn:
    text: "Office mostly"
    optional: true
- tapOn:
    text: "No pets"
    optional: true
- tapOn: "Next"

# Budget & timeline
- tapOn: "Flexible"
- tapOn: "Complete"

# Wait for discover page
- assertVisible:
    text: "Picked for You"
    optional: true
- assertVisible:
    text: "Discover"
    optional: true

# Navigate to swipe tab
- tapOn: "Swipe"
- assertVisible:
    text: "remaining"
    optional: true

# Navigate to chats
- tapOn: "Likes & Chat"
- assertVisible:
    text: "Likes"
    optional: true

# Navigate to profile
- tapOn: "Profile"
- assertVisible: "Test User"
- assertVisible: "Co-Hunter"

# Navigate to settings
- tapOn: "Settings"
- assertVisible: "Appearance"
````

## File: pubspec.lock
````
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  _flutterfire_internals:
    dependency: transitive
    description:
      name: _flutterfire_internals
      sha256: ff0a84a2734d9e1089f8aedd5c0af0061b82fb94e95260d943404e0ef2134b11
      url: "https://pub.dev"
    source: hosted
    version: "1.3.59"
  app_links:
    dependency: "direct main"
    description:
      name: app_links
      sha256: "5f88447519add627fe1cbcab4fd1da3d4fed15b9baf29f28b22535c95ecee3e8"
      url: "https://pub.dev"
    source: hosted
    version: "6.4.1"
  app_links_linux:
    dependency: transitive
    description:
      name: app_links_linux
      sha256: f5f7173a78609f3dfd4c2ff2c95bd559ab43c80a87dc6a095921d96c05688c81
      url: "https://pub.dev"
    source: hosted
    version: "1.0.3"
  app_links_platform_interface:
    dependency: transitive
    description:
      name: app_links_platform_interface
      sha256: "05f5379577c513b534a29ddea68176a4d4802c46180ee8e2e966257158772a3f"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.2"
  app_links_web:
    dependency: transitive
    description:
      name: app_links_web
      sha256: af060ed76183f9e2b87510a9480e56a5352b6c249778d07bd2c95fc35632a555
      url: "https://pub.dev"
    source: hosted
    version: "1.0.4"
  archive:
    dependency: transitive
    description:
      name: archive
      sha256: a96e8b390886ee8abb49b7bd3ac8df6f451c621619f52a26e815fdcf568959ff
      url: "https://pub.dev"
    source: hosted
    version: "4.0.9"
  args:
    dependency: transitive
    description:
      name: args
      sha256: d0481093c50b1da8910eb0bb301626d4d8eb7284aa739614d2b394ee09e3ea04
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  async:
    dependency: transitive
    description:
      name: async
      sha256: e2eb0491ba5ddb6177742d2da23904574082139b07c1e33b8503b9f46f3e1a37
      url: "https://pub.dev"
    source: hosted
    version: "2.13.1"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      sha256: "8aab1771e1243a5063b8b0ff68042d67334e3feab9e95b9490f9a6ebf73b42ea"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  cached_network_image:
    dependency: "direct main"
    description:
      name: cached_network_image
      sha256: "7c1183e361e5c8b0a0f21a28401eecdbde252441106a9816400dd4c2b2424916"
      url: "https://pub.dev"
    source: hosted
    version: "3.4.1"
  cached_network_image_platform_interface:
    dependency: transitive
    description:
      name: cached_network_image_platform_interface
      sha256: "35814b016e37fbdc91f7ae18c8caf49ba5c88501813f73ce8a07027a395e2829"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.1"
  cached_network_image_web:
    dependency: transitive
    description:
      name: cached_network_image_web
      sha256: "980842f4e8e2535b8dbd3d5ca0b1f0ba66bf61d14cc3a17a9b4788a3685ba062"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.1"
  characters:
    dependency: transitive
    description:
      name: characters
      sha256: faf38497bda5ead2a8c7615f4f7939df04333478bf32e4173fcb06d428b5716b
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  checked_yaml:
    dependency: transitive
    description:
      name: checked_yaml
      sha256: "959525d3162f249993882720d52b7e0c833978df229be20702b33d48d91de70f"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.4"
  cli_util:
    dependency: transitive
    description:
      name: cli_util
      sha256: ff6785f7e9e3c38ac98b2fb035701789de90154024a75b6cb926445e83197d1c
      url: "https://pub.dev"
    source: hosted
    version: "0.4.2"
  clock:
    dependency: transitive
    description:
      name: clock
      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  code_assets:
    dependency: transitive
    description:
      name: code_assets
      sha256: "83ccdaa064c980b5596c35dd64a8d3ecc68620174ab9b90b6343b753aa721687"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  collection:
    dependency: transitive
    description:
      name: collection
      sha256: "2f5709ae4d3d59dd8f7cd309b4e023046b57d8a6c82130785d2b0e5868084e76"
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  confetti:
    dependency: "direct main"
    description:
      name: confetti
      sha256: "979aafde2428c53947892c95eb244466c109c129b7eee9011f0a66caaca52267"
      url: "https://pub.dev"
    source: hosted
    version: "0.7.0"
  connectivity_plus:
    dependency: "direct main"
    description:
      name: connectivity_plus
      sha256: b5e72753cf63becce2c61fd04dfe0f1c430cc5278b53a1342dc5ad839eab29ec
      url: "https://pub.dev"
    source: hosted
    version: "6.1.5"
  connectivity_plus_platform_interface:
    dependency: transitive
    description:
      name: connectivity_plus_platform_interface
      sha256: "3c09627c536d22fd24691a905cdd8b14520de69da52c7a97499c8be5284a32ed"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  convert:
    dependency: transitive
    description:
      name: convert
      sha256: b30acd5944035672bc15c6b7a8b47d773e41e2f17de064350988c5d02adb1c68
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  cross_file:
    dependency: transitive
    description:
      name: cross_file
      sha256: "28bb3ae56f117b5aec029d702a90f57d285cd975c3c5c281eaca38dbc47c5937"
      url: "https://pub.dev"
    source: hosted
    version: "0.3.5+2"
  crypto:
    dependency: transitive
    description:
      name: crypto
      sha256: c8ea0233063ba03258fbcf2ca4d6dadfefe14f02fab57702265467a19f27fadf
      url: "https://pub.dev"
    source: hosted
    version: "3.0.7"
  csslib:
    dependency: transitive
    description:
      name: csslib
      sha256: "09bad715f418841f976c77db72d5398dc1253c21fb9c0c7f0b0b985860b2d58e"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.2"
  cupertino_icons:
    dependency: "direct main"
    description:
      name: cupertino_icons
      sha256: "41e005c33bd814be4d3096aff55b1908d419fde52ca656c8c47719ec745873cd"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.9"
  dart_jsonwebtoken:
    dependency: transitive
    description:
      name: dart_jsonwebtoken
      sha256: ad84e60181696513d04d5f2078e0bbc20365b911f46f647797317414bdc88fbe
      url: "https://pub.dev"
    source: hosted
    version: "3.4.1"
  dbus:
    dependency: transitive
    description:
      name: dbus
      sha256: d0c98dcd4f5169878b6cf8f6e0a52403a9dff371a3e2f019697accbf6f44a270
      url: "https://pub.dev"
    source: hosted
    version: "0.7.12"
  dio:
    dependency: "direct main"
    description:
      name: dio
      sha256: aff32c08f92787a557dd5c0145ac91536481831a01b4648136373cddb0e64f8c
      url: "https://pub.dev"
    source: hosted
    version: "5.9.2"
  dio_web_adapter:
    dependency: transitive
    description:
      name: dio_web_adapter
      sha256: "2f9e64323a7c3c7ef69567d5c800424a11f8337b8b228bad02524c9fb3c1f340"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      sha256: "5368f224a74523e8d2e7399ea1638b37aecfca824a3cc4dfdf77bf1fa905ac44"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.3"
  ffi:
    dependency: transitive
    description:
      name: ffi
      sha256: "6d7fd89431262d8f3125e81b50d3847a091d846eafcd4fdb88dd06f36d705a45"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  file:
    dependency: transitive
    description:
      name: file
      sha256: a3b4f84adafef897088c160faf7dfffb7696046cb13ae90b508c2cbc95d3b8d4
      url: "https://pub.dev"
    source: hosted
    version: "7.0.1"
  file_selector_linux:
    dependency: transitive
    description:
      name: file_selector_linux
      sha256: "2567f398e06ac72dcf2e98a0c95df2a9edd03c2c2e0cacd4780f20cdf56263a0"
      url: "https://pub.dev"
    source: hosted
    version: "0.9.4"
  file_selector_macos:
    dependency: transitive
    description:
      name: file_selector_macos
      sha256: "5e0bbe9c312416f1787a68259ea1505b52f258c587f12920422671807c4d618a"
      url: "https://pub.dev"
    source: hosted
    version: "0.9.5"
  file_selector_platform_interface:
    dependency: transitive
    description:
      name: file_selector_platform_interface
      sha256: "35e0bd61ebcdb91a3505813b055b09b79dfdc7d0aee9c09a7ba59ae4bb13dc85"
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  file_selector_windows:
    dependency: transitive
    description:
      name: file_selector_windows
      sha256: "62197474ae75893a62df75939c777763d39c2bc5f73ce5b88497208bc269abfd"
      url: "https://pub.dev"
    source: hosted
    version: "0.9.3+5"
  firebase_core:
    dependency: "direct main"
    description:
      name: firebase_core
      sha256: "7be63a3f841fc9663342f7f3a011a42aef6a61066943c90b1c434d79d5c995c5"
      url: "https://pub.dev"
    source: hosted
    version: "3.15.2"
  firebase_core_platform_interface:
    dependency: transitive
    description:
      name: firebase_core_platform_interface
      sha256: "0ecda14c1bfc9ed8cac303dd0f8d04a320811b479362a9a4efb14fd331a473ce"
      url: "https://pub.dev"
    source: hosted
    version: "6.0.3"
  firebase_core_web:
    dependency: transitive
    description:
      name: firebase_core_web
      sha256: "0ed0dc292e8f9ac50992e2394e9d336a0275b6ae400d64163fdf0a8a8b556c37"
      url: "https://pub.dev"
    source: hosted
    version: "2.24.1"
  firebase_messaging:
    dependency: "direct main"
    description:
      name: firebase_messaging
      sha256: "60be38574f8b5658e2f22b7e311ff2064bea835c248424a383783464e8e02fcc"
      url: "https://pub.dev"
    source: hosted
    version: "15.2.10"
  firebase_messaging_platform_interface:
    dependency: transitive
    description:
      name: firebase_messaging_platform_interface
      sha256: "685e1771b3d1f9c8502771ccc9f91485b376ffe16d553533f335b9183ea99754"
      url: "https://pub.dev"
    source: hosted
    version: "4.6.10"
  firebase_messaging_web:
    dependency: transitive
    description:
      name: firebase_messaging_web
      sha256: "0d1be17bc89ed3ff5001789c92df678b2e963a51b6fa2bdb467532cc9dbed390"
      url: "https://pub.dev"
    source: hosted
    version: "3.10.10"
  fixnum:
    dependency: transitive
    description:
      name: fixnum
      sha256: b6dc7065e46c974bc7c5f143080a6764ec7a4be6da1285ececdc37be96de53be
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_cache_manager:
    dependency: transitive
    description:
      name: flutter_cache_manager
      sha256: "400b6592f16a4409a7f2bb929a9a7e38c72cceb8ffb99ee57bbf2cb2cecf8386"
      url: "https://pub.dev"
    source: hosted
    version: "3.4.1"
  flutter_dotenv:
    dependency: "direct main"
    description:
      name: flutter_dotenv
      sha256: b7c7be5cd9f6ef7a78429cabd2774d3c4af50e79cb2b7593e3d5d763ef95c61b
      url: "https://pub.dev"
    source: hosted
    version: "5.2.1"
  flutter_launcher_icons:
    dependency: "direct dev"
    description:
      name: flutter_launcher_icons
      sha256: "10f13781741a2e3972126fae08393d3c4e01fa4cd7473326b94b72cf594195e7"
      url: "https://pub.dev"
    source: hosted
    version: "0.14.4"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      sha256: "3105dc8492f6183fb076ccf1f351ac3d60564bff92e20bfc4af9cc1651f4e7e1"
      url: "https://pub.dev"
    source: hosted
    version: "6.0.0"
  flutter_local_notifications:
    dependency: "direct main"
    description:
      name: flutter_local_notifications
      sha256: ef41ae901e7529e52934feba19ed82827b11baa67336829564aeab3129460610
      url: "https://pub.dev"
    source: hosted
    version: "18.0.1"
  flutter_local_notifications_linux:
    dependency: transitive
    description:
      name: flutter_local_notifications_linux
      sha256: "8f685642876742c941b29c32030f6f4f6dacd0e4eaecb3efbb187d6a3812ca01"
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
  flutter_local_notifications_platform_interface:
    dependency: transitive
    description:
      name: flutter_local_notifications_platform_interface
      sha256: "6c5b83c86bf819cdb177a9247a3722067dd8cc6313827ce7c77a4b238a26fd52"
      url: "https://pub.dev"
    source: hosted
    version: "8.0.0"
  flutter_localizations:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_plugin_android_lifecycle:
    dependency: transitive
    description:
      name: flutter_plugin_android_lifecycle
      sha256: "38d1c268de9097ff59cf0e844ac38759fc78f76836d37edad06fa21e182055a0"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.34"
  flutter_riverpod:
    dependency: "direct main"
    description:
      name: flutter_riverpod
      sha256: "9532ee6db4a943a1ed8383072a2e3eeda041db5657cdf6d2acecf3c21ecbe7e1"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  flutter_secure_storage:
    dependency: "direct main"
    description:
      name: flutter_secure_storage
      sha256: "9cad52d75ebc511adfae3d447d5d13da15a55a92c9410e50f67335b6d21d16ea"
      url: "https://pub.dev"
    source: hosted
    version: "9.2.4"
  flutter_secure_storage_linux:
    dependency: transitive
    description:
      name: flutter_secure_storage_linux
      sha256: be76c1d24a97d0b98f8b54bce6b481a380a6590df992d0098f868ad54dc8f688
      url: "https://pub.dev"
    source: hosted
    version: "1.2.3"
  flutter_secure_storage_macos:
    dependency: transitive
    description:
      name: flutter_secure_storage_macos
      sha256: "6c0a2795a2d1de26ae202a0d78527d163f4acbb11cde4c75c670f3a0fc064247"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
  flutter_secure_storage_platform_interface:
    dependency: transitive
    description:
      name: flutter_secure_storage_platform_interface
      sha256: cf91ad32ce5adef6fba4d736a542baca9daf3beac4db2d04be350b87f69ac4a8
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  flutter_secure_storage_web:
    dependency: transitive
    description:
      name: flutter_secure_storage_web
      sha256: f4ebff989b4f07b2656fb16b47852c0aab9fed9b4ec1c70103368337bc1886a9
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  flutter_secure_storage_windows:
    dependency: transitive
    description:
      name: flutter_secure_storage_windows
      sha256: b20b07cb5ed4ed74fc567b78a72936203f587eba460af1df11281c9326cd3709
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_web_plugins:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  functions_client:
    dependency: transitive
    description:
      name: functions_client
      sha256: "94074d62167ae634127ef6095f536835063a7dc80f2b1aa306d2346ff9023996"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.0"
  geocoding:
    dependency: "direct main"
    description:
      name: geocoding
      sha256: d580c801cba9386b4fac5047c4c785a4e19554f46be42f4f5e5b7deacd088a66
      url: "https://pub.dev"
    source: hosted
    version: "3.0.0"
  geocoding_android:
    dependency: transitive
    description:
      name: geocoding_android
      sha256: "1b13eca79b11c497c434678fed109c2be020b158cec7512c848c102bc7232603"
      url: "https://pub.dev"
    source: hosted
    version: "3.3.1"
  geocoding_ios:
    dependency: transitive
    description:
      name: geocoding_ios
      sha256: "18ab1c8369e2b0dcb3a8ccc907319334f35ee8cf4cfef4d9c8e23b13c65cb825"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.0"
  geocoding_platform_interface:
    dependency: transitive
    description:
      name: geocoding_platform_interface
      sha256: "8c2c8226e5c276594c2e18bfe88b19110ed770aeb7c1ab50ede570be8b92229b"
      url: "https://pub.dev"
    source: hosted
    version: "3.2.0"
  geolocator:
    dependency: "direct main"
    description:
      name: geolocator
      sha256: f62bcd90459e63210bbf9c35deb6a51c521f992a78de19a1fe5c11704f9530e2
      url: "https://pub.dev"
    source: hosted
    version: "13.0.4"
  geolocator_android:
    dependency: transitive
    description:
      name: geolocator_android
      sha256: fcb1760a50d7500deca37c9a666785c047139b5f9ee15aa5469fae7dbbe3170d
      url: "https://pub.dev"
    source: hosted
    version: "4.6.2"
  geolocator_apple:
    dependency: transitive
    description:
      name: geolocator_apple
      sha256: dbdd8789d5aaf14cf69f74d4925ad1336b4433a6efdf2fce91e8955dc921bf22
      url: "https://pub.dev"
    source: hosted
    version: "2.3.13"
  geolocator_platform_interface:
    dependency: transitive
    description:
      name: geolocator_platform_interface
      sha256: "30cb64f0b9adcc0fb36f628b4ebf4f731a2961a0ebd849f4b56200205056fe67"
      url: "https://pub.dev"
    source: hosted
    version: "4.2.6"
  geolocator_web:
    dependency: transitive
    description:
      name: geolocator_web
      sha256: b1ae9bdfd90f861fde8fd4f209c37b953d65e92823cb73c7dee1fa021b06f172
      url: "https://pub.dev"
    source: hosted
    version: "4.1.3"
  geolocator_windows:
    dependency: transitive
    description:
      name: geolocator_windows
      sha256: "175435404d20278ffd220de83c2ca293b73db95eafbdc8131fe8609be1421eb6"
      url: "https://pub.dev"
    source: hosted
    version: "0.2.5"
  glob:
    dependency: transitive
    description:
      name: glob
      sha256: c3f1ee72c96f8f78935e18aa8cecced9ab132419e8625dc187e1c2408efc20de
      url: "https://pub.dev"
    source: hosted
    version: "2.1.3"
  go_router:
    dependency: "direct main"
    description:
      name: go_router
      sha256: d8f590a69729f719177ea68eb1e598295e8dbc41bbc247fed78b2c8a25660d7c
      url: "https://pub.dev"
    source: hosted
    version: "16.3.0"
  google_fonts:
    dependency: "direct main"
    description:
      name: google_fonts
      sha256: ba03d03bcaa2f6cb7bd920e3b5027181db75ab524f8891c8bc3aa603885b8055
      url: "https://pub.dev"
    source: hosted
    version: "6.3.3"
  google_maps:
    dependency: transitive
    description:
      name: google_maps
      sha256: "5d410c32112d7c6eb7858d359275b2aa04778eed3e36c745aeae905fb2fa6468"
      url: "https://pub.dev"
    source: hosted
    version: "8.2.0"
  google_maps_flutter:
    dependency: "direct main"
    description:
      name: google_maps_flutter
      sha256: fc714bf8072e2c121d4277cb6dca23bbfae954b6c7b5d6dd73f1bc8d09762921
      url: "https://pub.dev"
    source: hosted
    version: "2.17.0"
  google_maps_flutter_android:
    dependency: transitive
    description:
      name: google_maps_flutter_android
      sha256: f1eb5ffa34ba41f8591e53ce439f78af179a506e8386a1297d0ecd202e05c734
      url: "https://pub.dev"
    source: hosted
    version: "2.19.8"
  google_maps_flutter_ios:
    dependency: transitive
    description:
      name: google_maps_flutter_ios
      sha256: "5ed8d8d0f93dfa7f5039c409c500948e98e59068f8f6fcf9105bfd07e3709d7f"
      url: "https://pub.dev"
    source: hosted
    version: "2.18.1"
  google_maps_flutter_platform_interface:
    dependency: transitive
    description:
      name: google_maps_flutter_platform_interface
      sha256: ddbe34435dfb34e83fca295c6a8dcc53c3b51487e9eec3c737ce4ae605574347
      url: "https://pub.dev"
    source: hosted
    version: "2.15.0"
  google_maps_flutter_web:
    dependency: transitive
    description:
      name: google_maps_flutter_web
      sha256: "6cefe4ef4cc61dc0dfba4c413dec4bd105cb6b9461bfbe1465ddd09f80af377d"
      url: "https://pub.dev"
    source: hosted
    version: "0.6.2"
  gotrue:
    dependency: transitive
    description:
      name: gotrue
      sha256: "7a4172601553e61716f5c3dd243aa3297e13308e07eb85b7853c941ba585dcf5"
      url: "https://pub.dev"
    source: hosted
    version: "2.20.0"
  gtk:
    dependency: transitive
    description:
      name: gtk
      sha256: e8ce9ca4b1df106e4d72dad201d345ea1a036cc12c360f1a7d5a758f78ffa42c
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  hooks:
    dependency: transitive
    description:
      name: hooks
      sha256: "025f060e86d2d4c3c47b56e33caf7f93bf9283340f26d23424ebcfccf34f621e"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.3"
  html:
    dependency: transitive
    description:
      name: html
      sha256: "6d1264f2dffa1b1101c25a91dff0dc2daee4c18e87cd8538729773c073dbf602"
      url: "https://pub.dev"
    source: hosted
    version: "0.15.6"
  http:
    dependency: transitive
    description:
      name: http
      sha256: "87721a4a50b19c7f1d49001e51409bddc46303966ce89a65af4f4e6004896412"
      url: "https://pub.dev"
    source: hosted
    version: "1.6.0"
  http_parser:
    dependency: transitive
    description:
      name: http_parser
      sha256: "178d74305e7866013777bab2c3d8726205dc5a4dd935297175b19a23a2e66571"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.2"
  image:
    dependency: transitive
    description:
      name: image
      sha256: f9881ff4998044947ec38d098bc7c8316ae1186fa786eddffdb867b9bc94dfce
      url: "https://pub.dev"
    source: hosted
    version: "4.8.0"
  image_picker:
    dependency: "direct main"
    description:
      name: image_picker
      sha256: "784210112be18ea55f69d7076e2c656a4e24949fa9e76429fe53af0c0f4fa320"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  image_picker_android:
    dependency: transitive
    description:
      name: image_picker_android
      sha256: "66810af8e99b2657ee98e5c6f02064f69bb63f7a70e343937f70946c5f8c6622"
      url: "https://pub.dev"
    source: hosted
    version: "0.8.13+16"
  image_picker_for_web:
    dependency: transitive
    description:
      name: image_picker_for_web
      sha256: "66257a3191ab360d23a55c8241c91a6e329d31e94efa7be9cf7a212e65850214"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.1"
  image_picker_ios:
    dependency: transitive
    description:
      name: image_picker_ios
      sha256: b9c4a438a9ff4f60808c9cf0039b93a42bb6c2211ef6ebb647394b2b3fa84588
      url: "https://pub.dev"
    source: hosted
    version: "0.8.13+6"
  image_picker_linux:
    dependency: transitive
    description:
      name: image_picker_linux
      sha256: "1f81c5f2046b9ab724f85523e4af65be1d47b038160a8c8deed909762c308ed4"
      url: "https://pub.dev"
    source: hosted
    version: "0.2.2"
  image_picker_macos:
    dependency: transitive
    description:
      name: image_picker_macos
      sha256: "86f0f15a309de7e1a552c12df9ce5b59fe927e71385329355aec4776c6a8ec91"
      url: "https://pub.dev"
    source: hosted
    version: "0.2.2+1"
  image_picker_platform_interface:
    dependency: transitive
    description:
      name: image_picker_platform_interface
      sha256: "567e056716333a1647c64bb6bd873cff7622233a5c3f694be28a583d4715690c"
      url: "https://pub.dev"
    source: hosted
    version: "2.11.1"
  image_picker_windows:
    dependency: transitive
    description:
      name: image_picker_windows
      sha256: d248c86554a72b5495a31c56f060cf73a41c7ff541689327b1a7dbccc33adfae
      url: "https://pub.dev"
    source: hosted
    version: "0.2.2"
  intl:
    dependency: "direct main"
    description:
      name: intl
      sha256: "3df61194eb431efc39c4ceba583b95633a403f46c9fd341e550ce0bfa50e9aa5"
      url: "https://pub.dev"
    source: hosted
    version: "0.20.2"
  jni:
    dependency: transitive
    description:
      name: jni
      sha256: c2230682d5bc2362c1c9e8d3c7f406d9cbba23ab3f2e203a025dd47e0fb2e68f
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  jni_flutter:
    dependency: transitive
    description:
      name: jni_flutter
      sha256: "8b59e590786050b1cd866677dddaf76b1ade5e7bc751abe04b86e84d379d3ba6"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.1"
  js:
    dependency: transitive
    description:
      name: js
      sha256: f2c445dce49627136094980615a031419f7f3eb393237e4ecd97ac15dea343f3
      url: "https://pub.dev"
    source: hosted
    version: "0.6.7"
  json_annotation:
    dependency: transitive
    description:
      name: json_annotation
      sha256: cb09e7dac6210041fad964ed7fbee004f14258b4eca4040f72d1234062ace4c8
      url: "https://pub.dev"
    source: hosted
    version: "4.11.0"
  jwt_decode:
    dependency: transitive
    description:
      name: jwt_decode
      sha256: d2e9f68c052b2225130977429d30f187aa1981d789c76ad104a32243cfdebfbb
      url: "https://pub.dev"
    source: hosted
    version: "0.3.1"
  leak_tracker:
    dependency: transitive
    description:
      name: leak_tracker
      sha256: "33e2e26bdd85a0112ec15400c8cbffea70d0f9c3407491f672a2fad47915e2de"
      url: "https://pub.dev"
    source: hosted
    version: "11.0.2"
  leak_tracker_flutter_testing:
    dependency: transitive
    description:
      name: leak_tracker_flutter_testing
      sha256: "1dbc140bb5a23c75ea9c4811222756104fbcd1a27173f0c34ca01e16bea473c1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.10"
  leak_tracker_testing:
    dependency: transitive
    description:
      name: leak_tracker_testing
      sha256: "8d5a2d49f4a66b49744b23b018848400d23e54caf9463f4eb20df3eb8acb2eb1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.2"
  lints:
    dependency: transitive
    description:
      name: lints
      sha256: "12f842a479589fea194fe5c5a3095abc7be0c1f2ddfa9a0e76aed1dbd26a87df"
      url: "https://pub.dev"
    source: hosted
    version: "6.1.0"
  logging:
    dependency: transitive
    description:
      name: logging
      sha256: c8245ada5f1717ed44271ed1c26b8ce85ca3228fd2ffdb75468ab01979309d61
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  matcher:
    dependency: transitive
    description:
      name: matcher
      sha256: dc0b7dc7651697ea4ff3e69ef44b0407ea32c487a39fff6a4004fa585e901861
      url: "https://pub.dev"
    source: hosted
    version: "0.12.19"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      sha256: "9c337007e82b1889149c82ed242ed1cb24a66044e30979c44912381e9be4c48b"
      url: "https://pub.dev"
    source: hosted
    version: "0.13.0"
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: "23f08335362185a5ea2ad3a4e597f1375e78bce8a040df5c600c8d3552ef2394"
      url: "https://pub.dev"
    source: hosted
    version: "1.17.0"
  mime:
    dependency: transitive
    description:
      name: mime
      sha256: "41a20518f0cb1256669420fdba0cd90d21561e560ac240f26ef8322e45bb7ed6"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.0"
  native_toolchain_c:
    dependency: transitive
    description:
      name: native_toolchain_c
      sha256: "6ba77bb18063eebe9de401f5e6437e95e1438af0a87a3a39084fbd37c90df572"
      url: "https://pub.dev"
    source: hosted
    version: "0.17.6"
  nm:
    dependency: transitive
    description:
      name: nm
      sha256: "2c9aae4127bdc8993206464fcc063611e0e36e72018696cd9631023a31b24254"
      url: "https://pub.dev"
    source: hosted
    version: "0.5.0"
  objective_c:
    dependency: transitive
    description:
      name: objective_c
      sha256: "100a1c87616ab6ed41ec263b083c0ef3261ee6cd1dc3b0f35f8ddfa4f996fe52"
      url: "https://pub.dev"
    source: hosted
    version: "9.3.0"
  octo_image:
    dependency: transitive
    description:
      name: octo_image
      sha256: "34faa6639a78c7e3cbe79be6f9f96535867e879748ade7d17c9b1ae7536293bd"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  package_config:
    dependency: transitive
    description:
      name: package_config
      sha256: f096c55ebb7deb7e384101542bfba8c52696c1b56fca2eb62827989ef2353bbc
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  path:
    dependency: transitive
    description:
      name: path
      sha256: "75cca69d1490965be98c73ceaea117e8a04dd21217b37b292c9ddbec0d955bc5"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.1"
  path_provider:
    dependency: "direct main"
    description:
      name: path_provider
      sha256: "50c5dd5b6e1aaf6fb3a78b33f6aa3afca52bf903a8a5298f53101fdaee55bbcd"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.5"
  path_provider_android:
    dependency: transitive
    description:
      name: path_provider_android
      sha256: "69cbd515a62b94d32a7944f086b2f82b4ac40a1d45bebfc00813a430ab2dabcd"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.1"
  path_provider_foundation:
    dependency: transitive
    description:
      name: path_provider_foundation
      sha256: "2a376b7d6392d80cd3705782d2caa734ca4727776db0b6ec36ef3f1855197699"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.0"
  path_provider_linux:
    dependency: transitive
    description:
      name: path_provider_linux
      sha256: f7a1fe3a634fe7734c8d3f2766ad746ae2a2884abe22e241a8b301bf5cac3279
      url: "https://pub.dev"
    source: hosted
    version: "2.2.1"
  path_provider_platform_interface:
    dependency: transitive
    description:
      name: path_provider_platform_interface
      sha256: "88f5779f72ba699763fa3a3b06aa4bf6de76c8e5de842cf6f29e2e06476c2334"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  path_provider_windows:
    dependency: transitive
    description:
      name: path_provider_windows
      sha256: bd6f00dbd873bfb70d0761682da2b3a2c2fccc2b9e84c495821639601d81afe7
      url: "https://pub.dev"
    source: hosted
    version: "2.3.0"
  petitparser:
    dependency: transitive
    description:
      name: petitparser
      sha256: "91bd59303e9f769f108f8df05e371341b15d59e995e6806aefab827b58336675"
      url: "https://pub.dev"
    source: hosted
    version: "7.0.2"
  pin_input_text_field:
    dependency: transitive
    description:
      name: pin_input_text_field
      sha256: f45683032283d30b670ec343781660655e3e1953438b281a0bc6e2d358486236
      url: "https://pub.dev"
    source: hosted
    version: "4.5.2"
  platform:
    dependency: transitive
    description:
      name: platform
      sha256: "5d6b1b0036a5f331ebc77c850ebc8506cbc1e9416c27e59b439f917a902a4984"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.6"
  plugin_platform_interface:
    dependency: transitive
    description:
      name: plugin_platform_interface
      sha256: "4820fbfdb9478b1ebae27888254d445073732dae3d6ea81f0b7e06d5dedc3f02"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.8"
  pointycastle:
    dependency: transitive
    description:
      name: pointycastle
      sha256: "92aa3841d083cc4b0f4709b5c74fd6409a3e6ba833ffc7dc6a8fee096366acf5"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.0"
  posix:
    dependency: transitive
    description:
      name: posix
      sha256: "185ef7606574f789b40f289c233efa52e96dead518aed988e040a10737febb07"
      url: "https://pub.dev"
    source: hosted
    version: "6.5.0"
  postgrest:
    dependency: transitive
    description:
      name: postgrest
      sha256: "9d61b3d4a88fcf9424d400127c54d49ed1b56ec30838fc0a33a64f31d4e694cc"
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  pub_semver:
    dependency: transitive
    description:
      name: pub_semver
      sha256: "5bfcf68ca79ef689f8990d1160781b4bad40a3bd5e5218ad4076ddb7f4081585"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  qr:
    dependency: transitive
    description:
      name: qr
      sha256: "5a1d2586170e172b8a8c8470bbbffd5eb0cd38a66c0d77155ea138d3af3a4445"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.2"
  qr_flutter:
    dependency: "direct main"
    description:
      name: qr_flutter
      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.0"
  realtime_client:
    dependency: transitive
    description:
      name: realtime_client
      sha256: "7dfccf372d2f55aacfeefb6186f65a06f3ffae383fe042dbeef9d85d33487576"
      url: "https://pub.dev"
    source: hosted
    version: "2.7.3"
  record_use:
    dependency: transitive
    description:
      name: record_use
      sha256: "2551bd8eecfe95d14ae75f6021ad0248be5c27f138c2ec12fcb52b500b3ba1ed"
      url: "https://pub.dev"
    source: hosted
    version: "0.6.0"
  retry:
    dependency: transitive
    description:
      name: retry
      sha256: "822e118d5b3aafed083109c72d5f484c6dc66707885e07c0fbcb8b986bba7efc"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  riverpod:
    dependency: transitive
    description:
      name: riverpod
      sha256: "59062512288d3056b2321804332a13ffdd1bf16df70dcc8e506e411280a72959"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  rxdart:
    dependency: transitive
    description:
      name: rxdart
      sha256: "5c3004a4a8dbb94bd4bf5412a4def4acdaa12e12f269737a5751369e12d1a962"
      url: "https://pub.dev"
    source: hosted
    version: "0.28.0"
  sanitize_html:
    dependency: transitive
    description:
      name: sanitize_html
      sha256: "12669c4a913688a26555323fb9cec373d8f9fbe091f2d01c40c723b33caa8989"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  share_plus:
    dependency: "direct main"
    description:
      name: share_plus
      sha256: fce43200aa03ea87b91ce4c3ac79f0cecd52e2a7a56c7a4185023c271fbfa6da
      url: "https://pub.dev"
    source: hosted
    version: "10.1.4"
  share_plus_platform_interface:
    dependency: transitive
    description:
      name: share_plus_platform_interface
      sha256: cc012a23fc2d479854e6c80150696c4a5f5bb62cb89af4de1c505cf78d0a5d0b
      url: "https://pub.dev"
    source: hosted
    version: "5.0.2"
  shared_preferences:
    dependency: "direct main"
    description:
      name: shared_preferences
      sha256: c3025c5534b01739267eb7d76959bbc25a6d10f6988e1c2a3036940133dd10bf
      url: "https://pub.dev"
    source: hosted
    version: "2.5.5"
  shared_preferences_android:
    dependency: transitive
    description:
      name: shared_preferences_android
      sha256: e8d4762b1e2e8578fc4d0fd548cebf24afd24f49719c08974df92834565e2c53
      url: "https://pub.dev"
    source: hosted
    version: "2.4.23"
  shared_preferences_foundation:
    dependency: transitive
    description:
      name: shared_preferences_foundation
      sha256: "4e7eaffc2b17ba398759f1151415869a34771ba11ebbccd1b0145472a619a64f"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.6"
  shared_preferences_linux:
    dependency: transitive
    description:
      name: shared_preferences_linux
      sha256: "580abfd40f415611503cae30adf626e6656dfb2f0cee8f465ece7b6defb40f2f"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  shared_preferences_platform_interface:
    dependency: transitive
    description:
      name: shared_preferences_platform_interface
      sha256: "649dc798a33931919ea356c4305c2d1f81619ea6e92244070b520187b5140ef9"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2"
  shared_preferences_web:
    dependency: transitive
    description:
      name: shared_preferences_web
      sha256: c49bd060261c9a3f0ff445892695d6212ff603ef3115edbb448509d407600019
      url: "https://pub.dev"
    source: hosted
    version: "2.4.3"
  shared_preferences_windows:
    dependency: transitive
    description:
      name: shared_preferences_windows
      sha256: "94ef0f72b2d71bc3e700e025db3710911bd51a71cefb65cc609dd0d9a982e3c1"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  sms_autofill:
    dependency: "direct main"
    description:
      name: sms_autofill
      sha256: c65836abe9c1f62ce411bb78d5546a09ece4297558070b1bd871db1db283aaf9
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  source_span:
    dependency: transitive
    description:
      name: source_span
      sha256: "56a02f1f4cd1a2d96303c0144c93bd6d909eea6bee6bf5a0e0b685edbd4c47ab"
      url: "https://pub.dev"
    source: hosted
    version: "1.10.2"
  sqflite:
    dependency: transitive
    description:
      name: sqflite
      sha256: "564cfed0746fe53140c23b70b308e045c3b31f17778f2f326ccb7d804ea0250a"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2+1"
  sqflite_android:
    dependency: transitive
    description:
      name: sqflite_android
      sha256: "881e28efdcc9950fd8e9bb42713dcf1103e62a2e7168f23c9338d82db13dec40"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2+3"
  sqflite_common:
    dependency: transitive
    description:
      name: sqflite_common
      sha256: "5e8377564d95166761a968ed96104e0569b6b6cc611faac92a36ab8a169112c3"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.6+1"
  sqflite_darwin:
    dependency: transitive
    description:
      name: sqflite_darwin
      sha256: "279832e5cde3fe99e8571879498c9211f3ca6391b0d818df4e17d9fff5c6ccb3"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2"
  sqflite_platform_interface:
    dependency: transitive
    description:
      name: sqflite_platform_interface
      sha256: "8dd4515c7bdcae0a785b0062859336de775e8c65db81ae33dd5445f35be61920"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.0"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
      url: "https://pub.dev"
    source: hosted
    version: "1.12.1"
  state_notifier:
    dependency: transitive
    description:
      name: state_notifier
      sha256: b8677376aa54f2d7c58280d5a007f9e8774f1968d1fb1c096adcb4792fba29bb
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  storage_client:
    dependency: transitive
    description:
      name: storage_client
      sha256: "4801e8ca219a35e51cbb30589aba5306667ae8935b792504595a45273cef0b18"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.2"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      sha256: "969e04c80b8bcdf826f8f16579c7b14d780458bd97f56d107d3950fdbeef059d"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  stream_transform:
    dependency: transitive
    description:
      name: stream_transform
      sha256: ad47125e588cfd37a9a7f86c7d6356dde8dfe89d071d293f80ca9e9273a33871
      url: "https://pub.dev"
    source: hosted
    version: "2.1.1"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      sha256: "921cd31725b72fe181906c6a94d987c78e3b98c2e205b397ea399d4054872b43"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  supabase:
    dependency: transitive
    description:
      name: supabase
      sha256: "40e5a8833c8834e140ef53b60a6181849667eba9ca125acb7f8e24c6a769d418"
      url: "https://pub.dev"
    source: hosted
    version: "2.10.6"
  supabase_flutter:
    dependency: "direct main"
    description:
      name: supabase_flutter
      sha256: c02ce58abcaf86cb8055ad40bfd98bbf5b93fed3b5b56b8220d88ed03842818b
      url: "https://pub.dev"
    source: hosted
    version: "2.12.4"
  synchronized:
    dependency: transitive
    description:
      name: synchronized
      sha256: "63896c27e81b28f8cb4e69ead0d3e8f03f1d1e5fc531a3e579cabed6a2c7c9e5"
      url: "https://pub.dev"
    source: hosted
    version: "3.4.0+1"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      sha256: "7f554798625ea768a7518313e58f83891c7f5024f88e46e7182a4558850a4b8e"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  test_api:
    dependency: transitive
    description:
      name: test_api
      sha256: "8161c84903fd860b26bfdefb7963b3f0b68fee7adea0f59ef805ecca346f0c7a"
      url: "https://pub.dev"
    source: hosted
    version: "0.7.10"
  timezone:
    dependency: transitive
    description:
      name: timezone
      sha256: dd14a3b83cfd7cb19e7888f1cbc20f258b8d71b54c06f79ac585f14093a287d1
      url: "https://pub.dev"
    source: hosted
    version: "0.10.1"
  typed_data:
    dependency: transitive
    description:
      name: typed_data
      sha256: f9049c039ebfeb4cf7a7104a675823cd72dba8297f264b6637062516699fa006
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  url_launcher:
    dependency: "direct main"
    description:
      name: url_launcher
      sha256: f6a7e5c4835bb4e3026a04793a4199ca2d14c739ec378fdfe23fc8075d0439f8
      url: "https://pub.dev"
    source: hosted
    version: "6.3.2"
  url_launcher_android:
    dependency: transitive
    description:
      name: url_launcher_android
      sha256: "3bb000251e55d4a209aa0e2e563309dc9bb2befea2295fd0cec1f51760aac572"
      url: "https://pub.dev"
    source: hosted
    version: "6.3.29"
  url_launcher_ios:
    dependency: transitive
    description:
      name: url_launcher_ios
      sha256: "580fe5dfb51671ae38191d316e027f6b76272b026370708c2d898799750a02b0"
      url: "https://pub.dev"
    source: hosted
    version: "6.4.1"
  url_launcher_linux:
    dependency: transitive
    description:
      name: url_launcher_linux
      sha256: d5e14138b3bc193a0f63c10a53c94b91d399df0512b1f29b94a043db7482384a
      url: "https://pub.dev"
    source: hosted
    version: "3.2.2"
  url_launcher_macos:
    dependency: transitive
    description:
      name: url_launcher_macos
      sha256: "368adf46f71ad3c21b8f06614adb38346f193f3a59ba8fe9a2fd74133070ba18"
      url: "https://pub.dev"
    source: hosted
    version: "3.2.5"
  url_launcher_platform_interface:
    dependency: transitive
    description:
      name: url_launcher_platform_interface
      sha256: "552f8a1e663569be95a8190206a38187b531910283c3e982193e4f2733f01029"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.2"
  url_launcher_web:
    dependency: transitive
    description:
      name: url_launcher_web
      sha256: d0412fcf4c6b31ecfdb7762359b7206ffba3bbffd396c6d9f9c4616ece476c1f
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2"
  url_launcher_windows:
    dependency: transitive
    description:
      name: url_launcher_windows
      sha256: "712c70ab1b99744ff066053cbe3e80c73332b38d46e5e945c98689b2e66fc15f"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.5"
  uuid:
    dependency: transitive
    description:
      name: uuid
      sha256: "1fef9e8e11e2991bb773070d4656b7bd5d850967a2456cfc83cf47925ba79489"
      url: "https://pub.dev"
    source: hosted
    version: "4.5.3"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      sha256: d530bd74fea330e6e364cda7a85019c434070188383e1cd8d9777ee586914c5b
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  vm_service:
    dependency: transitive
    description:
      name: vm_service
      sha256: "046d3928e16fa4dc46e8350415661755ab759d9fc97fc21b5ab295f71e4f0499"
      url: "https://pub.dev"
    source: hosted
    version: "15.1.0"
  web:
    dependency: transitive
    description:
      name: web
      sha256: "868d88a33d8a87b18ffc05f9f030ba328ffefba92d6c127917a2ba740f9cfe4a"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  web_socket:
    dependency: transitive
    description:
      name: web_socket
      sha256: "34d64019aa8e36bf9842ac014bb5d2f5586ca73df5e4d9bf5c936975cae6982c"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.1"
  web_socket_channel:
    dependency: transitive
    description:
      name: web_socket_channel
      sha256: d645757fb0f4773d602444000a8131ff5d48c9e47adfe9772652dd1a4f2d45c8
      url: "https://pub.dev"
    source: hosted
    version: "3.0.3"
  win32:
    dependency: transitive
    description:
      name: win32
      sha256: d7cb55e04cd34096cd3a79b3330245f54cb96a370a1c27adb3c84b917de8b08e
      url: "https://pub.dev"
    source: hosted
    version: "5.15.0"
  xdg_directories:
    dependency: transitive
    description:
      name: xdg_directories
      sha256: "7a3f37b05d989967cdddcbb571f1ea834867ae2faa29725fd085180e0883aa15"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  xml:
    dependency: transitive
    description:
      name: xml
      sha256: "971043b3a0d3da28727e40ed3e0b5d18b742fa5a68665cca88e74b7876d5e025"
      url: "https://pub.dev"
    source: hosted
    version: "6.6.1"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: b9da305ac7c39faa3f030eccd175340f968459dae4af175130b3fc47e40d76ce
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
  yet_another_json_isolate:
    dependency: transitive
    description:
      name: yet_another_json_isolate
      sha256: fe45897501fa156ccefbfb9359c9462ce5dec092f05e8a56109db30be864f01e
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
sdks:
  dart: ">=3.11.0 <4.0.0"
  flutter: ">=3.38.4"
````

## File: pubspec.yaml
````yaml
name: flatmates_app
description: "360 FlatMates"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.0
  flutter: ">=3.38.4"

dependencies:
  app_links: ^6.3.3
  cached_network_image: ^3.4.1
  connectivity_plus: ^6.1.4
  cupertino_icons: ^1.0.8
  dio: ^5.9.0
  firebase_core: ^3.14.0
  firebase_messaging: ^15.2.9
  flutter:
    sdk: flutter
  flutter_dotenv: ^5.2.1
  flutter_local_notifications: ^18.0.1
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  flutter_secure_storage: ^9.2.4
  geocoding: ^3.0.0
  geolocator: ^13.0.2
  go_router: ^16.2.1
  google_fonts: ^6.3.2
  google_maps_flutter: ^2.12.0
  image_picker: ^1.1.2
  intl: ^0.20.2
  path_provider: ^2.1.5
  share_plus: ^10.1.4
  shared_preferences: ^2.5.3
  sms_autofill: ^2.3.0
  url_launcher: ^6.3.1
  supabase_flutter: ^2.10.4
  confetti: ^0.7.0
  qr_flutter: ^4.1.0

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: ^0.14.3

flutter:
  generate: true
  uses-material-design: true

  assets:
    - assets/illustrations/

  # NOTE: .env is intentionally NOT listed as a Flutter asset here.
  # If it were, the build would fail when the file is absent (e.g. fresh clone).
  # Instead, EnvLoader loads it from the file system at runtime and falls back
  # to --dart-define / environment variables when it is missing.

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#5B4BCF"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/icons/splash_logo.png
  branding: assets/icons/splash_branding.png
  android: true
  ios: true
````

## File: lib/app/app.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/deep_links/deep_link_service.dart';
import '../core/network/connectivity_monitor.dart';
import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_controller.dart';
import '../features/bootstrap/bootstrap_controller.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/gen/app_localizations.dart';
import 'router/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  DeepLinkService? _deepLinkService;

  // Local notifications are initialized in bootstrap() before runApp().
  // NotificationService.initialize() is called after auth login (see ref.listen below).

  @override
  void initState() {
    super.initState();
    // Deep link service is initialized after the first frame so that
    // GoRouter is available via the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      _deepLinkService = DeepLinkService(router: router)..init();
    });
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);
    final bootstrapState = ref.watch(bootstrapControllerProvider);

    // Handle notification deep links on bootstrap completion
    if (bootstrapState is AsyncData && bootstrapState.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromPendingNotification(router);
      });
    }

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      final bootstrap = ref.read(bootstrapControllerProvider.notifier);
      if (next.isLoggedIn) {
        bootstrap.load();
        ref.read(notificationServiceProvider).initialize();
      } else {
        ref.read(notificationServiceProvider).dispose();
        bootstrap.clear();
      }
    });

    return Stack(
      children: [
        MaterialApp.router(
          title: '360 FlatMates',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(
            brightness: Brightness.light,
            palette: settings.palette,
          ),
          darkTheme: AppTheme.build(
            brightness: Brightness.dark,
            palette: settings.palette,
          ),
          themeMode: settings.themeMode,
          locale: settings.locale,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
        const OfflineBanner(),
      ],
    );
  }

  void _navigateFromPendingNotification(GoRouter router) {
    final route = NotificationService.consumePendingRoute();
    if (route != null && route.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(route);
      });
    }
  }
}
````

## File: lib/bootstrap.dart
````dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/env_loader.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/secure_kv_store.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    // Initialize local notifications so background messages can be displayed.
    await NotificationService.initializeLocalNotifications();

    // Show notification for data-only messages (no notification payload).
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title'] ?? '360 FlatMates';
      final body = message.data['body'] ?? message.data['message'] ?? '';
      final route = message.data['route'];
      if (body.isNotEmpty) {
        await FlutterLocalNotificationsPlugin().show(
          message.hashCode,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'flatmates_messages',
              'Messages & Matches',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: route,
        );
      }
    }
  } catch (_) {
    // Firebase may not be configured; skip silently.
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await initializeDateFormatting();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } catch (error) {
    runApp(_ConfigErrorApp(message: error.toString()));
    return;
  }

  var firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (_) {
    // Firebase may not be configured yet (e.g. missing google-services.json /
    // GoogleService-Info.plist). Allow the app to start so it can still be
    // developed and tested without Firebase.
  }
  NotificationService.messagingEnabled = firebaseInitialized;

  if (firebaseInitialized) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize the local notifications plugin early so it is ready before
  // the widget tree mounts and before any foreground / background messages
  // arrive.
  await NotificationService.initializeLocalNotifications();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  final preferences = await AppPreferences.create();
  const secureStore = SecureKvStore();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appPreferencesProvider.overrideWithValue(preferences),
        secureStoreProvider.overrideWithValue(secureStore),
      ],
      child: const App(),
    ),
  );
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Configuration required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '$message\n\nRun with --dart-define values for API_BASE_URL, SUPABASE_URL, and SUPABASE_PUBLISHABLE_KEY.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
````
