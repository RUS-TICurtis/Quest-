## 2026-08-03 - Added missing tooltips to IconButtons
**Learning:** Found that numerous `IconButton` widgets across the app lacked the `tooltip` property, reducing accessibility for screen reader users and missing visual hints on long-press.
**Action:** Always ensure `tooltip` strings are provided for icon-only interactive widgets (like `IconButton`) in Flutter to comply with accessibility standards.
