# How to Contribute

Welcome to the 360 FlatMates codebase. This section covers the workflows, conventions, and tools you need to contribute effectively.

## Before You Start

Read these files in order:

1. **AGENTS.md** (repo root) -- Core rules, architecture boundaries, Riverpod guidance, error handling, UI conventions, and banned patterns. This is the authoritative reference for how code should be written.
2. **AGENTS.md** (repo root) -- Commands, architecture overview, key patterns, and cross-repo dependencies. Contains the full feature directory layout and state management conventions.
3. **DESIGN.md** (repo root) -- Design tokens, component specifications, and screen-by-screen implementation targets. All visual work must match this document.

## Quick Links

| Topic | Page |
|-------|------|
| Branch, code, test, PR cycle | [Development Workflow](development-workflow.md) |
| Testing strategy and tools | [Testing](testing.md) |
| CLI tools and utilities | [Tooling](tooling.md) |

## Key Principles

- **Real backend only.** No mock repositories, fake payloads, or hardcoded catalogs. Treat `../backend` as the source of truth.
- **Feature-first structure.** Each feature owns its controllers, repositories, models, and pages under `lib/features/<name>/`.
- **Controllers over direct repository calls.** Business logic goes in `application/` layer controllers. Widgets call `ref.read(controllerProvider.notifier).method()`.
- **StateProvider over `setState()`.** Local UI state uses `StateProvider` at file level, not `setState()` in `ConsumerStatefulWidget`.
- **Design system compliance.** All visual tokens must match DESIGN.md. Use `Flatmates*` shared components and `AppMotion`/`AppSemanticColors` tokens.
- **Localization parity.** English and Hindi must stay in sync for all primary user flows. Use `AppLocalizations.of(context)` for all user-facing strings.

## Contribution Checklist

Before submitting a PR, verify:

- [ ] `dart format .` produces no changes
- [ ] `flutter analyze` passes with no issues
- [ ] `flutter test` passes
- [ ] `bash scripts/banned_patterns.sh` passes
- [ ] No `error.toString()` in page files
- [ ] No `apiClientProvider` usage in page files
- [ ] No `Supabase.instance` usage in page files
- [ ] No raw `Image.network` in feature code (use `FlatmatesNetworkImage`)
- [ ] `const` constructors on all immutable widgets
- [ ] `tooltip` on every `IconButton`
- [ ] No empty catch blocks (must `debugPrint` at minimum)
- [ ] English and Hindi ARB files updated for new strings
