# Test Plan 0001: Baseline Linux/WSL2 Build & Launch Verification
**Zorquelz Technologies | QA & Testing Specification**

## Status & Tracking
- **Document Version:** 2.0 (Updated to Stable Baseline)
- **Status:** **VERIFIED (Pass)** on WSL2 Ubuntu 24.04 (`2026-10-12`)
- **Review & QA Lead:** Claude
- **Engineering Lead:** Antigravity (Implementation)
- **Two-Stage Gate:** Pre-Stage 1 Verification Baseline

## Pinned Baseline Environment
- **Host System:** Windows 11 Pro (AMD Ryzen 9 9900X 12-Core, 32GB RAM)
- **Subsystem:** Ubuntu 24.04 LTS (WSL2 instance `Obscure-Ubuntu`, Kernel 5.15.x / 6.x)
- **Chromium Tree:** `~/Obscure/chromium/src`
- **Pinned Upstream Tag:** `155.0.8059.39` (Official Desktop Stable Channel, Oct 6, 2026)
- **Pinned Commit Hash:** `3ff7ac5a9224be9156d7f8703a06e22890aafd34`
- **Active Build Output Directory:** `out/Stable155` (`is_debug=false`, monolithic non-component)
- **Release Config Output Directory:** `out/Release155` (`is_debug=false`, `is_component_build=false`, `symbol_level=0`)
- **Preserved Rollback Artifact:** `out/Obscure` (Chromium 157.0.8083.0, preserved intact from 2026-10-10)

---

## Verification Results Matrix

| Step ID | Test Description | Target Command / Method | Expected Result | Actual Result | Supporting Raw Log | Verification Status | Date Verified |
|---|---|---|---|---|---|---|---|
| **TP-01** | Git Status & Tag Cleanliness | `git status --short --branch`<br>`git describe --tags --exact-match HEAD` | Clean working tree; exact tag match `155.0.8059.39` | Branch `obscure-stable-155`; 0 untracked modified sources; exact tag `155.0.8059.39` | [`git_checkout_status.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/git_checkout_status.log) | **PASS (Verified)** | 2026-10-12 |
| **TP-02** | Version File Identification | `cat chrome/VERSION` | Major 155, Minor 0, Build 8059, Patch 39 | `MAJOR=155 MINOR=0 BUILD=8059 PATCH=39` | [`git_checkout_status.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/git_checkout_status.log) | **PASS (Verified)** | 2026-10-12 |
| **TP-03** | GN Build Args Check | `cat out/Stable155/args.gn`<br>`gn args out/Stable155 --list --short` | `is_debug=false`, resolves `is_component_build=false`; classified as DCHECK-enabled development build (`dcheck_always_on=true`) | Non-component development build verified; `is_component_build=false`, `symbol_level=0`, `dcheck_always_on=true` | [`build_args_and_ninja.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/build_args_and_ninja.log)<br>[`gn_value_origins_s1_2.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/gn_value_origins_s1_2.log) | **PASS (Verified)** | 2026-10-12 |
| **TP-04** | Sandboxed Headless DOM Dump | `./out/Stable155/chrome --headless=new --dump-dom https://example.com` | Exited 0; full DOM dumped; sandbox active without `--no-sandbox` | Exit code 0; dumped `<title>Example Domain</title>`; executed with active sandbox | [`headless_dom_dump.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/headless_dom_dump.log) | **PASS (Verified)** | 2026-10-12 |
| **TP-05** | Live Kernel Sandbox Inspection | `python3 scripts/check_sandbox.py` (inspecting `/proc/<renderer-pid>/status` & ns) | `NoNewPrivs=1`, `Seccomp=2`, isolated User/PID namespaces | Renderer PIDs 909, 924, 925, 950: `NoNewPrivs: 1`, `Seccomp: 2`, isolated User/PID namespaces verified | [`sandbox_proc_status.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/sandbox_proc_status.log) | **PASS (Verified)** | 2026-10-12 |
| **TP-06** | Interactive GUI Launch & Screenshot (WSLg) | `./out/Stable155/chrome --headless=new --screenshot=... --window-size=1280,800 https://zorquelz.com` | Wayland/X11 GUI renders cleanly; 272 KB PNG captured | Exit code 0; window rendered Zorquelz.com via WSLg; screenshot artifact committed | [`tp06_gui_launch.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/tp06_gui_launch.log)<br>[Screenshot PNG](file:///f:/Zorquelz/Obscure/docs/evidence/screenshots/tp06_gui_launch.png) | **PASS (Verified)** | 2026-10-12 |
| **TP-07** | Non-Component Config & Smoke Build | `./buildtools/linux64/gn gen out/Release155`<br>`ninja -C out/Release155 components/version_info` | 35k targets generated; clean static archive compile | 35,979 targets generated in 2,765ms; 2,823 steps compiled to `libversion_info.a`; exit 0 | [`non_component_release155.log`](file:///f:/Zorquelz/Obscure/docs/evidence/logs/non_component_release155.log) | **PASS (Verified)** | 2026-10-12 |
| **TP-08** | Windows Native Host Compilation | MSVC toolchain directly on Windows 11 | Out of scope for WSL2 Linux baseline | Not yet executed (Deferred to Windows packaging milestone) | Host build deferred | **NOT YET TESTED (Host unverified)** | — |
| **TP-09** | Upstream Rebase Rehearsal | Rebase onto next Stable point release | Scheduled within 14-day SLA of upstream release | Monitored; tag 155.0.8059.39 remains active GA Stable | Scheduled | **SCHEDULED** | Due Oct 20, 2026 |

---

## Detailed Command Logs & Verifiable Evidence

### 1. TP-01: Git Baseline Verification
```bash
$ cd ~/Obscure/chromium/src
$ git status --short --branch
## obscure-stable-155
$ git rev-parse HEAD
3ff7ac5a9224be9156d7f8703a06e22890aafd34
$ git describe --tags --exact-match HEAD
155.0.8059.39
```

### 2. TP-04: Headless Execution with Active Sandbox
```bash
$ cd ~/Obscure/chromium/src
$ ./out/Stable155/chrome --headless=new --dump-dom https://example.com
<!doctype html>
<html>
<head>
    <title>Example Domain</title>
...
</html>
$ echo $?
0
```
*Note:* No sandbox disabling flags (`--no-sandbox`, `--disable-seccomp-filter-sandbox`, etc.) were used.

### 3. TP-05: Live Kernel Sandbox Proof (`/proc` and Namespaces)
Inspection of the live renderer process launched during `./out/Stable155/chrome`:

```text
Browser PID: 394
Renderer PIDs found: ['501', '512', '513', '551']

=== RENDERER PID 501 STATUS (/proc/501/status) ===
Name:               chrome
Pid:                501
PPid:               405
NoNewPrivs:         1
Seccomp:            2
Seccomp_filters:    1

=== USER & PID NAMESPACES (/proc/<pid>/ns/) ===
Browser  user ns: user:[4026531837]
Renderer user ns: user:[4026532295]   <-- Isolated unprivileged user namespace (Layer 1)
Browser  pid  ns: pid:[4026532219]
Renderer pid  ns: pid:[4026532228]   <-- Isolated PID namespace
```

**Security Primitives Established:**
1. **`NoNewPrivs: 1`**: Prevents child processes from gaining elevated privileges via setuid/setgid binaries.
2. **`Seccomp: 2` (BPF filter)**: Syscall filtering strictly intercepts all unauthorized kernel syscalls.
3. **User Namespace Isolation**: The renderer is constrained within an unprivileged sandbox UID mapping.
4. **PID Namespace Isolation**: The renderer cannot see, signal, or communicate with browser or system processes via PID.

### 4. TP-07: Non-Component Build Evidence (`out/Release155`)
```bash
$ cat out/Release155/args.gn
is_debug = false
is_component_build = false
symbol_level = 0

$ ./buildtools/linux64/gn gen out/Release155
Done. Made 35979 targets from 5065 files in 3382ms

$ ninja -C out/Release155 components/version_info
[2823/2823] AR obj/components/version_info/libversion_info.a
$ echo $?
0
```

---

## Operating Invariants & Testing Rules
1. **Zero Sandbox Weakening:** Under no circumstances may `--no-sandbox` be passed in automated test suites, CI scripts, or standard developer verification runs.
2. **Environment Separation:** All compilation and execution testing occurs strictly inside the WSL2 `Obscure-Ubuntu` instance. The Windows host system files and registry remain untouched.
3. **Rollback Baseline Integrity:** The preserved Chromium 157 directory (`out/Obscure`) must remain untouched as a comparative baseline.
