## 2024-08-07 - Add ARIA equivalent label to icon-only buttons
**Learning:** In Flutter apps, `IconButton`s missing `tooltip` attributes can pose an accessibility issue since screen readers rely on tooltips to identify the buttons when no text label is present. Without a tooltip or semantic label, an icon-only button is read as unlabelled, leading to confusion.
**Action:** Always verify icon-only buttons (like those inside an `AppBar`'s leading or actions sections) have an associated `tooltip` or `semanticLabel` property that concisely explains their action.
