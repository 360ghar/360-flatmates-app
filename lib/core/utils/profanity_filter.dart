/// Basic client-side profanity filter for user-generated content.
///
/// Provides a lightweight content filter to prevent the most egregious
/// profanity from being sent. This is a client-side complement to
/// server-side moderation — not a replacement.
class ProfanityFilter {
  ProfanityFilter._();

  /// Checks if [text] contains profanity. Returns true if blocked content
  /// is detected. Uses a simple substring match against a blocklist.
  static bool containsProfanity(String text) {
    final lower = text.toLowerCase();
    return _blockedWords.any((word) => lower.contains(word));
  }

  /// Returns a censored version of [text] where matched words are
  /// replaced with asterisks.
  static String censor(String text) {
    var result = text;
    for (final word in _blockedWords) {
      final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
      result = result.replaceAll(pattern, '*' * word.length);
    }
    return result;
  }

  /// Basic English blocklist. Server-side moderation handles the
  /// comprehensive filtering — this is a first-pass client filter.
  static const _blockedWords = [
    'fuck',
    'shit',
    'asshole',
    'bastard',
    'bitch',
    'dickhead',
    'motherfucker',
    'cunt',
    'wanker',
  ];
}
