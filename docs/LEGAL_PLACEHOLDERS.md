# Legal Documents

This directory contains placeholder legal document references for the 360 FlatMates app.

## Required Before Store Submission

1. **Privacy Policy URL** — Must be hosted and accessible. Set the URL in:
   - Android: `android/app/src/main/AndroidManifest.xml` (via meta-data or app linking)
   - iOS: App Store Connect metadata
   - App: `lib/core/config/constants.dart` → `kPrivacyPolicyUrl`

2. **Terms & Conditions URL** — Must be hosted and accessible. Set the URL in:
   - App: `lib/core/config/constants.dart` → `kTermsOfServiceUrl`

3. **Support URL** — Must be hosted and accessible. Set the URL in:
   - iOS: App Store Connect metadata
   - App: `lib/core/config/constants.dart` → `kSupportEmail`

## Placeholders

Replace these with actual hosted URLs before production release:
- `https://360ghar.com/policies/privacy-policy` → Privacy Policy
- `https://360ghar.com/policies/terms-of-service` → Terms & Conditions
- `https://360ghar.com/support` → Support / Help
