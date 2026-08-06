_Last Modified: 2026-08-06_

# 8. Platform Notes

## Android

| Property | Value |
|---|---|
| Package | `com.example.quest` |
| Min SDK | 21 (Android 5.0 Lollipop) |
| Target SDK | 34 (Android 14) |
| App Label | `Quest❕` |
| Build System | Gradle (Kotlin DSL) |
| Native Arch | `arm64-v8a`, `armeabi-v7a`, `x86_64` |

**Notes:**
- `compileSdkVersion` must be ≥ 34 for Material3 dynamic color support
- `connectivity_plus` requires `android.permission.ACCESS_NETWORK_STATE` in manifest (already added)
- `url_launcher` requires `<queries>` block for SMS intent on Android 11+ (already added in manifest)

## iOS

| Property | Value |
|---|---|
| Bundle ID | `com.example.quest` |
| CFBundleName | `Quest❕` |
| Deployment Target | iOS 13.0 |
| Supported Architectures | `arm64` (device), `x86_64` (simulator) |

**Notes:**
- `google_fonts` requires internet access on first launch for font download; subsequent loads use cache
- `url_launcher` requires LSApplicationQueriesSchemes for `sms` in Info.plist for offline SMS fallback in chat

## Web

| Property | Value |
|---|---|
| Renderer | CanvasKit (default for production) |
| Index | `web/index.html` |

**Notes:**
- `connectivity_plus` on Web uses `navigator.onLine` — not all network state events are available
- GoRouter handles browser history and deep links natively via `GoRouter.router`

## Desktop (Windows / macOS / Linux)

- Navigation uses `NavigationRail` sidebar (responsive breakpoint: `> 600px` width)
- `HapticFeedback` is a no-op on desktop — this is expected
- `url_launcher` must be enabled in the platform runner on macOS (`macos/Runner/DebugProfile.entitlements`)
