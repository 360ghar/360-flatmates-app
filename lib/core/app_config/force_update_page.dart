import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_semantic_colors.dart';

/// Non-dismissible force update screen shown when the installed app version
/// is below [minimum_required_version].
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, required this.updateUrl});

  final String updateUrl;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update_outlined,
                    size: 64,
                    color: AppSemanticColors.accent,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    locale.forceUpdateTitle,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    locale.forceUpdateMessage,
                    // Brightness-aware token: this screen is non-dismissible,
                    // so the body copy must stay legible in dark mode too.
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _launchUrl,
                      child: Text(locale.forceUpdateCta),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the store page in the browser. [updateUrl] comes from server
  /// app-config, so only `http`/`https` is allowed: `canLaunchUrl` would
  /// otherwise hand a custom scheme (`intent://`, `tel:`, …) to another app
  /// on the device.
  Future<void> _launchUrl() async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.tryParse(updateUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      debugPrint('ForceUpdatePage._launchUrl: refused non-http(s) update URL');
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('ForceUpdatePage._launchUrl: $e');
    }
  }
}
