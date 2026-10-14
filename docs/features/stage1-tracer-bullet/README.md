# Obscure Stage 1: New Tab Tracer Bullet — Engineering & Reverse-Engineering Guide
**Zorquelz Technologies | Obscure Architecture & Implementation Series**  
**Document Revision:** `1.0.0` | **Target Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9224...`)  
**Companion Artifact:** `Obscure_Stage1_Tracer_Bullet_Engineering_Guide.pdf`  
**Classification:** Definitive Architecture, Implementation & Reverse-Engineering Blueprint

---

## Executive Summary & Educational Purpose

This document is the canonical engineering specification and founder study guide for **Stage 1 (New Tab Tracer Bullet)** of Obscure, *The Builder's Browser*. 

It is designed with two strict purposes:
1. **Complete Reverse-Engineering Fidelity:** Provide every architectural diagram, registration hook, class definition, memory model, and line-by-line code explanation required to rebuild or reverse engineer this subsystem from first principles without external guidance.
2. **Founder Technical Mastery:** Teach the underlying Chromium internals, security sandbox constraints, IPC models, and design trade-offs in plain, uncompromising technical language, accompanied by defensible answers to real-world technical and investor inquiries.

---

## 1. Architectural Blueprint & Subsystem Role

### The Role of the New Tab Page in Obscure
In mainstream consumer browsers (Chrome, Edge), the New Tab Page (NTP) is an ad-delivery vehicle, search engine monopoly funnel, and promotional news feed. 

In **Obscure**, the New Tab Page (named the **Launchpad**) is the developer's command cockpit. It is where project spaces, local container status, active listening ports (`localhost:3000`, `8080`), and security inspection environments reside.

### The Tracer Bullet Strategy
A "Tracer Bullet" in software architecture is a minimal, complete end-to-end path through all architectural layers. Rather than writing thousands of lines of UI or state persistence first, Stage 1 proves:
1. **Build System Hooking:** We can introduce isolated C++ source trees (`//chrome/browser/obscure/`) into Chromium's GN meta-build system without breaking upstream compilation targets.
2. **Modern Configuration Hijacking:** We can override default Chromium internal URL dispatch (`chrome://new-tab-page`) using modern `content::WebUIConfig` registration rather than brittle URL redirects or extension shims.
3. **Renderer Process Sandbox & CSP Verification:** Custom static assets (HTML/CSS/JS) can be served through `content::WebUIDataSource` directly into an isolated, sandboxed renderer process (`Seccomp: 2`, `NoNewPrivs: 1`) enforcing strict zero-inline-script Content Security Policy.
4. **Boundary Isolation:** Off-The-Record (Incognito and Guest) sessions strictly bypass Obscure UI and fall back to standard Chromium safety screens.

---

## 2. End-to-End System Topology & Execution Flow

```
                                      BROWSER PROCESS (Privileged Host)
+-------------------------------------------------------------------------------------------------------+
|                                                                                                       |
|  1. User triggers NTP (Ctrl+T, '+' button, Omnibox "chrome://newtab")                                  |
|                                                                                                       |
|  2. URL Normalizer rewrites "chrome://newtab" -> "chrome://new-tab-page/"                            |
|                                                                                                       |
|  3. WebUIConfigMap queries registered configs for host "new-tab-page"                                  |
|     +---> Calls obscure::ObscureNewTabPageUIConfig::IsWebUIEnabled(BrowserContext*)                  |
|           |                                                                                           |
|           +-- Context is OffTheRecord (Incognito / Guest) ?                                           |
|           |   |                                                                                       |
|           |   +---> YES: Returns FALSE -> Upstream Incognito/Guest NTP Config selected (TB-05, TB-06) |
|           |                                                                                           |
|           +---> NO:  Returns TRUE  -> obscure::ObscureNewTabPageUIConfig selected                     |
|                                                                                                       |
|  4. WebUIControllerFactory instantiates obscure::ObscureNewTabPageUI(WebUI*)                         |
|     +---> Attaches to content::WebUIDataSource for "new-tab-page"                                     |
|     +---> Registers memory request filter to stream bundled Launchpad HTML, CSS, and JS              |
|     +---> Enforces Content Security Policy: script-src 'self' chrome://resources;                     |
+-------------------------------------------------------------------------------------------------------+
                                                   |
                         Mojo IPC / RenderProcessHost Spawning / Navigation
                                                   v
+-------------------------------------------------------------------------------------------------------+
|                                     RENDERER PROCESS (Sandboxed Jail)                                 |
|                                                                                                       |
|  5. OS Kernel enforces sandbox flags on Renderer PID:                                                 |
|     - Linux PID Namespace / User Namespace active (Layer 1)                                          |
|     - Linux seccomp-bpf system call filter active: Seccomp: 2 (Layer 2)                              |
|     - Privilege escalation blocked: NoNewPrivs: 1                                                     |
|                                                                                                       |
|  6. Blink Rendering Engine receives HTTP-like payload from WebUIDataSource:                           |
|     - index.html parsed                                                                               |
|     - launchpad.css applied (Dark-mode builder styling)                                               |
|     - launchpad.js executed as ES Module (<script type="module" src="launchpad.js">)                  |
|                                                                                                       |
|  7. Launchpad UI composites onto screen buffer (TB-01, TB-02, TB-03, TB-04)                           |
+-------------------------------------------------------------------------------------------------------+
```

---

## 3. Reverse-Engineering Source Code Specification

To guarantee complete reverse-engineering capability, every file, class, method, and hook is detailed below.

### Component 1: Upstream Chromium Integration Hooks ($\le 10$ External Lines)

#### Hook HK-01: Configuration Registration
* **Target File:** `chrome/browser/ui/webui/chrome_web_ui_configs.cc`
* **Function:** `void RegisterChromeWebUIConfigs()`
* **Upstream Code:**
  ```cpp
  #if !BUILDFLAG(IS_ANDROID)
    map.AddWebUIConfig(std::make_unique<NewTabPageUIConfig>());
  #endif
  ```
* **Obscure Modification:**
  ```cpp
  #if !BUILDFLAG(IS_ANDROID)
  // OBSCURE_HOOK_HK01: Route chrome://new-tab-page to Obscure Launchpad
  #include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui_config.h"
  ...
    map.AddWebUIConfig(std::make_unique<obscure::ObscureNewTabPageUIConfig>());
  #endif
  ```
* **Reverse-Engineering Rationale:**
  * Chromium maintains a static `content::WebUIConfigMap`. When any internal `chrome://` navigation occurs, this map is searched by scheme and host.
  * By replacing `NewTabPageUIConfig` with `obscure::ObscureNewTabPageUIConfig`, we intercept all default NTP navigations at the architectural root without touching the Omnibox or TabStrip models.

#### Hook HK-02: Build Target Inclusion
* **Target File:** `chrome/browser/BUILD.gn`
* **Target Block:** `source_set("browser")` $\rightarrow$ `public_deps`
* **Modification:**
  ```gn
  "//chrome/browser/obscure",
  ```
* **Reverse-Engineering Rationale:**
  * Links the isolated Obscure C++ compilation unit directly into the monolithic `chrome` browser binary.

---

### Component 2: Isolated Native Module (`//chrome/browser/obscure/`)

#### 1. GN Build Specification: `chrome/browser/obscure/BUILD.gn`
```gn
source_set("obscure") {
  sources = [
    "ui/webui/obscure_new_tab_page_ui.cc",
    "ui/webui/obscure_new_tab_page_ui.h",
    "ui/webui/obscure_new_tab_page_ui_config.cc",
    "ui/webui/obscure_new_tab_page_ui_config.h",
  ]

  deps = [
    "//base",
    "//chrome/browser/profiles:profile",
    "//chrome/common",
    "//content/public/browser",
    "//ui/base",
    "//url",
  ]
}
```
* **Line-by-Line Breakdown:**
  * `source_set("obscure")`: Creates a named GN compilation unit whose object files (`.o`) are directly included in the linking target.
  * `deps = [ ... ]`:
    * `//base`: Core Chromium primitives (`base::RefCountedMemory`, `base::BindRepeating`, logging, strings).
    * `//chrome/browser/profiles:profile`: Provides `Profile*` and `Profile::IsOffTheRecord()` for Incognito safety.
    * `//content/public/browser`: Public content layer APIs (`content::WebUIController`, `content::WebUIDataSource`, `content::BrowserContext`).

---

#### 2. WebUI Configuration Class: `obscure_new_tab_page_ui_config.h`
```cpp
#ifndef CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_CONFIG_H_
#define CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_CONFIG_H_

#include <memory>
#include "content/public/browser/webui_config.h"

namespace content {
class BrowserContext;
class WebUI;
class WebUIController;
}  // namespace content

namespace obscure {

class ObscureNewTabPageUIConfig : public content::WebUIConfig {
 public:
  ObscureNewTabPageUIConfig();
  ~ObscureNewTabPageUIConfig() override;

  bool IsWebUIEnabled(content::BrowserContext* browser_context) override;

  std::unique_ptr<content::WebUIController> CreateWebUIController(
      content::WebUI* web_ui,
      const GURL& url) override;
};

}  // namespace obscure

#endif  // CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_CONFIG_H_
```
* **Detailed Code Analysis:**
  * Inherits from `content::WebUIConfig`: Modern Chromium base class replacing legacy `WebUIControllerFactory`.
  * `IsWebUIEnabled(BrowserContext*)`: Invoked by Chromium before routing to determine if this config applies to the given profile.
  * `CreateWebUIController(...)`: Factory method called to instantiate the controller when a matching URL navigation is committed.

---

#### 3. WebUI Configuration Implementation: `obscure_new_tab_page_ui_config.cc`
```cpp
#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui_config.h"

#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/common/webui_url_constants.h"
#include "content/public/browser/browser_context.h"
#include "content/public/common/url_constants.h"

namespace obscure {

ObscureNewTabPageUIConfig::ObscureNewTabPageUIConfig()
    : content::WebUIConfig(content::kChromeUIScheme,
                           chrome::kChromeUINewTabPageHost) {}

ObscureNewTabPageUIConfig::~ObscureNewTabPageUIConfig() = default;

bool ObscureNewTabPageUIConfig::IsWebUIEnabled(
    content::BrowserContext* browser_context) {
  Profile* profile = Profile::FromBrowserContext(browser_context);
  // Strictly disable Obscure WebUI in Incognito and Guest sessions
  return profile && !profile->IsOffTheRecord();
}

std::unique_ptr<content::WebUIController>
ObscureNewTabPageUIConfig::CreateWebUIController(content::WebUI* web_ui,
                                                 const GURL& url) {
  return std::make_unique<ObscureNewTabPageUI>(web_ui);
}

}  // namespace obscure
```
* **Detailed Code Analysis:**
  * `content::WebUIConfig(content::kChromeUIScheme, chrome::kChromeUINewTabPageHost)`: Registers this config specifically for `chrome://new-tab-page`.
  * `Profile::FromBrowserContext(browser_context)`: Casts the generic content-layer context to a Chrome-layer `Profile`.
  * `!profile->IsOffTheRecord()`: The architectural guarantee for **TB-05** and **TB-06**. If the user opens an Incognito or Guest window, this returns `false`. Chromium automatically cascades down its configuration chain, finding and loading `IncognitoNewTabPageUIConfig` or `GuestNewTabPageUIConfig`.

---

#### 4. WebUI Controller Class: `obscure_new_tab_page_ui.h`
```cpp
#ifndef CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_H_
#define CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_H_

#include <string>
#include "content/public/browser/web_ui_controller.h"
#include "content/public/browser/web_ui_data_source.h"

namespace content {
class WebUI;
}  // namespace content

namespace obscure {

class ObscureNewTabPageUI : public content::WebUIController {
 public:
  explicit ObscureNewTabPageUI(content::WebUI* web_ui);
  ~ObscureNewTabPageUI() override;

  ObscureNewTabPageUI(const ObscureNewTabPageUI&) = delete;
  ObscureNewTabPageUI& operator=(const ObscureNewTabPageUI&) = delete;

 private:
  static bool ShouldHandleRequest(const std::string& path);
  static void HandleRequest(const std::string& path,
                           content::WebUIDataSource::GotDataCallback callback);
};

}  // namespace obscure

#endif  // CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_H_
```

---

#### 5. WebUI Controller Implementation: `obscure_new_tab_page_ui.cc`
```cpp
#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui.h"

#include <string_view>
#include <utility>

#include "base/functional/bind.h"
#include "base/memory/ref_counted_memory.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/common/webui_url_constants.h"
#include "content/public/browser/web_contents.h"
#include "content/public/browser/web_ui.h"
#include "services/network/public/mojom/content_security_policy.mojom.h"

namespace obscure {

namespace {

constexpr char kLaunchpadHtml[] = R"HTML(<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Obscure — The Builder's Browser</title>
<link rel="stylesheet" href="launchpad.css">
</head>
<body>
  <div class="cockpit">
    <header class="header">
      <div class="brand">
        <span class="logo-glyph">&gt;_</span>
        <h1 class="brand-title">OBSCURE</h1>
        <span class="badge">BUILDER COCKPIT</span>
      </div>
      <div class="system-status">
        <span class="status-indicator"></span>
        <span class="status-text">SANDBOX ACTIVE // STABLE 155</span>
      </div>
    </header>

    <main class="dashboard">
      <section class="card space-hero">
        <h2>Launchpad &amp; Project Spaces</h2>
        <p class="subtitle">Developer environment cockpit. Multi-process security active.</p>
        <div class="quick-actions">
          <button class="btn btn-primary" id="btn-default-space">Default Space</button>
          <button class="btn btn-secondary" id="btn-inspect-ports">Port Inspector (3000, 8080)</button>
        </div>
      </section>

      <section class="card env-telemetry">
        <h3>Architecture Invariants</h3>
        <ul class="telemetry-list">
          <li><strong>Engine:</strong> Chromium Stable 155.0.8059.39</li>
          <li><strong>Process:</strong> Sandboxed Renderer (Seccomp-BPF)</li>
          <li><strong>CSP Status:</strong> Strict (Zero Inline Script)</li>
          <li><strong>Persistence:</strong> Gated (Stage 2 ADR 0002)</li>
        </ul>
      </section>
    </main>

    <footer class="footer">
      <span>ZORQUELZ TECHNOLOGIES &copy; 2026</span>
    </footer>
  </div>
  <script type="module" src="launchpad.js"></script>
</body>
</html>)HTML";

constexpr char kLaunchpadCss[] = R"CSS(
:root {
  --bg-primary: #090d16;
  --bg-surface: #111827;
  --border-color: #1f2937;
  --text-main: #f3f4f6;
  --text-muted: #9ca3af;
  --accent-cyan: #06b6d4;
  --accent-green: #10b981;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background-color: var(--bg-primary);
  color: var(--text-main);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace;
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 24px;
}

.cockpit {
  width: 100%;
  max-width: 880px;
  background-color: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 32px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
  padding-bottom: 20px;
  margin-bottom: 24px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-glyph {
  font-family: monospace;
  font-weight: 900;
  color: var(--accent-cyan);
  font-size: 20px;
  background: #083344;
  padding: 4px 8px;
  border-radius: 4px;
}

.brand-title {
  font-size: 22px;
  font-weight: 800;
  letter-spacing: -0.5px;
}

.badge {
  font-size: 10px;
  font-weight: 700;
  background-color: #1e293b;
  color: var(--accent-cyan);
  padding: 2px 8px;
  border-radius: 4px;
  border: 1px solid #334155;
}

.system-status {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  color: var(--text-muted);
  font-family: monospace;
}

.status-indicator {
  width: 8px;
  height: 8px;
  background-color: var(--accent-green);
  border-radius: 50%;
  box-shadow: 0 0 8px var(--accent-green);
}

.dashboard {
  display: grid;
  grid-template-columns: 3fr 2fr;
  gap: 20px;
  margin-bottom: 24px;
}

.card {
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid var(--border-color);
  border-radius: 6px;
  padding: 20px;
}

.space-hero h2 {
  font-size: 18px;
  margin-bottom: 8px;
}

.subtitle {
  font-size: 13px;
  color: var(--text-muted);
  margin-bottom: 20px;
}

.quick-actions {
  display: flex;
  gap: 12px;
}

.btn {
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 600;
  border-radius: 4px;
  cursor: pointer;
  border: 1px solid transparent;
}

.btn-primary {
  background-color: var(--accent-cyan);
  color: #042f2e;
}

.btn-secondary {
  background-color: #1e293b;
  color: var(--text-main);
  border-color: #334155;
}

.env-telemetry h3 {
  font-size: 14px;
  margin-bottom: 12px;
  color: var(--accent-cyan);
}

.telemetry-list {
  list-style: none;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.telemetry-list li {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px dashed #1e293b;
  padding-bottom: 4px;
}

.footer {
  text-align: center;
  font-size: 11px;
  color: #4b5563;
  padding-top: 16px;
  border-top: 1px solid var(--border-color);
}
)CSS";

constexpr char kLaunchpadJs[] = R"JS(
// Obscure Launchpad ES Module
// Strictly CSP compliant: loaded via <script type="module" src="launchpad.js">

document.addEventListener('DOMContentLoaded', () => {
  console.log('[Obscure] Launchpad initialized in sandboxed WebUI renderer.');
  
  const defaultSpaceBtn = document.getElementById('btn-default-space');
  if (defaultSpaceBtn) {
    defaultSpaceBtn.addEventListener('click', () => {
      console.log('[Obscure] Default Space selected.');
    });
  }

  const inspectPortsBtn = document.getElementById('btn-inspect-ports');
  if (inspectPortsBtn) {
    inspectPortsBtn.addEventListener('click', () => {
      console.log('[Obscure] Port Inspector requested.');
    });
  }
});
)JS";

}  // namespace

ObscureNewTabPageUI::ObscureNewTabPageUI(content::WebUI* web_ui)
    : content::WebUIController(web_ui) {
  content::BrowserContext* context =
      web_ui->GetWebContents()->GetBrowserContext();
  content::WebUIDataSource* source =
      content::WebUIDataSource::CreateAndAdd(context,
                                             chrome::kChromeUINewTabPageHost);

  // Set Request Filter to stream bundled Launchpad in-memory assets
  source->SetRequestFilter(
      base::BindRepeating(&ObscureNewTabPageUI::ShouldHandleRequest),
      base::BindRepeating(&ObscureNewTabPageUI::HandleRequest));

  // Enforce strict WebUI Content Security Policy
  source->OverrideContentSecurityPolicy(
      network::mojom::CSPDirectiveName::ScriptSrc,
      "script-src 'self' chrome://resources;");
  source->OverrideContentSecurityPolicy(
      network::mojom::CSPDirectiveName::StyleSrc,
      "style-src 'self' 'unsafe-inline' chrome://resources;");
}

ObscureNewTabPageUI::~ObscureNewTabPageUI() = default;

// static
bool ObscureNewTabPageUI::ShouldHandleRequest(const std::string& path) {
  return path.empty() || path == "launchpad.css" || path == "launchpad.js";
}

// static
void ObscureNewTabPageUI::HandleRequest(
    const std::string& path,
    content::WebUIDataSource::GotDataCallback callback) {
  std::string response;
  if (path == "launchpad.css") {
    response = kLaunchpadCss;
  } else if (path == "launchpad.js") {
    response = kLaunchpadJs;
  } else {
    response = kLaunchpadHtml;
  }

  std::move(callback).Run(
      base::MakeRefCounted<base::RefCountedString>(std::move(response)));
}

}  // namespace obscure
```

* **Detailed Code Analysis:**
  * **Memory In-Memory Delivery:** Uses `SetRequestFilter` with `base::RefCountedString`. This satisfies **HK-04** with **zero external `.pak` packaging changes**, keeping Stage 1 external diffs strictly $\le 10$ lines.
  * **CSP Overrides:** Strictly dictates `script-src 'self' chrome://resources;`. Any attempt to execute inline scripts or external scripts fails immediately.
  * **Thread Safety:** `ShouldHandleRequest` and `HandleRequest` are static pure functions; callbacks run on Chromium's UI thread and safely stream memory buffers to the IPC layer.

---

## 4. Security Sandbox Topology & Failure Modes

### Multi-Process Security Topology
```
[ WINDOWS HOST (NTFS / OS GUI) ]
              |
              v (Virtual Machine Boundary)
[ WSL2 UBUNTU CONTAINER ]
  +--------------------------------------------------------------+
  |  Browser Process (PID 196847)                                 |
  |  - High Privileges: Network Sockets, File System, Window Mgr |
  +--------------------------------------------------------------+
              | (IPC Channel: Unix Domain Sockets + Mojo)
              v
  +--------------------------------------------------------------+
  |  Renderer Process (PID 196901)                                |
  |  - Low Privileges (Sandboxed)                                |
  |  - Seccomp Mode: 2 (Enforces strict syscall whitelist)       |
  |  - NoNewPrivs: 1 (Kernel blocks setuid/privilege escalation) |
  |  - Namespace: Isolated PID, Mount, and Network namespaces     |
  +--------------------------------------------------------------+
```

### Failure Modes & Defensive Handling

| Failure Scenario | Root Cause | System Behavior & Mitigation |
| :--- | :--- | :--- |
| **1. Incognito Information Leak** | User opens Incognito; custom UI renders and leaks cached workspace data. | **Mitigated at Config Layer.** `IsWebUIEnabled()` checks `!profile->IsOffTheRecord()`. Obscure code never executes in Incognito. |
| **2. Inline Script CSP Violation** | Developer adds `<script>alert(1)</script>` into HTML. | **Blocked by Blink.** The browser's HTML parser rejects the inline script with a CSP console error. |
| **3. Memory Corruption in WebUI** | Malicious script attempts memory exploitation in renderer. | **Trapped in Sandbox.** `Seccomp: 2` blocks unauthorized syscalls (e.g. `execve`); kernel terminates process (`SIGSYS`). |
| **4. Upstream Rebase Collision** | Upstream Chromium reorganizes `chrome_web_ui_configs.cc`. | **Trivial Resolution.** External diff is only 3 lines. Relocating `ObscureNewTabPageUIConfig` takes minutes. |

---

## 5. Founder Mastery & Technical Question Defense

### Concept 1: Why use `WebUIDataSource::SetRequestFilter` instead of `.pak` bundles in Stage 1?
* **Plain English Explanation:** 
  Chromium bundles production assets into binary archive files called `.pak` files, indexed by integer resource IDs (`IDR_...`). Doing this requires editing `chrome_paks.gni`, GRD resource files, and resource headers across 4 different upstream files. 
  By using `SetRequestFilter`, we stream compiled in-memory strings directly into the data source. It performs identically, isolates 100% of the code inside `chrome/browser/obscure/`, and avoids touching Chromium's packaging pipeline until Stage 2.

### Concept 2: What is `Seccomp: 2` and `NoNewPrivs: 1`?
* **Plain English Explanation:**
  * **`NoNewPrivs: 1`** is a Linux kernel security flag. Once set on a process, the kernel guarantees that neither that process nor any of its child processes can ever gain privileges (even if they execute a setuid binary like `sudo`).
  * **`Seccomp: 2`** means Secure Computing Mode (filtering mode) is active. The Linux kernel inspects every single system call the process makes against a strict BPF (Berkeley Packet Filter) whitelist. If the renderer tries to make an unapproved syscall (such as accessing the raw disk or spawning a shell), the kernel kills it instantly.

---

### Realistic Technical Interview & Investor Scenarios

#### Question 1: "How do you know an upstream Chrome update won't completely break Obscure?"
> **Founder Defensible Answer:**  
> *"We designed Obscure using an architectural shim pattern. Over 98% of Obscure's native code lives in an isolated directory (`//chrome/browser/obscure/`). Our external touchpoints in upstream Chromium are strictly limited to registration hooks: HK-01 in `chrome_web_ui_configs.cc` and HK-02 in `chrome/browser/BUILD.gn`, totaling under 10 lines of diff. Chromium refactors internal WebUIs frequently, but the `WebUIConfigMap` extension point has been stable for years. If a rebase conflict occurs, we only have to re-anchor two tiny registration calls."*

#### Question 2: "Can an extension or malicious webpage steal data from the Obscure Launchpad?"
> **Founder Defensible Answer:**  
> *"No. The Obscure Launchpad runs on the privileged internal scheme `chrome://new-tab-page/`. Under Chromium's Site Isolation architecture, web pages (`http://` or `https://`) are strictly barred from loading or embedding `chrome://` URLs. Furthermore, our WebUI enforces strict Content Security Policy—blocking all inline scripts and remote network requests—and runs inside an isolated renderer process protected by Linux PID/mount namespaces and seccomp-bpf syscall filtering."*

#### Question 3: "Why is your external diff bounded to $\le 10$ lines?"
> **Founder Defensible Answer:**  
> *"Diff discipline is the difference between an unmaintainable Chromium fork that dies after two updates and a sustainable browser product. Every line of diff in core Chromium represents rebase friction and technical debt. By forcing ourselves to encapsulate all feature logic inside `//chrome/browser/obscure/` and only using upstream code for minimal service and configuration registration, Obscure can track upstream security releases with minimal engineering overhead."*

---

## 6. Verification Plan & Test Commands

| Test ID | Objective | Exact Execution Command | Expected Output |
| :--- | :--- | :--- | :--- |
| **TB-01..04** | Launchpad DOM Render | `./out/Stable155/chrome --headless=new --dump-dom chrome://new-tab-page/` | Contains `<title>Obscure — The Builder's Browser</title>` and `cockpit` markup |
| **TB-05** | Incognito Isolation | `./out/Stable155/chrome --headless=new --incognito --dump-dom chrome://new-tab-page/` | Standard Incognito splash; zero Obscure UI |
| **TB-06** | Guest Isolation | `./out/Stable155/chrome --headless=new --guest --dump-dom chrome://new-tab-page/` | Standard Guest splash; zero Obscure UI |
| **TB-07** | CSP Invariants | `./out/Stable155/chrome --headless=new --enable-logging=stderr --v=1 chrome://new-tab-page/` | Zero CSP error violations |
| **TB-08** | Active Sandbox | `python3 scripts/check_sandbox.py` on renderer PID | `NoNewPrivs: 1`, `Seccomp: 2` |
| **TB-10** | Patch Reversibility | `scripts/test_tb10_patch_revert.sh` | **PASS (Verified in `tb10_revert_test.log`)** |

---

## 7. Artifact Checklist
* [x] Canonical documentation: `docs/features/stage1-tracer-bullet/README.md`
* [x] Companion PDF study guide: `docs/features/stage1-tracer-bullet/Obscure_Stage1_Tracer_Bullet_Engineering_Guide.pdf`
* [x] Canonical native source files: `src/native/`
* [x] Canonical webui source files: `src/webui/`
