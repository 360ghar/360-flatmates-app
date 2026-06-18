# Getting Started

This guide covers setting up the 360 FlatMates Flutter project for local development.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | 3.41.9 | Pinned via FVM (see `.fvmrc`) |
| Dart SDK | ^3.9.0 | Bundled with Flutter |
| Xcode | Latest stable | Required for iOS builds and Simulator |
| Android Studio | Latest stable | Required for Android builds and emulator |
| Node.js | 18+ | For `serve-sim` and `npx` commands |
| FVM | Latest | Flutter Version Management (optional but recommended) |

## Environment Setup

### 1. Clone and configure

```bash
git clone <repo-url>
cd 360-flatmates-app
cp .env.example .env
```

Edit `.env` with the required values:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase anon/publishable key |
| `API_BASE_URL` | Backend API base URL (e.g. `http://localhost:8000/api/v1`) |
| `GOOGLE_PLACES_API_KEY` | Google Places API key for location search autocomplete |

### 2. Install dependencies

```bash
# If using FVM:
fvm use
fvm flutter pub get

# Without FVM:
flutter pub get
```

### 3. Run the app

```bash
# With FVM:
fvm flutter run

# Without FVM:
flutter run
```

## Backend Dependency

The app requires the FastAPI backend monolith at `../backend` to be running for most features. The bootstrap endpoint (`/flatmates/bootstrap`) loads profile data, catalogs, and counts on every app start.

Without the backend, the app will show a splash screen and fail to authenticate.

## iOS Simulator Browser Preview

For visual testing without controlling the Simulator app directly, use `serve-sim` to stream the iOS Simulator to a browser:

```bash
# Start the stream BEFORE running the app
npx serve-sim                  # -> http://localhost:3200
flutter run                    # then launch on the simulator
```

The stream supports 60fps MJPEG, gesture forwarding, keyboard input, and drag-and-drop media. Requires macOS with Xcode command line tools.

## Code Generation

The project uses Freezed and json_serializable for domain models. After modifying any model annotated with `@freezed` or `@JsonSerializable`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`.freezed.dart`, `.g.dart`) are committed to the repository.

## Localization

The app uses ARB-based localization with English and Hindi:

```bash
flutter gen-l10n
```

This generates Dart classes from `lib/l10n/arb/app_en.arb` (template) and `lib/l10n/arb/app_hi.arb` into `lib/l10n/gen/`. Localization is also auto-generated during `flutter run`.

## Quality Checks

Run these before every commit:

```bash
# Format all Dart files
dart format .

# Static analysis
flutter analyze

# Run tests
flutter test

# Check for banned patterns (no error.toString() in pages, no apiClientProvider in pages, etc.)
bash scripts/banned_patterns.sh
```

### Auto-fix lint issues

```bash
# Preview fixes
dart fix --dry-run lib/

# Apply fixes
dart fix --apply lib/
```

## CI Pipeline

The GitHub Actions workflow (`.github/workflows/quality.yml`) runs on every push and PR:

1. `dart format --set-exit-if-changed .` -- formatting gate
2. `flutter analyze --fatal-infos` -- static analysis
3. `flutter gen-l10n` -- ensure generated l10n is up to date
4. `flutter test` -- unit tests

## Project Structure Quick Reference

```
lib/
  main.dart                 -> entry point
  bootstrap.dart            -> DI setup, Supabase init, Firebase, ProviderScope
  app/                      -> App widget, AppShell, GoRouter
  core/                     -> infrastructure (network, theme, errors, storage, analytics)
  features/                 -> feature modules (auth, discover, swipe, chats, listings, etc.)
  l10n/arb/                 -> ARB localization files
  l10n/gen/                 -> generated localization Dart files
```

## Editor Configuration

### VS Code / Cursor / Windsurf

Format-on-save is configured in `.vscode/settings.json` and applies `dart format` automatically.

### IntelliJ / Android Studio

Enable format-on-save: Settings > Tools > Actions on Save > Reformat code. A shared Dart code style is provided at `.idea/codeStyles/`.
