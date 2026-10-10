# ADR 0002: MVP Scope and Isolated Shim Architecture

## Status
Proposed (Under Review by Claude)

## Date
2026-10-10

## Context
Modifying Chromium's native C++ Views directly (e.g. within `//chrome/browser/ui/views/`) creates severe maintainability risks:
- Frequent upstream merge conflicts during bi-weekly security rebases.
- Long incremental compilation cycles during UI experimentation.
- High barrier to rapid visual iteration for a bootstrapped founder.

Furthermore, attempting to support everyday users, full multi-profile per-tab partition isolation, cloud sync, and AI features within a 60-day window (December 9, 2026 revenue target) creates excessive scope risk.

## Decisions

1. **Target Audience Pruning for MVP:**
   - Active development focus is restricted to **solo developers and indie hackers**.
   - Everyday consumer features, AI services, and cloud sync are explicitly out of scope for v1.0.

2. **WebUI over Native Views Patching:**
   - Obscure's primary custom interfaces (New Tab / Launchpad, Settings, Drawer) will be implemented as Chromium WebUI pages (`chrome://obscure-newtab`, `chrome://obscure-settings`).
   - Native Views code will be touched only where strictly required for window framing or top-level triggers.

3. **Isolated Native Shim (`//chrome/browser/obscure/`):**
   - Custom C++ backend logic (workspace state handling, file persistence) will be placed in a dedicated, isolated directory: `//chrome/browser/obscure/`.
   - Core Chromium subsystems will be kept intact and unmodified wherever possible.

4. **Project Spaces State Persistence (v1):**
   - For v1.0, Project Spaces will implement **tab & session stashing** (saving URLs, tab hierarchy, titles, active tab index).
   - State will be saved to a local versioned JSON file using `base::ImportantFileWriter` (atomic write via temp file + rename) to prevent corruption upon abrupt process termination.
   - Hard storage partition isolation (separate cookie jars per space) is deferred to v1.1.

## Consequences
- Fast UI iteration cycle using standard web technologies.
- Upstream Chromium updates remain clean to merge because core files are rarely modified.
- Eliminates dependency on external servers or cloud accounts.
- Trade-off: Tabs within different spaces in v1.0 share general profile cookies unless opened in guest/incognito contexts. This trade-off must be explicitly communicated in the UI.
