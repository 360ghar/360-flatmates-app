import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../storage/auth_token_storage.dart';

typedef AuthException = supabase.AuthException;

/// Thrown by [AuthTokenProvider.getAccessToken] when a token refresh attempt
/// failed for a transient reason (e.g. network timeout) and the local session
/// is otherwise present. Callers should treat the current request as
/// unauthenticated *for this attempt only* and MUST NOT clear the session —
/// the user may still be logged in once connectivity returns. Distinguishing
/// this from a `null` return prevents transient errors from forcing logout.
class TransientAuthRefreshException implements Exception {
  TransientAuthRefreshException(this.cause);
  final Object cause;
  @override
  String toString() => 'TransientAuthRefreshException: $cause';
}

abstract interface class AuthTokenProvider {
  Future<String?> getAccessToken();

  Future<void> clearSession();
}

final class RefreshingAuthTokenProvider implements AuthTokenProvider {
  RefreshingAuthTokenProvider(this._storage);

  final AuthTokenStorage _storage;
  Future<supabase.Session?>? _refreshInflight;

  @override
  Future<String?> getAccessToken() async {
    late final supabase.SupabaseClient client;
    try {
      client = supabase.Supabase.instance.client;
    } catch (e) {
      debugPrint(
        'RefreshingAuthTokenProvider.getAccessToken: Supabase client not available: $e',
      );
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
        session = await _refreshSession(client);
        if (session != null &&
            (session.isExpired || _isJwtExpired(session.accessToken))) {
          await _storage.clear();
          return null;
        }
      } on AuthException catch (e) {
        debugPrint(
          'RefreshingAuthTokenProvider.getAccessToken: session refresh auth error: $e',
        );
        await _storage.clear();
        return null;
      } catch (e) {
        debugPrint(
          'RefreshingAuthTokenProvider.getAccessToken: session refresh failed: $e',
        );
        // Refresh failed for a non-auth reason (transport, timeout, etc.).
        // The local token is known expired so we cannot return it (would
        // cause a 401→refresh loop under the new single-flight). But we
        // also don't want to return plain `null` here — that's the same
        // signal as "no session at all", which makes AuthInterceptor clear
        // the session and force a re-login on what may just be a flaky
        // network. Throw a typed exception so the caller can distinguish.
        throw TransientAuthRefreshException(e);
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
    } catch (e) {
      // Ignore SDK cleanup failures.
      debugPrint(
        'RefreshingAuthTokenProvider.clearSession: signOut failed: $e',
      );
    } finally {
      await _storage.clear();
    }
  }

  // Single-flight: concurrent callers share one Supabase refresh RPC.
  Future<supabase.Session?> _refreshSession(supabase.SupabaseClient client) {
    final existing = _refreshInflight;
    if (existing != null) return existing;
    final future = _doRefresh(client);
    _refreshInflight = future;
    future.whenComplete(() {
      if (identical(_refreshInflight, future)) {
        _refreshInflight = null;
      }
    });
    return future;
  }

  Future<supabase.Session?> _doRefresh(supabase.SupabaseClient client) async {
    // Callers decide to refresh based on an expiry check taken OUTSIDE the
    // single-flight guard, so a refresh that completed while this caller was
    // en route may already have produced a fresh session. Re-check here to
    // avoid a duplicate refresh RPC.
    final current = client.auth.currentSession;
    if (current != null &&
        !current.isExpired &&
        !_isJwtExpired(current.accessToken)) {
      return current;
    }
    final refreshed = await client.auth.refreshSession();
    return refreshed.session ?? client.auth.currentSession;
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
  } catch (e) {
    debugPrint('_isJwtExpired: failed to decode token: $e');
    return false;
  }
}
