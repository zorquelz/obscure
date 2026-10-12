# Test Plan 0002: Project Spaces Resilience, Security & Recovery Specification
**Zorquelz Technologies | QA & Testing Specification**

## Status & Tracking
- **Document Version:** 2.0 (Comprehensive Pre-Implementation Specification)
- **Status:** **PROPOSED** (Awaiting Claude QA Audit & CEO Stage 2 Gate Clearance)
- **Two-Stage Gate:** Gate 2 Prerequisite (Implementation BLOCKED until approved)
- **Target Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)
- **Review & QA Lead:** Claude
- **Chief Architect:** ChatGPT
- **Engineering Lead:** Antigravity (Implementation)

---

## 1. Scope & System Under Test (SUT)

This specification defines the exhaustive test criteria for `ObscureWorkspaceService`, `ObscureNewTabPageUI`, and the associated Mojo IPC bridge inside `//chrome/browser/obscure/`.

It validates that Obscure withstands:
1. Malicious input injections and privileged scheme escapes.
2. Malformed or adversarial Mojo IPC messages from renderer processes.
3. Massive payload denial-of-service attempts via strict 10 MB file caps.
4. Abrupt process termination (`kill -9`) and filesystem corruption (`ENOSPC`, permission lockouts).
5. Schema version changes and future-version downgrades.
6. Off-The-Record (Incognito) and Guest session privacy invariants.
7. New Tab Page (NTP) routing across diverse search providers, window modes, and startup configurations.

---

## 2. Test Cases Matrix

### Category 1: Security & URL Scheme Allowlisting

| Test ID | Test Case Name | Injection Vector / Input | Expected Browser Process Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-SEC-01** | JavaScript Scheme Injection | `{"url": "javascript:alert(document.cookie)"}` | Deserializer rejects non-allowlisted scheme | Replaced with `about:blank`; zero script execution |
| **TP-SEC-02** | Local Filesystem Probe | `{"url": "file:///etc/passwd"}` or `{"url": "file:///C:/Windows/win.ini"}` | Deserializer rejects `file://` scheme | Replaced with `about:blank`; local filesystem access blocked |
| **TP-SEC-03** | Privileged Chrome Scheme Probe | `{"url": "chrome://settings"}` or `{"url": "chrome://flags"}` | Deserializer blocks restoration of internal WebUI schemes | Replaced with `about:blank`; privileged pages cannot be restored |
| **TP-SEC-04** | Data URI Payload | `{"url": "data:text/html,<script>alert(1)</script>"}` | Deserializer rejects `data:` scheme | Replaced with `about:blank`; zero inline payload execution |
| **TP-SEC-05** | Blob & Extension URI Abuse | `{"url": "blob:http://..."}` or `{"url": "chrome-extension://..."}` | Deserializer rejects `blob:` and extension schemes | Replaced with `about:blank` |
| **TP-SEC-06** | View-Source Protocol Abuse | `{"url": "view-source:https://google.com"}` | Deserializer strips/rejects `view-source:` | Replaced with `about:blank` or sanitized to raw URL |
| **TP-SEC-07** | DOM Injection / XSS in WebUI | Space name: `<img src=x onerror=alert(1)>`<br>Tab title: `<script>fetch('/stolen')</script>` | WebUI frontend binds text via `textContent` exclusively | Rendered strictly as escaped literal string; zero DOM execution |
| **TP-SEC-08** | URL Allowlist Strict Compliance | Tab URL: `http://localhost:3000`, `https://github.com`, `about:blank`, `chrome://newtab/` | Deserializer allows recognized HTTP, HTTPS, and safe NTP | Allowed through untouched; navigations proceed normally |

---

### Category 2: Malformed Mojo IPC & Renderer Message Validation

| Test ID | Test Case Name | Injected IPC Payload | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-IPC-01** | Non-UTF8 & Multi-Byte Corruption | Space/Tab name containing truncated surrogate pairs or invalid UTF-8 sequences | `base::IsStringUTF8()` check fails in C++ Mojo receiver | Message safely rejected; error returned to caller; zero crash |
| **TP-IPC-02** | Oversized String Payload | Space name length > 10,000 characters | String length validation rejects payload exceeding `kMaxSpaceNameLength` (128 chars) | Message rejected with `mojo::ReportBadMessage()`; process stable |
| **TP-IPC-03** | Out-of-Bounds Integer Indices | Tab index `-1` or `999999` sent in `SwitchToTab()` | Bounds check against `space->tabs().size()` | Operation rejected; vector out-of-range exception prevented |
| **TP-IPC-04** | Missing or Nil Space UUID | Empty string or malformed UUID string passed in `DeleteSpace()` | `base::Uuid::ParseCaseInsensitive()` validation | Call rejected cleanly without touching in-memory model |
| **TP-IPC-05** | Deeply Nested JSON Input | JSON hierarchy nested > 100 levels deep | `base::JSONReader::ReadWithOptions` with depth limit | Parser returns `JSON_PARSE_ERROR`; zero stack overflow |
| **TP-IPC-06** | Prototype Pollution / Extra Keys | Injected JSON containing `{"__proto__": ...}` or unmodeled keys | Strict model parser iterates only recognized schema keys | Extra keys ignored; model initialized cleanly without side-effects |

---

### Category 3: File-Size Cap & Memory Exhaustion Defenses

| Test ID | Test Case Name | Simulated Payload Size | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-CAP-01** | 10 MB Max File-Size Enforcement | `obscure_spaces.json` padded with whitespace/dummy spaces to 11.5 MB | `base::ReadFileToStringWithMaxSize(..., kMaxSpacesFileSize)` returns error | File rejected before parsing; memory exhaustion prevented; fallback to `.bak` |
| **TP-CAP-02** | Massive Space Tab Count | Space containing 1,000 tabs (~500 KB JSON) | System parses valid file within memory limits | State loaded successfully; warning displayed if tab count > 500 |
| **TP-CAP-03** | Rapid Tab Addition Burst | 100 tab additions within 1,000 ms | 500 ms debounce timer coalesces writes | Exactly 1 or 2 atomic file writes dispatched to disk; zero disk thrashing |

---

### Category 4: File Corruption & Backup Recovery

| Test ID | Test Case Name | Simulated Failure Condition | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-REC-01** | Truncated JSON on Startup | `obscure_spaces.json` truncated mid-string (e.g. `{"version": 1, "spaces": [`) | JSON parser fails; corruption detected; service attempts `.bak` restoration | Spaces successfully restored from `.bak`; primary file regenerated |
| **TP-REC-02** | Double Corruption (Primary + `.bak`) | Both `obscure_spaces.json` and `.bak` contain invalid bytes | Service preserves primary as `.corrupt`, logs error, initializes clean default space | Clean browser boot; zero crash; non-fatal user notification displayed |
| **TP-REC-03** | Future Schema Version | `obscure_spaces.json` contains `{"version": 99, ...}` | Service detects `version > kCurrentSchemaVersion`; **refuses destructive write** | User's future file untouched; ephemeral fallback session used; zero data loss |
| **TP-REC-04** | Missing Primary File | `obscure_spaces.json` deleted while `.bak` exists | Service loads `.bak` | Spaces restored; primary file regenerated |
| **TP-REC-05** | Backward Schema Migration | `obscure_spaces.json` contains schema v1 format without newer fields | Migration handler applies defaults for missing fields | Spaces cleanly migrated to v2 in-memory and saved |
| **TP-REC-06** | Zero-Byte Primary File | Empty 0-byte `obscure_spaces.json` created by filesystem glitch | Parser treats as corrupt; loads `.bak` | Valid backup restored cleanly |

---

### Category 5: OS & Filesystem Failure Modes

| Test ID | Test Case Name | Simulated Environment Condition | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-FS-01** | Disk Full Simulation (`ENOSPC`) | Filesystem mounted with 0 free bytes during write | `ImportantFileWriter` write to temporary file fails | Original file and `.bak` intact; write error surfaced cleanly to UI |
| **TP-FS-02** | Read-Only File Permissions | `chmod 0400 obscure_spaces.json` | Write fails gracefully; error logged | In-memory state maintained; warning logged; zero crash |
| **TP-FS-03** | Rapid Process Termination (`kill -9`) | 100 iterations of space creation followed by `kill -9` within 100ms–2000ms | Atomic rename guarantees no half-written files exist | File on disk is always 100% syntactically valid (pre- or post-state) |
| **TP-FS-04** | Profile Lock Contention | Secondary Chromium instance launched on same profile | Chromium profile lock blocks secondary process | Primary process maintains ownership; zero state collision |
| **TP-FS-05** | POSIX Permission Validation | Fresh write of `obscure_spaces.json` on Linux/WSL2 | `base::SetPosixFilePermissions` applied | Permissions verify to `0600` (`-rw-------`); unauthorized users cannot read |

---

### Category 6: Incognito, Guest, and Profile Isolation

| Test ID | Test Case Name | Profile Context | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-OTR-01** | Incognito Profile Launch | User opens Incognito Window (`Ctrl+Shift+N`) | `ObscureWorkspaceServiceFactory::GetBrowserContextToUse()` returns `nullptr` | No `obscure_spaces.json` created; zero disk writes; spaces UI hidden |
| **TP-OTR-02** | Guest Session Launch | User opens Guest Window | Service factory returns `nullptr` | No persistence; guest session leaves zero filesystem traces |
| **TP-OTR-03** | Multi-Profile Separation | User has Profile 1 (Default) and Profile 2 (Work) | Each profile maintains independent `obscure_spaces.json` in its own profile directory | Spaces in Profile 1 never visible or modified by Profile 2 |
| **TP-OTR-04** | Incognito Window Close | User closes Incognito window | Any ephemeral tabs discarded by Chromium core | Zero data remains in memory or disk |

---

### Category 7: New Tab Page (NTP) Behavior Matrix

| Test ID | Test Case Name | User Action / Trigger | Default Search Engine | Expected Target Controller | Pass Criteria |
|---|---|---|---|---|---|
| **TP-NTP-01** | Tab Strip "+" Click | Normal Profile | Google (Default) | `ObscureNewTabPageUI` | Obscure Launchpad renders cleanly |
| **TP-NTP-02** | Keyboard Shortcut `Ctrl+T` | Normal Profile | Google (Default) | `ObscureNewTabPageUI` | Obscure Launchpad renders cleanly |
| **TP-NTP-03** | New Window `Ctrl+N` | Normal Profile | Google (Default) | `ObscureNewTabPageUI` | Obscure Launchpad renders cleanly |
| **TP-NTP-04** | Incognito `Ctrl+Shift+N` | Incognito Profile | Any | `IncognitoNewTabPageUI` | Standard dark Incognito splash; **NO** Obscure UI |
| **TP-NTP-05** | Guest Window New Tab | Guest Profile | Any | `GuestNewTabPageUI` | Standard Guest splash; **NO** Obscure UI |
| **TP-NTP-06** | Alternative Search Provider | Normal Profile | DuckDuckGo / Bing / Brave | `ObscureNewTabPageUI` | Obscure Launchpad renders; not replaced by third-party search NTP |
| **TP-NTP-07** | Session Restore on Startup | Normal Profile ("Continue where you left off") | Any | Core Session Restore | Inactive space tabs stashed; active space tabs restored |
| **TP-NTP-08** | Omnibox URL Navigation | Normal Profile navigates to `chrome://newtab` | Any | Rewrites to `chrome://new-tab-page/` | Obscure Launchpad renders |

---

## 3. Automated Test Execution Harness

The test cases specified above will be executed using two automated harnesses:

1. **C++ Unit Tests (`//chrome/browser/obscure/obscure_workspace_service_unittest.cc`):**
   - Linked into `unit_tests` target via hook HK-05 (`chrome/test/BUILD.gn`).
   - Validates memory management, JSON parsing, 10 MB caps, corruption recovery, and scheme filtering using Chromium's `base::ScopedTempDir` and `content::BrowserTaskEnvironment`.
2. **Integration Test Runner (`scripts/test_spaces_resilience.py`):**
   - Headless and GUI driver launching `./out/Stable155/chrome` with temporary `--user-data-dir`.
   - Simulates `kill -9` loops, corrupted file injection, and permission lockdowns.
