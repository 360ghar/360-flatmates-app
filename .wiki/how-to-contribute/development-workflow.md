# Development Workflow

The standard branch-to-merge cycle for 360 FlatMates.

## Branch Naming

Use descriptive branch names from the repo root:

```text
feature/<short-description>
fix/<short-description>
refactor/<short-description>
```

## Development Cycle

### 1. Branch from main

```bash
git checkout main
git pull origin main
git checkout -b feature/my-feature
```

### 2. Write code

Follow the conventions in AGENTS.md:

- Feature logic in `lib/features/<name>/`
- Business logic in `application/` controllers, not widgets
- UI state via `StateProvider`, not `setState()`
- All user-facing strings through `AppLocalizations.of(context)`
- Design tokens from `core/theme/` (no magic numbers)
- `const` constructors on immutable widgets
- `tooltip` on every `IconButton`

### 3. Run code generation (if models changed)

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates Freezed and json_serializable files. Generated `.freezed.dart` and `.g.dart` files are committed.

### 4. Update localization (if strings changed)

```bash
flutter gen-l10n
```

Add new keys to both `lib/l10n/arb/app_en.arb` and `lib/l10n/arb/app_hi.arb`.

### 5. Format and fix

```bash
# Format all files
dart format .

# Auto-fix lint issues
dart fix --apply lib/
```

VS Code users get format-on-save via `.vscode/settings.json`. IntelliJ users should enable Settings > Tools > Actions on Save > Reformat code.

### 6. Run quality checks

```bash
flutter analyze
flutter test
bash scripts/banned_patterns.sh
```

### 7. Commit

Write clear commit messages describing the change. Run `dart format .` before committing -- CI will reject unformatted code.

### 8. Push and open PR

```bash
git push origin feature/my-feature
```

Open a PR against `main`. The CI pipeline (`.github/workflows/quality.yml`) runs automatically:

1. `dart format --set-exit-if-changed` -- rejects unformatted files
2. `flutter analyze --fatal-infos` -- static analysis with info-level as errors
3. `flutter gen-l10n` -- ensures generated l10n matches ARB sources
4. `flutter test` -- unit tests

All four checks must pass before merging.

## Common Tasks

### Adding a new API endpoint

1. Add the path constant to `lib/core/config/endpoints.dart`
2. Add the method to the relevant repository in `lib/features/<name>/data/`
3. If the response shape is complex, create a DTO in the feature's `data/` layer
4. Call the repository from a controller in `application/`
5. Update the widget to call the controller via `ref.read(controllerProvider.notifier)`

### Adding a new screen

1. Create the page widget in `lib/features/<name>/presentation/`
2. Use `FlatmatesScreen` as the scaffold wrapper
3. Add the route in `lib/app/router/app_router.dart`
4. If it needs bottom nav, add a branch to `StatefulShellRoute`
5. Add localization keys to both ARB files
6. Use meaningful `Key` values on interactive widgets for Maestro stability

### Adding a new shared component

1. Create the widget in `lib/features/shared/presentation/`
2. Export it from `lib/features/shared/presentation/components.dart`
3. Use `AppMotion` tokens for animations and `AppSemanticColors` for colors
4. Include `const` constructor and `tooltip` on any `IconButton`

### Modifying a Freezed model

1. Edit the model class in `lib/features/<name>/domain/`
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Commit both the source and generated files
