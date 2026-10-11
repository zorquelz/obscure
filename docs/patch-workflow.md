# Patch Application & Chromium Synchronization Workflow
**Zorquelz Technologies | Developer Guide**

> This document defines how custom Obscure code and patches are synchronized into the live Chromium checkout without corrupting or losing the pristine upstream baseline.

---

## 1. Directory Relationship

```text
F:\Zorquelz\Obscure\                      ~/Obscure/chromium/src/
├── src/                                  (The Live Chromium Tree)
│   ├── native/            --rsync/copy-> ├── chrome/browser/obscure/
│   └── webui/             --rsync/copy-> └── chrome/browser/obscure/ui/webui/resources/
│
├── patches/                              (Unified Diff Patches)
│   ├── 0001-hooks.patch   --git apply--> Applied to files outside //chrome/browser/obscure/
│   └── ...
```

---

## 2. Rule of Isolation

1. **New Files Live in `src/`:**
   - All Obscure-specific source code (`.cc`, `.h`, `.html`, `.css`, `.ts`, `BUILD.gn`) is authored and tracked in this repository under `src/`.
   - When deploying to Chromium, these files are copied or symlinked into `~/Obscure/chromium/src/chrome/browser/obscure/`.
2. **Modifications to Existing Files Live in `patches/`:**
   - Any modification to an existing Chromium file (e.g. `chrome_web_ui_configs.cc`, `chrome/browser/BUILD.gn`) must be maintained as a numbered unified `.patch` file inside `patches/`.
   - Patches are applied to the live checkout via `git apply`.

---

## 3. Workflow Steps

### Step A: Deploying Custom Files
```bash
# Sync Obscure native source into Chromium tree
mkdir -p ~/Obscure/chromium/src/chrome/browser/obscure
rsync -av --delete /mnt/f/Zorquelz/Obscure/src/native/ ~/Obscure/chromium/src/chrome/browser/obscure/
```

### Step B: Applying External Hooks Patches
```bash
cd ~/Obscure/chromium/src

# 1. Verify patch cleanly applies without changes
git apply --check /mnt/f/Zorquelz/Obscure/patches/0001-external-hooks.patch

# 2. Apply patch
git apply /mnt/f/Zorquelz/Obscure/patches/0001-external-hooks.patch
```

### Step C: Compiling Incremental Target
```bash
cd ~/Obscure/chromium/src
autoninja -C out/Obscure chrome
```

### Step D: Reverting Cleanly
If anything fails or a clean baseline must be restored:
```bash
cd ~/Obscure/chromium/src

# Reverse the patch
git apply -R /mnt/f/Zorquelz/Obscure/patches/0001-external-hooks.patch

# Remove untracked Obscure files from the Chromium tree
rm -rf chrome/browser/obscure

# Verify pristine tree
git status -s
```
**Expected Status:** Returns zero modifications and zero untracked files, restoring the pristine checkout immediately.
