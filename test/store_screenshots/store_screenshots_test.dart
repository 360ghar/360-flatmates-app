// Renders real app screens with demo data and writes them as PNGs for the
// store listing. Skipped unless STORE_SHOTS_OUT is set:
//
//   STORE_SHOTS_OUT=/abs/out STORE_PHOTOS_DIR=/abs/photos \
//     flutter test test/store_screenshots
//
// STORE_PHOTOS_DIR holds room1..4.jpg and person1..6.jpg. They are served from
// a local HTTP server, so the app's own network-image widget draws them.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/chats/chat_thread_page.dart';
import 'package:flatmates_app/features/chats/domain/chat_models.dart';
import 'package:flatmates_app/features/discover/discover_page.dart';
import 'package:flatmates_app/features/discover/flat_details_page.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';
import 'package:flatmates_app/features/swipe/match_celebration_screen.dart';
import 'package:flatmates_app/features/swipe/swipe_deck_page.dart';
import 'package:flatmates_app/features/visits/schedule_visit_page.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/golden_fonts.dart';
import '../helpers/test_helpers.dart';

final _outDir = Platform.environment['STORE_SHOTS_OUT'];
final _photosDir = Platform.environment['STORE_PHOTOS_DIR'];

late HttpServer _server;
String get _base => 'http://127.0.0.1:${_server.port}';

String _room(int n) => '$_base/room$n.jpg';
String _person(int n) => '$_base/person$n.jpg';

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);
  final Object? Function(RequestOptions) _handler;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(_handler(options) ?? {}),
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

const _titles = [
  'Sunny 2BHK near Sony World Signal',
  'Private room in a quiet society',
  'Spacious room, balcony and parking',
  'Furnished room near the metro',
];
const _localities = ['Koramangala', 'Indiranagar', 'HSR Layout', 'Whitefield'];

Map<String, dynamic> _listing(int id) => {
  'id': id,
  'owner_id': 100 + id,
  'property_type': 'flatmate',
  'title': _titles[(id - 1) % 4],
  'description':
      'A bright flat with cross ventilation, a big balcony and a quiet lane. '
      'Walkable to the metro and cafes. Looking for a tidy flatmate who works '
      'from office most days.',
  'city': 'Bangalore',
  'state': 'Karnataka',
  'locality': _localities[(id - 1) % 4],
  'latitude': 12.9352,
  'longitude': 77.6245,
  'monthly_rent': 14000.0 + id * 1500,
  'security_deposit': 28000.0,
  'maintenance_charges': 1500.0,
  'main_image_url': _room((id - 1) % 4 + 1),
  'image_urls': [
    _room((id - 1) % 4 + 1),
    _room(id % 4 + 1),
    _room((id + 1) % 4 + 1),
  ],
  'bedrooms': 2,
  'bathrooms': 2,
  'area_sqft': 1100.0,
  'floor_number': 3,
  'total_floors': 5,
  'features': ['wifi', 'parking', 'lift', 'furnished'],
  'available_from': '2027-03-01T00:00:00Z',
  'status': 'live',
  'interest_count': 5,
  'view_count': 120,
  'like_count': 10,
  'is_available': true,
  'listing_preferences': {
    'sharing_type': 'private_room',
    'gender_preference': 'any',
  },
  'owner': {
    'id': 100 + id,
    'full_name': 'Priya Nair',
    'mode': 'room_poster',
    'profile_image_url': _person(1),
  },
  'created_at': '2026-10-01T10:00:00Z',
};

Map<String, dynamic> _peer(
  int id,
  String name,
  int photo, {
  String sleep = 'early_bird',
  String clean = 'tidy',
  String food = 'vegetarian',
  String work = 'hybrid',
  String profession = 'Product designer',
  String locality = 'Indiranagar',
  String bio = 'Early riser, tidy, cooks on weekends.',
}) => {
  'id': id,
  'full_name': name,
  'profile_image_url': _person(photo),
  'mode': 'co_hunter',
  'city': 'Bangalore',
  'locality': locality,
  'bio': bio,
  'age_bucket': '25-30',
  'budget_min': 12000.0,
  'budget_max': 24000.0,
  'move_in_timeline': 'within_1_month',
  'sleep_schedule': sleep,
  'cleanliness': clean,
  'food_habits': food,
  'guests_policy': 'occasional_ok',
  'work_style': work,
  'smoking': 'never',
  'drinking': 'occasionally',
  'gender': 'female',
  'gender_preference': 'any',
  'non_negotiables': ['no_smoking'],
  'has_pets': false,
  'profession': profession,
  'listing': null,
  'match_percentage': 88.0,
  'top_matches': ['Same sleep schedule', 'Both vegetarian'],
};

Map<String, dynamic> _conv(int id) => {
  'id': id,
  'peer': _peer(
    201,
    'Ananya Krishnamurthy',
    1,
    locality: 'Indiranagar HAL 2nd Stage',
  ),
  'context_property': {
    'id': 1,
    'title': _titles[0],
    'monthly_rent': 24000.0,
    'locality': 'Koramangala',
    'city': 'Bangalore',
    'main_image_url': _room(1),
  },
  'source': 'profile_match',
  'status': 'active',
  'last_message_preview': 'Is the room still available from November?',
  'last_message_at': '2026-10-20T09:30:00Z',
  'matched_at': '2026-10-19T09:30:00Z',
  'unread_count': 0,
};

Map<String, dynamic> _msg(int id, int sender, String body, String at) => {
  'id': id,
  'conversation_id': 7,
  'sender_id': sender,
  'body': body,
  'message_type': 'text',
  'created_at': at,
  'read_at': '2026-10-20T10:00:00Z',
};

Object? _route(RequestOptions o) {
  final p = o.path;
  if (p == '/properties') {
    return {
      'items': List.generate(4, (i) => _listing(i + 1)),
      'next_cursor': null,
      'has_more': false,
    };
  }
  if (p.startsWith('/properties/')) return _listing(1);
  if (p == '/flatmates/profiles') {
    return {
      'items': [
        _peer(
          301,
          'Ananya K',
          1,
          bio: 'Product designer. Early riser, tidy, cooks on weekends.',
        ),
        _peer(
          302,
          'Rohan M',
          2,
          sleep: 'flexible',
          food: 'non_vegetarian',
          profession: 'Software engineer',
          bio: 'Works from home on Fridays. Loves cricket and cooking.',
        ),
        _peer(303, 'Meera S', 3, profession: 'Data analyst'),
      ],
      'next_cursor': null,
      'has_more': false,
    };
  }
  if (p == '/flatmates/conversations') {
    return {
      'items': [_conv(7)],
      'next_cursor': null,
      'has_more': false,
    };
  }
  if (p == '/flatmates/conversations/7') return _conv(7);
  if (p == '/flatmates/conversations/7/messages') {
    return {
      'items': [
        _msg(
          4,
          201,
          'Is the room still available from November?',
          '2026-10-20T09:30:00Z',
        ),
        _msg(
          3,
          1,
          'Yes, it is. The flat has a big balcony and the metro is a 5 minute walk.',
          '2026-10-20T09:20:00Z',
        ),
        _msg(
          2,
          201,
          'Nice! We both said early bird on the quiz, so that should work.',
          '2026-10-20T09:10:00Z',
        ),
        _msg(
          1,
          1,
          'Hi Ananya! Great to match with you.',
          '2026-10-20T09:00:00Z',
        ),
      ],
      'next_cursor': null,
      'has_more': false,
    };
  }
  return null;
}

ApiClient _api() {
  final api = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  api.dio.httpClientAdapter = _Adapter(_route);
  return api;
}

class _Boot extends BootstrapController {
  @override
  Future<BootstrapData?> build() async {
    final d = _data();
    state = AsyncValue.data(d);
    return d;
  }

  @override
  Future<void> refresh() async => state = AsyncValue.data(_data());

  BootstrapData _data() => BootstrapData(
    profile: const FlatmatesProfileModel(
      id: 1,
      fullName: 'Aarav Mehta',
      phone: '+919999999999',
      email: 'aarav@example.com',
      mode: 'co_hunter',
      profileStatus: FlatmatesProfileStatus.active,
      onboardingCompleted: true,
      age: 27,
      profession: 'Software engineer',
      city: 'Bangalore',
      locality: 'Koramangala',
      profileImageUrl: 'http://127.0.0.1/none',
      sleepSchedule: 'early_bird',
      cleanliness: 'tidy',
      foodHabits: 'vegetarian',
      workStyle: 'hybrid',
    ),
    catalogs: fakeBootstrapData().catalogs,
  );
}

class _Loc extends LocationController {
  @override
  LocationState build() => const LocationState(
    selectedLocation: LocationData(
      name: 'Koramangala, Bangalore',
      latitude: 12.9352,
      longitude: 77.6245,
    ),
  );
  @override
  Future<void> getCurrentLocation({bool forceRefresh = false}) async {}
  @override
  void selectLocation(LocationData location) {}
  @override
  Future<void> selectAndPersistLocation(LocationData location) async {}
}

Future<void> _loadDevanagari() async {
  final f = File('/System/Library/Fonts/Kohinoor.ttc');
  if (!f.existsSync()) return;
  final loader = FontLoader('KohinoorDevanagari')
    ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await loader.load();
}

void main() {
  final out = _outDir;
  final photos = _photosDir;
  if (out == null || photos == null) {
    test(
      'store screenshots (set STORE_SHOTS_OUT and STORE_PHOTOS_DIR)',
      () {},
      skip: 'needs STORE_SHOTS_OUT and STORE_PHOTOS_DIR',
    );
    return;
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The image cache needs path_provider and sqflite. Answer with a temp dir
    // and the FFI sqlite, so photos download and render.
    final tmp = Directory.systemTemp.createTempSync('store_shots').path;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tmp,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await loadGoldenFonts();
    await _loadDevanagari();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      _server.forEach((req) async {
        final f = File('$photos${req.uri.path}');
        if (f.existsSync()) {
          req.response.headers.contentType = ContentType('image', 'jpeg');
          req.response.add(await f.readAsBytes());
        } else {
          req.response.statusCode = 404;
        }
        await req.response.close();
      }),
    );
  });
  tearDownAll(() => _server.close(force: true));

  final shots = <String, Widget Function()>{
    '01_discover': () => const DiscoverPage(),
    '02_swipe': () => const SwipeDeckPage(),
    '03_match': () => MatchCelebrationScreen(
      userName: 'Aarav Mehta',
      userImageUrl: _person(4),
      peerName: 'Ananya K',
      peerImageUrl: _person(1),
      onOpenChat: () {},
      onKeepSwiping: () {},
    ),
    '04_chat': () => ChatThreadPage(
      conversationId: 7,
      conversation: ConversationSummaryModel.fromJson(_conv(7)),
    ),
    '05_flat': () => const FlatDetailsPage(listingId: 1),
    '06_visit': () => ScheduleVisitPage(
      conversation: ConversationSummaryModel.fromJson(_conv(7)),
    ),
  };

  for (final lang in ['en', 'hi']) {
    for (final e in shots.entries) {
      testWidgets('${e.key}_$lang', (tester) async {
        SharedPreferences.setMockInitialValues({});
        resetTestAppPreferences();
        HttpOverrides.global = null;
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        // Status bar and home indicator insets of a modern iPhone (physical px).
        const insets = FakeViewPadding(top: 141, bottom: 102);
        tester.view.padding = insets;
        tester.view.viewPadding = insets;
        addTearDown(tester.view.reset);
        final prefs = await testAppPreferences;
        final base = AppTheme.build(brightness: Brightness.light);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(fakeAppConfig()),
              appPreferencesProvider.overrideWithValue(prefs),
              authControllerProvider.overrideWith(() => FakeAuthController()),
              bootstrapControllerProvider.overrideWith(_Boot.new),
              settingsControllerProvider.overrideWith(
                () => FakeSettingsController(),
              ),
              apiClientProvider.overrideWithValue(_api()),
              locationControllerProvider.overrideWith(_Loc.new),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lang == 'hi'
                  ? base.copyWith(
                      textTheme: base.textTheme.apply(
                        fontFamilyFallback: ['KohinoorDevanagari'],
                      ),
                    )
                  : base,
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: e.value(),
            ),
          ),
        );
        // Let the local server answer, then let the widgets settle.
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 400)),
          );
          await tester.pump(const Duration(milliseconds: 300));
        }
        final err = tester.takeException();
        final bytes = await tester.runAsync(() async {
          final image = await captureImage(
            tester.element(find.byType(MaterialApp)),
          );
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        final file = File('$out/${e.key}_$lang.png')
          ..createSync(recursive: true);
        file.writeAsBytesSync(bytes!);
        // Drop the tree and run out the image cache's cleanup timers.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
        // The image cache has no path_provider here; the widget falls back to
        // Image.network, so that error is expected.
        if (err != null && !'$err'.contains('MissingPluginException')) {
          fail('$err');
        }
      });
    }
  }
}
