---
name: document-changes
description: "Documents every codebase change (minor, major, etc.) into the docs/ folder in accordance with the Quest Living Documentation Requirement."
---

# Document Changes

## Overview
This skill instructs the agent to systematically document every change it makes to the codebase. It ensures a high standard of maintainability by keeping a persistent, human-readable record of modifications in the modular architecture documentation.

## When to Use
- Invoke this skill at the end of any coding session.
- Use it whenever you have added, modified, refactored, or deleted any architectural component, file, model, Riverpod provider, route, screen, theme token, or behavior.

## Instructions
1. **Identify the Relevant Modular Document**: Find the appropriate file(s) in `docs/architecture/` that corresponds to the feature, component, or logic you just changed. Do NOT just append to a generic changelog.
2. **Update the Content**:
   - Ensure the directory tree, provider catalog, route catalog, and feature notes reflect your new changes accurately.
   - Describe both major architectural shifts and minor bug fixes in the relevant sections.
   - Include any reasoning or context that a future developer or agent might need to know.
3. **Update the Timestamp**: Append or update the `_Last Modified: YYYY-MM-DD_` timestamp at the top of any documentation file you modify.
4. **Master Documentation Index**: Check `CODEBASE_DOCUMENTATION.md` in the root. If you created a new modular doc or fundamentally changed the structure, ensure this index is still accurate.
5. **No Documentation Drift**: Ensure no documentation drift occurs. The docs must perfectly match the code you just wrote.
6. **Persist the files** by writing the updates to the file system.
