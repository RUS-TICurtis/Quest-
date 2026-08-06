## 2024-05-23 - Accessibility wrapper for Gesture Detectors
**Learning:** In Flutter, custom buttons implemented with `GestureDetector` require manual `Semantics` wrapping, as they don't inherit the accessibility properties of standard material buttons like `ElevatedButton`. Without this wrapper, screen readers are unable to correctly identify them as buttons, read their labels, or announce their states properly.
**Action:** Always wrap custom button implementations using `GestureDetector` in a `Semantics` widget, setting `button: true`, `label: ...`, and `enabled: ...`.
