#!/bin/sh
# Exposes variables from a .env file into the current environment.
#
# This script MUST be sourced (dotted) so the exported variables persist in
# the caller's shell, e.g.:
#
#   . ./scripts/load_env.sh            # loads ./.env
#   . ./scripts/load_env.sh path/.env  # loads a custom path
#
# Lines beginning with '#' and blank lines are ignored. Inline comments after
# a value are stripped. Existing shell variables are NOT overwritten, so you
# can override .env values by exporting them first.

load_env() {
  envfile="${1:-.env}"
  if [ ! -f "$envfile" ]; then
    echo "load_env: file not found: $envfile" >&2
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
    esac

    key=${line%%=*}
    val=${line#*=}
    key=$(printf '%s' "$key" | tr -d '[:space:]')
    val=$(printf '%s' "$val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//')

    [ -z "$key" ] && continue
    eval "if [ -z \"\${$key+x}\" ]; then export $key='$val'; fi"
  done < "$envfile"
}

load_env "${1:-.env}"
