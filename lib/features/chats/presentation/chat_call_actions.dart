import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_toast.dart';
import '../application/chat_actions_controller.dart';

/// Calls a matched peer.
///
/// The phone is read from the match contact route
/// (`GET /flatmates/matches/{id}/contact`), never from a peer payload. A pair
/// that is not an active match has no phone, and the user is told so.
Future<void> callMatchedPeer({
  required BuildContext context,
  required WidgetRef ref,
  required int peerId,
}) async {
  final locale = AppLocalizations.of(context);
  String? phone;
  try {
    phone = await ref.read(chatActionsControllerProvider).matchPhone(peerId);
  } catch (e) {
    debugPrint('callMatchedPeer($peerId) failed: $e');
    if (!context.mounted) return;
    FlatmatesToast.error(
      context,
      e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.errorUnknown,
    );
    return;
  }
  if (!context.mounted) return;
  if (phone == null || phone.isEmpty) {
    FlatmatesToast.info(context, locale.phoneNotAvailable);
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone);
  // `launchUrl` can return false even after `canLaunchUrl` said yes.
  final launched = await canLaunchUrl(uri) && await launchUrl(uri);
  if (!launched && context.mounted) {
    FlatmatesToast.info(context, locale.phoneNotAvailable);
  }
}
