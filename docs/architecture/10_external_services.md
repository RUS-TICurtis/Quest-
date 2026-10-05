_Last Modified: 2026-10-05_

# 10. External Services & APIs (Free-Tier Optimized)

To build out the "Social Operating System" while maintaining minimal operational overhead, Quest relies on a carefully selected stack of third-party APIs and services. The architecture is optimized to stay entirely within generous Free Tiers during the MVP and early growth phases.

## 1. Core Backend: Supabase (Already Integrated)
Supabase serves as our primary unified backend, replacing the need for separate AWS/GCP services.
* **Services Used**:
  * **Auth**: Authentication (Email, Magic Links, OAuth).
  * **Database**: PostgreSQL (handling users, events, guilds).
  * **Realtime**: WebSockets for live chat messages and presence (Online/Offline status).
  * **Storage**: Avatars, community banners, event images.
  * **Edge Functions**: Executing server-side logic and managing atomic operations:
    * `sign-media-upload`: Authenticated delegation of upload credentials and signing (Mux direct uploads, Cloudinary HMAC, ImageKit HMAC) without client secrets.
    * `publish-experience`: Secure, centralized creation of posts across feed, story, and community destinations.
    * `interact-video`: Atomic handling of likes and comments with automatic calculation of creator engagement scores.
    * `send-message`: Chat message transmission with simultaneous updates to thread metadata (`lastMessageText`, `lastMessageTime`).
    * `update-profile`: Sanitized profile mutation preventing modification of protected properties like `trust_score`.
    * `delete-experience`: Cascading removal of stories and videos across unified and legacy tables with creator authorization checks.
* **Security & Secret Segregation**:
  * Privileged keys (`SUPABASE_SERVICE_ROLE_KEY`, `MUX_TOKEN_SECRET`, `CLOUDINARY_API_SECRET`, `IMAGEKIT_PRIVATE_KEY`) reside exclusively in Supabase backend environments / Edge Functions.
  * The Flutter client bundle NEVER contains private keys or service role tokens.
* **Free Tier Limits**:
  * 50,000 Monthly Active Users (MAU).
  * 500 MB Database space & 1 GB File Storage.
  * 200 concurrent Realtime connections.
  * 2,000,000 Edge Function invocations per month.
* **Future Upgrade Path**: $25/mo Pro plan unlocks 100k MAU, 8GB DB, 100GB Storage, and 500 concurrent connections.

## 2. Live Audio Stage: Agora.io or LiveKit
The `/stage` feature requires real-time low-latency audio broadcasting (WebRTC) capable of handling speakers and large audiences.
* **Recommended Service: Agora.io** (Flutter SDK: `agora_rtc_engine`)
  * **Use Case**: Powering the audio rooms, speaker roster, and microphone toggles.
  * **Free Tier Limits**: 10,000 free minutes per month (every month).
* **Alternative: LiveKit** (Open Source / Cloud)
  * **Free Tier Limits**: 50GB bandwidth per month.
* **Future Upgrade Path**: Agora charges ~$0.99 per 1,000 minutes of audio once past the free tier.

## 3. Geospatial & Proximity Radar: PostGIS (Supabase) + Mapbox
The `/radar` feature requires calculating relative distances between users and physical hubs.
* **Backend Geospatial Calculations**: 
  * Handled 100% via **PostGIS** extension in our existing Supabase PostgreSQL database (Free).
* **Map Rendering (If visual maps are added later)**: 
  * **Recommended Service: Mapbox**
  * **Free Tier Limits**: 50,000 map loads per month.

## 4. Push Notifications: Firebase Cloud Messaging (FCM)
For out-of-app alerts (e.g., direct messages, event reminders).
* **Service**: Firebase Cloud Messaging (via `firebase_messaging` Flutter package).
* **Implementation**: We trigger FCM payloads securely from Supabase Edge Functions.
* **Free Tier Limits**: 100% Free indefinitely. No scaling costs for notifications.

## 5. Analytics & Crash Reporting: Firebase
* **Services**: Firebase Crashlytics & Google Analytics for Firebase.
* **Use Case**: Tracking fatal/non-fatal app crashes and tracking screen views.
* **Free Tier Limits**: 100% Free indefinitely.

## 6. Video & Media Streaming: Server-Delegated Uploads (Mux + Cloudinary + ImageKit)
* **Zero Client Secrets**:
  * No `MUX_TOKEN_SECRET`, `CLOUDINARY_API_SECRET`, or `IMAGEKIT_PRIVATE_KEY` are packaged or loaded in Flutter.
  * Client requests signed upload credentials via the `sign-media-upload` Edge Function.
* **Primary Video (Mux)**:
  * Client calls `sign-media-upload` to generate a temporary direct upload URL with public playback policy.
  * Client streams video bytes directly to the pre-signed Mux CDN URL via standard HTTP `PUT`.
  * Asset status polling or webhook ingestion (`mux-webhook`) transitions the video into `ready` state.
  * Throws `MuxQuotaException` on HTTP 402/429 for gateway fallback.
* **Fallback Video & Chat Media (Cloudinary)**:
  * Client requests an upload signature from `sign-media-upload` with server-side HMAC hashing.
  * Client performs multipart POST directly to Cloudinary using the signature.
* **Image Media (ImageKit)**:
  * Client requests authentication parameters (`token`, `expire`, `signature`) from `sign-media-upload`.
  * Uploads directly to ImageKit using the public key and server signature.
* **Progress & UI Feedback**: `UploadStatusCallback` in `MediaServiceGateway` feeds human-readable stage messages to the UI.

## 7. Device Notifications: `flutter_local_notifications`
* **Package**: `flutter_local_notifications: ^18.0.1`
* **Service**: `lib/core/services/app_notification_service.dart`
* **Channels**:
  * `quest_uploads` – upload progress (ongoing) and completion/failure alerts.
  * `quest_chat` – incoming message alerts.
  * `quest_general` – quest events, level-ups, general updates.
* **Permissions**: `POST_NOTIFICATIONS` + `VIBRATE` added to `AndroidManifest.xml`.
* **Initialization**: Called once in `main()` before `runApp`.

## 6. Email Delivery: Resend
For sending transactional emails (Event tickets, Guild invitations, Welcome emails).
* **Service**: Resend (Easily integrates with Supabase Auth & Edge Functions).
* **Free Tier Limits**: 3,000 emails per month (100 per day).
* **Future Upgrade Path**: $20/mo for 50,000 emails.

## 8. Local Storage & Caching: Hive
For offline resilience, fast initial render, and stale-while-revalidate patterns, structured data is cached locally via Hive.
* **Service**: `LocalDatabaseService` utilizing `hive_flutter`.
* **Boxes (Caches)**:
  * `chat_rooms`: Chat room metadata (TypeAdapter 1).
  * `chat_messages`: Messaging history outbox/inbox (TypeAdapter 2).
  * `feed_video_cache`: Feed video dedup & 24h stale-while-revalidate (TypeAdapter 10).
  * `memberProfilesBox` / `profile_cache`: Member profile caching avoiding redundant Supabase requests (TypeAdapter 11).
  * `storiesBox` / `story_cache`: Stories 24-hour TTL caching for instantaneous viewing (TypeAdapter 12).
* **Settings**: `LocalStorageService` utilizing `shared_preferences` for UI settings and scalar properties.

---

### Summary of MVP Tech Stack Costs
If we utilize the services above, the operational cost for the Quest MVP (up to ~5,000 active users) will be **$0.00/month**. 

**Scaling Bottlenecks to Watch**:
1. **Supabase Realtime Connections**: The 200 concurrent connection limit is the tightest bottleneck. If >200 users are simultaneously chatting or in the app, we must upgrade to the $25/mo Pro plan.
2. **Agora Audio Minutes**: 10,000 minutes = ~166 hours. If 10 users sit in an audio stage for 1 hour, that consumes 600 minutes. Heavy stage usage will exhaust this quickly.
