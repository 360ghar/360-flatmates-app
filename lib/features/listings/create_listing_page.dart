import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart' hide UploadFailure;
import '../../core/errors/l10n_bridge.dart';
import '../../core/storage/image_upload_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../discover/application/discover_feed_controller.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/components.dart';
import 'listings_repository.dart';
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
  int _step = 0;
  bool _submitting = false;
  bool _photosUploading = false;
  bool _dirty = false;
  bool _loadingExisting = false;
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
    if (widget.listingId != null) {
      _loadingExisting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadListingForEdit(widget.listingId!);
      });
    }
  }

  Future<void> _loadListingForEdit(int listingId) async {
    final locale = AppLocalizations.of(context);
    try {
      final listing = await ref
          .read(discoverRepositoryProvider)
          .fetchListing(listingId);
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
    if (_photosUploading) return; // prevent concurrent upload sessions
    final locale = AppLocalizations.of(context);
    try {
      final service = ref.read(imageUploadServiceProvider);
      final files = await service.pickImages(limit: 10 - _roomPhotoUrls.length);
      if (files.isEmpty) return;
      setState(() => _photosUploading = true);
      for (final file in files) {
        final result = await service.uploadListingPhoto(file);
        if (!mounted) return;
        if (result is UploadSuccess) {
          setState(() {
            _roomPhotoUrls.add(result.url);
            _validation = kNoListingValidation;
            _dirty = true;
          });
        } else if (result is UploadFailure) {
          FlatmatesToast.error(context, result.reason);
          break;
        }
      }
    } catch (e) {
      debugPrint('CreateListingPage._pickRoomPhotos failed: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.listingSubmitFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _photosUploading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return; // guard against double-submit
    final locale = AppLocalizations.of(context);
    setState(() => _submitting = true);
    final editingId = widget.listingId;
    try {
      final request = _formData.toRequest();
      final repo = ref.read(listingsRepositoryProvider);
      final listingId = editingId != null
          ? await repo.updateListing(editingId, request)
          : await repo.createListing(request);
      unawaited(ref.read(discoverFeedControllerProvider.notifier).refresh());
      ref.invalidate(myListingsProvider);
      await ref.read(bootstrapControllerProvider.notifier).refresh();
      if (!mounted) return;
      _dirty = false;
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Confirms discarding unsaved entries when the user backs out mid-flow.
  Future<bool> _confirmDiscard() async {
    if (!_dirty || _submitting) return true;
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
    _validation = kNoListingValidation;
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
    final summary = _formData.stepSummary(locale, _step, _catalogLabel);
    final canAdvance = _formData.canProceed(_step) && !_photosUploading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: FlatmatesHeader.logo(onBack: _handleBack),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  ListingStepHeader(
                    locale: locale,
                    step: _step,
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
                        AppSpacing.section * 4 + AppSpacing.sm,
                      ),
                      children: [
                        ListingStepView(
                          step: _step,
                          data: _formData,
                          catalog: _catalog,
                          catalogLabel: _catalogLabel,
                          showRentValidation: _validation.rent,
                          showDepositValidation: _validation.deposit,
                          showMaintenanceValidation: _validation.maintenance,
                          showCostValidation: _validation.cost,
                          showElectricityValidation: _validation.electricity,
                          showPhotosValidation: _validation.photos,
                          callbacks: _stepCallbacks,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_loadingExisting)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: FlatmatesBottomActionBar(
          primaryButtonKey: _step < totalSteps - 1
              ? const Key('listing_next_button')
              : const Key('listing_publish_button'),
          secondaryButtonKey: _step > 0
              ? const Key('listing_back_button')
              : null,
          label: _submitting
              ? locale.postingInProgress
              : (_step < totalSteps - 1
                    ? locale.onboardingNext
                    : locale.publishListingCta),
          onPressed: _submitting
              ? null
              : (_step < totalSteps - 1
                    ? (canAdvance
                          ? () {
                              _showInlineValidation();
                              setState(() {
                                _step++;
                                _clearValidationFlags();
                              });
                            }
                          : () {
                              _showInlineValidation();
                              setState(() {});
                            })
                    : _submit),
          icon: _step < totalSteps - 1
              ? Icons.arrow_forward_rounded
              : Icons.upload_rounded,
          secondaryLabel: _step > 0 ? locale.backCta : null,
          secondaryOnPressed: _step > 0
              ? () => setState(() {
                  _step--;
                  _clearValidationFlags();
                })
              : null,
          secondaryIcon: _step > 0 ? Icons.arrow_back_rounded : null,
        ),
      ),
    );
  }

  void _showInlineValidation() {
    _validation = computeStepValidation(_formData, _step);
  }

  ListingStepCallbacks get _stepCallbacks => ListingStepCallbacks(
    onFieldChanged: _onFieldChanged,
    onSocietyTypeChanged: (v) => setState(() {
      _societyType = v;
      _dirty = true;
    }),
    onSocietyAmenityToggled: _toggleSet(_societyAmenities),
    onVibeToggled: _toggleSet(_societyVibeTags),
    onRoomTypeChanged: (v) => setState(() {
      _roomType = v;
      _dirty = true;
    }),
    onFurnishingToggled: _toggleSet(_roomFurnishing),
    onFeatureToggled: _toggleSet(_roomFeatures),
    onPickPhotos: _pickRoomPhotos,
    onRemovePhoto: (i) => setState(() {
      _roomPhotoUrls.removeAt(i);
      _dirty = true;
    }),
    onVideoTourUrlChanged: (u) => setState(() {
      _videoTourUrl = u;
      _dirty = true;
    }),
    onVideoUploadingChanged: (v) => setState(() => _videoUploading = v),
    onFlatConfigChanged: (v) => setState(() {
      _flatConfig = v;
      _dirty = true;
    }),
    onFlatAmenityToggled: _toggleSet(_flatAmenities),
    onElectricityChanged: (v) => setState(() {
      _electricityIncluded = v;
      _dirty = true;
    }),
    onGenderChanged: (v) => setState(() {
      _genderPreference = v;
      _dirty = true;
    }),
    onAgeRangeChanged: (min, max) => setState(() {
      _ageMin = min;
      _ageMax = max;
      _dirty = true;
    }),
    onNonNegotiableToggled: _toggleSet(_nonNegotiables),
    onAvailableFromChanged: (d) => setState(() {
      _availableFrom = d;
      _dirty = true;
    }),
    onGoToStep: (s) => setState(() => _step = s),
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

  /// Marks the form dirty when a text field changes (drives the back guard).
  void _onFieldChanged() => setState(() => _dirty = true);

  /// Helper to create a toggle callback for a `Set`.
  void Function(String, bool) _toggleSet(Set<String> set) =>
      (key, selected) => setState(() {
        selected ? set.add(key) : set.remove(key);
        _dirty = true;
      });
}
