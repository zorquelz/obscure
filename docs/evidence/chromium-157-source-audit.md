# Chromium 157 Source Tree Evidence & Audit Report
**Zorquelz Technologies | Engineering & Implementation Lead (Antigravity)**  
**Date:** October 11, 2026  
**Target Repository:** `~/Obscure/chromium/src` (WSL2 `Obscure-Ubuntu`)

---

## 1. Revision & Baseline Verification

Every entry in this report was verified against the active Chromium source checkout via terminal execution on October 11, 2026.

### Git Baseline Commands & Output
```bash
$ git rev-parse HEAD
e3a47f1afe3c87307d7b98638a576a5993fb95d7

$ git describe --tags --always
pre_blink_merge-1544735-ge3a47f1afe3c8

$ git branch -a
* (HEAD detached at origin/main)
  main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```

### Version String (`chrome/VERSION`)
```ini
MAJOR=157
MINOR=0
BUILD=8083
PATCH=0
```

### Channel & Stability Analysis
- **Status:** **Pre-Stable / Trunk (Canary/Dev branch)**.
- **Why this revision exists in checkout:** `depot_tools` `fetch --nohooks chromium` syncs `origin/main` by default unless explicitly pinned with `--version` or checkout tag.
- **Implications for Obscure:**
  - Modern C++20/C++23 features and modern Chromium modular patterns (`content::WebUIConfigMap`) are active.
  - Trunk code undergoes daily churn upstream. To maintain reproducible builds, our build is frozen to pinned commit `e3a47f1afe3c87307d7b98638a576a5993fb95d7`.
  - A formal rebase rehearsal onto a newer milestone tag is required before November 14, 2026.

---

## 2. Persistence Subsystems Comparison

### A. SessionService
- **Path:** `chrome/browser/sessions/session_service.h` (Line 52)
- **Verified Behavior:**
  - Inherits from `SessionServiceBase`.
  - Uses `CommandStorageBackend` (SNSS binary command log) to serialize open windows, tabs, and navigation entries (`SerializedNavigationEntry`).
  - Writes incrementally to `Sessions/Session_<timestamp>` and `Sessions/Tabs_<timestamp>`.
- **Verdict for Project Spaces:** **Rejected.** `SessionService` is designed exclusively for global browser crash and restart recovery. It does not support user-defined workspaces, workspace naming, independent stashing, or human-readable JSON import/export. Modifying it would destabilize standard session restore.

### B. SavedTabGroup & TabGroupSyncService
- **Paths:** 
  - `components/saved_tab_groups/public/saved_tab_group.h` (Line 34)
  - `components/saved_tab_groups/public/tab_group_sync_service.h` (Line 45)
- **Verified Behavior:**
  - Deeply coupled to Google Account Sync: includes `components/sync/base/collaboration_id.h` and `google_apis/gaia/gaia_id.h`.
  - Manages `GaiaId removed_by`, `creator_cache_guid`, and sync protocol bridges (`SavedTabGroupSyncBridge`).
- **Verdict for Project Spaces:** **Rejected.** Bending `TabGroupSyncService` into an offline, local-first, account-free persistence engine introduces substantial sync dependencies and unwanted Google Account tie-ins.

### C. Custom ObscureWorkspaceService (File-Backed JSON)
- **Verdict:** **Approved.** Clean separation of concerns, human-readable schema, versioned format, exportable, and fully offline.

---

## 3. ImportantFileWriter Deep Dive & Threading Invariants

Inspected: `base/files/important_file_writer.h` and `base/files/important_file_writer.cc`.

### Threading Architecture (Strictly Off-UI-Thread)
- In Chromium, **synchronous disk I/O on the UI thread triggers `DCHECK` panics and browser jank**.
- All writes dispatched by `ImportantFileWriter` execute on a background `SequencedTaskRunner` (`base::ThreadPool::CreateSequencedTaskRunner({base::MayBlock(), base::TaskPriority::USER_VISIBLE, base::TaskShutdownBehavior::BLOCK_SHUTDOWN})`).
- Calling `WriteNow()` serializes strings on the UI thread and immediately posts the write task to the background sequence without blocking the UI message pump.

### The 10-Second Debounce Window Discovery
In `base/files/important_file_writer.cc` (line 46):
```cpp
constexpr auto kDefaultCommitInterval = Seconds(10);
```
- **Risk:** If `ScheduleWrite()` is called, data remains in memory for up to **10 seconds** before flushing to disk. An abrupt process termination (`SIGKILL`, OS shutdown, crash) within this window causes silent loss of space updates.
- **Requirement:** 
  1. We must configure a custom provisional debounce interval of `base::Milliseconds(500)` for non-critical tab focus and scroll events.
  2. Critical events (**Space creation, deletion, rename, tab closure, window close, browser shutdown**) must bypass the timer and trigger immediate asynchronous dispatch via `ImportantFileWriter::WriteNow()`.

### Crash Resilience Boundaries
In `base/files/important_file_writer.h` (line 79):
```cpp
// Does not guarantee file integrity across system crash... thus using
// ImportantFileWriter is not a valid substitute for file integrity checks
// and recovery codepaths for malformed files.
```
- **Contract:** Protects against **application-level crashes** during write via temp-file creation and atomic rename. Does not protect against hard kernel panics or power outages before hardware write caches sync.
- **Mitigation:**
  1. Must maintain a `.bak` backup file (`obscure_spaces.json.bak`).
  2. Rotate backup only **after** the replacement file has been verified on disk.
  3. Validate JSON schema version on load; if corrupted, fallback to `.bak` automatically.

### File Permissions & Path Resolution
- **Profile Path API:** `chrome/browser/profiles/profile.h` line 210:
  ```cpp
  base::FilePath GetPath() const override = 0;
  ```
  Path: `profile->GetPath().Append(FILE_PATH_LITERAL("obscure_spaces.json"))`.
- **POSIX Permissions:** `base/files/file_util.h` line 385:
  ```cpp
  BASE_EXPORT bool SetPosixFilePermissions(const FilePath& path, int mode);
  ```
  Enforces `0600` (`base::FILE_PERMISSION_READ_BY_USER | base::FILE_PERMISSION_WRITE_BY_USER`) on Linux.

---

## 4. WebUI Registration & NTP Override (Exact Source Lines)

### WebUI Registration Architecture in Chromium 157
In modern Chromium (v157), WebUI pages do NOT register via the legacy `ChromeWebUIControllerFactory`. They use `content::WebUIConfigMap`.

Verified in `chrome/browser/ui/webui/chrome_web_ui_configs.cc`:
- Line 250: `void RegisterChromeWebUIConfigs()`
- Line 267: `auto& map = content::WebUIConfigMap::GetInstance();`
- Line 335: `map.AddWebUIConfig(std::make_unique<NewTabPageUIConfig>());`
- Line 464: `map.AddWebUIConfig(std::make_unique<SandboxInternalsUIConfig>());` (serves `chrome://sandbox`)

### Verified Line Evidence for Build & Lifecycle Hooks
- **HK-02 (Build Target Dependency):** `chrome/browser/BUILD.gn` lines 1081–1095:
  ```gn
  "//chrome/browser/ui/webui:configs",
  "//chrome/browser/ui/webui:log_web_ui_url",
  "//chrome/browser/ui/webui/actor_internals",
  "//chrome/browser/ui/webui/bluetooth_internals",
  "//chrome/browser/ui/webui/chrome_urls",
  "//chrome/browser/ui/webui/connectors_internals",
  ```
- **HK-03 (Keyed Service Factory):** `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc` lines 1599–1605:
  ```cpp
  WebDataServiceFactory::GetInstance();
  webrtc_event_logging::WebRtcEventLogManagerKeyedServiceFactory::GetInstance();
  ```

---

## 5. Linux Sandbox Status & Interactive Launch (TP-05)

### Exact Interactive Launch Command (TP-05)
```bash
$ ./out/Obscure/chrome https://zorquelz.com
```
- **Execution Context:** Launched in Ubuntu 24.04 LTS running under WSL2 with WSLg (Wayland/XWayland display server).
- **Flags Used:** **Zero sandbox-disabling flags**. No `--no-sandbox`, no `--disable-gpu-sandbox`.
- **Observed Behavior:** Window initialized, connected to Wayland display, rendered `https://zorquelz.com` with working TLS, DOM, and JavaScript execution.

### Headless Sandboxed Execution Verification (TP-04)
```bash
$ ./out/Obscure/chrome --headless=new --dump-dom https://example.com
```
- **Result:** **Success.** Exit code `0`. Rendered full HTML DOM of `https://example.com`.
- **Sandbox Verdict:** The standard Chromium Layer-1 (User Namespaces) and Layer-2 (BPF seccomp) sandbox is fully operational in this environment.
- **Rule:** `--no-sandbox` is strictly prohibited from all release and testing workflows.
