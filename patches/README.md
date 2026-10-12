# Patches Directory
**Zorquelz Technologies | Upstream Patch Series**

This directory stores per-commit `.patch` files generated via `git format-patch` against the pinned immutable baseline tag `obscure-baseline-155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`).

## Conventions & Workflow Alignment

### 1. Line-Ending Invariant (`-text`)
In accordance with repository `.gitattributes` rules, all patch files are tagged `*.patch -text`. This guarantees Git preserves diff bytes verbatim across Windows and Linux environments without introducing line-ending conversions that could corrupt hunk line counts.

### 2. Stale-Patch Purge
Before exporting any updated patch series, all existing patches in this directory must be purged to ensure obsolete commits do not linger:
```bash
rm -f /mnt/f/Zorquelz/Obscure/patches/*.patch
```

### 3. Generation via `git format-patch`
```bash
git format-patch obscure-baseline-155.0.8059.39..obscure-stable-155 -o /mnt/f/Zorquelz/Obscure/patches/
```
Each patch retains author metadata, commit timestamps, and atomic commit messages (`0001-....patch`, `0002-....patch`).

### 4. Throwaway-Branch Validation
Before landing or submitting patches for PR review, validate that the patch series applies cleanly on a temporary branch:
```bash
# 1. Create temporary throwaway branch from immutable baseline
git checkout -b throwaway-verify obscure-baseline-155.0.8059.39

# 2. Dry-run verify
git apply --check /mnt/f/Zorquelz/Obscure/patches/*.patch

# 3. Apply series
git am --signoff /mnt/f/Zorquelz/Obscure/patches/*.patch

# 4. Verify compilation smoke test
ninja -C out/Stable155 components/version_info

# 5. Cleanly delete verification branch
git checkout obscure-stable-155
git branch -D throwaway-verify
```

### 5. Safe Rollback
- If `git am` encounters conflicts: `git am --abort`
- If aborting on work branch: preserve commits via emergency backup branch before resetting to `obscure-baseline-155.0.8059.39`.
