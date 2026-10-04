import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/shared/presentation/flatmates_button.dart';
import '../../features/shared/presentation/flatmates_dialog.dart';
import '../../l10n/gen/app_localizations.dart';

/// Optional update dialog. Dismissal is tracked per-version (by the caller's
/// [onDismiss]) so the user is not repeatedly nagged for the same version.
abstract final class OptionalUpdateDialog {
  static Future<void> show(
    BuildContext context, {
    required String updateUrl,
    required String message,
    required VoidCallback onDismiss,
  }) {
    final locale = AppLocalizations.of(context);
    return FlatmatesDialog.custom<void>(
      context,
      barrierDismissible: false,
      title: locale.optionalUpdateTitle,
      body: (ctx, _) => Text(
        message.isNotEmpty ? message : locale.optionalUpdateMessage,
        style: Theme.of(ctx).textTheme.bodyLarge,
      ),
      actions: (ctx, _, close) => [
        FlatmatesButton.tertiary(
          label: locale.optionalUpdateLater,
          onPressed: () {
            close();
            onDismiss();
          },
        ),
        FlatmatesButton(
          label: locale.optionalUpdateCta,
          onPressed: () {
            close();
            _launchUrl(updateUrl);
          },
        ),
      ],
    );
  }

  /// Opens the store page in the browser. [updateUrl] comes from server
  /// app-config, so only `http`/`https` is allowed: `canLaunchUrl` would
  /// otherwise hand a custom scheme (`intent://`, `tel:`, …) to another app
  /// on the device.
  static Future<void> _launchUrl(String updateUrl) async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.tryParse(updateUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      debugPrint(
        'OptionalUpdateDialog._launchUrl: refused non-http(s) update URL',
      );
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('OptionalUpdateDialog._launchUrl: $e');
    }
  }
}
