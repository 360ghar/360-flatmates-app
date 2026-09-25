import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_screen.dart';
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
    final locale = AppLocalizations.of(context);

    return FlatmatesScreen(
      appBar: FlatmatesHeader.backTitle(title: title),
      body: FlatmatesAsyncView<String>(
        value: content,
        loading: const FlatmatesSkeleton.legalContent(),
        error: (error, stack) => FlatmatesErrorState(
          message: locale.couldNotLoadContent,
          onRetry: () => ref.invalidate(_legalContentProvider(assetPath)),
        ),
        data: (content) => _LegalMarkdownContent(content: content),
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
    final ink = AppSemanticColors.textPrimaryFor(theme.brightness);
    // Long-form reading: 16 px body in ink; display headings keep the
    // theme's Gambarino weights (no forced bold).
    final body = theme.textTheme.bodyLarge?.copyWith(color: ink, height: 1.5);

    return Markdown(
      data: content,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.lg,
      ),
      styleSheet: MarkdownStyleSheet(
        h1: theme.textTheme.headlineMedium?.copyWith(color: ink),
        h2: theme.textTheme.titleLarge?.copyWith(color: ink),
        h3: theme.textTheme.titleMedium?.copyWith(color: ink),
        p: body,
        listBullet: body,
        strong: body?.copyWith(fontWeight: FontWeight.w700),
        em: body?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}
