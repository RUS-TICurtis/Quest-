# Quest Create & Sharing Pipeline — Comprehensive UI/UX Audit

_Last Modified: 2026-10-09_  
_Auditor: Senior UI/UX Designer & Mobile Design Technologist_  
_Methodology: Code Inspection, Runtime Contract Tracing, Apple Human Interface Guidelines (WWDC Fluid Interfaces), Nielsen Norman Usability Heuristics, and UI-Skills Design Engineering Guidelines (`frontend-design`, `apple-design`, `better-ui`, `improve-ui`)._

---

## Executive Summary

The Create and Sharing pipeline is the kinetic heartbeat of **Quest (QWST.RUN)**. While the underlying backend infrastructure has solid foundations—featuring a multi-cloud media gateway (`MediaServiceGateway`) routing to Mux with Cloudinary fallback, signed upload edge functions, and Supabase database persistence—the **front-end user experience, camera ergonomics, review workflow, and social sharing mechanics currently suffer from severe usability defects, broken functional contracts, and brand misalignment**.

Most critically:
1. **Showstopper Functional Bug**: Text creation mode crashes both the media preview and upload pipeline in `ShareExperienceScreen` due to treating raw caption strings as local file paths.
2. **Missing Essential Camera Controls**: The camera viewfinder lacks basic mobile primitives—there is no camera flip toggle (rear camera is hardcoded), no torch/flash switch, no tap-to-focus/exposure reticle, and no pinch-to-zoom.
3. **Absence of Video Recording Feedback**: During video capture, there is no recording timer, elapsed duration display, maximum duration limit, or radial progress bar.
4. **Shell Navigation Collision**: `CreateScreen` is rendered inside `MainShell` with the bottom navigation bar visible directly below the camera shutter, creating navigation collisions and thumb-zone crowding.
5. **Preview Distortion**: The media review card in `ShareExperienceScreen` is constrained to a fixed 250px height, severely letterboxing 9:16 vertical video into an unwatchable thumbnail with no playback or trimming controls.
6. **Hollow Sharing**: The "Share" button on the video feed merely increments a database counter with a SnackBar message, lacking native OS sheet export, deep linking, or in-app DM forwarding.
7. **Identity Disconnection**: The publishing flow does not integrate with Quest's core proposition: linking posts to active Quests, event proofs, verified participation milestones, or place check-ins.

### Audit Scorecard

| Dimension | Rating | Status | Summary |
|---|---|---|---|
| **Visual Design & Craft** | 4.5 / 10 | 🔴 Critical Drift | Raw black backgrounds, unstyled buttons, inconsistent padding, lack of glassmorphism. |
| **Ergonomics & Thumb Zone** | 3.5 / 10 | 🔴 Poor | Shutter button overlaps shell bottom nav; mode selector lacks carousel swipe physics. |
| **Motion & Micro-interactions** | 4.0 / 10 | 🟠 Underdeveloped | Limited haptics; missing spring-based shutter press states, mode transitions, or recording pulses. |
| **System Feedback & State** | 3.0 / 10 | 🔴 Critical Gaps | Zero video recording timer; generic error toasts; no visual upload percentage bar. |
| **Platform Conventions (iOS / Android)** | 4.0 / 10 | 🟠 Below Standard | Hardcoded camera sensor; no permission deep-link to OS settings; missing native share sheet. |
| **Social OS & Gamification Alignment** | 2.5 / 10 | 🔴 Misaligned | Generic "Story/Feed" switches; no Quest tagging, XP preview, or event proof verification. |

---

## Detailed Pipeline Analysis

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   CURRENT PIPELINE FLOW                                          │
│                                                                                                  │
│   [Bottom Nav / Status] ──► [CreateScreen] ──► [ShareExperienceScreen] ──► [Edge Function]       │
│      • Tab 2 inside shell      • Camera (rear only)  • 250px media preview    • Mux / Cloudinary │
│      • Status FAB push         • Text Mode (broken)  • Switches (Story/Feed)   • Publish         │
│                                • Vlog (no timer)     • Upload status button                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### Phase 1: Entry & Viewfinder Architecture (`CreateScreen`)

#### 1.1 Shell Collision & Navigation Trap
- **Finding**: `CreateScreen` is mapped as tab index 2 in `MainShell` (`app_router.dart:187`), which renders `BottomNavigationBar` persistently below the viewfinder.
- **UX Consequence**:
  - In `create_screen.dart:178`, controls are positioned at `bottom: 40`. On mobile devices with gesture navigation bars, the mode selector and shutter button are squeezed directly against the bottom navigation items.
  - Tapping near the shutter button frequently triggers tab switching to "Explore" or "Connect", abruptly terminating camera initialization and losing camera state.
  - When pushed as a modal from `MyStatusModal` (`context.push('/create')`), there is **no close ("X") or back button** anywhere in the UI. The user is trapped unless they use device hardware back gestures.
- **Design Standard**: The creation camera must be an **immersive, full-bleed modal experience** (`fullscreenDialog: true` or parent navigator route) that completely hides the global bottom navigation bar and displays a clear top-left dismissal button.

#### 1.2 Hardware Controls & Camera Primitives
- **Finding**: `_cameras![0]` is hardcoded in `_initCamera()` (`create_screen.dart:75`).
- **Defects**:
  - **No Camera Flip**: Users cannot switch to the front camera for selfies, vlogging, or reaction videos.
  - **No Torch / Flash Control**: No toggle for auto/on/off flash in low-light environments.
  - **No Tap-to-Focus or Exposure Control**: Users cannot tap a subject to lock exposure or adjust brightness via vertical slider.
  - **No Pinch-to-Zoom**: Viewfinder does not support multi-touch pinch or standard zoom steps (0.5x, 1x, 2x, 3x).
  - **Viewfinder Aspect Ratio Letterboxing**: `AspectRatio(_cameraController!.value.aspectRatio, child: CameraPreview(...))` on portrait devices produces black bars or clipping depending on sensor resolution.
- **Design Standard**: Provide top floating glass controls (Close, Flash, Flip, Settings) and a full-bleed viewfinder with tap-to-focus reticle (spring animation + haptic click).

#### 1.3 Mode Selector Ergonomics
- **Finding**: Mode switching between "Text", "Image", and "Vlog" is implemented using a horizontal `ListView.builder` with `height: 30` (`create_screen.dart:185`).
- **UX Consequence**:
  - The mode labels are small, lack touch target padding (violating 44x44pt minimum touch target rules), and require precise finger taps.
  - Swiping horizontally across the screen does nothing. In iOS Camera, Snapchat, Instagram, and TikTok, the user can swipe anywhere across the viewfinder to glide between modes with a haptic tick on every transition.
- **Design Standard**: Implement an interactive, gesture-driven mode carousel with snapping physics, centered active pill, and velocity-aware switching (`HapticFeedback.selectionClick()`).

---

### Phase 2: Capture & Recording Mechanics

#### 2.1 Video Capture UX ("Vlog" Mode)
- **Finding**: Tapping the shutter button starts `_cameraController!.startVideoRecording()` and morphs the inner circle to a rounded square (`create_screen.dart:284`).
- **Critical Defects**:
  - **No Recording Timer**: There is no timer indicating how long the user has been recording (`00:00`).
  - **No Max Duration / Progress Ring**: There is no time cap (e.g. 15s / 30s / 60s) and no visual radial stroke filling clockwise around the shutter button.
  - **No Audio Metering**: No indicator verifying that the microphone is actively capturing sound.
  - **Single Tap Only**: Users expect modern camera controls where **holding the shutter records video**, dragging upward zooms in, and releasing stops recording.
- **Design Standard**: Shutter button should feature:
  - Outer ring: 80pt diameter with animated radial SVG progress stroke.
  - Center core: Red glowing record badge with spring scale (0.92 on press, 1.0 on release).
  - Top header: Pill displaying `● REC  00:14 / 00:60` with pulsing red dot.
  - Dual-gesture: Tap for photo in Image mode; hold-to-record or tap-to-lock in Vlog mode.

#### 2.2 Text Creation Mode
- **Finding**: Text mode renders a basic centered `TextField` with `Add GIF` button (`create_screen.dart:419`).
- **Critical Defects**:
  - The "Add GIF" button shows a SnackBar: `"GIF Picker coming soon"`.
  - There is no background color/gradient picker (e.g. Aurora purple, Midnight slate, Quest blue gradients).
  - There is no font family / style picker or text alignment toggle.
  - When the user taps the forward arrow, `context.push('/share-experience', extra: text)` sends the raw text string to the next screen.

---

### Phase 3: Review & Editing Surface (`ShareExperienceScreen`)

#### 3.1 Showstopper Pipeline Bug (Text Mode Crash)
- **Code Trace**:
  ```dart
  // In create_screen.dart:268
  context.push('/share-experience', extra: text);

  // In share_experience_screen.dart:423
  image: widget.mediaPath != null && !_isVideo(widget.mediaPath!)
      ? DecorationImage(image: FileImage(File(widget.mediaPath!))) // CRASH: File("What's on your mind?")
      : null,

  // In share_experience_screen.dart:765
  await MediaServiceGateway.uploadImage(File(widget.mediaPath!), ...); // CRASH: PathNotFoundException
  ```
- **Analysis**:
  - The router passes text as `extra: String`, which `ShareExperienceScreen` assumes is a local file path.
  - The image loader attempts to open the user's sentence as a local file, throwing an exception and showing a broken container.
  - The text typed by the user in `CreateScreen` is lost; `_captionController.text` initializes completely empty!
  - Uploading crashes with `PathNotFoundException`.
- **Correction**: Introduce a strongly-typed `CreateSubmission` payload:
  ```dart
  enum MediaType { image, video, text }
  class CreatePayload {
    final MediaType type;
    final String? localFilePath;
    final String? textContent;
    final Color? textBackgroundColor;
  }
  ```

#### 3.2 Media Preview Distortion & Lack of Playback Controls
- **Finding**: In `share_experience_screen.dart:416`, the media container is locked to:
  ```dart
  Container(height: 250, width: double.infinity, ...)
  ```
- **UX Consequence**:
  - A standard 9:16 vertical smartphone video has an aspect ratio of ~0.56. Inside a 250px height container, the video renders at only **140px wide**, surrounded by massive empty gray letterboxing.
  - The video automatically loops in the background with **zero playback controls**: no tap to pause/play, no volume/mute button, no timeline scrubber, and no full-screen expansion.
  - There is no "Retake" or "Discard" button if the user is dissatisfied with the capture.
- **Design Standard**: The preview card should be presented in a dedicated 9:16 portrait viewport (or full-bleed screen with overlay controls), featuring:
  - Play/Pause toggle with center waterdrop icon animation.
  - Mute/Unmute audio button.
  - Top "Retake" action leading back to camera.
  - Bottom expandable thumbnail drawer for trimming video start/end points.

---

### Phase 4: Publishing, Metadata & Gamification Architecture

#### 4.1 Social OS vs Generic Social Clone
- **Finding**: Publishing destinations in `ShareExperienceScreen` are 3 generic switches: "My Story", "Main Feed", and "Communities".
- **Product Philosophy Conflict (`DESIGN.md` & `docs/architecture/13_brand_positioning_qwst_run.md`)**:
  - Quest's mission is: *"A Social Operating System for turning intent into participation."*
  - The current screen looks like a generic Instagram clone from 2018. It has zero awareness of:
    1. **Active Quests**: Creators cannot link this experience as proof of completing a daily or community quest (e.g., "+50 XP: Morning 5km Run").
    2. **Event Verification**: Attendees cannot tag their post to an active event they are attending to verify participation.
    3. **Place / Venue Tagging**: No location tagging for proximity radar nodes or campus hubs.
    4. **Privacy / Audience Controls**: No granular visibility selector (Public vs Community Members vs Private).

#### 4.2 Form Ergonomics & Upload Status
- **Finding**: The "Post To" switches occupy 3 separate rows taking up half the screen.
- **Upload State**:
  - When uploading, the primary button disables and changes its text label to `_uploadStatus` ("Uploading to Mux...", "Compressing video...").
  - There is no visual percentage progress bar (0% -> 100%).
  - If the user leaves the screen, upload progress is only displayed via system notification.
- **Design Standard**:
  - Replace vertical switches with a compact segmented destination card selector.
  - Add an inline animated progress bar with smooth indeterminate shimmer.
  - Include an interactive XP preview banner: `🎯 Sharing this will earn you +25 XP`.

---

### Phase 5: Consumption, Status & Downstream Sharing Loops

#### 5.1 Hollow Feed "Share" Action
- **Finding**: In `feed_screen.dart:136`, tapping `Icons.share_outlined`:
  ```dart
  await ref.read(feedRepositoryProvider).shareVideo(video.id);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Shared experience!')),
  );
  ```
- **UX Consequence**:
  - The user expects a native share dialog to send the video to external apps (WhatsApp, Telegram, X, iMessage) or forward it to an in-app friend/community.
  - Instead, nothing happens except an internal database counter increments and a SnackBar pops up. This feels artificial and frustrating.
- **Design Standard**:
  - Tapping Share should open a custom Quest Share Sheet:
    1. **Direct Send (Top Row)**: Recent chats / mutual connections with one-tap send button.
    2. **Community Send (Middle Row)**: Quick share into joined communities.
    3. **System Actions (Bottom Row)**: Copy Link, Native Share (`Share.share(...)`), Save Video to Device, Repost.

#### 5.2 Story Viewer Modal V2 (`story_viewer_modal_v2.dart`)
- **Finding**: The story viewer displays stories grouped by user, but is purely read-only:
  - No reply text field (`"Send a message..."`).
  - No quick reaction emojis (🔥, ❤️, 👏, 😂).
  - No share button.
  - No viewer analytics or delete button for own stories (these are only accessible through `MyStatusModal`).
- **Design Standard**: Provide a floating glass bottom input bar with quick emoji reaction pills that directly send a DM to the author via `chatProvider`.

---

## Comprehensive Heuristic Evaluation

| Heuristic (Nielsen & Apple HIG) | Finding in Quest Create/Share | Severity | Remedy |
|---|---|---|---|
| **1. Visibility of System Status** | Video recording has no timer, duration meter, or audio indicator; upload has no percentage bar. | 🔴 High | Add pulsing `REC 00:15 / 01:00` header, radial shutter progress, and 0-100% upload bar. |
| **2. Match with Real World** | Camera acts like a static widget rather than a physical camera lens; no haptic recoil on shutter. | 🟠 Med | Add Apple-grade fluid haptics (`heavyImpact` on shutter, `selectionClick` on mode switch) and spring scale. |
| **3. User Control & Freedom** | No back/close button in `CreateScreen`; no retake/discard in preview; text mode crashes. | 🔴 High | Add top-left "X" button on camera; full retake flow in preview; typed payload model. |
| **4. Consistency & Standards** | Share button on feed does not share; camera preview is letterboxed to 250px instead of 9:16. | 🔴 High | Integrate `share_plus` native OS sheet; scale preview to responsive 9:16 aspect ratio. |
| **5. Error Prevention & Recovery** | Hardcoded rear camera with no flip toggle; camera error screen is trapped with no alternate exit. | 🔴 High | Dynamic camera switcher (`lensDirection.front` vs `back`); clear dismiss button on error state. |
| **6. Recognition over Recall** | Communities search requires navigating a deep modal sheet with no recent destinations. | 🟡 Low | Show quick-tag chips for top 3 joined communities. |
| **7. Flexibility & Efficiency** | No hold-to-record shutter gesture; mode list requires small tap instead of horizontal swipe. | 🟠 Med | Support tap-for-photo, hold-for-video; full-screen horizontal swipe gesture. |
| **8. Aesthetic & Minimalist Design** | Switches take up excessive vertical space; hardcoded text styles; inconsistent spacing. | 🟠 Med | Compact destination segmented cards; adhere to `AppColors` tokens. |

---

## Actionable Design Blueprint & Implementation Plan

### Architecture Redesign

```
lib/features/interaction/create/
├── data/
│   ├── models/
│   │   ├── create_submission_payload.dart     # Strongly-typed union (Image, Video, Text)
│   │   └── camera_config_state.dart          # FlashMode, CameraLens, ZoomLevel, Timer
│   └── create_controller.dart                # StateNotifier for recording duration & state
└── presentation/
    ├── create_camera_screen.dart              # Edge-to-edge full-bleed camera viewfinder
    ├── widgets/
    │   ├── camera_top_controls.dart           # Close, Flash, Flip, Settings glass bar
    │   ├── camera_shutter_button.dart         # Dual-gesture (tap/hold) with radial progress SVG
    │   ├── camera_mode_carousel.dart          # Velocity-aware swipeable mode ticker
    │   ├── recording_indicator_header.dart    # Pulsing REC badge + 00:00 counter
    │   └── text_create_canvas.dart            # Gradient/font picker for rich text statuses
    ├── share_experience_screen.dart           # Redesigned review & publishing screen
    └── widgets/
        ├── media_review_card.dart             # Responsive 9:16 interactive preview + play/mute
        ├── destination_selector_group.dart    # Segmented Story / Feed / Community pills
        ├── quest_link_picker.dart             # "Link to Active Quest" for XP verification
        └── upload_progress_sheet.dart         # Floating non-blocking background upload bar
```

### 3-Phase Execution Roadmap

#### Phase 1: High-Severity Bug Fixes & Camera Fundamentals (Immediate)
1. **Fix Text Mode Pipeline**:
   - Create `CreateSubmissionPayload` resolving the `mediaPath` conflict in `ShareExperienceScreen`.
   - Ensure text statuses correctly populate captions and text-card backgrounds without touching the image file loader.
2. **Add Camera Flip & Torch Controls**:
   - Query all `availableCameras()` and enable switching between front and rear lenses.
   - Add flash/torch toggle (`FlashMode.auto`, `FlashMode.always`, `FlashMode.off`).
3. **Add Navigation Safety**:
   - Add top-left floating close ("X") button in `CreateScreen` to allow clean dismissal back to previous routes.
   - Hide `BottomNavigationBar` while on the camera surface or launch `CreateScreen` with `fullscreenDialog: true`.

#### Phase 2: Ergonomic Polish, Recording Feedback & Preview Modernization
1. **Recording Feedback Engine**:
   - Add active recording timer (`Timer.periodic`) and visual elapsed timestamp on screen.
   - Implement radial SVG progress border around the shutter button filling up to 60 seconds.
   - Support hold-to-record gesture.
2. **Review Surface Overhaul**:
   - Replace 250px fixed container in `ShareExperienceScreen` with a responsive 9:16 card.
   - Add play/pause toggle, mute switch, and "Retake" button.
3. **Native Sharing in Feed**:
   - Replace hollow share counter with `share_plus` native OS sheet and in-app chat forwarding options.

#### Phase 3: Quest Social OS Integration & Gamification Hooks
1. **Quest & Event Proof Linking**:
   - Allow creators to tag an active Quest (e.g. "Run 5km", "Daily Gratitude", "Attend Tech Meetup").
   - Display dynamic XP reward badge (`+50 XP upon verification`).
2. **Story Interactions**:
   - Add reply input and quick emoji reactions to `StoryViewerModalV2`.
   - Wire emoji reactions directly to `chatProvider` as direct messages.
