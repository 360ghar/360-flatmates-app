#!/usr/bin/env python3
"""Write lib/core/domain/wire_enums.dart: the wire enums this app reads or sends.

Source of the values, in this order:

1. `--source PATH` (a contract-audit `enums.json`, or a backend `openapi.json`).
2. The backend `docs/openapi.json` next to this repo
   (`../../360ghar/360ghar-backend/docs/openapi.json`).
3. `../../360ghar/contract-audit/enums.json`.

Every enum gets `fromJson` (null for a value this build does not know; the miss is logged,
nothing falls back to a real value) and `toJson` (the wire value).

Run from the repo root:

    python3 tool/gen_enums.py

To use another enum, add its name to `ENUMS` and run the script again.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WORKSPACE = REPO.parents[1] / "360ghar"
OUT = REPO / "lib" / "core" / "domain" / "wire_enums.dart"
DEFAULT_SOURCES = (
    WORKSPACE / "360ghar-backend" / "docs" / "openapi.json",
    WORKSPACE / "contract-audit" / "enums.json",
)

# Component enums the app reads or sends. Keep sorted.
ENUMS = (
    "AppKey",
    "AuthMethod",
    "BugSeverity",
    "BugType",
    "Cleanliness",
    "ConversationSource",
    "ConversationStatus",
    "DevicePlatform",
    "FlatmatesDrinkingType",
    "FlatmatesMode",
    "FlatmatesProfileStatus",
    "FlatmatesSmokingType",
    "FoodHabits",
    "FurnishingLevel",
    "GuestsPolicy",
    "KitchenType",
    "ListingGenderPreference",
    "ListingModerationStatus",
    "ListingSharingType",
    "MessageType",
    "MoveInTimeline",
    "PropertyPurpose",
    "PropertyType",
    "SleepSchedule",
    "StorageFolderType",
    "SwipeAction",
    "SwipeTargetType",
    "TourVisibility",
    "UserMatchStatus",
    "UserReportReason",
    "VentilationType",
    "VisitContext",
    "VisitStatus",
    "WorkStyle",
)

# Dart words that cannot be an enum member name.
RESERVED = {
    "abstract", "as", "assert", "async", "await", "break", "case", "catch", "class", "const",
    "continue", "covariant", "default", "deferred", "do", "dynamic", "else", "enum", "export",
    "extends", "extension", "external", "factory", "false", "final", "finally", "for", "get",
    "if", "implements", "import", "in", "interface", "is", "late", "library", "mixin", "new",
    "null", "on", "operator", "part", "required", "rethrow", "return", "set", "static",
    "super", "switch", "sync", "this", "throw", "true", "try", "typedef", "var", "void",
    "while", "with", "yield", "values", "index", "wire", "hashCode", "toString",
}


def load(path: Path) -> dict[str, list[str]]:
    data = json.loads(path.read_text())
    if "components" in data:
        schemas = data["components"]["schemas"]
        return {
            name: list(schema["enum"])
            for name, schema in schemas.items()
            if isinstance(schema, dict) and "enum" in schema
        }
    return {name: list(values) for name, values in data.items() if isinstance(values, list)}


def member(value: str) -> str:
    parts = [p for p in re.split(r"[^0-9A-Za-z]+", value) if p]
    if not parts:
        raise ValueError(f"cannot name enum value {value!r}")
    name = parts[0].lower() + "".join(p[:1].upper() + p[1:].lower() for p in parts[1:])
    if name[0].isdigit():
        name = "v" + name[:1].upper() + name[1:]
    return name + "Value" if name in RESERVED else name


def render(name: str, values: list[str]) -> str:
    members = [(member(v), v) for v in values]
    names = [m for m, _ in members]
    if len(set(names)) != len(names):
        raise ValueError(f"{name}: two wire values give one Dart name: {names}")
    body = ",\n".join(f"  {m}('{v}')" for m, v in members)
    return f"""/// Wire values of `{name}`.
enum {name} {{
{body};

  const {name}(this.wire);

  /// The value the backend sends and accepts.
  final String wire;

  /// The member for [value], or null when [value] is null or not known to this build.
  /// A value that is not known is logged. It never becomes a real member.
  static {name}? fromJson(Object? value) {{
    if (value == null) return null;
    for (final member in values) {{
      if (member.wire == value) return member;
    }}
    debugPrint('{name}.fromJson: unknown wire value $value');
    return null;
  }}

  String toJson() => wire;
}}
"""


def registry_entry(name: str) -> str:
    """One `kWireEnumValues` entry, wrapped the way `dart format` wraps it (80 columns)."""
    line = f"  '{name}': [for (final v in {name}.values) v.wire],\n"
    if len(line.rstrip("\n")) <= 80:
        return line
    return f"  '{name}': [\n    for (final v in {name}.values) v.wire,\n  ],\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--source", type=Path, help="enums.json or openapi.json")
    args = parser.parse_args()

    candidates = [args.source] if args.source else list(DEFAULT_SOURCES)
    source = next((p for p in candidates if p and p.exists()), None)
    if source is None:
        print("no enum source found: " + ", ".join(str(p) for p in candidates), file=sys.stderr)
        return 1
    known = load(source)

    missing = [n for n in ENUMS if n not in known]
    if missing:
        print(f"{source}: enum(s) not found: {', '.join(missing)}", file=sys.stderr)
        return 1

    header = (
        "// GENERATED by tool/gen_enums.py. Do not edit by hand.\n"
        "// Source: backend OpenAPI component enums (see the script for the order of sources).\n"
        "// ignore_for_file: constant_identifier_names\n\n"
        "import 'package:flutter/foundation.dart';\n\n"
    )
    registry = (
        "\n/// Every enum above with the wire values this build knows, by backend name. The contract\n"
        "/// tests compare it with the values the backend serves.\n"
        "final Map<String, List<String>> kWireEnumValues = {\n"
        + "".join(registry_entry(n) for n in ENUMS)
        + "};\n"
    )
    text = header + "\n".join(render(n, known[n]) for n in ENUMS) + registry
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(REPO)} ({len(ENUMS)} enums from {source})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
