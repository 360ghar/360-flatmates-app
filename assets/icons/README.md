# App Icons & Splash Assets

This directory holds icon and splash assets used by `flutter_launcher_icons` and `flutter_native_splash`.

## Required Files

| File | Purpose | Specs |
|------|---------|-------|
| `app_icon.png` | Launcher icon (legacy / iOS) | 1024×1024px, no transparency, full-bleed |
| `app_icon_foreground.png` | Android adaptive icon foreground | 1024×1024px, safe-zone 72% (inner 768×768), transparent background |
| `splash_logo.png` | Native splash center image | ~480×480px, brand mark on transparent bg |
| `splash_branding.png` | Native splash bottom branding | ~320×80px, tagline on transparent bg |

## Generating Icons

After placing the source assets, run:

```bash
dart run flutter_launcher_icons
```

## Generating Splash

After placing splash assets, run:

```bash
dart run flutter_native_splash:create
```

To remove the splash:

```bash
dart run flutter_native_splash:remove
```

## Design References

- Primary color: `#5B4BCF` (used for adaptive icon background)
- See `DESIGN.md` for logo specs (compact mode: "36" + rotate_right icon + "FLATMATES")
