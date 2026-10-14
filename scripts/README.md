# Obscure Build, Test & QA Tooling Scripts
**Zorquelz Technologies | Engineering & QA Infrastructure**

This directory contains deterministic automation scripts for building, inspecting, testing, and verifying Obscure across the Windows control repository and the WSL2 Ubuntu Chromium build environment.

---

## Script Catalog & Responsibilities

| Script Name | Environment | Category | Primary Function | Supporting Artifact / Output |
| :--- | :--- | :--- | :--- | :--- |
| [`sync_sources.py`](file:///f:/Zorquelz/Obscure/scripts/sync_sources.py) | Python 3 (Win / Linux) | Build Pipeline | Safely synchronizes native C++ and GN sources from `src/native/` to `//chrome/browser/obscure/` without symlinks. | Console SHA-256 integrity report |
| [`check_sandbox.py`](file:///f:/Zorquelz/Obscure/scripts/check_sandbox.py) | Python 3 (Linux / WSL2) | Security QA | Inspects live kernel `/proc/<pid>/status` and `/proc/<pid>/ns/` to verify multi-process sandbox invariants. | `sandbox_proc_status.log` |
| [`test_tb10_patch_revert.sh`](file:///f:/Zorquelz/Obscure/scripts/test_tb10_patch_revert.sh) | Bash (WSL2) | Acceptance Test | Validates clean patch application (`git apply`, `git am`) and 100% reversible hard rollback (`git reset --hard`). | `docs/evidence/logs/tb10_revert_test.log` |
| [`demonstrate_rollback_recovery.sh`](file:///f:/Zorquelz/Obscure/scripts/demonstrate_rollback_recovery.sh) | Bash (WSL2) | Safety QA | Proves zero work loss by bundling custom commits, hard-resetting to baseline, and restoring byte-for-byte. | `docs/evidence/logs/rollback_recovery_demonstration.log` |
| [`capture_tp06_screenshot.sh`](file:///f:/Zorquelz/Obscure/scripts/capture_tp06_screenshot.sh) | Bash (WSL2) | Evidence Capture | Launches Chromium in `--headless=new` mode to capture DOM layout screenshot evidence. | `docs/evidence/screenshots/tp06_gui_launch.png` |
| [`capture_evidence_logs.sh`](file:///f:/Zorquelz/Obscure/scripts/capture_evidence_logs.sh) | Bash (WSL2) | Audit Pipeline | Collects raw Git checkout statuses, GN variable origins, dependency hashes, and binary metadata. | `docs/evidence/logs/*.log` |
| [`audit_submodules.py`](file:///f:/Zorquelz/Obscure/scripts/audit_submodules.py) | Python 3 (Win / Linux) | Provenance QA | Cross-references actual Git submodule HEADs against pinned hashes in Chromium `DEPS` at tag `155.0.8059.39`. | `submodule_revisions_s1_1.log` |

---

## Detailed Script Breakdown & Line-by-Line Mechanics

### 1. `scripts/sync_sources.py`
* **Purpose:** Solves the cross-filesystem problem. Symlinking files between Windows NTFS (`F:\Zorquelz\Obscure`) and WSL2 ext4 (`~/Obscure/chromium/src`) causes Git index corruption and Ninja header-tracking loops. This script copies files deterministically and verifies their SHA-256 hashes.
* **Usage:**
  ```bash
  # Check status without copying
  python scripts/sync_sources.py --check

  # Dry-run planned operations
  python scripts/sync_sources.py --dry-run

  # Execute synchronization
  python scripts/sync_sources.py
  ```
* **Key Mechanics:**
  * Computes SHA-256 hashes of all `.h`, `.cc`, and `.gn` files in `src/native/`.
  * Compares against destination files in `//chrome/browser/obscure/`.
  * Creates parent directories on-demand and copies only mismatched/missing files.

---

### 2. `scripts/test_tb10_patch_revert.sh`
* **Purpose:** Proves Test Plan 0003 condition TB-10: that Obscure patches can be cleanly applied to the Chromium tree and 100% cleanly reverted back to pristine baseline with zero residue.
* **Usage:**
  ```bash
  wsl -d Obscure-Ubuntu bash scripts/test_tb10_patch_revert.sh
  ```
* **Step-by-Step Execution Flow:**
  1. **Line 16–21:** Cleans up stale state and creates a temporary branch `tb10-patch-generator` off `obscure-baseline-155.0.8059.39`.
  2. **Line 22–32:** Generates a synthetic hook commit in `chrome/browser/obscure/tb10_hook.h` and exports it using `git format-patch -1 HEAD`.
  3. **Line 39–44:** Creates an isolated branch `tb10-disposable-verify` and records `BASELINE_COMMIT`.
  4. **Line 47–49:** Executes `git apply --check` to dry-run patch verification.
  5. **Line 52–59:** Applies the patch with `git am --signoff` and records `APPLIED_COMMIT`.
  6. **Line 62–66:** Executes safe rollback with `git reset --hard obscure-baseline-155.0.8059.39` and records `RESTORED_COMMIT`.
  7. **Line 68–74:** Verifies that `RESTORED_COMMIT == BASELINE_COMMIT`. Returns exit code 0 on PASS, 1 on FAIL.
  8. **Line 77–84:** Deletes the temporary verification branch and restores the repository to a clean, active state.

---

### 3. `scripts/demonstrate_rollback_recovery.sh`
* **Purpose:** Empirical proof for Claude's S1-6 requirement: demonstrates that custom Obscure code can be backed up to portable `.bundle` files and completely recovered even after a catastrophic `git reset --hard`.
* **Usage:**
  ```bash
  wsl -d Obscure-Ubuntu bash scripts/demonstrate_rollback_recovery.sh
  ```
* **Safety Invariants:**
  * Backs up commits to `backups/obscure_recovery_demo.bundle`.
  * Verifies bundle integrity using `git bundle verify`.
  * Restores via `git pull` from the bundle, verifying `BEFORE_COMMIT == AFTER_COMMIT`.

---

### 4. `scripts/check_sandbox.py`
* **Purpose:** Validates condition TB-08 and S1-3 without ever running `--no-sandbox` or compromising system safety.
* **Usage:**
  ```bash
  wsl -d Obscure-Ubuntu python3 scripts/check_sandbox.py
  ```
* **Kernel Fields Inspected:**
  * `/proc/<pid>/status` $\rightarrow$ `Seccomp: 2` (Layer 2 sandbox active; Berkeley Packet Filter syscall filtering).
  * `/proc/<pid>/status` $\rightarrow$ `NoNewPrivs: 1` (Privilege escalation permanently blocked).
  * `/proc/<pid>/ns/user` and `/proc/<pid>/ns/pid` $\rightarrow$ Confirms renderer runs in an isolated user and PID namespace compared to the browser process.

---

### 5. `scripts/capture_tp06_screenshot.sh`
* **Purpose:** Launches Chromium in headless mode to render a webpage and dump the raster frame to a PNG screenshot.
* **Usage:**
  ```bash
  wsl -d Obscure-Ubuntu bash scripts/capture_tp06_screenshot.sh
  ```
* **Flags Explained:**
  * `--headless=new`: Modern Chrome headless architecture running full Blink and Viz compositing.
  * `--screenshot=<path>`: Renders the active layout and captures the frame buffer.
  * `--window-size=1280,800`: Establishes deterministic layout dimensions.
