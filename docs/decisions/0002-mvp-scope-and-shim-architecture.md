# ADR 0002: MVP Scope, WebUI Architecture, and Persistence Specification

## Status
Accepted (Revised based on Chromium 157 source audit and QA review)

## Date
2026-10-11

## Context
Modifying Chromium's native C++ Views directly creates severe maintenance risks, slow compilation cycles, and upstream merge conflicts. To deliver a functional, resilient product by December 9, 2026 on a ₹0 budget, Obscure must strictly isolate custom logic, prune extraneous scope, and establish bulletproof local persistence.

---

## Decisions

### 1. Target Audience & Scope Pruning
- **Sole Target Audience for MVP:** Independent developers and indie hackers managing local servers (`localhost`), APIs, and web dashboards.
- **Explicit Exclusions:** Everyday general consumers, AI services, cloud accounts, proprietary sync infrastructure, and deep penetration testing suites are strictly excluded from v1.0.

### 2. Cookie & Session Storage Policy (No False Claims)
- **Shared Session Context in v1.0:** In v1.0, Project Spaces implement **visual and tab stashing**, not hard multi-profile `StoragePartition` isolation. Tabs across different spaces share the active profile's cookie jar and local storage.
- **Marketing & UI Ban:** No documentation, marketing, or UI element may claim "container isolation" or "cookie isolation" in v1.0.
- **Mandatory UI Disclosure:** When a user creates or opens a Space, the UI must display a clear, plain-language transparency notice:
  > *"Tabs in this space share your active session cookies with other spaces. Full storage container isolation is coming in v1.1."*

### 3. WebUI Integration Layer
- **Architecture:** Obscure's New Tab Page / Launchpad will be implemented as a modern WebUI page served via Chromium's native WebUI data source.
- **Registration Mechanism:** Registered via `content::WebUIConfigMap::GetInstance().AddWebUIConfig()` inside `chrome/browser/ui/webui/chrome_web_ui_configs.cc` (substituting `NewTabPageUIConfig` on `chrome::kChromeUINewTabPageHost`).
- **External Touchpoints:** Strictly governed by `HOOKS.md`.

### 4. Persistence Architecture (`ObscureWorkspaceService`)
- **Storage Location:** Workspace state must be stored inside the user's active Chromium profile directory:
  `profile->GetPath().Append(FILE_PATH_LITERAL("obscure_spaces.json"))`.
  Hardcoded paths outside the profile are strictly banned.
- **File Permissions:** Enforce POSIX `0600` (`base::FILE_PERMISSION_READ_BY_USER | base::FILE_PERMISSION_WRITE_BY_USER`) via `base::SetPosixFilePermissions` on Linux.
- **Debounce & Flush Rules:**
  - A provisional debounce interval of `base::Milliseconds(500)` will be configured for non-critical tab focus and scroll events.
  - Critical persistence events must bypass the debounce timer and trigger immediate synchronous atomic flush (`WriteNow()` / `DoScheduledWrite()`):
    1. Space creation
    2. Space deletion
    3. Space rename
    4. Tab close
    5. Window close
    6. Browser shutdown sequence (`Profile` destruction)
- **Backup & Recovery Rotation:**
  - An atomic backup file (`obscure_spaces.json.bak`) must be maintained.
  - The backup is rotated only **after** the replacement file has successfully written and validated on disk.
  - On startup, if the primary JSON file is missing, empty, or fails schema validation, the service must automatically restore from `.bak`.

### 5. Security & Input Validation Invariants
- **URL Scheme Whitelist:** On workspace restoration, URLs are strictly whitelisted to `http://`, `https://`, and `about:blank`.
  - All other schemes (`javascript:`, `file:`, `chrome:`, `data:`, `blob:`) must be rejected or sanitized.
- **Mojo IPC Validation:** Every IPC message from WebUI renderers must be explicitly validated in the C++ browser process before execution (validating Space IDs, URL syntax, and string lengths).
- **DOM Injection Prevention:** WebUI frontend code must use `textContent` exclusively for user-controlled strings (tab titles, URLs, Space names). `innerHTML` is strictly forbidden.
- **Sandbox Requirement:** All releases, packages, and tests must run with Chromium's native sandbox active. Launching or distributing with `--no-sandbox` is prohibited.

### 6. Upstream Maintenance & Rebase Rehearsal
- To ensure Obscure does not get stranded on a pre-stable or vulnerable Chromium revision, a mandatory **rebase rehearsal** onto a newer upstream tag must be executed and documented before November 14, 2026, recording all merge conflicts and resolutions.

---

## Consequences
- Guarantees predictable, fast iteration by leveraging WebUI and HTML/CSS/TS.
- Protects user data from corruption during crashes via atomic writes, debounced commits, and `.bak` rotation.
- Prevents security regressions by enforcing Chromium's sandboxing, scheme whitelisting, and strict IPC validation.
- Clear, honest communication with users regarding cookie sharing until v1.1.
