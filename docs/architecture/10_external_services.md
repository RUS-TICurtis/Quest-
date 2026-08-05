_Last Modified: 2026-08-05_

# 10. External Services & APIs (Free-Tier Optimized)

To build out the "Social Operating System" while maintaining minimal operational overhead, Quest relies on a carefully selected stack of third-party APIs and services. The architecture is optimized to stay entirely within generous Free Tiers during the MVP and early growth phases.

## 1. Core Backend: Supabase (Already Integrated)
Supabase serves as our primary unified backend, replacing the need for separate AWS/GCP services.
* **Services Used**:
  * **Auth**: Authentication (Email, Magic Links, OAuth).
  * **Database**: PostgreSQL (handling users, events, guilds).
  * **Realtime**: WebSockets for live chat messages and presence (Online/Offline status).
  * **Storage**: Avatars, community banners, event images.
  * **Edge Functions**: Executing server-side logic (e.g., triggering push notifications).
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

## 6. Email Delivery: Resend
For sending transactional emails (Event tickets, Guild invitations, Welcome emails).
* **Service**: Resend (Easily integrates with Supabase Auth & Edge Functions).
* **Free Tier Limits**: 3,000 emails per month (100 per day).
* **Future Upgrade Path**: $20/mo for 50,000 emails.

---

### Summary of MVP Tech Stack Costs
If we utilize the services above, the operational cost for the Quest MVP (up to ~5,000 active users) will be **$0.00/month**. 

**Scaling Bottlenecks to Watch**:
1. **Supabase Realtime Connections**: The 200 concurrent connection limit is the tightest bottleneck. If >200 users are simultaneously chatting or in the app, we must upgrade to the $25/mo Pro plan.
2. **Agora Audio Minutes**: 10,000 minutes = ~166 hours. If 10 users sit in an audio stage for 1 hour, that consumes 600 minutes. Heavy stage usage will exhaust this quickly.
