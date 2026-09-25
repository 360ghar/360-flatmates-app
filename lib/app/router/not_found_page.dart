import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/shared/presentation/components.dart';
import '../../features/shared/presentation/paper/paper_scene.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shown for unknown routes, deep links that match nothing, and route ids
/// that fail to parse. Always offers a way back.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.message});

  /// Specific reason (for example "Invalid listing ID"). Defaults to the
  /// generic not-found copy.
  final String? message;

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/discover');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => _leave(context))),
      body: SafeArea(
        child: FlatmatesEmptyState(
          prop: PaperProp.rainCloud,
          title: locale.notFoundTitle,
          subtitle: message ?? locale.errorNotFound,
          ctaLabel: locale.navHome,
          onCtaTap: () => context.go('/discover'),
          expand: true,
        ),
      ),
    );
  }
}
