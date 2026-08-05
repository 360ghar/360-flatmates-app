import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/app_config/patch_service.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';

/// Stands in for the Shorebird engine, which is never present under
/// `flutter test`. [available] models a non-Shorebird build, where the real
/// updater returns null from both reads.
class _FakeUpdater implements ShorebirdUpdater {
  _FakeUpdater({
    this.current,
    this.next,
    this.available = true,
    this.throws = false,
  });

  final int? current;
  final int? next;
  final bool available;
  final bool throws;

  @override
  bool get isAvailable => available;

  @override
  Future<Patch?> readCurrentPatch() async {
    if (throws) throw const ReadPatchException(message: 'boom');
    if (!available || current == null) return null;
    return Patch(number: current!);
  }

  @override
  Future<Patch?> readNextPatch() async {
    if (throws) throw const ReadPatchException(message: 'boom');
    if (!available || next == null) return null;
    return Patch(number: next!);
  }

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async =>
      UpdateStatus.unavailable;

  @override
  Future<void> update({UpdateTrack? track}) async {}
}

AppPreferences? _cachedPrefs;

PatchService _service(_FakeUpdater updater) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(_cachedPrefs!),
      patchServiceProvider.overrideWith(
        (ref) => PatchService(ref: ref, updater: updater),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container.read(patchServiceProvider);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
    _cachedPrefs = await testAppPreferences;
  });

  group('PatchService.currentPatchNumber', () {
    test('returns the running patch number', () async {
      final service = _service(_FakeUpdater(current: 3, next: 3));
      expect(await service.currentPatchNumber(), 3);
    });

    test('returns null on a build without the updater', () async {
      final service = _service(_FakeUpdater(available: false));
      expect(await service.currentPatchNumber(), isNull);
    });

    test('swallows ReadPatchException rather than surfacing it', () async {
      final service = _service(_FakeUpdater(throws: true));
      expect(await service.currentPatchNumber(), isNull);
    });
  });

  group('PatchService.pendingPatchNumber', () {
    test(
      'returns null when next equals current (nothing downloaded)',
      () async {
        // readNextPatch() returns the CURRENT patch when no new patch has been
        // downloaded, so equality must not be reported as pending.
        final service = _service(_FakeUpdater(current: 3, next: 3));
        expect(await service.pendingPatchNumber(), isNull);
      },
    );

    test('returns the new number when a patch awaits restart', () async {
      final service = _service(_FakeUpdater(current: 3, next: 4));
      expect(await service.pendingPatchNumber(), 4);
    });

    test(
      'reports the first patch on a base release (no current patch)',
      () async {
        final service = _service(_FakeUpdater(next: 1));
        expect(await service.pendingPatchNumber(), 1);
      },
    );

    test('returns null on a build without the updater', () async {
      final service = _service(
        _FakeUpdater(current: 3, next: 4, available: false),
      );
      expect(await service.pendingPatchNumber(), isNull);
    });
  });

  group('PatchService nudge bookkeeping', () {
    test('nudges once per patch number, then stops', () async {
      final service = _service(_FakeUpdater(current: 3, next: 4));
      expect(service.shouldNudgeForPatch(4), isTrue);

      await service.markPatchNudged(4);
      expect(service.shouldNudgeForPatch(4), isFalse);
    });

    test('a later patch re-arms the nudge', () async {
      final service = _service(_FakeUpdater(current: 3, next: 4));
      await service.markPatchNudged(4);
      expect(service.shouldNudgeForPatch(5), isTrue);
    });
  });
}
