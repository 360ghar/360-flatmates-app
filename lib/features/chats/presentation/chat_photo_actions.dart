import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart' show AppFailure;
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/storage/image_upload_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_toast.dart';
import '../application/messages_controller.dart';

/// Picks one gallery image, uploads it as a private chat photo, then sends
/// it as an `image` message on [conversationId].
///
/// No-ops while a send or upload is already in flight. Surfaces
/// [AppFailure] messages when possible; otherwise [AppLocalizations.failedToSendPhoto].
Future<void> sendPhotoFromChat({
  required BuildContext context,
  required WidgetRef ref,
  required int conversationId,
  required bool Function() isUploading,
  required void Function(bool value) setUploading,
  VoidCallback? onSuccess,
}) async {
  final locale = AppLocalizations.of(context);
  final messagesState = ref.read(messagesControllerProvider(conversationId));
  if (messagesState.isSending || isUploading()) return;

  try {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 1);
    if (files.isEmpty) return;
    if (!context.mounted) return;

    setUploading(true);
    final result = await service.uploadChatPhoto(files.first);
    if (!context.mounted) return;

    switch (result) {
      case UploadSuccess(:final url):
        await ref
            .read(messagesControllerProvider(conversationId).notifier)
            .sendMessage(attachmentUrl: url, messageType: 'image');
        onSuccess?.call();
      case UploadFailure(:final reason, :final underlyingError):
        debugPrint(
          'sendPhotoFromChat upload failed: $reason ($underlyingError)',
        );
        FlatmatesToast.error(context, locale.failedToSendPhoto);
    }
  } catch (e) {
    debugPrint('sendPhotoFromChat failed: $e');
    if (!context.mounted) return;
    final msg = e is AppFailure
        ? e.userMessage(locale.toUserMessageL10n())
        : locale.failedToSendPhoto;
    FlatmatesToast.error(context, msg);
  } finally {
    setUploading(false);
  }
}
