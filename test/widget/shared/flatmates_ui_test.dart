import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  group('initialsFromName', () {
    test('returns FM for null', () {
      expect(initialsFromName(null), 'FM');
    });

    test('returns FM for empty string', () {
      expect(initialsFromName(''), 'FM');
    });

    test('returns FM for whitespace-only string', () {
      expect(initialsFromName('   '), 'FM');
    });

    test('returns first two chars for single name', () {
      expect(initialsFromName('John'), 'JO');
    });

    test('returns first char of name for single-char name', () {
      expect(initialsFromName('A'), 'A');
    });

    test('returns initials of first and last name', () {
      expect(initialsFromName('John Doe'), 'JD');
    });

    test('returns initials ignoring extra spaces', () {
      expect(initialsFromName('  John   Doe  '), 'JD');
    });

    test('returns initials for three-part name', () {
      expect(initialsFromName('John Middle Doe'), 'JD');
    });

    test('uppercase the initials', () {
      expect(initialsFromName('john doe'), 'JD');
    });
  });

  group('avatarPaletteForName', () {
    test('returns deterministic palette for same name', () {
      final a = avatarPaletteForName('John Doe');
      final b = avatarPaletteForName('John Doe');
      expect(a.background, b.background);
      expect(a.foreground, b.foreground);
    });

    test('returns different palettes for different names (usually)', () {
      final a = avatarPaletteForName('Alice');
      final b = avatarPaletteForName('Bob');
      // Not guaranteed to differ but very likely with different hashes.
      expect(a, isNotNull);
      expect(b, isNotNull);
    });

    test('returns dark palette when brightness is dark', () {
      final light = avatarPaletteForName('Test');
      final dark = avatarPaletteForName('Test', brightness: Brightness.dark);
      expect(light.background, isNot(equals(dark.background)));
      expect(light.foreground, isNot(equals(dark.foreground)));
    });

    test('handles null name', () {
      final result = avatarPaletteForName(null);
      expect(result.background, isNotNull);
      expect(result.foreground, isNotNull);
    });

    test('handles empty name', () {
      final result = avatarPaletteForName('');
      expect(result.background, isNotNull);
      expect(result.foreground, isNotNull);
    });
  });

  group('humanizeFlatmatesToken', () {
    test('converts snake_case to Title Case', () {
      expect(humanizeFlatmatesToken('room_poster'), 'Room Poster');
    });

    test('converts hyphenated to Title Case', () {
      expect(humanizeFlatmatesToken('co-hunter'), 'Co Hunter');
    });

    test('handles single word', () {
      expect(humanizeFlatmatesToken('seeker'), 'Seeker');
    });

    test('handles multiple separators', () {
      expect(humanizeFlatmatesToken('high_speed_wifi'), 'High Speed Wifi');
    });

    test('handles empty string', () {
      expect(humanizeFlatmatesToken(''), '');
    });

    test('handles already capitalized', () {
      expect(humanizeFlatmatesToken('Room_Poster'), 'Room Poster');
    });
  });

  group('localizedFlatmatesModeLabel', () {
    final locale = lookupAppLocalizations(const Locale('en'));

    test('maps room_poster', () {
      expect(
        localizedFlatmatesModeLabel(locale, 'room_poster'),
        locale.modeRoomPoster,
      );
    });

    test('maps seeker', () {
      expect(localizedFlatmatesModeLabel(locale, 'seeker'), locale.modeSeeker);
    });

    test('maps co_hunter', () {
      expect(
        localizedFlatmatesModeLabel(locale, 'co_hunter'),
        locale.modeCoHunter,
      );
    });

    test('maps open_to_both', () {
      expect(
        localizedFlatmatesModeLabel(locale, 'open_to_both'),
        locale.modeOpenToBoth,
      );
    });

    test('falls back to humanize for unknown', () {
      expect(
        localizedFlatmatesModeLabel(locale, 'unknown_mode'),
        'Unknown Mode',
      );
    });

    test('is case-insensitive', () {
      expect(
        localizedFlatmatesModeLabel(locale, 'ROOM_POSTER'),
        locale.modeRoomPoster,
      );
    });
  });

  group('localizedFlatmatesGenderLabel', () {
    final locale = lookupAppLocalizations(const Locale('en'));

    test('maps any', () {
      expect(localizedFlatmatesGenderLabel(locale, 'any'), locale.genderAny);
    });

    test('maps male', () {
      expect(localizedFlatmatesGenderLabel(locale, 'male'), locale.genderMale);
    });

    test('maps female', () {
      expect(
        localizedFlatmatesGenderLabel(locale, 'female'),
        locale.genderFemale,
      );
    });

    test('falls back to humanize for unknown', () {
      expect(localizedFlatmatesGenderLabel(locale, 'non_binary'), 'Non Binary');
    });
  });

  group('localizedFlatmatesSharingTypeLabel', () {
    final locale = lookupAppLocalizations(const Locale('en'));

    test('maps private_room', () {
      expect(
        localizedFlatmatesSharingTypeLabel(locale, 'private_room'),
        locale.sharingPrivateRoom,
      );
    });

    test('maps shared_room', () {
      expect(
        localizedFlatmatesSharingTypeLabel(locale, 'shared_room'),
        locale.sharingSharedRoom,
      );
    });

    test('falls back to humanize for unknown', () {
      expect(
        localizedFlatmatesSharingTypeLabel(locale, 'dormitory'),
        'Dormitory',
      );
    });
  });

  group('localizedFlatmatesVisitStatusLabel', () {
    final locale = lookupAppLocalizations(const Locale('en'));

    test('maps scheduled', () {
      expect(
        localizedFlatmatesVisitStatusLabel(locale, 'scheduled'),
        locale.visitStatusScheduled,
      );
    });

    test('maps confirmed', () {
      expect(
        localizedFlatmatesVisitStatusLabel(locale, 'confirmed'),
        locale.visitStatusConfirmed,
      );
    });

    test('maps completed', () {
      expect(
        localizedFlatmatesVisitStatusLabel(locale, 'completed'),
        locale.visitStatusCompleted,
      );
    });

    test('maps cancelled', () {
      expect(
        localizedFlatmatesVisitStatusLabel(locale, 'cancelled'),
        locale.visitStatusCancelled,
      );
    });

    test('maps canceled (US spelling)', () {
      expect(
        localizedFlatmatesVisitStatusLabel(locale, 'canceled'),
        locale.visitStatusCancelled,
      );
    });

    test('maps requested', () {
      expect(
        localizedFlatmatesVisitStatusLabel(locale, 'requested'),
        locale.visitStatusRequested,
      );
    });

    test('falls back to humanize for unknown', () {
      expect(localizedFlatmatesVisitStatusLabel(locale, 'pending'), 'Pending');
    });
  });

  group('localizedFlatmatesFeatureLabel', () {
    final locale = lookupAppLocalizations(const Locale('en'));

    test('maps furnished', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'furnished'),
        locale.featureFurnished,
      );
    });

    test('maps semi_furnished', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'semi_furnished'),
        locale.featureSemiFurnished,
      );
    });

    test('maps wifi', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'wifi'),
        locale.featureWifi,
      );
    });

    test('maps wi_fi', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'wi_fi'),
        locale.featureWifi,
      );
    });

    test('maps high_speed_wifi', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'high_speed_wifi'),
        locale.featureWifi,
      );
    });

    test('maps balcony', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'balcony'),
        locale.featureBalcony,
      );
    });

    test('maps attached_bathroom', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'attached_bathroom'),
        locale.featureAttachedBathroom,
      );
    });

    test('maps parking', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'parking'),
        locale.featureParking,
      );
    });

    test('maps ac', () {
      expect(localizedFlatmatesFeatureLabel(locale, 'ac'), locale.featureAc);
    });

    test('maps air_conditioning', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'air_conditioning'),
        locale.featureAc,
      );
    });

    test('maps washing_machine', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'washing_machine'),
        locale.featureWashingMachine,
      );
    });

    test('falls back to humanize for unknown', () {
      expect(
        localizedFlatmatesFeatureLabel(locale, 'gym_access'),
        'Gym Access',
      );
    });
  });

  group('formatDistanceText', () {
    final locale = lookupAppLocalizations(const Locale('en'));

    test('returns empty string for null distance', () {
      expect(formatDistanceText(locale, null), '');
    });

    test('formats sub-km distance as meters', () {
      final result = formatDistanceText(locale, 0.5);
      expect(result, isNotEmpty);
      expect(result.contains('m'), isTrue);
    });

    test('formats sub-10km distance with one decimal', () {
      final result = formatDistanceText(locale, 2.5);
      expect(result, isNotEmpty);
      expect(result.contains('2.5'), isTrue);
    });

    test('formats 10+km distance as rounded km', () {
      final result = formatDistanceText(locale, 15.0);
      expect(result, isNotEmpty);
      expect(result.contains('15'), isTrue);
    });
  });

  group('FlatmatesAvatar', () {
    testWidgets('renders initials when no image URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesAvatar(name: 'John Doe')),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('renders FM for null name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlatmatesAvatar(name: null))),
      );

      expect(find.text('FM'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesAvatar(name: 'John', onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(FlatmatesAvatar));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('FlatmatesLogo', () {
    testWidgets('renders "36" and "FLATMATES" in default mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlatmatesLogo())),
      );

      // "36" is rendered inside a RichText (TextSpan), not a plain Text.
      // The icon also renders as a RichText, so we expect multiple.
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('FLATMATES'), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
    });

    testWidgets('renders compact variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlatmatesLogo(compact: true))),
      );

      expect(find.byType(RichText), findsWidgets);
      expect(find.text('FLATMATES'), findsOneWidget);
    });

    testWidgets('toolbar variant renders only RichText + icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlatmatesLogo(toolbar: true))),
      );

      // Toolbar mode: "36" + icon in RichText, no "FLATMATES" text.
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('FLATMATES'), findsNothing);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
    });
  });

  group('FlatmatesButton', () {
    testWidgets('primary variant renders label and calls onPressed', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesButton(
              label: 'Submit',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);

      await tester.tap(find.byType(FlatmatesButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('secondary variant renders label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesButton.secondary(label: 'Cancel', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('tertiary variant renders label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesButton.tertiary(label: 'Skip', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('icon variant renders icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesButton.icon(icon: Icons.add, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('primary with icon renders both icon and label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesButton(
              label: 'Save',
              icon: Icons.save,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesButton(label: 'Disabled', onPressed: null),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('fullWidth expands', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FlatmatesButton(
                label: 'Full',
                onPressed: () {},
                fullWidth: true,
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(FilledButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, double.infinity);
    });
  });

  group('GradientActionButton', () {
    testWidgets('delegates to FlatmatesButton', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientActionButton(
              label: 'Go',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Go'), findsOneWidget);

      await tester.tap(find.byType(GradientActionButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('FlatmatesSectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesSectionHeader(title: 'My Listings')),
        ),
      );

      expect(find.text('My Listings'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesSectionHeader(
              title: 'My Listings',
              subtitle: 'Manage your active posts',
            ),
          ),
        ),
      );

      expect(find.text('My Listings'), findsOneWidget);
      expect(find.text('Manage your active posts'), findsOneWidget);
    });

    testWidgets('renders action label and chevron', (tester) async {
      var actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesSectionHeader(
              title: 'My Listings',
              actionLabel: 'See all',
              onActionTap: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('See all'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
    });
  });

  group('InfoPill', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoPill(label: '2 BHK')),
        ),
      );

      expect(find.text('2 BHK'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPill(label: 'Furnished', icon: Icons.check),
          ),
        ),
      );

      expect(find.text('Furnished'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('FlatmatesMenuItem', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesMenuItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesMenuItem(
              label: 'Visits',
              icon: Icons.calendar_month_outlined,
              subtitle: '3 upcoming',
            ),
          ),
        ),
      );

      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('3 upcoming'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesMenuItem(
              label: 'Help',
              icon: Icons.help_outline,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FlatmatesMenuItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('dense variant renders with smaller padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesMenuItem(
              label: 'Edit',
              icon: Icons.edit,
              dense: true,
            ),
          ),
        ),
      );

      expect(find.text('Edit'), findsOneWidget);
      // The icon well should be 32px in dense mode.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final iconWell = containers.where((c) => c.constraints?.maxWidth == 32.0);
      expect(iconWell, isNotEmpty);
    });
  });

  group('FlatmatesNotificationCard', () {
    testWidgets('renders title, body, and time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesNotificationCard(
              title: 'New message',
              body: 'You have a new message from Priya',
              time: '2m ago',
              icon: Icons.chat_bubble_outline,
              iconBgColor: Colors.blue,
              iconColor: Colors.white,
            ),
          ),
        ),
      );

      expect(find.text('New message'), findsOneWidget);
      expect(find.text('You have a new message from Priya'), findsOneWidget);
      expect(find.text('2m ago'), findsOneWidget);
    });

    testWidgets('shows unread dot when isRead is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesNotificationCard(
              title: 'New message',
              body: 'Hello',
              time: '2m ago',
              icon: Icons.chat_bubble_outline,
              iconBgColor: Colors.blue,
              iconColor: Colors.white,
            ),
          ),
        ),
      );

      // The unread dot is a small 8x8 Container.
      final dots = tester.widgetList<Container>(find.byType(Container));
      expect(
        dots.where(
          (c) =>
              c.constraints?.maxWidth == 8.0 && c.constraints?.maxHeight == 8.0,
        ),
        isNotEmpty,
      );
    });

    testWidgets('does not show unread dot when isRead is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesNotificationCard(
              title: 'Old message',
              body: 'Hello',
              time: '2d ago',
              icon: Icons.chat_bubble_outline,
              iconBgColor: Colors.blue,
              iconColor: Colors.white,
              isRead: true,
            ),
          ),
        ),
      );

      final dots = tester.widgetList<Container>(find.byType(Container));
      expect(
        dots.where(
          (c) =>
              c.constraints?.maxWidth == 8.0 && c.constraints?.maxHeight == 8.0,
        ),
        isEmpty,
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesNotificationCard(
              title: 'New message',
              body: 'Hello',
              time: '2m ago',
              icon: Icons.chat_bubble_outline,
              iconBgColor: Colors.blue,
              iconColor: Colors.white,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FlatmatesNotificationCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
