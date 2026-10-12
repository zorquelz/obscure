# OBSCURE — The Builder's Browser
**Zorquelz Technologies | Project Control & Patch Repository**

> A Chromium-based desktop browser for developers, indie hackers, and cybersecurity practitioners.

---

## 1. Project Status & Gate Enforcement (As of October 12, 2026)

### Two-Stage Development Gate (CEO & QA Mandate)
- **Stage 1 — New Tab Tracer Bullet:** **BLOCKED** until all discrepancy evidence is reviewed and approved by Review & QA Lead (Claude) and the CEO.
- **Stage 2 — Project Spaces Persistence:** **BLOCKED** until persistence contract, flush policy, test plan 0002, and unit tests are reviewed and approved by Claude and the CEO.
- **Current Phase:** Stable Baseline QA Closure & Verification Package Delivery (Mission A & B).

### Verified Milestones (What Works)
- [x] **Upstream Stable Pinned:** Pinned to official Chromium Desktop Stable release tag `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`).
- [x] **Stable 155 Monolithic Compilation:** Full compilation (`54,376` targets) completed with **Exit code 0** in `out/Stable155`.
- [x] **Executable Verification:** `./out/Stable155/chrome --version` reports **`Chromium 155.0.8059.39`**.
- [x] **Live Kernel Sandbox Evidence:** Verified via `scripts/check_sandbox.py` on live renderer PID without `--no-sandbox`:
  - `NoNewPrivs: 1`
  - `Seccomp: 2` (`SECCOMP_MODE_FILTER`)
  - Isolated User Namespace (`user:[4026532295]`)
  - Isolated PID Namespace (`pid:[4026532228]`)
- [x] **Non-Component Build Target:** `out/Release155` generated via GN (`is_component_build=false, symbol_level=0`) with smoke test verified (`libversion_info.a`, exit code 0).
- [x] **Rollback Baselines Preserved:** Both `out/Obscure` (Chromium 157.0.8083.0) and `out/Stable155` remain intact.
- [x] **Git Workflow Corrected:** Pinned baseline tag `obscure-baseline-155.0.8059.39`, `git format-patch` series, `git bundle` safe backups, and `.gitattributes` LF line ending normalization.
- [x] **Comprehensive Test Plans:**
  - `docs/test-plans/0001-baseline-linux-wsl-verification.md` (v2.0 Stable Baseline & `/proc` evidence).
  - `docs/test-plans/0002-spaces-resilience-and-security.md` (v2.0 URL allowlisting, Mojo IPC validation, 10 MB cap, corruption recovery, Incognito/Guest isolation, NTP matrix).
- [x] **Governance & Security SLA:** 14-calendar-day security rebase SLA from upstream Linux GA, dual approval gate (CEO + Claude QA), and public advisory contingency policy committed in ADR 0002.

### What Does NOT Work Yet (Pending Gate Clearance)
- [ ] Obscure New Tab WebUI frontend (Stage 1 Gate Blocked).
- [ ] Project Spaces persistence shim (Stage 2 Gate Blocked).
- [ ] Standalone distributable packages (Linux `.deb`/AppImage or Windows `.exe`).
- [ ] Native Windows host compilation (MSVC) remains unexecuted and unverified.

---

## 2. Team Roster & Operating Governance

| Member | Official Role | Core Responsibility |
|---|---|---|
| **Founder** | **Founder & CEO** | Product vision, business priorities, feature approval, gate sign-off, tie-breaker. |
| **ChatGPT** | **Chief Architect & Technical Strategy Lead** | High-level system architecture, strategic boundaries, governance briefs. |
| **Antigravity** | **Engineering & Implementation Lead** | Source inspection, native C++ shims, WebUI, build execution, test logs, PR author. |
| **Claude** | **Review & QA Lead** | Code review, diff audits, security verification, test plan gates, sign-off. |

### Collaboration Rules of Engagement
1. **Two-Stage Gate Enforcement:** No tracer bullet or feature implementation begins until its respective gate is cleared by Claude and the CEO.
2. **No Direct Commits to Main:** Implementation occurs on dedicated feature branches and Pull Requests.
3. **Evidence-Based Dispute Resolution:** All claims regarding security, memory, or persistence must reference source files, line numbers, command logs, or test scripts.
4. **Permanent Record in Repo:** Architectural and governance conclusions are permanently tracked in `docs/decisions/` (ADRs).
5. **Security Dual-Approval:** Upstream version upgrades and security-sensitive shims require both CEO approval and Claude QA sign-off.

---

## 3. Repository Layout

```text
.
├── .gitattributes       # Normalizes line endings (LF) for clean patch application
├── HOOKS.md             # Re-derived external Chromium integration points (HK-01 to HK-05)
├── README.md            # Project dashboard, status tracking, and governance
├── docs/
│   ├── decisions/       # ADR 0001 (Governance), ADR 0002 (Architecture & Persistence)
│   ├── test-plans/      # TP 0001 (Baseline Verification), TP 0002 (Resilience & Security)
│   ├── evidence/        # Empirical source audits, logs, sandbox inspection reports
│   └── chromium-git-workflow.md # Git branch, patch export, bundle backup, and rollback rules
├── src/
│   ├── webui/           # Obscure WebUI frontends (Launchpad New Tab, Settings)
│   └── native/          # Canonical C++ shim sources (//chrome/browser/obscure/)
├── patches/             # Unified per-commit .patch files exported via git format-patch
└── scripts/             # Sandbox inspector, build helpers, and verification harnesses
```

---

## 4. Development Baseline Environment

- **Host Machine:** Windows 11 Pro (AMD Ryzen 9 9900X 12-Core, 32GB RAM)
- **Compilation Environment:** Ubuntu 24.04 LTS (WSL2 `Obscure-Ubuntu`)
- **Chromium Source Path:** `~/Obscure/chromium/src`
- **Pinned Upstream Tag:** `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)
- **Local Immutable Tag:** `obscure-baseline-155.0.8059.39`
- **Active Compilation Directory:** `out/Stable155` (`is_debug=false`, monolithic non-component)
- **Target Revenue Milestone:** December 9, 2026 (Founding Supporter validation)
