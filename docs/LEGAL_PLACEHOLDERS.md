# Legal Documents

Legal content (Privacy Policy and Terms of Service) is rendered natively in the app.

## Content Source

Both documents are defined directly in:
- `lib/features/profile/legal_content_page.dart`

The `LegalContentPage` widget accepts a `LegalContentType` enum
(`privacyPolicy` or `termsOfService`) and renders the corresponding
legal text as native Flutter widgets.

## Updates

To update the legal text, edit the `_privacyPolicySections` and
`_termsOfServiceSections` methods in `legal_content_page.dart`.
After updating, run `flutter analyze` to verify no issues.

## Store Metadata

- **Support URL**: `lib/core/config/constants.dart` → `kSupportEmail`
- **Privacy Policy** (App Store Connect / Play Console): can now reference
  a generic company policy page or point to the in-app content description.
