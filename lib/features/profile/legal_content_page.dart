import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_header.dart';

final _legalContentProvider =
    StateProvider.family<String, String>((ref, assetPath) => '');
final _legalLoadingProvider =
    StateProvider.family<bool, String>((ref, assetPath) => true);
final _legalHasErrorProvider =
    StateProvider.family<bool, String>((ref, assetPath) => false);

class LegalContentPage extends ConsumerStatefulWidget {
  const LegalContentPage({
    required this.title,
    required this.assetPath,
    super.key,
  });

  final String title;
  final String assetPath;

  @override
  ConsumerState<LegalContentPage> createState() => _LegalContentPageState();
}

class _LegalContentPageState extends ConsumerState<LegalContentPage> {
  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final content = await rootBundle.loadString(widget.assetPath);
      if (!mounted) return;
      ref.read(_legalContentProvider(widget.assetPath).notifier).state =
          content;
      ref.read(_legalLoadingProvider(widget.assetPath).notifier).state = false;
    } catch (e) {
      debugPrint(
        'LegalContentPage._loadContent failed for ${widget.assetPath}: $e',
      );
      if (!mounted) return;
      ref.read(_legalHasErrorProvider(widget.assetPath).notifier).state = true;
      ref.read(_legalLoadingProvider(widget.assetPath).notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final content = ref.watch(_legalContentProvider(widget.assetPath));
    final loading = ref.watch(_legalLoadingProvider(widget.assetPath));
    final hasError = ref.watch(_legalHasErrorProvider(widget.assetPath));

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: widget.title),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    locale.couldNotLoadContent,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Markdown(
                data: content,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                styleSheet: MarkdownStyleSheet(
                  h1: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                  h2: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                  h3: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                  p: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                    height: 1.6,
                  ),
                  listBullet: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                  strong: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                  em: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
      ),
    );
  }
}
