import 'dart:convert';

import 'package:flatmates_app/core/network/auth_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(Map<String, Object> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.sig';
}

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1_800_000_000 * 1000);
  const window = Duration(seconds: 30);

  test('a token issued 10 s ago is fresh (no forced refresh)', () {
    final token = _jwt({'iat': 1_800_000_000 - 10});
    expect(jwtIssuedWithin(token, window, now: now), isTrue);
  });

  test('a token issued now is fresh', () {
    final token = _jwt({'iat': 1_800_000_000});
    expect(jwtIssuedWithin(token, window, now: now), isTrue);
  });

  test('a token dated in the future is not fresh', () {
    // Device clock behind the server: a negative age must not read as recent,
    // or the token looks freshly minted for as long as the clock is behind.
    final token = _jwt({'iat': 1_800_000_000 + 5});
    expect(jwtIssuedWithin(token, window, now: now), isFalse);
  });

  test('a token issued 5 min ago is not fresh', () {
    final token = _jwt({'iat': 1_800_000_000 - 300});
    expect(jwtIssuedWithin(token, window, now: now), isFalse);
  });

  test('a token without iat or a garbage token is not fresh', () {
    expect(jwtIssuedWithin(_jwt({'exp': 1}), window, now: now), isFalse);
    expect(jwtIssuedWithin('not-a-jwt', window, now: now), isFalse);
  });
}
