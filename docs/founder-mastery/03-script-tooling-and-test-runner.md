# Obscure Founder Mastery: Script Tooling & Test Runner Mechanics
**Zorquelz Technologies | Founder Mastery Series — Chapter 3**  
**Audience:** Founder & CEO | **Technical Lead:** Antigravity  
**Goal:** Understand every line and flag in Obscure's automated test runners and QA scripts.

---

## 1. Deep Dive: `scripts/test_tb10_patch_revert.sh`

The script `test_tb10_patch_revert.sh` is our empirical proof for acceptance condition **TB-10**. Here is how to understand and defend every section of it:

### Section 1: Strict Execution Setup (Lines 1–9)
```bash
#!/bin/bash
set -e
cd ~/Obscure/chromium/src
LOG="/mnt/f/Zorquelz/Obscure/docs/evidence/logs/tb10_revert_test.log"
PATCH_FILE="/tmp/0001-test-tracer-bullet-hook.patch"
exec > "$LOG" 2>&1
```
* **`set -e`**: Instructs the Bash shell to terminate immediately if any command returns a non-zero exit code (failure). This guarantees that a silent failure cannot pretend to pass.
* **`exec > "$LOG" 2>&1`**: Redirects standard output (`1`) and standard error (`2`) into the persistent log file on the Windows host filesystem (`/mnt/f/...`).

### Section 2: Synthetic Patch Generation (Lines 21–32)
```bash
git checkout -b tb10-patch-generator obscure-baseline-155.0.8059.39
mkdir -p chrome/browser/obscure
echo "// Obscure TB-10 Smoke Hook" > chrome/browser/obscure/tb10_hook.h
git add chrome/browser/obscure/tb10_hook.h
git commit -m "feat(obscure): test hook for TB-10 revert validation"
git format-patch -1 HEAD -o /tmp/
```
* **Why synthetic?** We must test whether a patch applies and cleanly reverts **without modifying real production code**.
* **`git format-patch -1 HEAD`**: Exports the most recent commit into standard mbox email-format patch file containing author, timestamp, commit message, and diff.

### Section 3: Dry-Run Verification (Lines 46–49)
```bash
git apply --check "$PATCH_FILE"
```
* **`git apply --check`**: Performs a trial run of the patch against the working tree without actually modifying any files. If there is a merge conflict or line ending mismatch, it errors immediately with a non-zero exit code.

### Section 4: Applying the Patch Series (Lines 52–55)
```bash
git am --signoff "$PATCH_FILE"
```
* **`git am`**: ("Apply Mailbox") Reads the email-formatted patch file, applies the diff, and creates a full Git commit with the original author and message.
* **`--signoff`**: Appends a `Signed-off-by:` line, establishing cryptographic and developer audit provenance.

### Section 5: The Hard Reversal (Lines 61–65)
```bash
git reset --hard obscure-baseline-155.0.8059.39
RESTORED_COMMIT=$(git rev-parse HEAD)
```
* **`git reset --hard <tag>`**: Resets both the Git index (staging area) and the working tree to the exact state of the immutable baseline tag `obscure-baseline-155.0.8059.39`.
* **`git rev-parse HEAD`**: Returns the 40-character SHA-1 commit hash of the current commit.

### Section 6: Cryptographic Verification (Lines 68–74)
```bash
if [ "$RESTORED_COMMIT" = "$BASELINE_COMMIT" ]; then
  echo "VERIFICATION RESULT: PASS (100% Exact Restoration to Baseline Tag)"
else
  echo "VERIFICATION RESULT: FAIL (Commit Mismatch)"
  exit 1
fi
```
* Compares the commit hash before patch application with the commit hash after reset. If they match 100%, the rollback is mathematically verified.

---

## 2. Deep Dive: `scripts/check_sandbox.py`

This Python script verifies Chromium's multi-process sandbox without needing root privileges or third-party tools.

### Why inspect `/proc/<pid>/status`?
Under Linux and WSL2, the `/proc` filesystem is an in-memory interface provided by the Linux kernel that exposes live process metadata.
* **`Seccomp: 2`**: Confirms that Secure Computing Mode 2 (filtering mode) is active. In this mode, system calls are intercepted and filtered via Berkeley Packet Filter (BPF) programs.
* **`NoNewPrivs: 1`**: Confirms that the process cannot acquire new privileges through `execve()`.

### Why inspect `/proc/<pid>/ns/`?
Linux namespaces provide process isolation:
* If `/proc/<browser_pid>/ns/pid` and `/proc/<renderer_pid>/ns/pid` point to different namespace IDs, the kernel treats the renderer as living in an entirely isolated process tree.
