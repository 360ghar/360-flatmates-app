import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import 'application/create_listing_controller.dart';
import 'presentation/widgets/listing_form_data.dart';
import 'presentation/widgets/listing_step_header.dart';
import 'presentation/widgets/listing_step_view.dart';

// Local UI state for the create/edit listing page. Reset on entry so transient
// state does not leak across page instances.
final _createListingStepProvider = StateProvider<int>((ref) => 0);
final _createListingSubmittingProvider = StateProvider<bool>((ref) => false);
final _createListingPhotosUploadingProvider = StateProvider<bool>(
  (ref) => false,
);
final _createListingLoadingExistingProvider = StateProvider<bool>(
  (ref) => false,
);
final _createListingDirtyProvider = StateProvider<bool>((ref) => false);
final _createListingValidationProvider = StateProvider<ListingStepValidation>(
  (ref) => kNoListingValidation,
);

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({this.listingId, super.key});

  final int? listingId;

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _societyController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();
  String _societyType = 'gated';
  final _societyAmenities = <String>{};
  final _societyVibeTags = <String>{};
  String _roomType = 'private_room';
  final _roomFurnishing = <String>{};
  final _roomFeatures = <String>{};
  final _roomPhotoUrls = <String>[];
  String? _videoTourUrl;
  bool _videoUploading = false;
  String _flatConfig = '2BHK';
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _flatAmenities = <String>{};
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  String _electricityIncluded = 'separate';
  final _electricityEstController = TextEditingController();
  final _cookCostController = TextEditingController();
  final _maidCostController = TextEditingController();
  final _setupCostController = TextEditingController();
  final _typicalDayController = TextEditingController();
  String _genderPreference = 'any';
  double _ageMin = 18;
  double _ageMax = 40;
  final _nonNegotiables = <String>{};
  DateTime? _availableFrom;
  static const totalSteps = 8;

  @override
  void initState() {
    super.initState();
    _resetProviders();
    if (widget.listingId != null) {
      ref.read(_createListingLoadingExistingProvider.notifier).state = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadListingForEdit(widget.listingId!);
      });
    }
  }

  void _resetProviders() {
    ref.read(_createListingStepProvider.notifier).state = 0;
    ref.read(_createListingSubmittingProvider.notifier).state = false;
    ref.read(_createListingPhotosUploadingProvider.notifier).state = false;
    ref.read(_createListingLoadingExistingProvider.notifier).state = false;
    ref.read(_createListingDirtyProvider.notifier).state = false;
    ref.read(_createListingValidationProvider.notifier).state =
        kNoListingValidation;
  }

  Future<void> _loadListingForEdit(int listingId) async {
    final locale = AppLocalizations.of(context);
    try {
      final listing = await ref
          .read(createListingControllerProvider)
          .loadListingForEdit(listingId);
      if (!mounted) return;
      final scalars = populateListingControllers(
        listing: listing,
        society: _societyController,
        address: _addressController,
        city: _cityController,
        locality: _localityController,
        rent: _rentController,
        deposit: _depositController,
        maintenance: _maintenanceController,
        typicalDay: _typicalDayController,
        floor: _floorController,
        totalFloors: _totalFloorsController,
        roomFeatures: _roomFeatures,
        societyAmenities: _societyAmenities,
        societyVibeTags: _societyVibeTags,
        roomPhotoUrls: _roomPhotoUrls,
        fallbackRoomType: _roomType,
        fallbackSocietyType: _societyType,
        fallbackGenderPreference: _genderPreference,
      );
      setState(() {
        _roomType = scalars.roomType;
        _societyType = scalars.societyType;
        _genderPreference = scalars.genderPreference;
        _flatConfig = scalars.flatConfig;
        _videoTourUrl = scalars.videoTourUrl;
        _availableFrom = scalars.availableFrom;
      });
      ref.read(_createListingLoadingExistingProvider.notifier).state = false;
    } catch (e) {
      debugPrint(
        'CreateListingPage._loadListingForEdit failed for listing $listingId: $e',
      );
      if (!mounted) return;
      ref.read(_createListingLoadingExistingProvider.notifier).state = false;
      FlatmatesToast.error(context, locale.couldNotLoadListings);
    }
  }

  List<CatalogOption> _catalog(String key) {
    return ref
            .watch(bootstrapControllerProvider)
            .valueOrNull
            ?.catalogOptions(key) ??
        const [];
  }

  String _catalogLabel(String key, String id) {
    return _catalog(key)
        .firstWhere(
          (o) => o.id == id,
          orElse: () =>
              CatalogOption(id: id, label: humanizeFlatmatesToken(id)),
        )
        .label;
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

  Future<void> _pickRoomPhotos() async {
    if (ref.read(_createListingPhotosUploadingProvider)) return;
    final locale = AppLocalizations.of(context);
    final controller = ref.read(createListingControllerProvider);
    try {
      final files = await controller.pickRoomPhotos(
        limit: 10 - _roomPhotoUrls.length,
      );
      if (files.isEmpty) return;
      if (!mounted) return;
      ref.read(_createListingPhotosUploadingProvider.notifier).state = true;
      for (final file in files) {
        final url = await controller.uploadRoomPhoto(file);
        if (!mounted) return;
        setState(() => _roomPhotoUrls.add(url));
        ref.read(_createListingValidationProvider.notifier).state =
            kNoListingValidation;
        ref.read(_createListingDirtyProvider.notifier).state = true;
      }
    } catch (e) {
      debugPrint('CreateListingPage._pickRoomPhotos failed: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.listingSubmitFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) {
        ref.read(_createListingPhotosUploadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _submit() async {
    if (ref.read(_createListingSubmittingProvider)) return;
    final locale = AppLocalizations.of(context);
    final editingId = widget.listingId;
    ref.read(_createListingSubmittingProvider.notifier).state = true;
    try {
      final request = _formData.toRequest();
      final listingId = await ref
          .read(createListingControllerProvider)
          .submit(request: request, editingId: editingId);
      if (!mounted) return;
      ref.read(_createListingDirtyProvider.notifier).state = false;
      FlatmatesToast.success(
        context,
        editingId != null
            ? locale.listingUpdatedToast
            : locale.postListingSuccess,
      );
      if (listingId != null) {
        context.go('/listing-review/$listingId');
      } else {
        context.go('/discover');
      }
    } catch (error) {
      debugPrint('CreateListingPage._submit failed: $error');
      if (!mounted) return;
      final msg = error is AppFailure
          ? error.userMessage(locale.toUserMessageL10n())
          : locale.listingSubmitFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) {
        ref.read(_createListingSubmittingProvider.notifier).state = false;
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!ref.read(_createListingDirtyProvider) ||
        ref.read(_createListingSubmittingProvider)) {
      return true;
    }
    final locale = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.discardListingTitle),
        content: Text(locale.discardListingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(locale.keepEditingCta),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(locale.discardCta),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  void _clearValidationFlags() {
    ref.read(_createListingValidationProvider.notifier).state =
        kNoListingValidation;
  }

  Future<void> _handleBack() async {
    if (await _confirmDiscard()) {
      if (!mounted) return;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final step = ref.watch(_createListingStepProvider);
    final submitting = ref.watch(_createListingSubmittingProvider);
    final photosUploading = ref.watch(_createListingPhotosUploadingProvider);
    final loadingExisting = ref.watch(_createListingLoadingExistingProvider);
    final validation = ref.watch(_createListingValidationProvider);

    final summary = _formData.stepSummary(locale, step, _catalogLabel);
    final canAdvance = _formData.canProceed(step) && !photosUploading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: FlatmatesHeader.logo(onBack: () => unawaited(_handleBack())),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  ListingStepHeader(
                    locale: locale,
                    step: step,
                    totalSteps: totalSteps,
                    summary: summary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.xl * 4 + AppSpacing.sm,
                      ),
                      children: [
                        ListingStepView(
                          step: step,
                          data: _formData,
                          catalog: _catalog,
                          catalogLabel: _catalogLabel,
                          showRentValidation: validation.rent,
                          showDepositValidation: validation.deposit,
                          showMaintenanceValidation: validation.maintenance,
                          showCostValidation: validation.cost,
                          showElectricityValidation: validation.electricity,
                          showPhotosValidation: validation.photos,
                          callbacks: _stepCallbacks,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (loadingExisting)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x0D000000),
                    child: FlatmatesSkeleton.form(itemCount: 4),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: FlatmatesBottomActionBar(
          primaryButtonKey: step < totalSteps - 1
              ? const Key('listing_next_button')
              : const Key('listing_publish_button'),
          secondaryButtonKey: step > 0
              ? const Key('listing_back_button')
              : null,
          label: submitting
              ? locale.postingInProgress
              : (step < totalSteps - 1
                    ? locale.onboardingNext
                    : locale.publishListingCta),
          onPressed: submitting
              ? null
              : (step < totalSteps - 1
                    ? (canAdvance
                          ? () {
                              _showInlineValidation(step);
                              ref
                                      .read(_createListingStepProvider.notifier)
                                      .state =
                                  step + 1;
                              _clearValidationFlags();
                            }
                          : () {
                              _showInlineValidation(step);
                            })
                    : _submit),
          icon: step < totalSteps - 1
              ? Icons.arrow_forward_rounded
              : Icons.upload_rounded,
          secondaryLabel: step > 0 ? locale.backCta : null,
          secondaryOnPressed: step > 0
              ? () {
                  ref.read(_createListingStepProvider.notifier).state =
                      step - 1;
                  _clearValidationFlags();
                }
              : null,
          secondaryIcon: step > 0 ? Icons.arrow_back_rounded : null,
        ),
      ),
    );
  }

  void _showInlineValidation(int step) {
    ref.read(_createListingValidationProvider.notifier).state =
        computeStepValidation(_formData, step);
  }

  ListingStepCallbacks get _stepCallbacks => ListingStepCallbacks(
    onFieldChanged: _onFieldChanged,
    onSocietyTypeChanged: (v) => _updateString(() => _societyType = v),
    onSocietyAmenityToggled: _toggleSet(_societyAmenities),
    onVibeToggled: _toggleSet(_societyVibeTags),
    onRoomTypeChanged: (v) => _updateString(() => _roomType = v),
    onFurnishingToggled: _toggleSet(_roomFurnishing),
    onFeatureToggled: _toggleSet(_roomFeatures),
    onPickPhotos: _pickRoomPhotos,
    onRemovePhoto: (i) => _updateList(() => _roomPhotoUrls.removeAt(i)),
    onVideoTourUrlChanged: (u) => _updateString(() => _videoTourUrl = u),
    onVideoUploadingChanged: (v) => setState(() => _videoUploading = v),
    onFlatConfigChanged: (v) => _updateString(() => _flatConfig = v),
    onFlatAmenityToggled: _toggleSet(_flatAmenities),
    onElectricityChanged: (v) => _updateString(() => _electricityIncluded = v),
    onGenderChanged: (v) => _updateString(() => _genderPreference = v),
    onAgeRangeChanged: (min, max) => _updateState(() {
      _ageMin = min;
      _ageMax = max;
    }),
    onNonNegotiableToggled: _toggleSet(_nonNegotiables),
    onAvailableFromChanged: (d) => _updateNullable(() => _availableFrom = d),
    onGoToStep: (s) {
      ref.read(_createListingStepProvider.notifier).state = s;
      _clearValidationFlags();
    },
  );

  ListingFormData get _formData => ListingFormData(
    societyController: _societyController,
    addressController: _addressController,
    cityController: _cityController,
    localityController: _localityController,
    societyType: _societyType,
    societyAmenities: _societyAmenities,
    societyVibeTags: _societyVibeTags,
    roomType: _roomType,
    roomFurnishing: _roomFurnishing,
    roomFeatures: _roomFeatures,
    roomPhotoUrls: _roomPhotoUrls,
    videoTourUrl: _videoTourUrl,
    videoUploading: _videoUploading,
    flatConfig: _flatConfig,
    floorController: _floorController,
    totalFloorsController: _totalFloorsController,
    flatAmenities: _flatAmenities,
    rentController: _rentController,
    depositController: _depositController,
    maintenanceController: _maintenanceController,
    electricityIncluded: _electricityIncluded,
    electricityEstController: _electricityEstController,
    cookCostController: _cookCostController,
    maidCostController: _maidCostController,
    setupCostController: _setupCostController,
    typicalDayController: _typicalDayController,
    genderPreference: _genderPreference,
    ageMin: _ageMin,
    ageMax: _ageMax,
    nonNegotiables: _nonNegotiables,
    availableFrom: _availableFrom,
  );

  void _onFieldChanged() {
    ref.read(_createListingDirtyProvider.notifier).state = true;
  }

  void _updateString(void Function() setter) => _updateState(setter);

  void _updateNullable(void Function() setter) => _updateState(setter);

  void _updateList(void Function() setter) => _updateState(setter);

  void _updateState(void Function() setter) {
    setState(setter);
    ref.read(_createListingDirtyProvider.notifier).state = true;
  }

  void Function(String, bool) _toggleSet(Set<String> set) =>
      (key, selected) => _updateState(() {
        selected ? set.add(key) : set.remove(key);
      });
}
