
## 2024-08-08 - Tactile Responsiveness & Component Consistency
**Learning:** Empty states with tiny text or generic messages feel unpolished and can leave users confused. Additionally, relying on default platform buttons (like `ElevatedButton`) breaks immersion when a custom design system exists (like `QuestButton`). Furthermore, providing physical haptic feedback immediately on press (`onTapDown`) for primary actions gives a significantly higher quality "feel" to the app than visual-only feedback.
**Action:** Always use visual icons and clear spacing in empty states. Enforce design system components instead of default generic Flutter components. Bind `HapticFeedback.lightImpact()` to core interactive components' down-press state to make the app feel alive and responsive.
