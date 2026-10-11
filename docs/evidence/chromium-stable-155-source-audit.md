# Chromium Stable 155 Source Tree Evidence & Audit Report
**Zorquelz Technologies | Engineering & Implementation Lead (Antigravity)**  
**Date:** October 11, 2026  
**Target Repository:** `~/Obscure/chromium/src` (WSL2 `Obscure-Ubuntu`)

---

## 1. Stable Baseline Identification & Git Verification

Following CEO and Chief Architect directives, the project baseline has transitioned from pre-stable trunk to official **Chromium Stable**.

### Official Upstream Release Information
- **Release Channel:** Desktop Stable Channel (Linux, Windows, macOS)
- **Official Announcement Date:** October 6, 2026 ([Chrome Releases Blog](https://chromereleases.googleblog.com))
- **Release Version:** **`155.0.8059.39`**
- **Security Scope:** Includes 247 security fixes and upstream stability patches.

### Git Tag & Commit Verification (Executed in Checkout)
```bash
$ cd ~/Obscure/chromium/src
$ git fetch origin tag 155.0.8059.39
From https://chromium.googlesource.com/chromium/src
 * [new tag] 155.0.8059.39 -> 155.0.8059.39

$ git rev-parse 155.0.8059.39
3ff7ac5a9224be9156d7f8703a06e22890aafd34

$ git log -n 1 --oneline 155.0.8059.39
3ff7ac5a9224b Incrementing VERSION to 155.0.8059.39
```

### Version File (`chrome/VERSION`)
```ini
MAJOR=155
MINOR=0
BUILD=8059
PATCH=39
```

---

## 2. Security Maintenance Policy (14-Day SLA)
- **Policy:** Public Obscure targets shipping a verified security rebase build within **14 calendar days** of any applicable upstream Stable security release.
- **Workflow:**
  1. Monitor Chrome Releases RSS / security notices.
  2. Fetch new Stable tag (`git fetch origin tag <version>`).
  3. Rebase `obscure-stable-155` onto `<version>` and record conflict count.
  4. Run automated test suite (`TP-01` to `TP-05` and `0002-spaces-resilience`).
  5. Submit unified diff for Claude's QA audit and CEO sign-off before publishing.

---

## 3. Re-Derived Hooks in Stable 155 (Exact Line Evidence)

Every hook was re-verified against commit `3ff7ac5a9224be9156d7f8703a06e22890aafd34`:

### HK-01: WebUI Configuration Map Registration
- **File:** `chrome/browser/ui/webui/chrome_web_ui_configs.cc`
- **Line 248:** `void RegisterChromeWebUIConfigs()`
- **Line 333 (Target Replacement):**
  ```cpp
  map.AddWebUIConfig(std::make_unique<NewTabPageUIConfig>());
  ```
- **Line 462:** `map.AddWebUIConfig(std::make_unique<SandboxInternalsUIConfig>());`

### HK-02: Browser Target Dependencies
- **File:** `chrome/browser/BUILD.gn`
- **Lines 1077–1085:**
  ```gn
  "//chrome/browser/ui/webui/bluetooth_internals",
  "//chrome/browser/ui/webui/bluetooth_internals:mojo_bindings",
  "//chrome/browser/ui/webui/chrome_urls",
  "//chrome/browser/ui/webui/connectors_internals",
  ```
  *(Target integration point for `"//chrome/browser/obscure"`)*.

### HK-03: Keyed Service Factory Initialization
- **File:** `chrome/browser/profiles/chrome_browser_main_extra_parts_profiles.cc`
- **Lines 1605–1610:**
  ```cpp
  WebDataServiceFactory::GetInstance();
  webrtc_event_logging::WebRtcEventLogManagerKeyedServiceFactory::GetInstance();
  }
  ```
  *(Target integration point for `obscure::ObscureWorkspaceServiceFactory::GetInstance()`)*.

---

## 4. Build System & Toolchain Status on Stable 155

| Verification Step | Command | Result | Status |
|---|---|---|---|
| Checkout Tag | `git checkout -b obscure-stable-155 tags/155.0.8059.39` | Created branch on `3ff7ac5a9224be` | **VERIFIED** |
| Version Check | `cat chrome/VERSION` | `155.0.8059.39` | **VERIFIED** |
| GN Config Generation | `gn gen out/Obscure` | Completed with 0 errors | **VERIFIED** |
| Full 56,000-Step Compilation | `autoninja -C out/Obscure chrome` | Full rebuild from 155 not yet executed (~1.5h build cycle) | **PLANNED / PENDING** |
| Sandbox GUI Launch on 155 | `./out/Obscure/chrome https://zorquelz.com` | Verified on previous 157 build; pending full 155 build | **PLANNED / PENDING** |

*Honesty Note:* In accordance with our core engineering rules, we do NOT claim that a full compilation of `155.0.8059.39` has completed. The checkout switch and GN generation are verified; full compilation is queued.
