# Test Plan 0002: Project Spaces Resilience, Security & Recovery
**Zorquelz Technologies | QA & Testing Specification**

## Status
Draft / Specification for Implementation Phase

## Scope
Validates that `ObscureWorkspaceService` withstands filesystem corruptions, sudden process terminations, schema migrations, and malicious input injections without losing data or executing untrusted code.

---

## Test Cases Matrix

### 1. Security & Input Sanitization

| Test ID | Test Name | Injected Input | Expected Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-SEC-01** | Script Scheme Injection | `{"url": "javascript:alert(document.cookie)"}` | URL rejected upon parse or deserialization | Replaced with `about:blank`; no script execution |
| **TP-SEC-02** | Local Filesystem Probe | `{"url": "file:///etc/passwd"}` | URL rejected upon restore | Replaced with `about:blank`; local file access blocked |
| **TP-SEC-03** | Privileged Chrome Scheme | `{"url": "chrome://settings"}` | URL rejected upon restore | Replaced with `about:blank`; settings page not opened via space restore |
| **TP-SEC-04** | Data URI Payload | `{"url": "data:text/html,<script>alert(1)</script>"}` | URL rejected upon restore | Replaced with `about:blank` |
| **TP-SEC-05** | Mojo Payload Overflow | Space name > 10,000 characters | Mojo IPC validation in C++ rejects message | Process does not crash; error returned to WebUI |

---

### 2. File Corruption & Backup Recovery

| Test ID | Test Name | Simulated Failure Condition | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-REC-01** | Truncated JSON on Startup | `obscure_spaces.json` truncated mid-string (e.g. `{"version": 1, "spaces": [`) | JSON parser fails; service detects corruption; loads `obscure_spaces.json.bak` | All spaces from `.bak` successfully restored |
| **TP-REC-02** | Double Corruption (File + Bak Corrupted) | Both primary and `.bak` files contain invalid garbage bytes | Service logs non-fatal error; initializes clean default space | Browser starts smoothly; no crash; user warned |
| **TP-REC-03** | Future Schema Version | `{"version": 99, "spaces": [...]}` in JSON | Service detects unsupported version; refuses destructive write; backs up file | Preserves user's future data without overwriting |
| **TP-REC-04** | Missing Primary File | `obscure_spaces.json` deleted while `.bak` exists | Service restores from `.bak` | Spaces restored; primary file regenerated |

---

### 3. OS & Filesystem Failure Modes

| Test ID | Test Name | Simulated Environment Condition | Expected Service Behavior | Pass Criteria |
|---|---|---|---|---|
| **TP-FS-01** | Disk Full Simulation | Filesystem mounted with 0 free bytes (`ENOSPC`) during save | `ImportantFileWriter` write to temp file fails; original file and `.bak` remain intact | Existing spaces untouched; error surfaced to UI |
| **TP-FS-02** | Read-Only File Permissions | `chmod 0400 obscure_spaces.json` | Write operation fails gracefully; no crash | In-memory state maintained; warning logged |
| **TP-FS-03** | Rapid Process Termination (`kill -9`) | Loop running 100 iterations of space creation followed by `kill -9` within 100ms–2000ms | Atomic file writes never leave zero-byte or corrupt primary file | At least one valid state (either pre- or post-operation) readable on reboot |
| **TP-FS-04** | Profile Lock Contention | Launch second Chromium instance with same profile directory | Chromium profile lock blocks second instance from corrupting profile | Workspace state not overwritten by secondary process |

---

## Automated Execution Harness (Planned)
These test cases will be executed using automated Python / Bash scripts located in `scripts/test_spaces_resilience.py` targeting the test profile directory before feature sign-off.
