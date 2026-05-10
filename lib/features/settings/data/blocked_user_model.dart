class BlockedUser {
  const BlockedUser({
    required this.blockedUserId,
    required this.name,
    this.imageUrl,
    this.location,
  });

  final int blockedUserId;
  final String name;
  final String? imageUrl;
  final String? location;

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? const {});
    final locationParts = [
      user['locality']?.toString(),
      user['city']?.toString(),
    ].where((value) => value != null && value.trim().isNotEmpty).toList();
    return BlockedUser(
      blockedUserId: (json['blocked_user_id'] as num?)?.toInt() ?? 0,
      name: user['full_name']?.toString().trim().isNotEmpty == true
          ? user['full_name'].toString()
          : 'Flatmate',
      imageUrl: user['profile_image_url']?.toString(),
      location: locationParts.isEmpty ? null : locationParts.join(', '),
    );
  }
}
