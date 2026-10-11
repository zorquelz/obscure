# HOOKS.md — Chromium External Integration Points
**Zorquelz Technologies | Obscure Browser Engineering**
**Baseline:** Chromium Stable `155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`)

> This document catalogs every file and code location outside `//chrome/browser/obscure/` that Obscure modifies or extends. 
> To minimize merge conflicts during upstream rebases, modifications outside our isolated module directory are strictly limited to necessary registration hooks.

---

## Catalog of External Hooks (Re-Derived on Stable 155)

| Hook ID | Target File in Chromium Tree | Line in Stable 155 | Purpose / Responsibility | Estimated Diff Size | Rebase / Churn Risk |
|---|---|---|---|---|---|
| **HK-01** | `chrome/browser/ui/webui/chrome_web_ui_configs.cc` | Line 333 | Register `ObscureNewTabPageUIConfig` in `RegisterChromeWebUIConfigs()` (substituting default `NewTabPageUIConfig` on `chrome::kChromeUINewTabPageHost`) | ~3 lines | **Low** |
| **HK-02** | `chrome/browser/BUILD.gn` | Lines 1077–1085 | Add `"//chrome/browser/obscure"` to the dependencies of the main browser library target (`source_set("browser")`) | ~2 lines | **Low** |
| **HK-03** | `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc` | Lines 1605–1610 | Initialize `ObscureWorkspaceServiceFactory::GetInstance()` inside `EnsureBrowserContextKeyedServiceFactoriesBuilt()` | ~3 lines | **Low** |
| **HK-04** | `chrome/browser/resources/BUILD.gn` or WebUIDataSource | Component resource mapping | WebUI Resource Packaging: Serve bundled HTML, CSS, and TS assets to the renderer via `content::WebUIDataSource` | ~5 lines | **Low** |

---

## Detailed Evidence & Implementation for Each Hook

### HK-01: WebUI Configuration Registration
- **File:** `chrome/browser/ui/webui/chrome_web_ui_configs.cc`
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
- **Rationale:** Substitutes Obscure's New Tab UI directly on `chrome::kChromeUINewTabPageHost` ("new-tab-page"). Avoids invasive patching of `chrome/browser/search/search.cc` (`HandleNewTabURLRewrite`).

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
- **Rationale:** Links the isolated static library / source set defined in `//chrome/browser/obscure/BUILD.gn` directly into the Chromium browser binary.

### HK-03: Keyed Service Lifecycle Attachment
- **File:** `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc`
- **Verified Code Context (Lines 1605–1610 on Stable 155):**
  ```cpp
  WebDataServiceFactory::GetInstance();
  webrtc_event_logging::WebRtcEventLogManagerKeyedServiceFactory::GetInstance();
  }
  ```
- **Modification:**
  ```cpp
  #include "chrome/browser/obscure/obscure_workspace_service_factory.h"
  // ...
  obscure::ObscureWorkspaceServiceFactory::GetInstance();
  ```
- **Rationale:** Connects `ObscureWorkspaceService` to the active `Profile` lifecycle so it initializes cleanly and shuts down cleanly with each user profile.

### HK-04: WebUI Resource Packaging
- **Options Evaluated:**
  1. *Option A (In-binary string bundle for Tracer Bullet / MVP):* Embed the HTML/CSS/JS payload directly in C++ string literals or simple file reader in `ObscureNewTabPageUI::CreateDataSource()`. Zero GN touchpoints outside `//chrome/browser/obscure/`.
  2. *Option B (GN `build_webui` rule):* Use `//ui/webui/resources/tools/build_webui.gni` inside `//chrome/browser/obscure/resources/BUILD.gn` to emit a `.pak` file, and declare it in `chrome/chrome_paks.gni`.
- **Recommendation:** **Option A** for the initial tracer bullet (zero external packaging hooks); transition to **Option B** when the full TypeScript interface is locked.

---

## New Tab Behavior Test Matrix

To verify that HK-01 operates correctly across all user entry points:

| Case ID | User Action | Expected Navigation URL | Target Controller | Incognito / Normal Guard |
|---|---|---|---|---|
| **NTP-01** | Click "+" button on tab strip | `chrome://new-tab-page/` | `ObscureNewTabPageUI` | Normal profile only |
| **NTP-02** | Keyboard shortcut `Ctrl+T` | `chrome://new-tab-page/` | `ObscureNewTabPageUI` | Normal profile only |
| **NTP-03** | New Window (`Ctrl+N`) | `chrome://new-tab-page/` | `ObscureNewTabPageUI` | Normal profile only |
| **NTP-04** | Incognito Window (`Ctrl+Shift+N`) | `chrome://new-tab-page/` | `IncognitoNewTabPageUI` | **Must NOT** load Obscure Spaces in Incognito |
| **NTP-05** | Direct Omnibox `chrome://newtab` | Rewrites to `chrome://new-tab-page/` | `ObscureNewTabPageUI` | Normal profile only |
| **NTP-06** | Direct Omnibox `chrome://new-tab-page` | `chrome://new-tab-page/` | `ObscureNewTabPageUI` | Normal profile only |
