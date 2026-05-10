# Legal Documents

This directory contains placeholder legal document references for the 360 FlatMates app.

## Required Before Store Submission

1. **Privacy Policy URL** — Must be hosted and accessible. Set the URL in:
   - Android: `android/app/src/main/AndroidManifest.xml` (via meta-data or app linking)
   - iOS: App Store Connect metadata
   - App: `lib/core/config/app_config.dart` → `privacyPolicyUrl`

2. **Terms & Conditions URL** — Must be hosted and accessible. Set the URL in:
   - App: `lib/core/config/app_config.dart` → `termsAndConditionsUrl`

3. **Support URL** — Must be hosted and accessible. Set the URL in:
   - iOS: App Store Connect metadata
   - App: `lib/core/config/app_config.dart` → `supportUrl`

## Placeholders

Replace these with actual hosted URLs before production release:
- `https://the360ghar.com/flatmates/privacy` → Privacy Policy
- `https://the360ghar.com/flatmates/terms` → Terms & Conditions
- `https://the360ghar.com/flatmates/support` → Support / Help
