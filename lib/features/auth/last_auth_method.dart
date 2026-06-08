import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import 'domain/auth_state.dart';

/// Persisted record of the last auth method (and a masked identifier hint)
/// the user successfully signed in with, used to pre-select / highlight that
/// method on the auth-entry screen.
@immutable
class LastAuthRecord {
  const LastAuthRecord({required this.method, this.identifierHint});

  final AuthMethod method;
  final String? identifierHint;
}

/// Masks an identifier for display (e.g. `+9198XXXXXX21`, `jo***@gmail.com`)
/// so we never persist a full phone/email in plaintext prefs.
String maskIdentifier(String identifier) {
  final value = identifier.trim();
  if (value.isEmpty) return value;
  if (value.contains('@')) {
    final parts = value.split('@');
    final name = parts.first;
    final domain = parts.length > 1 ? parts[1] : '';
    final visible = name.length <= 2 ? name : name.substring(0, 2);
    return '$visible***@$domain';
  }
  // Phone: keep the country prefix and last 2 digits.
  if (value.length <= 4) return value;
  final head = value.startsWith('+')
      ? value.substring(0, 3)
      : value.substring(0, 2);
  final tail = value.substring(value.length - 2);
  return '$head${'*' * (value.length - head.length - 2)}$tail';
}

/// Reads/writes the last-used auth method via [AppPreferences].
final class LastAuthMethodStore {
  LastAuthMethodStore(this._prefs);

  final AppPreferences _prefs;

  LastAuthRecord? read() {
    final method = AuthMethodWire.fromWire(
      _prefs.getString(PrefKeys.lastAuthMethod),
    );
    if (method == null) return null;
    return LastAuthRecord(
      method: method,
      identifierHint: _prefs.getString(PrefKeys.lastAuthIdentifier),
    );
  }

  Future<void> write(AuthMethod method, {String? identifier}) async {
    await _prefs.setString(PrefKeys.lastAuthMethod, method.wireValue);
    if (identifier != null && identifier.trim().isNotEmpty) {
      await _prefs.setString(
        PrefKeys.lastAuthIdentifier,
        maskIdentifier(identifier),
      );
    }
  }

  Future<void> clear() async {
    await _prefs.remove(PrefKeys.lastAuthMethod);
    await _prefs.remove(PrefKeys.lastAuthIdentifier);
  }
}

final lastAuthMethodStoreProvider = Provider<LastAuthMethodStore>(
  (ref) => LastAuthMethodStore(ref.watch(appPreferencesProvider)),
);

/// The last auth method the user signed in with, or null if none recorded.
final lastAuthMethodProvider = Provider<LastAuthRecord?>(
  (ref) => ref.watch(lastAuthMethodStoreProvider).read(),
);
