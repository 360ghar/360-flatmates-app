import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/image_upload_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/components.dart';
import 'listings_repository.dart';
import 'presentation/widgets/listing_form_data.dart';
import 'presentation/widgets/listing_step_header.dart';
import 'presentation/widgets/listing_step_metadata.dart';
import 'presentation/widgets/step_about_section.dart';
import 'presentation/widgets/step_review_section.dart';
import 'presentation/widgets/step_costs_section.dart';
import 'presentation/widgets/step_flat_section.dart';
import 'presentation/widgets/step_location_section.dart';
import 'presentation/widgets/step_room_section.dart';
import 'presentation/widgets/step_society_section.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({this.listingId, super.key});

  final int? listingId;

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  int _step = 0;
  bool _submitting = false;
  bool _showRentValidation = false;
  bool _showPhotosValidation = false;
  bool _showDepositValidation = false;
  bool _showMaintenanceValidation = false;
  bool _showCostValidation = false;
  bool _showElectricityValidation = false;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadListingForEdit(widget.listingId!);
      });
    }
  }

  Future<void> _loadListingForEdit(int listingId) async {
    try {
      final listing = await ref
          .read(discoverRepositoryProvider)
          .fetchListing(listingId);
      if (!mounted) return;
      setState(() {
        _societyController.text = listing.title;
        _cityController.text = listing.city ?? '';
        _localityController.text = listing.locality ?? '';
        _rentController.text = listing.monthlyRent.toStringAsFixed(0);
        _availableFrom = listing.availableFrom;
      });
    } catch (_) {}
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
            double.tryParse(_rentController.text.trim()) != null &&
            (_electricityIncluded != 'separate' ||
                (_electricityEstController.text.trim().isNotEmpty &&
                    double.tryParse(_electricityEstController.text.trim()) !=
                        null)),
      6 => true,
      7 => true,
      _ => false,
    };
  }

  double get _totalMonthlyOutflow {
    final rent = double.tryParse(_rentController.text.trim()) ?? 0;
    final maintenance =
        double.tryParse(_maintenanceController.text.trim()) ?? 0;
    final electricity = _electricityIncluded == 'separate'
        ? (double.tryParse(_electricityEstController.text.trim()) ?? 0)
        : 0;
    final cook = double.tryParse(_cookCostController.text.trim()) ?? 0;
    final maid = double.tryParse(_maidCostController.text.trim()) ?? 0;
    return rent + maintenance + electricity + cook + maid;
  }

  Future<void> _pickRoomPhotos() async {
    try {
      final service = ref.read(imageUploadServiceProvider);
      final files = await service.pickImages(limit: 10 - _roomPhotoUrls.length);
      if (files.isEmpty) return;
      for (final file in files) {
        final result = await service.uploadListingPhoto(file);
        if (result is UploadSuccess) {
          setState(() {
            _roomPhotoUrls.add(result.url);
            _showPhotosValidation = false;
          });
        } else if (result is UploadFailure) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.reason)));
          break;
        }
      }
    } catch (e) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.listingSubmitFailed)));
    }
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final request = _formData.toRequest();
      final listingId = await ref
          .read(listingsRepositoryProvider)
          .createListing(request);
      ref.invalidate(discoverListingsProvider);
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
      ).showSnackBar(SnackBar(content: Text(locale.listingSubmitFailed)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearValidationFlags() {
    _showRentValidation = false;
    _showPhotosValidation = false;
    _showDepositValidation = false;
    _showMaintenanceValidation = false;
    _showCostValidation = false;
    _showElectricityValidation = false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final summary = _formData.stepSummary(locale, _step, _catalogLabel);

    return Scaffold(
      appBar: FlatmatesHeader.logo(onBack: () => Navigator.pop(context)),
      body: SafeArea(
        child: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                children: [_buildStep(_step)],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FlatmatesBottomActionBar(
        primaryButtonKey: _step < totalSteps - 1
            ? const Key('listing_next_button')
            : const Key('listing_publish_button'),
        secondaryButtonKey: _step > 0 ? const Key('listing_back_button') : null,
        label: _submitting
            ? locale.postingInProgress
            : (_step < totalSteps - 1
                  ? locale.onboardingNext
                  : locale.publishListingCta),
        onPressed: _submitting
            ? null
            : (_step < totalSteps - 1
                  ? (_canProceed()
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
    );
  }

  void _showInlineValidation() {
    _clearValidationFlags();
    if (_step == 3 && _roomPhotoUrls.isEmpty) {
      _showPhotosValidation = true;
    }
    if (_step == 5) {
      if (_rentController.text.trim().isEmpty) _showRentValidation = true;
      if (_electricityIncluded == 'separate') {
        final estText = _electricityEstController.text.trim();
        if (estText.isEmpty || double.tryParse(estText) == null) {
          _showElectricityValidation = true;
        }
      }
      final depositText = _depositController.text.trim();
      if (depositText.isNotEmpty && double.tryParse(depositText) == null) {
        _showDepositValidation = true;
      }
      final maintenanceText = _maintenanceController.text.trim();
      if (maintenanceText.isNotEmpty &&
          double.tryParse(maintenanceText) == null) {
        _showMaintenanceValidation = true;
      }
      final cookText = _cookCostController.text.trim();
      if (cookText.isNotEmpty && double.tryParse(cookText) == null) {
        _showCostValidation = true;
      }
      final maidText = _maidCostController.text.trim();
      if (maidText.isNotEmpty && double.tryParse(maidText) == null) {
        _showCostValidation = true;
      }
    }
  }

  Widget _buildStep(int step) => switch (step) {
    0 => StepLocationSection(
      societyController: _societyController,
      addressController: _addressController,
      cityController: _cityController,
      localityController: _localityController,
      onChanged: () => setState(() {}),
    ),
    1 => StepSocietySection(
      societyType: _societyType,
      societyAmenities: _societyAmenities,
      societyVibeTags: _societyVibeTags,
      catalog: _catalog,
      iconForOption: listingIconForOption,
      onSocietyTypeChanged: (v) => setState(() => _societyType = v),
      onAmenityToggled: _toggleSet(_societyAmenities),
      onVibeToggled: _toggleSet(_societyVibeTags),
    ),
    2 || 3 => StepRoomSection(
      step: step,
      roomType: _roomType,
      roomFurnishing: _roomFurnishing,
      roomFeatures: _roomFeatures,
      roomPhotoUrls: _roomPhotoUrls,
      videoTourUrl: _videoTourUrl,
      videoUploading: _videoUploading,
      showPhotosValidation: _showPhotosValidation,
      catalog: _catalog,
      iconForOption: listingIconForOption,
      onRoomTypeChanged: (v) => setState(() => _roomType = v),
      onFurnishingToggled: _toggleSet(_roomFurnishing),
      onFeatureToggled: _toggleSet(_roomFeatures),
      onPickPhotos: _pickRoomPhotos,
      onRemovePhoto: (i) => setState(() => _roomPhotoUrls.removeAt(i)),
      onVideoTourUrlChanged: (u) => setState(() => _videoTourUrl = u),
      onVideoUploadingChanged: (v) => setState(() => _videoUploading = v),
    ),
    4 => StepFlatSection(
      flatConfig: _flatConfig,
      floorController: _floorController,
      totalFloorsController: _totalFloorsController,
      flatAmenities: _flatAmenities,
      catalog: _catalog,
      iconForOption: listingIconForOption,
      onFlatConfigChanged: (v) => setState(() => _flatConfig = v),
      onAmenityToggled: _toggleSet(_flatAmenities),
    ),
    5 => StepCostsSection(
      rentController: _rentController,
      depositController: _depositController,
      maintenanceController: _maintenanceController,
      electricityIncluded: _electricityIncluded,
      electricityEstController: _electricityEstController,
      cookCostController: _cookCostController,
      maidCostController: _maidCostController,
      setupCostController: _setupCostController,
      showRentValidation: _showRentValidation,
      showDepositValidation: _showDepositValidation,
      showMaintenanceValidation: _showMaintenanceValidation,
      showCostValidation: _showCostValidation,
      showElectricityValidation: _showElectricityValidation,
      totalMonthlyOutflow: _totalMonthlyOutflow,
      flatConfig: _flatConfig,
      onElectricityChanged: (v) => setState(() => _electricityIncluded = v),
      onChanged: () => setState(() {}),
    ),
    6 => StepAboutSection(
      typicalDayController: _typicalDayController,
      genderPreference: _genderPreference,
      ageMin: _ageMin,
      ageMax: _ageMax,
      nonNegotiables: _nonNegotiables,
      availableFrom: _availableFrom,
      catalog: _catalog,
      onGenderChanged: (v) => setState(() => _genderPreference = v),
      onAgeRangeChanged: (min, max) => setState(() {
        _ageMin = min;
        _ageMax = max;
      }),
      onNonNegotiableToggled: _toggleSet(_nonNegotiables),
      onAvailableFromChanged: (d) => setState(() => _availableFrom = d),
    ),
    7 => StepReviewSection(
      data: _formData,
      catalogLabel: _catalogLabel,
      totalMonthlyOutflow: _totalMonthlyOutflow,
      onGoToStep: (s) => setState(() => _step = s),
    ),
    _ => const SizedBox.shrink(),
  };

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

  /// Helper to create a toggle callback for a `Set`.
  void Function(String, bool) _toggleSet(Set<String> set) =>
      (key, selected) => setState(() {
        selected ? set.add(key) : set.remove(key);
      });
}
