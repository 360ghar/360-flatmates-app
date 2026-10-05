import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../chats/match_qna_nudge.dart';
import '../shared/presentation/flatmates_toast.dart';
import 'application/match_qna_controller.dart';

/// Bottom sheet that nudges the user to answer 3 ice-breaker Q&A questions
/// after a match, before they start chatting. The form is the shared
/// [MatchQnANudge]; this sheet saves through [matchQnAControllerProvider].
class MatchQnANudgeSheet extends ConsumerWidget {
  const MatchQnANudgeSheet({required this.conversationId, super.key});

  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MatchQnANudge(
      peerName: '',
      onComplete: (answers) async {
        final locale = AppLocalizations.of(context);
        final ok = await ref
            .read(matchQnAControllerProvider.notifier)
            .submitAnswers(
              conversationId: conversationId,
              q1: answers['q1'] ?? '',
              q2: answers['q2'] ?? '',
              q3: answers['q3'] ?? '',
            );
        // Keep the sheet open so the user can retry without reopening.
        if (!ok && context.mounted) {
          FlatmatesToast.error(context, locale.errorUnknown);
        }
        return ok;
      },
    );
  }
}
