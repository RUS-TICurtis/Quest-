# Quest Codebase Architecture & Technical Documentation
> **Living Technical Specification & Architectural Reference**  
> *Version: 1.0.0 | Status: Production Prototype | Ecosystem: Flutter Multiplatform (Android, iOS, Web, Windows, macOS, Linux)*
> *Last Modified: 2026-10-06*

---

## 📌 Living Documentation Rule & Maintenance Protocol

> [!IMPORTANT]
> **MANDATORY MAINTENANCE PROTOCOL FOR ALL AGENTS & DEVELOPERS:**
> Whenever any file, data model, Riverpod provider, route, screen, theme token, or architectural pattern is created, modified, refactored, or deprecated in this repository:
> 1. **Update the relevant files in `docs/architecture/` synchronously in the exact same turn/commit.**
> 2. **Always append/update the "Last Modified: YYYY-MM-DD" timestamp at the top of any modified documentation file.**
> 3. Update the corresponding directory tree, file description, model signature, or route mapping.
> 4. Verify that zero lint warnings or architectural discrepancies remain (`flutter analyze`).
> 
> *Never allow documentation to drift from active implementation.*

---

## Documentation Index

The codebase documentation is being actively transitioned to the new Platform Architecture model.

### Primary Platform Documentation
00. [Platform Domain Model & Architectural Vision](docs/architecture/00_platform_domain_model.md)
01. [Platform Constitution (QPC)](docs/architecture/01_executive_summary.md) *(Pending full rewrite)*
02. [Product Overview](docs/architecture/01_executive_summary.md) *(Pending full rewrite)*
03. [Engineering Overview](docs/architecture/03_engineering_overview.md)
04. [Architecture](docs/architecture/06_state_management.md) *(Refactoring State & Navigation docs)*
05. [Feature Specifications](docs/architecture/07_feature_modules.md) *(Refactoring to Platform Domains)*
06. [API Documentation](#) *(Planned)*
07. [Database](#) *(Planned)*
08. [Design System](docs/architecture/04_design_system.md)
09. [AI Systems](#) *(Planned)*
10. [Deployment](docs/architecture/08_platform_notes.md) *(Refactoring from Platform Notes)*
12. [Quest Resource Engine](docs/architecture/12_resource_engine.md) — FastApi backend architecture.
13. [Brand Strategy & Naming Architecture (QWST.RUN)](docs/architecture/13_brand_positioning_qwst_run.md) — Multi-tier brand architecture, options, alternatives, action language taxonomy, and onboarding progression.

### Essential References
* [Roadmap & Execution Guide (Phases 3–7)](docs/JULES_HANDOFF_PHASES_3_TO_7.md) — Comprehensive implementation roadmap, live schema truth, and action items for Jules and core engineers.
* [Codebase Audit — 2026-10-05](docs/AUDIT_2026-10-05.md) — Truthful audit of current features, database tables, and security findings.
* [Canonical Vocabulary Registry](docs/architecture/canonical_vocabulary.md) — The single source of truth for platform terminology.
* [Agent Onboarding & System Audit Brief](CODEBASE_STATE_PROMPT.md) — Self-contained prompt for AI agents and onboarding engineers detailing full codebase state.

### Legacy / Supplemental Documents
*These documents are being actively migrated into the new `00-10` structure above.*
- [Directory & File Inventory](docs/architecture/03_directory_inventory.md)
- [Navigation & Routing](docs/architecture/05_navigation_routing.md)
- [State Management](docs/architecture/06_state_management.md)
- [QA & Verification](docs/architecture/09_qa_verification.md)
- [External Services](docs/architecture/10_external_services.md)
- [Database Schema Reference](docs/architecture/11_database_schema_reference.md) — Column naming conventions, caching decisions, edge function notes, dual-column architecture, Hive TypeAdapter patterns.
