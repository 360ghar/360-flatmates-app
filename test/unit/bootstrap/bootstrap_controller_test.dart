import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('BootstrapController', () {
    test('FakeBootstrapController provides fakeBootstrapData', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          bootstrapControllerProvider.overrideWith(
            () => FakeBootstrapController(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(bootstrapControllerProvider.future);
      final data = container.read(bootstrapControllerProvider).valueOrNull;
      expect(data, isNotNull);
      expect(data!.profile.id, 1);
      expect(data.profile.mode, 'co_hunter');
      expect(data.catalogs, isNotEmpty);
    });

    test('FakeBootstrapController.refresh updates state', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          bootstrapControllerProvider.overrideWith(
            () => FakeBootstrapController(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(bootstrapControllerProvider.future);
      final notifier = container.read(bootstrapControllerProvider.notifier);
      await notifier.refresh();
      final data = container.read(bootstrapControllerProvider).valueOrNull;
      expect(data, isNotNull);
    });

    test('FakeBootstrapController.clear sets state to null', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          bootstrapControllerProvider.overrideWith(
            () => FakeBootstrapController(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(bootstrapControllerProvider.future);
      expect(
        container.read(bootstrapControllerProvider).valueOrNull,
        isNotNull,
      );
      final notifier = container.read(bootstrapControllerProvider.notifier);
      notifier.clear();
      expect(container.read(bootstrapControllerProvider).valueOrNull, isNull);
    });

    test('refresh does not throw when logged out', () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          bootstrapControllerProvider.overrideWith(
            () => FakeBootstrapController(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(bootstrapControllerProvider.future);
      // FakeAuthController is unauthenticated; refresh on the fake still
      // returns data without throwing.
      final notifier = container.read(bootstrapControllerProvider.notifier);
      await notifier.refresh();
      expect(container.read(bootstrapControllerProvider).hasError, isFalse);
    });
  });

  group('BootstrapData', () {
    test('parses profile and catalogs correctly', () {
      final data = fakeBootstrapData();
      expect(data.profile.fullName, 'Test User');
      expect(data.profile.mode, 'co_hunter');
      expect(data.catalogs, hasLength(2));
      expect(data.catalogs[0].key, 'flatmates_modes');
      expect(data.catalogs[1].key, 'flatmates_popular_cities');
    });

    test('catalog payload contains items for flatmates_modes', () {
      final data = fakeBootstrapData();
      final modesCatalog = data.catalogs.firstWhere(
        (c) => c.key == 'flatmates_modes',
      );
      final items = modesCatalog.payload['items'] as List;
      expect(items, hasLength(3));
      expect((items[0] as Map)['id'], 'co_hunter');
      expect((items[1] as Map)['id'], 'room_poster');
      expect((items[2] as Map)['id'], 'open_to_both');
    });

    test('catalog payload contains items for popular cities', () {
      final data = fakeBootstrapData();
      final citiesCatalog = data.catalogs.firstWhere(
        (c) => c.key == 'flatmates_popular_cities',
      );
      final items = citiesCatalog.payload['items'] as List;
      expect(items, hasLength(3));
      expect((items[0] as Map)['id'], 'bangalore');
      expect((items[1] as Map)['id'], 'gurgaon');
      expect((items[2] as Map)['id'], 'hyderabad');
    });

    test('default counts are zero', () {
      final data = fakeBootstrapData();
      expect(data.activeListingCount, 0);
      expect(data.conversationCount, 0);
      expect(data.unreadMessageCount, 0);
    });

    test('realtime config is null by default in fakeBootstrapData', () {
      final data = fakeBootstrapData();
      expect(data.realtime, isNull);
    });
  });
}
