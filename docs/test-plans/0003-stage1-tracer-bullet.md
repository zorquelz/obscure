# Test Plan 0003: Stage 1 New Tab Tracer Bullet Specification
**Zorquelz Technologies | QA & Testing Specification**

## Status & Governance
- **Document Version:** 1.0 (Tracer Bullet Specification)
- **Status:** **PROPOSED** (Awaiting Independent QA Sign-off from Claude & CEO Gate Approval)
- **Stage 1 Implementation Gate:** **BLOCKED** — Implementation will NOT begin until Claude and the CEO explicitly clear Stage 1.
- **Stage 2 Persistence Gate:** **BLOCKED** — ADR 0002 remains Proposed. Zero native persistence code permitted in Stage 1.
- **Target Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)
- **Review & QA Lead:** Claude
- **Chief Architect:** ChatGPT
- **Engineering Lead:** Antigravity (Implementation)

---

## 1. Scope & Architectural Boundaries

The Stage 1 New Tab Tracer Bullet serves as the minimal end-to-end integration proof for Obscure. It validates the build pipeline, WebUI configuration registration, and isolated module linkage while strictly eliminating persistence complexity.

### Explicit Inclusions (Tracer Bullet Scope)
1. **Isolated Module Scaffolding:** Placement of isolated C++ files under `chrome/browser/obscure/` linked via `chrome/browser/BUILD.gn` (HK-02).
2. **WebUI Configuration Registration:** Substitution of `NewTabPageUIConfig` on `chrome::kChromeUINewTabPageHost` ("new-tab-page") inside `chrome/browser/ui/webui/chrome_web_ui_configs.cc` (HK-01).
3. **WebUI Data Source:** Creation of `content::WebUIDataSource` serving bundled static HTML, CSS, and JS assets for the Obscure Launchpad UI (HK-04).
4. **Strict WebUI CSP Compliance:** Adherence to Chromium WebUI Content Security Policy rules (no inline scripts, no `unsafe-eval`, separate static `.js` bundle, trusted local resources only).
5. **Patch Size Constraint:** Total external diff footprint outside `//chrome/browser/obscure/` must strictly not exceed **10 lines** (HK-01: ~3 lines; HK-02: ~2 lines).

### Explicit Exclusions (Strictly Prohibited in Stage 1)
1. **ZERO Native Persistence:** No reading or writing of `obscure_spaces.json`. No `ImportantFileWriter`. No disk I/O.
2. **ZERO Mojo IPC State:** No Mojo interfaces or message receivers.
3. **ZERO Project Spaces DB / State Management:** No space creation, deletion, tab stashing, or workspace models.
4. **ZERO KeyedService Registration:** `ObscureWorkspaceService` and `ObscureWorkspaceServiceFactory` are deferred to Stage 2.
5. **ZERO Storage Partitioning:** No multi-profile or container isolation hacks.
6. **ZERO External Network Requests:** The Launchpad WebUI must make zero outbound requests to external CDNs or analytics.

---

## 2. Acceptance Test Matrix (Stage 1 Tracer Bullet)

| Test ID | Test Category | User Action / Trigger | Expected System Behavior | Pass Criteria | Gate Dependency |
|---|---|---|---|---|---|
| **TB-01** | Tab Strip Navigation | User clicks "+" button on tab strip | Opens `chrome://new-tab-page/` | Obscure Launchpad WebUI renders cleanly | Stage 1 Core |
| **TB-02** | Keyboard Shortcut | User presses `Ctrl+T` | Opens `chrome://new-tab-page/` | Obscure Launchpad WebUI renders cleanly | Stage 1 Core |
| **TB-03** | Window Creation | User presses `Ctrl+N` (New Window) | New browser window opens to New Tab Page | Obscure Launchpad WebUI renders cleanly | Stage 1 Core |
| **TB-04** | Omnibox URL Rewrite | User navigates to `chrome://newtab` or `chrome://new-tab-page` | URL canonicalized to `chrome://new-tab-page/` | Obscure Launchpad WebUI renders cleanly | Stage 1 Core |
| **TB-05** | Incognito Privacy Guard | User presses `Ctrl+Shift+N` (Incognito Window) | Opens `chrome://new-tab-page/` in OffTheRecord profile | Renders standard `IncognitoNewTabPageUI`; **ZERO** Obscure UI rendered | Security & Privacy Invariant |
| **TB-06** | Guest Profile Guard | User launches browser in Guest mode | Opens Guest New Tab Page | Renders standard `GuestNewTabPageUI`; **ZERO** Obscure UI rendered | Security & Privacy Invariant |
| **TB-07** | Content Security Policy | Open DevTools Console on `chrome://new-tab-page/` | Inspect console for CSP errors | **Zero CSP errors**; no inline script violations; no `unsafe-eval` | Security Invariant |
| **TB-08** | Active Sandbox Verification | Launch `./out/Stable155/chrome` without `--no-sandbox` | Execute `scripts/check_sandbox.py` on renderer process | `NoNewPrivs: 1`, `Seccomp: 2`, User and PID namespace isolation active | Kernel Security Invariant |
| **TB-09** | Third-Party Search Engine | Change default search provider to DuckDuckGo/Bing | Press `Ctrl+T` to open New Tab Page | Obscure Launchpad WebUI renders cleanly (not hijacked by search provider NTP) | UI Invariant |
| **TB-10** | Clean Patch Reversibility | Execute `git apply -R patches/*.patch` on Chromium tree | Chromium tree returns to clean baseline | Compiles cleanly back to stock Chromium 155 | Audit Invariant |

---

## 3. Automated & Manual Verification Procedures

### Execution Procedure for TB-07 (CSP Compliance):
```bash
./out/Stable155/chrome --headless=new --dump-dom chrome://new-tab-page/
# DevTools Protocol inspection verifying:
# 1. Document title matches "Obscure"
# 2. Response headers include "Content-Security-Policy: script-src chrome://resources 'self';"
# 3. No console error events emitted
```

### Execution Procedure for TB-08 (Sandbox Verification):
```bash
python3 scripts/check_sandbox.py
# Must confirm Seccomp: 2 and NoNewPrivs: 1 on the Launchpad WebUI renderer PID
```

---

## 4. Rollback Plan for Stage 1 Implementation
If any unexpected regression, build break, or security violation occurs during Stage 1 tracer bullet testing:
```bash
cd ~/Obscure/chromium/src
git checkout obscure-stable-155
git reset --hard obscure-baseline-155.0.8059.39
```
This guarantees an instant, 100% clean return to the verified Stable 155 baseline.
