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
    final textTheme = Theme.of(context).textTheme;
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _launchUrl(context),
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

  Future<void> _launchUrl(BuildContext context) async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
