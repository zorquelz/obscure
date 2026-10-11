# Test Plan 0001: Baseline Linux/WSL2 Build & Launch Verification
**Zorquelz Technologies | QA & Testing Specification**

## Status
Verified on WSL2 Ubuntu 24.04 (`2026-10-11`)

## Target Environment
- Host: Windows 11 (AMD Ryzen 9 9900X, 32GB RAM)
- Subsystem: Ubuntu 24.04 LTS (WSL2 `Obscure-Ubuntu`)
- Source Path: `~/Obscure/chromium/src`
- Output Directory: `out/Obscure`
- Commit Hash: `e3a47f1afe3c87307d7b98638a576a5993fb95d7`

---

## Verification Results Matrix

| Step | Test Description | Target Command | Actual Result | Status |
|---|---|---|---|---|
| **TP-01** | Git Status Cleanliness | `git status -s` | `0` untracked, `0` modified | **PASS (Verified)** |
| **TP-02** | Chromium Version Identification | `cat chrome/VERSION` | `157.0.8083.0` | **PASS (Verified)** |
| **TP-03** | GN Build Args Check | `cat out/Obscure/args.gn` | `is_debug=false`, `is_component_build=true`, `symbol_level=0` | **PASS (Verified)** |
| **TP-04** | Sandbox Execution (Headless) | `./out/Obscure/chrome --headless=new --dump-dom https://example.com` | Exited 0; full DOM dumped; seccomp/namespace sandbox active | **PASS (Verified)** |
| **TP-05** | Interactive GUI Launch (WSLg) | `./out/Obscure/chrome https://zorquelz.com` | Window rendered zorquelz.com via Wayland display | **PASS (Verified 2026-10-10)** |
| **TP-06** | Full Non-Component Release Build | `is_component_build=false` | Not yet compiled (deferred to packaging milestone) | **NOT YET TESTED** |
| **TP-07** | Windows Native Host Compilation | MSVC toolchain on Windows 11 | Not yet executed | **NOT YET TESTED** |
| **TP-08** | Upstream Rebase Rehearsal | Rebase onto updated release tag | Scheduled before November 14, 2026 | **PENDING** |

---

## Detailed Command Logs (Evidence)

### TP-04: Sandboxed Headless DOM Dump Verification
```bash
$ cd ~/Obscure/chromium/src
$ ./out/Obscure/chrome --headless=new --dump-dom https://example.com
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Example Domain</title>
...
</html>
```
*Note on Sandbox Status:* The test ran **without** `--no-sandbox`. Chromium's Linux sandbox (User Namespaces + BPF seccomp) operated successfully inside WSL2 on Ubuntu 24.04.

---

## Rules for Future Executions
1. No developer or automated script may invoke tests with `--no-sandbox` unless diagnosing low-level kernel namespaces.
2. Production packages and release candidate artifacts must never bundle or rely on sandbox-bypass flags.
