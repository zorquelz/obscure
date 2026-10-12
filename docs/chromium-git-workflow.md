# Chromium Git Branch & Patch Export Workflow
**Zorquelz Technologies | Developer & QA Guide**
**Target Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)

> This document defines how development, testing, patch generation, and safe rollbacks are executed inside the live Chromium checkout (`~/Obscure/chromium/src`) using Git branches, per-commit patch series, safe bundle backups, and LF line ending normalization.

---

## 1. Branch Architecture & Baseline Pinning

All Obscure engineering inside the ~80GB Chromium checkout is isolated on a dedicated Git branch rooted at the official Stable 155 release tag:

```text
upstream/origin/main
         │
         ├── [Tag: 155.0.8059.39] (Commit: 3ff7ac5a9224be9156d7f8703a06e22890aafd34)
         │         │
         │         └── obscure-baseline-155.0.8059.39 (Local Immutable Baseline Tag)
         │                   │
         │                   └── obscure-stable-155 (Active Obscure Work Branch)
         │                             ├── Commit 1: "feat(obscure): scaffold isolated module"
         │                             └── Commit 2: "feat(obscure): register WebUI configs"
```

---

## 2. Line Ending Normalization (`.gitattributes`)

Because development spans the Windows 11 host (where the Obscure control repository resides) and the WSL2 Ubuntu environment (where Chromium is built), CRLF line endings can corrupt patch application (`git am`).

The Obscure control repository enforces strict Unix line feeds (LF) via `.gitattributes`:
```gitattributes
* text=auto eol=lf
*.patch text eol=lf
*.cc text eol=lf
*.h text eol=lf
*.gn text eol=lf
*.gni text eol=lf
*.json text eol=lf
*.md text eol=lf
```

---

## 3. Standard Operating Procedures in WSL2

### Step A: Verify Pinned Baseline & Establish Baseline Tag
```bash
cd ~/Obscure/chromium/src

# 1. Ensure on pinned commit
git checkout 3ff7ac5a9224be9156d7f8703a06e22890aafd34

# 2. Establish local immutable baseline tag if not present
git tag -a obscure-baseline-155.0.8059.39 3ff7ac5a9224be9156d7f8703a06e22890aafd34 -m "Obscure Stable 155 Immutable Baseline"

# 3. Create or checkout dedicated development branch
git checkout -B obscure-stable-155 obscure-baseline-155.0.8059.39
```

### Step B: Developing & Committing Custom Code
1. Place custom files strictly in `chrome/browser/obscure/`.
2. Apply minimal registration hooks as cataloged in `HOOKS.md`.
3. Commit changes in small, logical, atomic Git commits:
   ```bash
   git add chrome/browser/obscure/ chrome/browser/ui/webui/chrome_web_ui_configs.cc
   git commit -m "feat(obscure): register ObscureNewTabPageUIConfig (HK-01)"
   ```
4. Verify compilation locally:
   ```bash
   ninja -C out/Stable155 chrome
   ```

### Step C: Stale-Patch Purge & Exporting Per-Commit Patches
When code is ready for Claude's independent review and CEO gate approval:
```bash
cd ~/Obscure/chromium/src

# 1. Purge stale patches to ensure obsolete commits do not linger
rm -f /mnt/f/Zorquelz/Obscure/patches/*.patch

# 2. Generate clean per-commit numbered patch series into patches/ directory
git format-patch obscure-baseline-155.0.8059.39..obscure-stable-155 -o /mnt/f/Zorquelz/Obscure/patches/
```
**Benefits over monolithic diffs:**
- Retains commit author, timestamps, and commit log messages.
- Produces atomic, individually reviewable patches (`0001-....patch`, `0002-....patch`).
- Enables three-way patch merging and verification via `git am`.

### Step D: Throwaway-Branch Patch Validation
Before submitting patches for PR review, validate that the exported patch series applies cleanly to a clean tree and compiles:
```bash
cd ~/Obscure/chromium/src

# 1. Create a temporary throwaway verification branch from the immutable baseline
git checkout -b throwaway-verify obscure-baseline-155.0.8059.39

# 2. Test-apply patches without modifying tree (dry run)
git apply --check /mnt/f/Zorquelz/Obscure/patches/*.patch

# 3. Apply patch series preserving commit history
git am --signoff /mnt/f/Zorquelz/Obscure/patches/*.patch

# 4. Verify compilation smoke test
ninja -C out/Stable155 components/version_info

# 5. Cleanly delete the throwaway verification branch
git checkout obscure-stable-155
git branch -D throwaway-verify
```

---

## 4. Safe Rollback & Backup Procedures (No Destructive Cleanups)

### Strict Operational Bans
- **BANNED:** Never run `git clean -ffd` without backing up commits.
- **BANNED:** Never run `gclient sync -D` without an explicit safety plan approved by the Chief Architect, as `-D` automatically deletes untracked submodules and custom directories.

### Procedure 1: Creating a Safe Git Bundle Backup
Before any rebase, reset, or major branch switch, create a self-contained Git bundle backup:
```bash
cd ~/Obscure/chromium/src
mkdir -p /mnt/f/Zorquelz/Obscure/backups
git bundle create /mnt/f/Zorquelz/Obscure/backups/obscure-backup-$(date +%Y%m%d_%H%M%S).bundle -50 HEAD
git bundle verify /mnt/f/Zorquelz/Obscure/backups/obscure-backup-*.bundle
```

### Procedure 2: Safe Branch Rollback
If an experimental change must be aborted or rewound to the pristine baseline:
```bash
cd ~/Obscure/chromium/src

# 1. Preserve current work on a dated emergency recovery branch
git branch emergency-backup-$(date +%Y%m%d_%H%M%S)

# 2. Safely rewind development branch to the baseline tag
git checkout obscure-stable-155
git reset --hard obscure-baseline-155.0.8059.39

# 3. Verify clean state against baseline
git status --short
git diff obscure-baseline-155.0.8059.39 --stat
```
**Guaranteed Result:** Zero code is lost (preserved in bundle and backup branch), while `obscure-stable-155` returns 100% to the verified Stable 155 baseline.
