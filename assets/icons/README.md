# App Icons & Splash Assets

This directory holds the icon assets used by `flutter_launcher_icons`. The native splash is colour-only and uses no image from here (see below).

## Required Files

| File | Purpose | Specs |
|------|---------|-------|
| `app_icon.png` | Launcher icon (legacy / iOS) | 1024×1024px, no transparency, full-bleed |
| `app_icon_foreground.png` | Android adaptive icon foreground | 1024×1024px, safe-zone 72% (inner 768×768), transparent background |

The native splash uses no image: it is the plain paper "sky" colour
(`#E4EBE3` light / `#121814` dark) configured under `flutter_native_splash` in
`pubspec.yaml`. Android 12+ additionally draws the launcher icon over it, which
is the platform default when `android_12.image` is omitted.

## Generating Icons

After placing the source assets, run:

```bash
dart run flutter_launcher_icons
```

## Generating Splash

The splash has no image assets to place. To regenerate the colour-only launch
screen from `pubspec.yaml`, run:

```bash
dart run flutter_native_splash:create
```

To remove the splash:

```bash
dart run flutter_native_splash:remove
```

## Design References

- Neutral icon background: `#F3F3F2` (used for adaptive icon background)
- See `DESIGN.md` for logo specs (compact mode: "36" + rotate_right icon + "FLATMATES")
