# [SUPERSEDED] Chromium 157 Source Tree Evidence & Audit Report
**Zorquelz Technologies | Engineering & Implementation Lead (Antigravity)**  
**Date:** October 11, 2026 (Superseded: October 12, 2026)  
**Target Repository:** `~/Obscure/chromium/src` (WSL2 `Obscure-Ubuntu`)

> [!WARNING]
> **SUPERSEDED HISTORICAL EVIDENCE**:
> This document records the initial source audit performed against Chromium tip-of-tree trunk (`157.0.8083.0` / Commit `e3a47f1afe3c87307d7b98638a576a5993fb95d7`). 
> Following executive review and CEO directive on October 12, 2026, **Obscure uses official Chromium Stable only**. Trunk is rejected as a release baseline.
> 
> The active, production-grade baseline is **Chromium Stable `155.0.8059.39`** (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`).
> For active audit evidence, see [`docs/evidence/chromium-stable-155-source-audit.md`](./chromium-stable-155-source-audit.md).

---

## 1. Revision & Baseline Verification (Historical Trunk)

Every entry in this section was verified against the active Chromium source checkout on October 11, 2026 prior to the Stable transition.

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

---

## 4. Historical Reference to `out/Obscure` Build
- On October 10, 2026, a component build (`is_component_build=true`) of Chromium 157 was compiled into `out/Obscure` (56,726 steps).
- This binary (`out/Obscure/chrome`, 197 MB) remains preserved intact on disk as a historical comparison point and rollback reference.
