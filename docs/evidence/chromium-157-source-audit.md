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

## 3. ImportantFileWriter Deep Dive

Inspected: `base/files/important_file_writer.h` and `base/files/important_file_writer.cc`.

### Critical Finding: The 10-Second Debounce Window
In `base/files/important_file_writer.cc` (line 46):
```cpp
constexpr auto kDefaultCommitInterval = Seconds(10);
```
- **Risk:** If `ScheduleWrite()` is called, data remains in memory for up to **10 seconds** before flushing to disk. An abrupt process termination (`SIGKILL`, OS shutdown, crash) within this window causes silent loss of space updates.
- **Requirement:** 
  1. We must configure a custom provisional debounce interval of `base::Milliseconds(500)`.
  2. Critical events (**Space creation, deletion, rename, tab closure, window close, browser shutdown**) must bypass the timer and call `WriteNow()` / `DoScheduledWrite()` immediately.

### Crash Resilience Limitations
In `base/files/important_file_writer.h` (line 79):
```cpp
// Does not guarantee file integrity across system crash... thus using
// ImportantFileWriter is not a valid substitute for file integrity checks
// and recovery codepaths for malformed files.
```
- **Requirement:** 
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

## 4. WebUI Registration & NTP Override

### WebUI Registration Architecture in Chromium 157
In modern Chromium (v157), WebUI pages do NOT register via the legacy `ChromeWebUIControllerFactory`. They use `content::WebUIConfigMap`.

Verified in `chrome/browser/ui/webui/chrome_web_ui_configs.cc` (lines 250, 267):
```cpp
void RegisterChromeWebUIConfigs() {
  auto& map = content::WebUIConfigMap::GetInstance();
  map.AddWebUIConfig(std::make_unique<AccessibilityUIConfig>());
  // ...
}
```

### New Tab Page Integration Comparison
- **Option A (Direct Config Substitution):**
  - Line 335 in `chrome/browser/ui/webui/chrome_web_ui_configs.cc`:
    ```cpp
    map.AddWebUIConfig(std::make_unique<NewTabPageUIConfig>());
    ```
  - Substitute with `ObscureNewTabPageUIConfig` handling `chrome::kChromeUINewTabPageHost`.
  - Touches exactly **1 file** outside `//chrome/browser/obscure/`.
- **Option B (URL Rewrite Interception):**
  - Intercept `search::HandleNewTabURLRewrite` in `chrome/browser/search/search.cc` (line 408) to rewrite `chrome://newtab/` to `chrome://obscure-newtab/`.
  - Touches 4 external files (`webui_url_constants.h`, `webui_url_constants.cc`, `chrome_web_ui_configs.cc`, `search.cc`).
- **Conclusion:** **Option A** is significantly less invasive and reduces rebase maintenance risk.

---

## 5. Linux Sandbox Status Verification

Verified execution of `./out/Obscure/chrome` in Ubuntu 24.04 (WSL2):
```bash
$ ./out/Obscure/chrome --headless=new --dump-dom https://example.com
```
- **Result:** **Success.** Exit code `0`. Rendered full HTML DOM of `https://example.com`.
- **Sandbox Verdict:** The standard Chromium Layer-1 (User Namespaces) and Layer-2 (BPF seccomp) sandbox is fully operational in this environment.
- **Rule:** `--no-sandbox` is strictly prohibited from all release and testing workflows.
