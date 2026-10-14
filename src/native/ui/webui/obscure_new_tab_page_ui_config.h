// Copyright 2026 Zorquelz Technologies. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_CONFIG_H_
#define CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_CONFIG_H_

#include <memory>

#include "content/public/browser/webui_config.h"

namespace content {
class BrowserContext;
class WebUI;
class WebUIController;
}  // namespace content

class GURL;

namespace obscure {

// WebUIConfig implementation for Obscure Launchpad.
// Registers on chrome::kChromeUINewTabPageHost ("new-tab-page").
class ObscureNewTabPageUIConfig : public content::WebUIConfig {
 public:
  ObscureNewTabPageUIConfig();
  ~ObscureNewTabPageUIConfig() override;

  ObscureNewTabPageUIConfig(const ObscureNewTabPageUIConfig&) = delete;
  ObscureNewTabPageUIConfig& operator=(const ObscureNewTabPageUIConfig&) = delete;

  // WebUIConfig implementation:
  // Returns false in Incognito and Guest profiles to enforce privacy isolation
  // and trigger upstream fallback (TB-05, TB-06).
  bool IsWebUIEnabled(content::BrowserContext* browser_context) override;

  std::unique_ptr<content::WebUIController> CreateWebUIController(
      content::WebUI* web_ui,
      const GURL& url) override;
};

}  // namespace obscure

#endif  // CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_CONFIG_H_
