/// Centralized API path constants to avoid path drift and typos.
///
/// Use these constants in repositories instead of inline path strings.
abstract final class FlatmatesEndpoints {
  // -- Auth / User --
  static const me = '/users/me';
  static const authState = '/users/me/auth-state?app=flatmates';
  static const completeFlatmatesOnboarding =
      '/users/me/onboarding?app=flatmates';
  static const deleteAccount = '/users/me';
  static const userLocation = '/users/location';

  // -- Auth state-machine (Supabase-mirrored) --
  static const identifierStatus = '/auth/identifier-status';
  static const lastMethod = '/auth/last-method';
  static const authConfig = '/auth/config';

  // -- Bootstrap & Profile --
  static const bootstrap = '/flatmates/bootstrap';
  static const profile = '/flatmates/profile';

  // -- Catalogs --
  static const catalogs = '/flatmates/catalogs';

  // -- Blocks --
  static const blocks = '/flatmates/blocks';
  static String block(int id) => '/flatmates/blocks/$id';

  // -- Conversations --
  static const conversations = '/flatmates/conversations';
  static String conversation(int id) => '/flatmates/conversations/$id';
  static String conversationMessages(int id) =>
      '/flatmates/conversations/$id/messages';
  static String conversationMarkRead(int id) =>
      '/flatmates/conversations/$id/mark-read';
  static String conversationQnA(int id) => '/flatmates/conversations/$id/qna';

  // -- Swipes --
  static const swipes = '/flatmates/swipes';
  static const incomingLikes = '/flatmates/likes';
  static const outgoingLikes = '/flatmates/outgoing-likes';
  static const profileViews = '/flatmates/profile-views';

  // -- Reports --
  static const reports = '/flatmates/reports';

  // -- Properties --
  static const properties = '/properties';
  static String property(int id) => '/properties/$id';
  static const myProperties = '/properties/me';

  // -- Visits --
  static const visits = '/visits';
  static String visit(int id) => '/visits/$id';

  // -- Notifications --
  static const notifications = '/flatmates/notifications';
  static String notificationDetail(String id) => '/flatmates/notifications/$id';
  static const notificationMarkAllRead = '/flatmates/notifications';
  static const notificationRegister = '/notifications/devices/register';
  static const notificationUnregister = '/notifications/devices/unregister';

  // -- Version Check (backend: POST /versions/check) --
  static const versionCheck = '/versions/check';

  // -- Feedback (GLOBAL path, not under /flatmates) --
  static const bugs = '/bugs';

  // -- Flatmates --
  static const flatmatesProfile = '/flatmates/profile';
  static const flatmatesProfiles = '/flatmates/profiles';
  static String societyTagVotes(int id) =>
      '/flatmates/listings/$id/society-tags/votes';

  // -- Batch operations --
  static const swipesBatchRemove = '/swipes/batch-remove';
  static const uploadBatchDelete = '/upload/media/batch-delete';
}
