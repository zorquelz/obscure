# OBSCURE — The Builder's Browser
**Zorquelz Technologies | Project Control & Patch Repository**

> A Chromium-based desktop browser for developers, indie hackers, and cybersecurity practitioners.

---

## 1. Current Status (As of October 11, 2026)

### What Works
- [x] Baseline synchronized and pinned to official **Chromium Stable** tag `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`).
- [x] GN build configuration generated successfully (`gn gen out/Obscure` passed with 0 errors).
- [x] Official team roles and governance protocol established.
- [x] External integration points (`HOOKS.md`) re-derived and verified on Stable 155.
- [x] Space resilience test plan (`0002-spaces-resilience-and-security.md`) specified.

### What Does NOT Work Yet (WIP)
- [ ] Full 56,000-step native compilation on Stable 155 queued (pending initial build test).
- [ ] No custom Obscure branding or visual theme applied yet.
- [ ] Project Spaces (tab stashing / session restore) not yet implemented.
- [ ] WebUI pages (`chrome://obscure-newtab`, `chrome://obscure-settings`) not yet hooked.
- [ ] Standalone distributable packages (Linux `.deb`/AppImage or Windows `.exe`) not yet built.
- [ ] Multi-profile storage isolation not yet supported.

---

## 2. Team Roster & Operating Model

| Member | Official Position | Responsibility |
|---|---|---|
| **Founder** | **Founder & CEO** | Product vision, business priorities, feature approval, final tie-breaker. |
| **ChatGPT** | **Chief Architect & Technical Strategy Lead** | High-level system design, strategic trade-offs, architecture briefs. |
| **Antigravity** | **Engineering & Implementation Lead** | Hands-on code, patches, WebUI/C++ shims, build execution, PR author. |
| **Claude** | **Review & QA Lead** | Code review, diff audits, security verification, test plan approvals. |

### Collaboration Rules of Engagement
1. **No direct commits to main:** Implementation happens via feature branches and Pull Requests.
2. **Review before land:** Every non-trivial change must present an explicit `git diff` and a verified revert command for Claude's review.
3. **Evidence-based decisions:** Disputes regarding security or data integrity are resolved with tests, logs, or Chromium source references, not speculation.
4. **Decisions in Repo:** Architectural conclusions are committed under `docs/decisions/` (ADRs).
5. **Security SLA:** Tested security updates within 14 calendar days of upstream Chromium Stable releases.

---

## 3. Repository Layout

This repository intentionally **does not** contain the full Chromium source tree (~80GB). It contains our custom code, patches, architecture decisions, and tooling:

```text
.
├── docs/
│   ├── decisions/       # Architecture Decision Records (ADRs)
│   ├── test-plans/      # QA & test verification procedures
│   ├── evidence/        # Real source-tree audits & command logs
│   └── specs/           # Feature and UI/UX specifications
├── src/
│   ├── webui/           # Obscure WebUI frontends (New Tab, Settings, Drawer)
│   └── native/          # Isolated C++ shim files (//chrome/browser/obscure/)
├── patches/             # Unified .patch files applied cleanly over upstream Chromium
└── scripts/             # Build automation, sync helpers, and packaging scripts
```

---

## 4. Development Baseline

- **Host Machine:** Windows 11 (AMD Ryzen 9 9900X, 32GB RAM)
- **Compilation Environment:** Ubuntu 24.04 LTS (WSL2 `Obscure-Ubuntu`)
- **Chromium Source Path:** `~/Obscure/chromium/src`
- **Pinned Upstream Tag:** `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)
- **Current Target Build:** `out/Obscure` (`is_debug=false is_component_build=true symbol_level=0`)
- **Target Revenue Milestone:** December 9, 2026 (Founding Supporter validation)
