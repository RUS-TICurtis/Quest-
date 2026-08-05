## 2023-10-25 - Added Disabled State & Semantics to Custom Button
**Learning:** Custom UI components like `QuestButton` using `GestureDetector` do not automatically inherit standard button accessibility roles or visually indicate disabled states (opacity, shadows) when `onPressed` is null, which is common in Flutter.
**Action:** When creating custom interactive elements, always wrap them in `Semantics(button: true, enabled: !isDisabled, ...)` and implement a clear visual change (e.g., `Opacity(opacity: 0.5)`) for disabled states.
