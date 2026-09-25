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

  static Future<void> _launchUrl(String updateUrl) async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
