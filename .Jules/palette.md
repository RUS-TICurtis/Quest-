## 2024-05-14 - Screen Reader Support for Icon Buttons
**Learning:** In Flutter, `IconButton`s without text labels are completely inaccessible to screen readers (and desktop users don't get hover hints). The `tooltip` property acts exactly like an `aria-label` in web development, providing the necessary semantic context.
**Action:** Always add a descriptive `tooltip` property to every `IconButton` that doesn't have an accompanying text label.
