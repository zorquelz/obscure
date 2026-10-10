# Test Plan 0001: Baseline Linux/WSL2 Build & Launch Verification

## Purpose
Confirm that the pristine Chromium checkout in WSL2 builds cleanly, launches, renders real web content, and maintains a known-good baseline before any Obscure-specific patches are applied.

## Target Environment
- Host: Windows 11
- Subsystem: Ubuntu 24.04 LTS (WSL2 `Obscure-Ubuntu`)
- Source Path: `~/Obscure/chromium/src`
- Output Directory: `out/Obscure`

## Verification Steps

### Step 1: Git Status Cleanliness
```bash
cd ~/Obscure/chromium/src
git status
```
**Expected Result:** Clean working tree with no uncommitted modifications.

### Step 2: GN Arguments Verification
```bash
cat out/Obscure/args.gn
```
**Expected Result:**
```gn
is_debug = false
is_component_build = true
symbol_level = 0
```

### Step 3: Incremental Build Sanity Check
```bash
autoninja -C out/Obscure chrome
```
**Expected Result:**
`ninja: no work to do` (since full build succeeded on 2026-10-10).

### Step 4: Launch and Web Content Test
```bash
./out/Obscure/chrome --no-sandbox https://zorquelz.com
```
*(Note: `--no-sandbox` is only acceptable during initial WSLg display verification if user namespaces are restricted; production builds must run fully sandboxed).*

**Expected Result:**
- Chromium window opens via WSLg / Wayland display.
- zorquelz.com renders without tab crash (`SIGSEGV` / `STATUS_ACCESS_VIOLATION`).
- DevTools (`F12`) opens and inspects elements normally.

## Rollback / Recovery
If the build is ever corrupted:
```bash
# Clean out build outputs without re-downloading source
gn clean out/Obscure
gn gen out/Obscure --args='is_debug=false is_component_build=true symbol_level=0'
autoninja -C out/Obscure chrome
```
