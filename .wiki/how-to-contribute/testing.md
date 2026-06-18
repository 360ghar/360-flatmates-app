# Testing

Testing strategy and tools for the 360 FlatMates codebase.

## Unit Tests

Run the full test suite:

```bash
flutter test
```

The project maintains at least one fast local Flutter test at all times. Tests live alongside feature code or in `test/`.

## Static Analysis

```bash
flutter analyze
```

The project uses `package:flutter_lints/flutter.yaml` with 23 additional strict rules in `analysis_options.yaml`. Key rules:

| Rule | What it catches |
|------|----------------|
| `use_build_context_synchronously` | `context` usage after `await` without `mounted` check |
| `prefer_const_constructors` | Missing `const` on widget constructors |
| `prefer_const_literals_to_create_immutables` | Missing `const` on list/map/set literals |
| `unawaited_futures` | Fire-and-forget async calls without `unawaited()` |
| `avoid_print` | Use `debugPrint()` instead of `print()` |
| `avoid_dynamic_calls` | Avoid calling methods on `dynamic` values |
| `prefer_final_locals` | Use `final` for local variables |
| `prefer_single_quotes` | Use single quotes for strings |

CI runs `flutter analyze --fatal-infos`, treating info-level diagnostics as errors.

### Auto-fix lint issues

```bash
# Preview what would be fixed
dart fix --dry-run lib/

# Apply all auto-fixable issues
dart fix --apply lib/
```

This handles `prefer_const_constructors`, `avoid_redundant_argument_values`, and other auto-fixable rules.

## Banned Patterns

`scripts/banned_patterns.sh` enforces architecture guardrails by scanning page files for prohibited patterns:

| Pattern | Rule | Rationale |
|---------|------|-----------|
| `error.toString()` | Banned in pages | Use `AppFailure.userMessage()` via `FlatmatesAsyncView` |
| `apiClientProvider` | Banned in pages | Use a repository (page -> controller -> repository -> ApiClient) |
| `Supabase.instance` | Banned in pages | Use repositories or controllers for auth operations |
| `Image.network` | Banned in features | Use `FlatmatesNetworkImage` for consistent loading/error states |
| Page files > 500 lines | Warning | Split into smaller widgets or extract logic to controllers |

Run manually:

```bash
bash scripts/banned_patterns.sh
```

## Maestro E2E Tests

The project uses [Maestro](https://maestro.mobile.dev/) for end-to-end testing on real devices or simulators.

### Prerequisites

Set these environment variables:

```bash
export MAESTRO_PHONE="<test-phone-number>"
export MAESTRO_PASSWORD="<test-password>"
```

### Running E2E tests

```bash
maestro test .maestro/full_e2e.yaml
```

### When to update Maestro flows

Update Maestro test files when:

- Route names change
- Button labels change
- Login flow behavior changes
- New critical user paths are added

### Keys for Maestro stability

Use meaningful `Key` values on interactive widgets so Maestro can reliably target elements:

```dart
IconButton(
  key: const ValueKey('nav_home_tab'),
  icon: const Icon(Icons.home_outlined),
  tooltip: 'Home',
)
```

The `AppShell` uses `Semantics(identifier: ...)` on navigation icons for Maestro targeting.

## Testing Conventions

### Error handling in tests

Never use `error.toString()` in test assertions. Use typed `AppFailure` checks:

```dart
// Bad
expect(error.toString(), contains('network'));

// Good
expect(error, isA<NetworkFailure>());
```

### Widget testing

Use `ProviderScope` with overrides for testing widgets that depend on Riverpod providers:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      myProvider.overrideWithValue(testValue),
    ],
    child: const MyWidget(),
  ),
);
```

### Async testing

Use `pumpAndSettle()` for animations and async operations. Check `mounted` before using `context` after `await` in production code -- the `use_build_context_synchronously` lint rule catches this.
