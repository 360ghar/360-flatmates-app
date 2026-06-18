# Tooling

CLI tools and utilities used in the 360 FlatMates development workflow.

## FVM (Flutter Version Management)

The project pins Flutter 3.41.9 via FVM (see `.fvmrc`). FVM ensures all developers use the same Flutter version.

```bash
# Install FVM
dart pub global activate fvm

# Use the pinned version
fvm use

# Run Flutter commands through FVM
fvm flutter pub get
fvm flutter run
fvm flutter test
```

Without FVM, use the Flutter version specified in `.fvmrc` directly.

## serve-sim (iOS Simulator Browser Preview)

[serve-sim](https://github.com/EvanBacon/serve-sim) streams the iOS Simulator framebuffer to a browser at `http://localhost:3200`.

```bash
# Start BEFORE flutter run
npx serve-sim

# Run the app on the simulator
flutter run
```

Capabilities: 60fps MJPEG stream, gesture support (swipe-to-go-home, pinch-to-zoom), keyboard forwarding, drag-and-drop media, simulator log forwarding. Supports background mode with `npx serve-sim --detach`.

Requires macOS with Xcode command line tools and a booted iOS Simulator.

## dart fix

Auto-fixes common lint issues across the codebase:

```bash
# Preview fixes (dry run)
dart fix --dry-run lib/

# Apply all fixes
dart fix --apply lib/
```

Handles: `prefer_const_constructors`, `avoid_redundant_argument_values`, `prefer_const_literals_to_create_immutables`, and other auto-fixable rules. Run periodically to keep the codebase clean.

## build_runner (Code Generation)

Generates Freezed and json_serializable code for domain models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

When to run: after modifying any class annotated with `@freezed`, `@JsonSerializable`, or `@JsonKey`. The `--delete-conflicting-outputs` flag removes stale generated files before regenerating.

Generated files (`.freezed.dart`, `.g.dart`) are committed to the repository.

## flutter gen-l10n (Localization Generation)

Generates Dart localization classes from ARB files:

```bash
flutter gen-l10n
```

Source files:
- `lib/l10n/arb/app_en.arb` (English, template)
- `lib/l10n/arb/app_hi.arb` (Hindi)

Output: `lib/l10n/gen/` (generated Dart files)

This runs automatically during `flutter run` and `flutter build`, but can be triggered manually after editing ARB files.

## dart format

Formats all Dart files according to the Dart style guide:

```bash
# Format the entire project
dart format .

# Check without modifying (CI mode)
dart format --set-exit-if-changed .
```

### Editor integration

- **VS Code / Cursor / Windsurf**: Format-on-save is configured in `.vscode/settings.json`
- **IntelliJ / Android Studio**: Enable Settings > Tools > Actions on Save > Reformat code. Shared code style at `.idea/codeStyles/`.

## banned_patterns.sh

A shell script that scans page and feature files for prohibited code patterns:

```bash
bash scripts/banned_patterns.sh
```

Checks for:
- `error.toString()` in page files
- `apiClientProvider` in page files (must use repository)
- `Supabase.instance` in page files (must use repository/controller)
- `Image.network` in feature files (must use `FlatmatesNetworkImage`)
- Page files exceeding 500 lines

This runs as part of the local quality check workflow and catches architecture violations before CI.

## Maestro (E2E Testing)

[Maestro](https://maestro.mobile.dev/) drives end-to-end flows on real devices or simulators:

```bash
maestro test .maestro/full_e2e.yaml
```

Requires environment variables `MAESTRO_PHONE` and `MAESTRO_PASSWORD` for authentication.

## Fastlane

The project uses [Fastlane](https://fastlane.tools/) for build automation and deployment. See the Fastlane configuration in `ios/` and `android/` directories for lane definitions.

## Recommended Development Tools

| Tool | Purpose |
|------|---------|
| VS Code / Cursor | Primary editor with format-on-save |
| Flutter Inspector | Widget tree debugging (built into Flutter DevTools) |
| Dart DevTools | Performance profiling, memory analysis |
| Postman / HTTPie | Backend API testing |
| Xcode | iOS builds, Simulator management |
| Android Studio | Android builds, emulator management |
