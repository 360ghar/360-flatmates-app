/// A row of `GET /flatmates/blocks`:
/// `{ id, blocked_user_id, blocked_user: {id, display_name, avatar_url}, created_at }`.
///
/// The blocked user is a `PublicUserRef`: a name and an avatar, nothing else.
/// Unblock is keyed by the peer user id ([blockedUserId]), not by the row id.
class BlockedUser {
  const BlockedUser({
    required this.blockedUserId,
    required this.name,
    this.imageUrl,
  });

  final int blockedUserId;
  final String name;
  final String? imageUrl;

  /// Throws [FormatException] for a row with no usable user id, so the list
  /// parser skips it (and logs) instead of showing a row whose Unblock would
  /// target an id that is not a user.
  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(
      json['blocked_user'] as Map? ?? const {},
    );
    final id =
        (json['blocked_user_id'] as num?)?.toInt() ??
        (user['id'] as num?)?.toInt();
    if (id == null || id <= 0) {
      throw FormatException('blocked row has no blocked_user_id: $json');
    }
    final displayName = user['display_name']?.toString().trim() ?? '';
    return BlockedUser(
      blockedUserId: id,
      name: displayName.isEmpty ? 'Flatmate' : displayName,
      imageUrl: user['avatar_url']?.toString(),
    );
  }
}
