# HOOKS.md — Chromium External Integration Points
**Zorquelz Technologies | Obscure Browser Engineering**

> This document catalogs every file and code location outside `//chrome/browser/obscure/` that Obscure modifies or extends. 
> To minimize merge conflicts during upstream rebases, modifications outside our isolated module directory are strictly limited to necessary registration hooks.

---

## Catalog of External Hooks

| Hook ID | Target File in Chromium Tree | Purpose / Responsibility | Estimated Diff Size | Rebase / Churn Risk | Mitigation & Design |
|---|---|---|---|---|---|
| **HK-01** | `chrome/browser/ui/webui/chrome_web_ui_configs.cc` | Register `ObscureNewTabPageUIConfig` in `RegisterChromeWebUIConfigs()` (substituting default `NewTabPageUIConfig`) | ~3 lines (1 include, 2 lines in registration) | **Low** | Placed in alphabetical order among standard WebUI registrations. |
| **HK-02** | `chrome/browser/BUILD.gn` | Add `"//chrome/browser/obscure"` to dependencies of target `"browser"` | ~2 lines | **Low** | Added cleanly to the `deps` block of the main browser library. |
| **HK-03** | `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc` | Initialize `ObscureWorkspaceServiceFactory::GetInstance()` inside `EnsureBrowserContextKeyedServiceFactoriesBuilt()` | ~3 lines (1 include, 2 lines in factory list) | **Low** | Appended to the keyed service initialization list where new services are standard. |
| **HK-04** | `chrome/common/webui_url_constants.h` *(Optional / Conditional)* | Define custom URL constants (`kChromeUIObscureSettingsURL`, etc.) if needed beyond default NTP override | ~4 lines | **Low** | Only used if dedicated custom scheme hosts are registered outside the NTP host. |

---

## Detailed Analysis of Each Integration Point

### HK-01: WebUI Configuration Registration
- **File:** `chrome/browser/ui/webui/chrome_web_ui_configs.cc`
- **Location:** Inside `void RegisterChromeWebUIConfigs()` (around line 267–340).
- **Modification:**
  ```cpp
  #include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui.h"
  // ...
  // Replace:
  // map.AddWebUIConfig(std::make_unique<NewTabPageUIConfig>());
  // With:
  map.AddWebUIConfig(std::make_unique<obscure::ObscureNewTabPageUIConfig>());
  ```
- **Rationale:** Substitutes Obscure's New Tab UI directly on `chrome::kChromeUINewTabPageHost`. Avoids invasive patching of `chrome/browser/search/search.cc` (`HandleNewTabURLRewrite`).

### HK-02: Build Target Dependency
- **File:** `chrome/browser/BUILD.gn`
- **Location:** Inside `split_static_library("browser")` or `source_set("browser")` `deps = [ ... ]`.
- **Modification:**
  ```gn
  deps += [
    "//chrome/browser/obscure",
  ]
  ```
- **Rationale:** Ensures ninja compiles and links the Obscure C++ shim module into the browser binary.

### HK-03: Keyed Service Lifecycle Attachment
- **File:** `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc`
- **Location:** Inside `ChromeBrowserMainExtraPartsProfiles::EnsureBrowserContextKeyedServiceFactoriesBuilt()`.
- **Modification:**
  ```cpp
  #include "chrome/browser/obscure/obscure_workspace_service_factory.h"
  // ...
  obscure::ObscureWorkspaceServiceFactory::GetInstance();
  ```
- **Rationale:** Connects `ObscureWorkspaceService` to the active `Profile` lifecycle so it initializes cleanly and shuts down cleanly with each user profile.

---

## Strict Rule on External Hooks
No developer or AI agent may add changes to any other file outside `//chrome/browser/obscure/` without first:
1. Documenting the file, rationale, and exact proposed diff here in `HOOKS.md`.
2. Providing a reviewable unified patch to the Review & QA Lead (Claude).
3. Receiving explicit approval.
