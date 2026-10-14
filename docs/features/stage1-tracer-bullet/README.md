# Stage 1: New Tab Tracer Bullet — Founder Engineering Study Notes
**Zorquelz Technologies | Architecture & Implementation Series**  
**Document Revision:** `1.1.0` | **Target Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9...`)  
**Companion Artifact:** [`Obscure_Stage1_Tracer_Bullet_Engineering_Guide.pdf`](file:///f:/Zorquelz/Obscure/docs/features/stage1-tracer-bullet/Obscure_Stage1_Tracer_Bullet_Engineering_Guide.pdf) (176 KB standalone study guide)

---

## 1. The Mental Model: What is a Tracer Bullet?

> **The Tracer Bullet Principle:**  
> A Tracer Bullet is not a prototype or mock. It is the skinniest possible vertical slice of real production code that cuts through *every architectural layer* of the system:
> 
> $\text{Meta-Build System (GN)} \longrightarrow \text{Browser Process C++} \longrightarrow \text{IPC / Config Routing} \longrightarrow \text{Sandboxed Renderer} \longrightarrow \text{Blink Paint}$

In Stage 1, we do **not** write workspace persistence, database files, or complex settings. We prove the plumbing:
1. We can compile our custom isolated C++ module (`//chrome/browser/obscure/`) inside Chromium's Ninja build system.
2. We can route `chrome://new-tab-page` to our native WebUI controller without brittle redirects or extensions.
3. We can stream dark-mode Launchpad assets to a sandboxed renderer process (`Seccomp: 2`, `NoNewPrivs: 1`).
4. We strictly enforce privacy fallback in Incognito and Guest modes (zero custom Obscure UI rendered).

---

## 2. The 4-Phase System Flow

```
Phase 1: Build & Link
   Chromium's GN/Ninja build system links //chrome/browser/obscure into the browser binary.

Phase 2: Navigation & Routing
   User hits Ctrl+T -> WebUIConfigMap matches "chrome://new-tab-page" to ObscureNewTabPageUIConfig.

Phase 3: Privacy Gatekeeper
   ObscureNewTabPageUIConfig::IsWebUIEnabled() checks if the profile is Off-The-Record.
   - If Incognito / Guest: Returns FALSE (standard Chromium private screen renders).
   - If Normal Profile:   Returns TRUE (Obscure Launchpad renders).

Phase 4: Sandboxed Delivery
   ObscureNewTabPageUI streams bundled in-memory Launchpad assets to the sandboxed renderer PID.
```

---

## 3. The "Shim Pattern": Why Obscure Avoids Rebase Hell

Over 99% of Chromium forks fail because they edit hundreds of files across Chromium's 40-million-line codebase. When Google releases an update with 50,000 commits, the fork drowns in merge conflicts.

**The Obscure Shim Rule:** Over 98% of Obscure code lives in an isolated directory: `//chrome/browser/obscure/`. Upstream Chromium is modified in exactly **two files**, totaling under 10 lines of diff:

| Hook ID | File in Upstream Chromium | Lines | Purpose |
| :--- | :--- | :---: | :--- |
| **HK-01** | `chrome/browser/ui/webui/chrome_web_ui_configs.cc` | ~3 lines | Replaces default `NewTabPageUIConfig` with `ObscureNewTabPageUIConfig`. |
| **HK-02** | `chrome/browser/BUILD.gn` | ~2 lines | Appends `"//chrome/browser/obscure"` to browser library dependencies. |

### Hook HK-01 Code Breakdown
```cpp
// Inside chrome_web_ui_configs.cc -> RegisterChromeWebUIConfigs()
#if !BUILDFLAG(IS_ANDROID)
#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui_config.h"

  map.AddWebUIConfig(std::make_unique<obscure::ObscureNewTabPageUIConfig>());
#endif
```
* `std::make_unique`: Heap-allocates our config using single-ownership modern C++ semantics.
* `map.AddWebUIConfig(...)`: Registers our configuration in Chromium's internal URL lookup table.

---

## 4. Component Deep-Dive: The Native Files

All Obscure-specific C++ logic lives in `src/native/` and is synchronized to `chrome/browser/obscure/`:

### 1. The Gatekeeper: `ObscureNewTabPageUIConfig`
* **File:** [`src/native/ui/webui/obscure_new_tab_page_ui_config.cc`](file:///f:/Zorquelz/Obscure/src/native/ui/webui/obscure_new_tab_page_ui_config.cc)
* **Key Function:**
  ```cpp
  bool ObscureNewTabPageUIConfig::IsWebUIEnabled(content::BrowserContext* browser_context) {
    Profile* profile = Profile::FromBrowserContext(browser_context);
    return profile && !profile->IsOffTheRecord();
  }
  ```
* **Why it matters:** `!profile->IsOffTheRecord()` guarantees that Obscure custom UI and workspace data **never execute in Incognito or Guest profiles** (TB-05, TB-06).

### 2. The Controller: `ObscureNewTabPageUI`
* **File:** [`src/native/ui/webui/obscure_new_tab_page_ui.cc`](file:///f:/Zorquelz/Obscure/src/native/ui/webui/obscure_new_tab_page_ui.cc)
* **Key Architecture:**
  * Uses `content::WebUIDataSource::SetRequestFilter` to stream bundled in-memory Launchpad HTML, CSS, and JS using `base::RefCountedString`.
  * **Why not `.pak` files?** Upstream `.pak` packaging requires editing GRD resource tables and build files across 4 upstream locations. `SetRequestFilter` keeps Stage 1 external diffs strictly $\le 10$ lines.
  * **Strict CSP:** Overrides `ScriptSrc` to `"script-src 'self' chrome://resources;"`. Prohibits inline scripts and `eval()`.

---

## 5. Security Model: The Multi-Process Sandbox Jail

In Electron, a renderer window often has direct access to Node.js APIs (`fs`, `child_process`), creating severe vulnerability risks. In Obscure, our Launchpad runs inside a **sandboxed Linux jail**:

| Layer | Kernel Mechanism | What It Physically Enforces |
| :--- | :--- | :--- |
| **Layer 1** | PID & User Namespaces | Renderer cannot view foreign OS processes or access host filesystems. |
| **Layer 2** | `Seccomp: 2` (Syscall Filter) | Linux kernel whitelist. Unauthorized syscalls (e.g. `execve`) cause instant termination (`SIGSYS`). |
| **Privilege Block** | `NoNewPrivs: 1` | Blocks privilege escalation (e.g. executing setuid root binaries). |
| **Site Isolation** | `chrome://` Scheme Boundary | Public internet websites (`https://...`) are strictly barred from framing or embedding Obscure WebUI pages. |

---

## 6. Founder Defense Cheat Sheet

### Q1: "Why build Obscure on Chromium C++ instead of a Chrome Extension?"
> **Founder Answer:**  
> *"Extensions are cosmetic overlays. They cannot manage browser process memory, cannot isolate workspace networking, cannot inspect local developer ports safely, and can be disabled by Chrome policies. By engineering Obscure at the native C++ layer, we control the browser engine while preserving Chromium's world-class multi-process sandbox."*

### Q2: "How do you avoid rebase friction when Google updates Chromium?"
> **Founder Answer:**  
> *"We follow the Shim Pattern: over 98% of Obscure code lives in an isolated module directory (`//chrome/browser/obscure/`). Upstream Chromium is modified in only two files (HK-01 and HK-02) totaling under 10 lines of registration code. When Chromium updates, we only re-anchor those two tiny hooks."*

### Q3: "Does Obscure store workspace data on disk in Stage 1?"
> **Founder Answer:**  
> *"No. Stage 1 is strictly a Tracer Bullet. It proves the build system, URL configuration routing, and sandboxed WebUI delivery. All native disk persistence is intentionally deferred to Stage 2 under ADR 0002 to maintain rigorous scope boundaries."*

---

## 7. Acceptance Test Verification Matrix

| Test ID | Objective | Command | Pass Criteria | Status |
| :--- | :--- | :--- | :--- | :---: |
| **TB-01..04** | Tab / Shortcut Navigation | `./out/Stable155/chrome --headless=new --dump-dom chrome://new-tab-page/` | Launchpad cockpit HTML rendered | <span style="color:#b91c1c; font-weight:bold;">BLOCKED</span> |
| **TB-05** | Incognito Isolation | `./out/Stable155/chrome --headless=new --incognito --dump-dom chrome://new-tab-page/` | Standard Incognito splash; 0 Obscure UI | <span style="color:#b91c1c; font-weight:bold;">BLOCKED</span> |
| **TB-06** | Guest Isolation | `./out/Stable155/chrome --headless=new --guest --dump-dom chrome://new-tab-page/` | Standard Guest splash; 0 Obscure UI | <span style="color:#b91c1c; font-weight:bold;">BLOCKED</span> |
| **TB-07** | CSP Enforcement | `./out/Stable155/chrome --headless=new --enable-logging=stderr --v=1 chrome://new-tab-page/` | Zero CSP console violations | <span style="color:#b91c1c; font-weight:bold;">BLOCKED</span> |
| **TB-08** | Sandbox Verification | `python3 scripts/check_sandbox.py` on renderer PID | `NoNewPrivs: 1`, `Seccomp: 2` | <span style="color:#b91c1c; font-weight:bold;">BLOCKED</span> |
| **TB-10** | Patch Reversibility | `scripts/test_tb10_patch_revert.sh` | 100% exact baseline return | <span style="color:#15803d; font-weight:bold;">PASS (Verified)</span> |
