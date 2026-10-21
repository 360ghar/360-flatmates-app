import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/chats_repository.dart';

/// Controller for submitting match Q&A ice-breaker answers.
///
/// Saves through [ChatsRepository.submitQnA], the one place that builds the
/// `/qna` body (answer keys `"0"`, `"1"`, `"2"`; a blank answer is left out).
class MatchQnAController extends Notifier<bool> {
  @override
  bool build() => false; // isSubmitting

  /// Submits the 3 Q&A answers. Returns `true` on success, `false` on
  /// failure (error is logged; the caller shows a toast).
  Future<bool> submitAnswers({
    required int conversationId,
    required String q1,
    required String q2,
    required String q3,
  }) async {
    if (state) return false;
    state = true;
    try {
      await ref.read(chatsRepositoryProvider).submitQnA(conversationId, {
        'q1': q1,
        'q2': q2,
        'q3': q3,
      });
      return true;
    } catch (e) {
      debugPrint(
        'MatchQnAController.submitAnswers failed for conversation '
        '$conversationId: $e',
      );
      return false;
    } finally {
      state = false;
    }
  }
}

final matchQnAControllerProvider = NotifierProvider<MatchQnAController, bool>(
  MatchQnAController.new,
);
