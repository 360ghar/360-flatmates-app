import 'package:flatmates_app/core/review/review_prompter.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReview implements InAppReview {
  int requests = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool available = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  late AppPreferences prefs;
  late _FakeReview review;
  var now = DateTime(2026, 10);

  ReviewPrompter build() =>
      ReviewPrompter(prefs, review: review, clock: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPreferences.create();
    review = _FakeReview();
    now = DateTime(2026, 10);
  });

  test('first success does not prompt', () async {
    await build().onSuccess();
    expect(review.requests, 0);
  });

  test('second success prompts once', () async {
    final p = build();
    await p.onSuccess();
    await p.onSuccess();
    await p.onSuccess();
    expect(review.requests, 1);
  });

  test('prompts again only after the cooldown', () async {
    final p = build();
    await p.onSuccess();
    await p.onSuccess();
    now = now.add(const Duration(days: 119));
    await p.onSuccess();
    expect(review.requests, 1);
    now = now.add(const Duration(days: 2));
    await p.onSuccess();
    expect(review.requests, 2);
  });

  test('prompt: false counts but does not ask', () async {
    final p = build();
    await p.onSuccess(prompt: false);
    await p.onSuccess(prompt: false);
    expect(review.requests, 0);
    await p.onSuccess();
    expect(review.requests, 1);
  });

  test('does not record a prompt when the sheet is unavailable', () async {
    review.available = false;
    final p = build();
    await p.onSuccess();
    await p.onSuccess();
    expect(review.requests, 0);
    review.available = true;
    await p.onSuccess();
    expect(review.requests, 1);
  });
}
