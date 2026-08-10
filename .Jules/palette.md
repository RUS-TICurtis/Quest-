## 2026-08-10 - Tactile Responsiveness for Core Components
**Learning:** Adding subtle haptic feedback to core custom design components (like buttons) on press creates a more tactile, responsive UI feel, elevating the UX and giving immediate confirmation of intent without waiting for the next state to render.
**Action:** When creating or iterating on custom components that users frequently interact with (like QuestButton), integrate HapticFeedback.lightImpact() on the down-press (onTapDown) state.
