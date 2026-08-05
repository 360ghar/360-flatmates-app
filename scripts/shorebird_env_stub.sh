#!/bin/sh
# Sourced by scripts/shorebird_release.sh and scripts/shorebird_patch.sh.
# Not executable on its own.
#
# `.env` is a declared Flutter asset (see pubspec.yaml), so its exact bytes are
# part of the asset bundle. That matters twice over:
#
#  1. Shorebird diffs the patch build's assets against the release's. CI writes
#     a one-line `APP_ENV=prod` stub, so a developer's real .env would make
#     every locally-built patch report spurious asset changes.
#  2. A real .env bundled into a release would ship secrets as an app asset —
#     exactly what the pubspec comment warns against. Real config reaches the
#     app through --dart-define.
#
# So both release and patch builds run against the same one-line stub, and the
# developer's real .env is restored afterwards, including on failure.

_SHOREBIRD_ENV_BACKUP=''

shorebird_restore_env() {
  if [ -n "$_SHOREBIRD_ENV_BACKUP" ]; then
    mv -f "$_SHOREBIRD_ENV_BACKUP" .env
    echo "shorebird: restored your local .env"
  else
    # There was no .env to begin with — don't leave the stub behind.
    rm -f .env
  fi
}

# Replaces ./.env with the CI-identical stub and arms restoration on exit.
shorebird_stub_env() {
  trap shorebird_restore_env EXIT HUP INT TERM
  if [ -f .env ]; then
    _SHOREBIRD_ENV_BACKUP="$(mktemp -t flatmates_env)"
    cp .env "$_SHOREBIRD_ENV_BACKUP"
    echo "shorebird: using the CI .env stub for this build (yours is restored after)"
  fi
  printf 'APP_ENV=prod\n' > .env
}
