import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_skeleton.dart';

final _legalContentProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, assetPath) => rootBundle.loadString(assetPath),
);

class LegalContentPage extends ConsumerWidget {
  const LegalContentPage({
    required this.title,
    required this.assetPath,
    super.key,
  });

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(_legalContentProvider(assetPath));

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: title),
      body: SafeArea(
        child: FlatmatesAsyncView<String>(
          value: content,
          loading: const FlatmatesSkeleton.legalContent(),
          error: (error, stack) => const _LegalContentError(),
          data: (content) => _LegalMarkdownContent(content: content),
        ),
      ),
    );
  }
}

class _LegalContentError extends StatelessWidget {
  const _LegalContentError();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          locale.couldNotLoadContent,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LegalMarkdownContent extends StatelessWidget {
  const _LegalMarkdownContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Markdown(
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
    );
  }
}
