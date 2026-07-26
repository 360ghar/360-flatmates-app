import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../application/create_listing_controller.dart';
import 'listing_form_data.dart';

/// Upload room photos one-by-one so a single failure does not abort the batch.
Future<void> pickAndUploadRoomPhotos({
  required WidgetRef ref,
  required BuildContext context,
  required bool Function() isMounted,
  required int currentPhotoCount,
  required void Function(String url) onUrlAdded,
  required bool isUploading,
  required void Function(bool uploading) setUploading,
  required VoidCallback clearValidation,
  required VoidCallback markDirty,
}) async {
  if (isUploading) return;
  final locale = AppLocalizations.of(context);
  final controller = ref.read(createListingControllerProvider);
  try {
    final files = await controller.pickRoomPhotos(
      limit: 10 - currentPhotoCount,
    );
    if (files.isEmpty) return;
    if (!context.mounted || !isMounted()) return;
    setUploading(true);
    for (final file in files) {
      try {
        final url = await controller.uploadRoomPhoto(file);
        if (!context.mounted || !isMounted()) return;
        onUrlAdded(url);
        clearValidation();
        markDirty();
      } catch (e) {
        debugPrint('pickAndUploadRoomPhotos upload failed for $file: $e');
        if (!context.mounted || !isMounted()) return;
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.listingSubmitFailed;
        FlatmatesToast.error(context, msg);
      }
    }
  } catch (e) {
    debugPrint('pickAndUploadRoomPhotos failed: $e');
    if (!context.mounted || !isMounted()) return;
    final msg = e is AppFailure
        ? e.userMessage(locale.toUserMessageL10n())
        : locale.listingSubmitFailed;
    FlatmatesToast.error(context, msg);
  } finally {
    if (isMounted()) setUploading(false);
  }
}

/// Validates required steps then creates/updates the listing.
Future<void> submitListingForm({
  required WidgetRef ref,
  required BuildContext context,
  required bool Function() isMounted,
  required ListingFormData formData,
  required int? editingId,
  required bool isSubmitting,
  required void Function(bool submitting) setSubmitting,
  required void Function(int step) setStep,
  required void Function(ListingStepValidation validation) setValidation,
  required VoidCallback markClean,
}) async {
  if (isSubmitting) return;
  final locale = AppLocalizations.of(context);

  if (!formData.canPublish) {
    if (!formData.canProceed(0)) {
      setStep(0);
      setValidation(computeStepValidation(formData, 0));
    } else if (!formData.canProceed(3)) {
      setStep(3);
      setValidation(computeStepValidation(formData, 3));
    } else if (!formData.canProceed(5)) {
      setStep(5);
      setValidation(computeStepValidation(formData, 5));
    }
    FlatmatesToast.error(context, locale.listingSubmitFailed);
    return;
  }

  setSubmitting(true);
  try {
    final result = await ref
        .read(createListingControllerProvider)
        .submit(request: formData.toRequest(), editingId: editingId);
    if (!context.mounted || !isMounted()) return;
    markClean();
    FlatmatesToast.success(
      context,
      editingId != null
          ? locale.listingUpdatedToast
          : locale.postListingSuccess,
    );
    if (result.id != null) {
      context.go('/listing-review/${result.id}', extra: result.listing);
    } else {
      context.go('/discover');
    }
  } catch (error) {
    debugPrint('submitListingForm failed: $error');
    if (!context.mounted || !isMounted()) return;
    final msg = error is AppFailure
        ? error.userMessage(locale.toUserMessageL10n())
        : locale.listingSubmitFailed;
    FlatmatesToast.error(context, msg);
  } finally {
    if (isMounted()) setSubmitting(false);
  }
}
