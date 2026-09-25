import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import 'application/create_listing_controller.dart';
import 'presentation/widgets/create_listing_actions.dart';
import 'presentation/widgets/listing_catalog_options.dart';
import 'presentation/widgets/listing_form_data.dart';
import 'presentation/widgets/listing_step_header.dart';
import 'presentation/widgets/listing_step_view.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({this.listingId, super.key});

  final int? listingId;

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  /// Unsaved edits. Never shown, so a plain field (no rebuild) is enough.
  bool _dirty = false;

  // Ephemeral page state (setState): each page instance starts fresh.
  int _step = 0;
  bool _submitting = false;
  bool _photosUploading = false;
  late bool _loadingExisting = widget.listingId != null;
  ListingStepValidation _validation = kNoListingValidation;

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
  String? _kitchenType;
  String? _ventilationType;
  final _windowsController = TextEditingController();
  final _ventilationShaftsController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  String _electricityIncluded = 'separate';
  final _electricityEstController = TextEditingController();
  final _cookCostController = TextEditingController();
  final _maidCostController = TextEditingController();
  final _setupCostController = TextEditingController();
  final _otherChargesController = TextEditingController();
  final _otherChargesDescriptionController = TextEditingController();
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
    if (widget.listingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadListingForEdit(widget.listingId!);
      });
    }
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
        electricityEst: _electricityEstController,
        cookCost: _cookCostController,
        maidCost: _maidCostController,
        setupCost: _setupCostController,
        otherCharges: _otherChargesController,
        otherChargesDescription: _otherChargesDescriptionController,
        windowsCount: _windowsController,
        ventilationShafts: _ventilationShaftsController,
        roomFeatures: _roomFeatures,
        societyAmenities: _societyAmenities,
        societyVibeTags: _societyVibeTags,
        nonNegotiables: _nonNegotiables,
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
        _kitchenType = scalars.kitchenType;
        _ventilationType = scalars.ventilationType;
        _electricityIncluded = scalars.electricityIncluded;
        _videoTourUrl = scalars.videoTourUrl;
        _availableFrom = scalars.availableFrom;
        // Clamp to the slider range (18-50) so an odd stored value cannot
        // assert in RangeSlider.
        final min = (scalars.ageMin ?? _ageMin).clamp(18.0, 50.0);
        final max = (scalars.ageMax ?? _ageMax).clamp(18.0, 50.0);
        _ageMin = min <= max ? min : max;
        _ageMax = max >= min ? max : min;
        _loadingExisting = false;
      });
    } catch (e) {
      debugPrint(
        'CreateListingPage._loadListingForEdit failed for listing $listingId: $e',
      );
      if (!mounted) return;
      setState(() => _loadingExisting = false);
      FlatmatesToast.error(context, locale.couldNotLoadListings);
    }
  }

  // Thin adapters over listing_catalog_options.dart so the tear-offs passed to
  // ListingStepView keep their existing signatures.
  List<CatalogOption> _catalog(String key) =>
      listingCatalog(ref, AppLocalizations.of(context), key);

  String _catalogLabel(String key, String id) =>
      listingCatalogLabel(ref, AppLocalizations.of(context), key, id);

  @override
  void dispose() {
    for (final c in [
      _societyController,
      _addressController,
      _cityController,
      _localityController,
      _floorController,
      _totalFloorsController,
      _windowsController,
      _ventilationShaftsController,
      _rentController,
      _depositController,
      _maintenanceController,
      _electricityEstController,
      _cookCostController,
      _maidCostController,
      _setupCostController,
      _otherChargesController,
      _otherChargesDescriptionController,
      _typicalDayController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickRoomPhotos() => pickAndUploadRoomPhotos(
    ref: ref,
    context: context,
    isMounted: () => mounted,
    currentPhotoCount: _roomPhotoUrls.length,
    onUrlAdded: (url) => setState(() => _roomPhotoUrls.add(url)),
    isUploading: _photosUploading,
    setUploading: (v) => setState(() => _photosUploading = v),
    clearValidation: _clearValidationFlags,
    markDirty: () => _dirty = true,
  );

  Future<void> _submit() => submitListingForm(
    ref: ref,
    context: context,
    isMounted: () => mounted,
    formData: _formData,
    editingId: widget.listingId,
    isSubmitting: _submitting,
    setSubmitting: (v) => setState(() => _submitting = v),
    setStep: (s) => setState(() => _step = s),
    setValidation: (v) => setState(() => _validation = v),
    markClean: () => _dirty = false,
  );

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _submitting) {
      return true;
    }
    final locale = AppLocalizations.of(context);
    return FlatmatesDialog.confirm(
      context,
      title: locale.discardListingTitle,
      message: locale.discardListingMessage,
      cancelLabel: locale.keepEditingCta,
      confirmLabel: locale.discardCta,
      destructive: true,
    );
  }

  void _clearValidationFlags() {
    if (!mounted) return;
    setState(() => _validation = kNoListingValidation);
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      _validation = kNoListingValidation;
    });
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
    final step = _step;
    final submitting = _submitting;
    // A step change during an upload would drop the uploaded URL, so the
    // step buttons wait for photo and video uploads.
    final uploading = _photosUploading || _videoUploading;
    final loadingExisting = _loadingExisting;
    final validation = _validation;

    final summary = _formData.stepSummary(locale, step, _catalogLabel);
    final canAdvance = _formData.canProceed(step) && !uploading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_handleBack());
      },
      child: FlatmatesScreen(
        appBar: FlatmatesHeader.logo(onBack: () => unawaited(_handleBack())),
        body: Stack(
          children: [
            // The step header scrolls with the form, so the keyboard can
            // never squeeze it into an overflow.
            ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                ListingStepHeader(
                  locale: locale,
                  step: step,
                  totalSteps: totalSteps,
                  summary: summary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: ListingStepView(
                    step: step,
                    data: _formData,
                    catalog: _catalog,
                    catalogLabel: _catalogLabel,
                    showSocietyValidation: validation.society,
                    showCityValidation: validation.city,
                    showLocalityValidation: validation.locality,
                    showRentValidation: validation.rent,
                    showDepositValidation: validation.deposit,
                    showMaintenanceValidation: validation.maintenance,
                    showCostValidation: validation.cost,
                    showElectricityValidation: validation.electricity,
                    showPhotosValidation: validation.photos,
                    callbacks: _stepCallbacks,
                  ),
                ),
              ],
            ),
            // Edit mode: the form skeleton covers the empty form on the
            // page colour until the listing loads.
            if (loadingExisting)
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const FlatmatesSkeleton.form(itemCount: 4),
                ),
              ),
          ],
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
          onPressed: submitting || uploading
              ? null
              : (step < totalSteps - 1
                    ? (canAdvance
                          ? () => _goToStep(step + 1)
                          : () => _showInlineValidation(step))
                    // _submit itself gates canPublish and jumps to the first
                    // incomplete required step instead of posting empty data.
                    : _submit),
          icon: step < totalSteps - 1
              ? Icons.arrow_forward_rounded
              : Icons.upload_rounded,
          secondaryLabel: step > 0 ? locale.backCta : null,
          secondaryOnPressed: step > 0 && !uploading
              ? () => _goToStep(step - 1)
              : null,
          secondaryIcon: step > 0 ? Icons.arrow_back_rounded : null,
        ),
      ),
    );
  }

  void _showInlineValidation(int step) {
    setState(() => _validation = computeStepValidation(_formData, step));
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
    onKitchenTypeChanged: (v) => _updateString(() => _kitchenType = v),
    onVentilationTypeChanged: (v) => _updateString(() => _ventilationType = v),
    onFlatAmenityToggled: _toggleSet(_flatAmenities),
    onElectricityChanged: (v) => _updateString(() => _electricityIncluded = v),
    onGenderChanged: (v) => _updateString(() => _genderPreference = v),
    onAgeRangeChanged: (min, max) => _updateState(() {
      _ageMin = min;
      _ageMax = max;
    }),
    onNonNegotiableToggled: _toggleSet(_nonNegotiables),
    onAvailableFromChanged: (d) => _updateNullable(() => _availableFrom = d),
    onGoToStep: _goToStep,
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
    kitchenType: _kitchenType,
    ventilationType: _ventilationType,
    windowsController: _windowsController,
    ventilationShaftsController: _ventilationShaftsController,
    rentController: _rentController,
    depositController: _depositController,
    maintenanceController: _maintenanceController,
    electricityIncluded: _electricityIncluded,
    electricityEstController: _electricityEstController,
    cookCostController: _cookCostController,
    maidCostController: _maidCostController,
    setupCostController: _setupCostController,
    otherChargesController: _otherChargesController,
    otherChargesDescriptionController: _otherChargesDescriptionController,
    typicalDayController: _typicalDayController,
    genderPreference: _genderPreference,
    ageMin: _ageMin,
    ageMax: _ageMax,
    nonNegotiables: _nonNegotiables,
    availableFrom: _availableFrom,
  );

  void _onFieldChanged() {
    _dirty = true;
  }

  void _updateString(void Function() setter) => _updateState(setter);

  void _updateNullable(void Function() setter) => _updateState(setter);

  void _updateList(void Function() setter) => _updateState(setter);

  void _updateState(void Function() setter) {
    setState(setter);
    _dirty = true;
  }

  void Function(String, bool) _toggleSet(Set<String> set) =>
      (key, selected) => _updateState(() {
        selected ? set.add(key) : set.remove(key);
      });
}
