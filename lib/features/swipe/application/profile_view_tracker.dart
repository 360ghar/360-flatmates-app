import '../swipe_repository.dart' show kMaxProfileViewSeconds;

class ProfileViewSample {
  const ProfileViewSample({
    required this.profileId,
    required this.durationSeconds,
  });

  final int profileId;
  final int durationSeconds;
}

class ProfileViewTracker {
  DateTime? _startedAt;
  int? _profileId;

  void start(int profileId) {
    _profileId = profileId;
    _startedAt = DateTime.now();
  }

  void clear() {
    _profileId = null;
    _startedAt = null;
  }

  ProfileViewSample? finish() {
    final profileId = _profileId;
    final startedAt = _startedAt;
    clear();
    if (profileId == null || startedAt == null) return null;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    if (elapsed <= 0) return null;
    // The API accepts at most 3600 seconds; a longer view is capped, not lost.
    final durationSeconds = elapsed > kMaxProfileViewSeconds
        ? kMaxProfileViewSeconds
        : elapsed;
    return ProfileViewSample(
      profileId: profileId,
      durationSeconds: durationSeconds,
    );
  }
}
