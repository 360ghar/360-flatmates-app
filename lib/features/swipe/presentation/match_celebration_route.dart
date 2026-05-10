import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void pushMatchCelebration(
  BuildContext context, {
  required String userName,
  required String? userImageUrl,
  required String peerName,
  required String? peerImageUrl,
  required int? conversationId,
}) {
  context.push(
    '/match-celebration',
    extra: {
      'userName': userName,
      'userImageUrl': userImageUrl,
      'peerName': peerName,
      'peerImageUrl': peerImageUrl,
      'conversationId': conversationId,
    },
  );
}
