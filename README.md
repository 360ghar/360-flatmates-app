# 360 FlatMates

Flutter mobile client for the 360 FlatMates product.

## Setup

1. Copy `.env.example` to `.env` and fill the Supabase and backend values.
2. Run `flutter pub get`.
3. Start the backend monolith from `../backend`.
4. Run the app for your target device. For a physical Android phone over USB,
   use `.\scripts\run_android_usb.ps1` instead of plain `flutter run`.

## Release Configuration

- Android map features read `GOOGLE_MAPS_API_KEY` from `android/local.properties`, a Gradle property (`-PGOOGLE_MAPS_API_KEY=...`), or the shell environment. Android release builds fail fast when this value is missing.
- iOS App Store links read `APP_STORE_ID` from `--dart-define=APP_STORE_ID=...` after App Store Connect assigns the app ID.

## Running on iOS Simulator (Browser Preview)

Stream the iOS Simulator to your browser for agent-accessible testing using [serve-sim](https://github.com/EvanBacon/serve-sim):

```bash
# Prerequisites: macOS with Xcode + a booted iOS simulator
# 1. Start the simulator stream (run BEFORE flutter run)
npx serve-sim                  # → http://localhost:3200

# 2. Run the Flutter app on the simulator
flutter run
```

Once running, the simulator is viewable and interactable at `http://localhost:3200` — no need to control the Simulator app directly. This enables AI agents (Codex, Cursor, Claude Desktop) to visually test the app through the browser.

Key capabilities: full 60fps MJPEG stream, gesture support (swipe-to-go-home, pinch-to-zoom with option key), keyboard forwarding, drag-and-drop media onto the device, simulator log forwarding to browser. Works with any booted iOS, iPad, or Apple Watch simulator. Supports multiple devices and background mode (`npx serve-sim --detach`).

## Running on Android USB

Use the Windows PowerShell helper when the backend is running on the host machine and the app should run on a physical Android device over USB:

```powershell
.\scripts\run_android_usb.ps1
```

The script checks `http://127.0.0.1:3600/health`, finds `adb`, selects one ready USB device, runs `adb reverse tcp:3600 tcp:3600`, then launches Flutter with `API_BASE_URL=http://127.0.0.1:3600/api/v1`.

Common options:

```powershell
.\scripts\run_android_usb.ps1 -DeviceId R5CT123456A
.\scripts\run_android_usb.ps1 -BackendPort 3700
.\scripts\run_android_usb.ps1 -FlutterArgs "--debug","--verbose"
```

If multiple devices are connected, pass `-DeviceId`. If the backend uses a non-default port, pass `-BackendPort`.

## Quality Checks

- `flutter analyze`
- `flutter test`

## Backend Dependency

This app expects the FlatMates API surface to exist in the shared FastAPI monolith at `../backend`.
