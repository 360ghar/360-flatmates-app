/// Google Web OAuth client ID for Google Sign-In.
/// Provide via --dart-define=GOOGLE_WEB_CLIENT_ID=... at build time.
const kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);
const kSupportEmail = 'info@360ghar.com';

/// Apple App Store ID supplied at build time once App Store Connect assigns it.
const kAppStoreId = String.fromEnvironment('APP_STORE_ID');

/// Google Play Store ID — update this when the app is published.
const kPlayStoreId = 'com.the360ghar.flatmates360';

/// Constructs the App Store deep link URL using [kAppStoreId].
/// Returns an empty string when the store ID has not been assigned yet.
String get appStoreUrl {
  final appStoreId = kAppStoreId.trim();
  if (appStoreId.isEmpty) return '';
  return 'https://apps.apple.com/app/id$appStoreId';
}

/// Constructs the Play Store deep link URL using [kPlayStoreId].
String get playStoreUrl =>
    'https://play.google.com/store/apps/details?id=$kPlayStoreId';
