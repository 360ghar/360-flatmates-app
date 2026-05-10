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
    final durationSeconds = DateTime.now().difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return null;
    return ProfileViewSample(
      profileId: profileId,
      durationSeconds: durationSeconds,
    );
  }
}
