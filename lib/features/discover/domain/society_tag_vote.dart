/// The answer to `POST /flatmates/listings/{id}/society-tags/votes`
/// (`SocietyTagVoteOut`). The listing payload carries no vote counts: the
/// server hides them from `listing_preferences`, so this is the only source.
class SocietyTagVote {
  const SocietyTagVote({
    required this.tag,
    required this.upvotes,
    required this.downvotes,
    required this.currentVote,
    this.disputed = false,
  });

  /// Null when the body has no readable `tag`.
  static SocietyTagVote? fromJson(Object? json) {
    if (json is! Map) return null;
    final tag = json['tag'];
    final up = json['upvotes'];
    final down = json['downvotes'];
    if (tag is! String || up is! num || down is! num) return null;
    final vote = json['current_vote'];
    return SocietyTagVote(
      tag: tag,
      upvotes: up.toInt(),
      downvotes: down.toInt(),
      currentVote: vote == 'up' || vote == 'down' ? vote as String : null,
      disputed: json['disputed'] == true,
    );
  }

  final String tag;
  final int upvotes;
  final int downvotes;

  /// `up` or `down`, null when the server sent anything else.
  final String? currentVote;
  final bool disputed;

  int get netVotes => upvotes - downvotes;
}
