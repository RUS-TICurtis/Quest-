# Project-Scoped Agent Rules & Guidelines

## 1. Living Documentation Requirement (Mandatory)
- **Master Documentation Index**: [`CODEBASE_DOCUMENTATION.md`](../CODEBASE_DOCUMENTATION.md)
- **Modular Docs Directory**: `docs/architecture/`
- **Rule**: Whenever any architectural component, file, model, Riverpod provider, route, screen, theme token, or behavior is added, modified, refactored, or deleted in this codebase:
  1. The agent/contributor **MUST** update the relevant modular file(s) in `docs/architecture/` in the exact same turn/commit.
  2. The agent/contributor **MUST** append or update the `_Last Modified: YYYY-MM-DD_` timestamp at the top of any modified documentation file.
  3. Ensure the directory tree, provider catalog, route catalog, and feature notes reflect the new changes accurately.
  4. Ensure no documentation drift occurs.

## 2. Code Quality & Analysis
- Always verify changes with `flutter analyze`.
- Zero warnings and zero errors are permitted.

## 3. Design & Micro-Interaction Integrity
- Adhere strictly to the design system in `lib/core/theme/app_colors.dart` and `DESIGN.md`.
- Ensure tactile haptic feedback (`HapticFeedback`) and fluid spring animations accompany interactive actions.
