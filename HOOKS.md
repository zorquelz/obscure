# HOOKS.md — Chromium External Integration Points
**Zorquelz Technologies | Obscure Browser Engineering**
**Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)

> This document catalogs every file and code location outside `//chrome/browser/obscure/` that Obscure modifies or extends. 
> To minimize merge conflicts during upstream rebases, modifications outside our isolated module directory are strictly limited to necessary registration hooks.

---

## Catalog of External Hooks (Re-Derived on Stable 155)

| Hook ID | Target File in Chromium Tree | Line Range in Stable 155 | Purpose / Responsibility | Estimated Diff Size | Rebase / Churn Risk |
|---|---|---|---|---|---|
| **HK-01** | `chrome/browser/ui/webui/chrome_web_ui_configs.cc` | Line 333 (within `RegisterChromeWebUIConfigs()`) | Register `ObscureNewTabPageUIConfig` (substituting default `NewTabPageUIConfig` on `chrome::kChromeUINewTabPageHost`) | ~3 lines | **Medium** |
| **HK-02** | `chrome/browser/BUILD.gn` | Lines 1077–1085 (within `source_set("browser")`) | Add `"//chrome/browser/obscure"` to browser library dependencies | ~2 lines | **Low** |
| **HK-03** | `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc` | Lines 689–692 (signature)<br>Lines 1605–1614 (hook site) | Initialize `ObscureWorkspaceServiceFactory::GetInstance()` inside `EnsureBrowserContextKeyedServiceFactoriesBuilt()` | ~3 lines | **Low** |
| **HK-04** | `chrome/chrome_paks.gni` *(Production only; 0 touchpoints for Tracer Bullet)* | Paks bundle definitions block | Add Obscure WebUI `.pak` bundle to browser resources packaging (Production phase) | ~4 lines | **Low** |
| **HK-05** | `chrome/test/BUILD.gn` | Line 520 (within `test("unit_tests")` deps) | Link `"//chrome/browser/obscure:unit_tests"` into the main unit test suite | ~2 lines | **Low** |

---

## Detailed Evidence & Implementation for Each Hook

### HK-01: WebUI Configuration Registration
- **File:** `chrome/browser/ui/webui/chrome_web_ui_configs.cc`
- **Enclosing Function:** `void RegisterChromeWebUIConfigs()` (begins at line 248)
- **Verified Code Context (Line 333 on Stable 155):**
  ```cpp
  map.AddWebUIConfig(std::make_unique<NewTabPageUIConfig>());
  ```
- **Replacement:**
  ```cpp
  #include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui.h"
  // ...
  map.AddWebUIConfig(std::make_unique<obscure::ObscureNewTabPageUIConfig>());
  ```
- **Churn Rating Rationale:** **Medium**. While the replacement is a single-line substitution, `chrome_web_ui_configs.cc` has regular upstream activity across Chromium milestone updates as internal WebUIs are added, refactored, or guarded behind feature flags. Rebase conflicts are straightforward to resolve by re-locating `NewTabPageUIConfig` in the registration sequence.

---

### HK-02: Browser Build Target Dependency
- **File:** `chrome/browser/BUILD.gn`
- **Verified Code Context (Lines 1077–1085 on Stable 155):**
  ```gn
  "//chrome/browser/ui/webui/bluetooth_internals",
  "//chrome/browser/ui/webui/bluetooth_internals:mojo_bindings",
  "//chrome/browser/ui/webui/chrome_urls",
  "//chrome/browser/ui/webui/connectors_internals",
  ```
- **Modification:**
  ```gn
  "//chrome/browser/obscure",
  ```
- **Churn Rating Rationale:** **Low**. Appends a single dependency into the public `source_set("browser")` deps list. Upstream rarely removes or alters neighboring stable UI dependencies.

---

### HK-03: Keyed Service Lifecycle Attachment
- **File:** `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc`
- **Verified Full Function Signature (Lines 689–692 on Stable 155):**
  ```cpp
  // static
  void ChromeBrowserMainExtraPartsProfiles::
      EnsureBrowserContextKeyedServiceFactoriesBuilt() {
  ```
- **Verified Hook Site (Lines 1605–1610 on Stable 155):**
  ```cpp
    WebDataServiceFactory::GetInstance();
    webrtc_event_logging::WebRtcEventLogManagerKeyedServiceFactory::GetInstance();
  }
  ```
- **Enclosing Lifecycle Hook (Lines 1612–1614 on Stable 155):**
  ```cpp
  void ChromeBrowserMainExtraPartsProfiles::PreProfileInit() {
    EnsureBrowserContextKeyedServiceFactoriesBuilt();
  }
  ```
- **Modification:**
  ```cpp
  #include "chrome/browser/obscure/obscure_workspace_service_factory.h"
  // ...
    obscure::ObscureWorkspaceServiceFactory::GetInstance();
  ```
- **Rationale:** Guarantees that `ObscureWorkspaceServiceFactory` is registered during `PreProfileInit` before any `Profile` instance is constructed.
- **Churn Rating Rationale:** **Low**. The closing block of `EnsureBrowserContextKeyedServiceFactoriesBuilt()` is an established pattern where hundreds of factories are statically instantiated.

---

### HK-04: WebUI Resource Packaging, API Invariants & CSP Policy
- **Packaging Architecture & Zero-Touchpoint Tracer Bullet:**
  - **Stage 1 (Tracer Bullet):** Requires **zero external touchpoints**. Assets are compiled directly into isolated C++ files under `//chrome/browser/obscure/ui/webui/`.
  - **Accurate `content::WebUIDataSource` API Methods:**
    - `content::WebUIDataSource::AddString()` is strictly reserved for **i18n string placeholders** (e.g., passing `$i18n{title}` keys to the template).
    - To serve raw document assets (HTML, CSS, JS), `content::WebUIDataSource` uses `source->SetDefaultResource(resource_id)` or `source->AddResourcePath("launchpad.js", resource_id)`.
    - For dynamically served in-memory strings, `content::WebUIDataSource` utilizes `base::RefCountedString` via `source->AddResourcePath("launchpad.js", base::MakeRefCounted<base::RefCountedString>(std::move(payload)))` or `source->SetRequestFilter()`.
  - **Strict Content Security Policy (CSP) Invariants:**
    - Chromium WebUI enforces strict CSP by default. In accordance with Chromium security standards:
      1. **No `unsafe-eval`:** Dynamic code execution (`eval()`, `new Function()`) is strictly prohibited.
      2. **No Inline Scripts:** `<script>` tags embedded inline in HTML violate default WebUI CSP (`script-src 'self' chrome://resources;`). All logic must reside in a separate JavaScript module (`launchpad.js`) loaded via `<script type="module" src="launchpad.js"></script>`.
      3. **No External Network Dependencies:** Zero CDN links, external Google Fonts, or remote styles. All CSS and fonts must be bundled locally within the WebUI data source.
      4. **Trusted Types:** WebUI pages must avoid unsafe DOM sinks and use `textContent` exclusively for all dynamic string insertions.
  - **Runtime Filesystem Read Ban:** Ad-hoc reading of raw HTML/JS files from disk at runtime is strictly prohibited in shipping browser binaries (incompatible with release packaging, sandbox restrictions, and security models).
  - **Stage 2 (Production Packaging):** Packaged via `//chrome/browser/obscure/resources/BUILD.gn` using `build_webui()` into `obscure_resources.pak`, with the single external touchpoint declared in `chrome/chrome_paks.gni`.
- **Churn Rating Rationale:** **Low**.

---

### HK-05: Unit Test Target Integration
- **File:** `chrome/test/BUILD.gn`
- **Verified Code Context (Line 520 on Stable 155):**
  Within the `test("unit_tests")` target `deps` block:
  ```gn
  "//chrome/browser",
  "//chrome/browser/ui",
  ```
- **Modification:**
  ```gn
  "//chrome/browser/obscure:unit_tests",
  ```
- **Rationale:** Ensures that `ObscureWorkspaceService` unit tests run automatically as part of Chromium's `autoninja -C out/... unit_tests`.
- **Churn Rating Rationale:** **Low**.

---

## New Tab Behavior Test Matrix

To verify that HK-01 operates correctly across all user entry points, search engine choices, profile configurations, and window states:

| Case ID | Profile / Window Context | User Action / Trigger | Default Search Engine | Expected Target Controller | Expected UI Result | Incognito / Guest Privacy Guard |
|---|---|---|---|---|---|---|
| **NTP-01** | Normal Profile | Click "+" button on tab strip | Google (Default) | `ObscureNewTabPageUI` | Obscure Launchpad renders | Normal profile |
| **NTP-02** | Normal Profile | Keyboard shortcut `Ctrl+T` | Google (Default) | `ObscureNewTabPageUI` | Obscure Launchpad renders | Normal profile |
| **NTP-03** | Normal Profile | New Window (`Ctrl+N`) | Google (Default) | `ObscureNewTabPageUI` | Obscure Launchpad renders | Normal profile |
| **NTP-04** | Incognito Profile | New Incognito Tab / Window (`Ctrl+Shift+N`) | Any | `IncognitoNewTabPageUI` | Standard Incognito splash | **Must NOT** load Obscure Spaces or UI |
| **NTP-05** | Guest Profile | Guest Window New Tab | Any | `GuestNewTabPageUI` | Standard Guest splash | **Must NOT** load Obscure Spaces or UI |
| **NTP-06** | Normal Profile | Tab opened with third-party search engine | DuckDuckGo / Bing / Brave | `ObscureNewTabPageUI` | Obscure Launchpad renders (not overridden by search provider NTP) | Normal profile |
| **NTP-07** | Normal Profile | Direct Omnibox `chrome://newtab` | Any | URL rewritten to `chrome://new-tab-page/` | Obscure Launchpad renders | Normal profile |
| **NTP-08** | Normal Profile | Direct Omnibox `chrome://new-tab-page/` | Any | `ObscureNewTabPageUI` | Obscure Launchpad renders | Normal profile |
| **NTP-09** | Normal Profile | Browser Startup with "Open the New Tab page" setting | Any | `ObscureNewTabPageUI` | Obscure Launchpad renders on startup | Normal profile |
| **NTP-10** | Normal Profile | Browser Startup with "Continue where you left off" | Any | Session Restore Controller | Restores prior tabs; active space tabs shown, inactive stashed | Normal profile |
