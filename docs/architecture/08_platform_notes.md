_Last Modified: 2026-09-13_

# 8. Platform Notes

## Android

| Property | Value |
|---|---|
| Package | `com.quest.quest` |
| Min SDK | Flutter Min SDK |
| Target SDK | Flutter Target SDK |
| App Label | `Quest` |
| Build System | Gradle (Kotlin DSL) |
| Native Arch | `arm64-v8a`, `armeabi-v7a`, `x86_64` (Split APKs available) |

**Notes:**
- `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE` in `android/app/src/main/AndroidManifest.xml` ensure release APK builds have full network connectivity for Supabase and Google Auth.
- Deep link intent-filter configured for `io.supabase.quest://login-callback`.
- Google Sign-In requires an Android OAuth Client ID in Google Cloud Console configured with package `com.quest.quest` and debug keystore SHA-1 fingerprint (`7B:41:DF:F2:38:D1:E1:1E:48:FE:E4:0A:58:66:9D:17:63:39:CE:A2`).
- `url_launcher` requires `<queries>` block in manifest for text processing.

## iOS

| Property | Value |
|---|---|
| Bundle ID | `com.example.quest` |
| CFBundleName | `Quest` |
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
