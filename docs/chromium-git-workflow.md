# Chromium Git Branch & Patch Export Workflow
**Zorquelz Technologies | Developer Guide**

> This document defines how development occurs inside the live Chromium checkout (`~/Obscure/chromium/src`) using a dedicated Git feature branch rather than raw file rsyncing.

---

## 1. Why the Rsync / In-Place Workflow Was Rejected
Rsyncing files into a detached HEAD inside `~/Obscure/chromium/src` creates severe operational risks:
1. Running `gclient sync` or `git checkout .` silently blows away uncommitted custom files.
2. Changes outside `//chrome/browser/obscure/` become mixed with dirty tree state.
3. Upstream rebase conflicts cannot be resolved cleanly using standard Git three-way merges.

---

## 2. The Chromium Git Branch Architecture

All work inside the Chromium checkout is tracked on a dedicated Git branch:

```text
upstream/origin/main (Pinned: e3a47f1afe3c87307d7b98638a576a5993fb95d7)
         │
         └── obscure-v1.0 (Our local Chromium work branch)
                  ├── Commit: "feat(obscure): add obscure browser module"
                  └── Commit: "feat(obscure): register WebUI configs and hooks"
```

---

## 3. Standard Operating Commands in WSL2

### Step A: Initialize the Work Branch (One-Time Setup)
```bash
cd ~/Obscure/chromium/src

# Ensure on pinned commit
git checkout e3a47f1afe3c87307d7b98638a576a5993fb95d7

# Create dedicated Obscure development branch
git checkout -b obscure-v1.0
```

### Step B: Developing Custom Code
1. Place new files directly in `chrome/browser/obscure/`.
2. Apply external hooks (as cataloged in `HOOKS.md`).
3. Compile and verify locally:
   ```bash
   autoninja -C out/Obscure chrome
   ```

### Step C: Exporting Unified Patches to Obscure Control Repo
When a milestone or tracer bullet is ready for Claude's review:
```bash
cd ~/Obscure/chromium/src

# Export clean patch series against pinned upstream baseline
git diff e3a47f1afe3c87307d7b98638a576a5993fb95d7..obscure-v1.0 > /mnt/f/Zorquelz/Obscure/patches/0001-tracer-bullet-ntp.patch
```

### Step D: Verifying Upstream Baseline Purity
To verify that no unexpected files or modifications exist:
```bash
cd ~/Obscure/chromium/src
git status
git diff e3a47f1afe3c87307d7b98638a576a5993fb95d7 --stat
```

### Step E: Absolute Rollback / Reset
If any experiment must be completely aborted to restore the pristine baseline:
```bash
cd ~/Obscure/chromium/src
git checkout e3a47f1afe3c87307d7b98638a576a5993fb95d7
git branch -D obscure-v1.0
git clean -ffd
```
**Guaranteed Result:** The Chromium source checkout returns 100% to the exact pristine baseline with zero untracked files.
