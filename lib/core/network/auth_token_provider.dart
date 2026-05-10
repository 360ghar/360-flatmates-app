import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../storage/auth_token_storage.dart';

typedef AuthException = supabase.AuthException;

abstract interface class AuthTokenProvider {
  Future<String?> getAccessToken();

  Future<void> clearSession();
}

final class RefreshingAuthTokenProvider implements AuthTokenProvider {
  RefreshingAuthTokenProvider(this._storage);

  final AuthTokenStorage _storage;

  @override
  Future<String?> getAccessToken() async {
    late final supabase.SupabaseClient client;
    try {
      client = supabase.Supabase.instance.client;
    } catch (_) {
      await _storage.clear();
      return null;
    }

    var session = client.auth.currentSession;
    if (session == null) {
      await _storage.clear();
      return null;
    }

    if (session.isExpired || _isJwtExpired(session.accessToken)) {
      try {
        final refreshed = await client.auth.refreshSession();
        session = refreshed.session ?? client.auth.currentSession;
        if (session != null &&
            (session.isExpired || _isJwtExpired(session.accessToken))) {
          await _storage.clear();
          return null;
        }
      } on AuthException catch (_) {
        await _storage.clear();
        return null;
      } catch (_) {
        return _storage.read();
      }
    }

    final token = session?.accessToken;
    if (token != null && token.isNotEmpty) {
      await _storage.save(token);
      return token;
    }

    await _storage.clear();
    return null;
  }

  @override
  Future<void> clearSession() async {
    try {
      await supabase.Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore SDK cleanup failures.
    } finally {
      await _storage.clear();
    }
  }
}

bool _isJwtExpired(
  String token, {
  Duration skew = const Duration(seconds: 10),
}) {
  final parts = token.split('.');
  if (parts.length < 2) return false;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return false;
    final exp = payload['exp'];
    final expiry = exp is num
        ? exp.toInt()
        : int.tryParse(exp?.toString() ?? '');
    if (expiry == null) return false;
    return DateTime.now()
        .add(skew)
        .isAfter(DateTime.fromMillisecondsSinceEpoch(expiry * 1000));
  } catch (_) {
    return false;
  }
}
