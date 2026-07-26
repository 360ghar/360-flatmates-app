/// Shared phone/email identifier rules for the auth flows.
///
/// The E.164 `+91` ladder and the email shape check live here so the auth
/// entry, password-reset and add-phone paths cannot drift apart.
library;

/// Whether [value] looks like a real email address (`local@domain.tld`).
///
/// Deliberately stricter than a bare `contains('@')`: a half-typed `"a@"`
/// must not be routed down the email channel.
bool looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

/// Normalizes a phone identifier to E.164 (`+91…`).
///
/// Emails and anything the ladder does not recognise come back trimmed but
/// otherwise unchanged, so the backend still sees exactly what the user typed.
///
/// The email bail-out uses `contains('@')` rather than [looksLikeEmail] on
/// purpose: a phone number never contains `@`, and a still-malformed address
/// such as `9876543210@gmail` must not be rewritten into a phone number.
String normalizeIdentifier(String raw) {
  final identifier = raw.trim();
  if (identifier.isEmpty || identifier.contains('@')) return identifier;

  var digits = identifier.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  } else if (digits.startsWith('0')) {
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
  }
  if (digits.length == 10) {
    return '+91$digits';
  }
  if (digits.length == 12 && digits.startsWith('91')) {
    return '+$digits';
  }
  return identifier;
}
