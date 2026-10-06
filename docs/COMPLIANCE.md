# Quest - Compliance Register

_Generated continuously during development using the app-store-compliance skill._

## Summary
The Quest application is evaluated against Apple App Store, Google Play, Privacy, and Content policies to ensure a smooth submission process.

## Apple App Store
- **Status:** Needs Review
- **Notes:** Need to declare usage of `Camera`, `Microphone`, and `Location` in iOS `Info.plist`. The app requests location for the `Radar` feature and handles UGC. A mechanism to Report/Block users exists in the UI but backend blocking filters must be verified.

## Google Play
- **Status:** Needs Review
- **Notes:** Need to map requested permissions (`ACCESS_FINE_LOCATION`) and ensure a clear privacy policy link is exposed prominently due to UGC and geolocation features.

## Privacy & Account Deletion
- **Status:** Manual Review Required
- **Notes:** In-app account deletion is implemented in the Settings UI (`SettingsScreen` sign out / delete account section). We must confirm that the associated Edge Function fully purges row data in Supabase (or correctly anonymizes) rather than just dropping the Auth user.
- **Required Action:** Verify `delete_account` RPC or Edge Function logic.

## User-Generated Content (UGC)
- **Status:** Needs Verification
- **Notes:** The Feed, Comments, and Chat are heavily reliant on UGC. Apple requires 1) filtering of objectionable material, 2) a mechanism to report offensive content, 3) the ability to block abusive users, and 4) published contact info.
- **Risk:** High. If blocking a user doesn't physically filter their messages/feed posts from the local client, the app will face rejection under Guideline 1.2 (User Generated Content).

## Location / Radar
- **Status:** Code Issue
- **Notes:** The Radar screen prompts for location, but the background continuous query could trigger aggressive Apple/Google location permission reviews. We need to ensure the permission prompt context is extremely explicit about *why* we need it ("to show your proximity to Quest events").

## Authentication
- **Status:** Compliant
- **Notes:** Standard Google OAuth implemented via Supabase. Apple requires "Sign in with Apple" if other third-party providers (like Google) are used.
- **Risk:** High. **If Sign In With Apple is not implemented alongside Google, the App Store will reject it under Guideline 4.8 (Sign in with Apple).**

## Last Checked
* 2026-10-05

## Immediate Store Submission Risks
1. Missing **Sign in with Apple** implementation (mandated when Google/third-party is used).
2. Missing **EULA/Terms** confirmation in the Onboarding flow.
3. Need backend validation that **Block User** hides content locally and globally for the blocked pair.
