import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/image_upload_service.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../discover/application/discover_feed_controller.dart';
import '../../swipe/application/swipe_deck_controller.dart';
import '../profile_repository.dart';

final editProfileActionsControllerProvider =
    Provider<EditProfileActionsController>(EditProfileActionsController.new);

/// Edit-profile writes, kept out of the page layer.
class EditProfileActionsController {
  EditProfileActionsController(this._ref);
  final Ref _ref;

  /// Saves [payload], reloads the bootstrap profile, and drops the feed and
  /// deck, which read the profile once and would keep stale results.
  Future<void> save(Map<String, dynamic> payload) async {
    await _ref.read(profileRepositoryProvider).updateProfile(payload: payload);
    await _ref.read(bootstrapControllerProvider.notifier).refresh();
    _ref.invalidate(discoverFeedControllerProvider);
    _ref.invalidate(swipeDeckControllerProvider);
  }

  /// Opens the picker for one photo and uploads it. Returns null when the
  /// user cancels the picker.
  Future<UploadResult?> pickAndUploadPhoto() async {
    final service = _ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 1);
    if (files.isEmpty) return null;
    return service.uploadProfilePhoto(files.first);
  }
}
