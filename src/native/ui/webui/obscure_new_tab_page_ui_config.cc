// Copyright 2026 Zorquelz Technologies. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui_config.h"

#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/common/webui_url_constants.h"
#include "content/public/browser/browser_context.h"
#include "content/public/browser/web_ui.h"
#include "content/public/browser/web_ui_controller.h"
#include "content/public/common/url_constants.h"
#include "url/gurl.h"

namespace obscure {

ObscureNewTabPageUIConfig::ObscureNewTabPageUIConfig()
    : content::WebUIConfig(content::kChromeUIScheme,
                           chrome::kChromeUINewTabPageHost) {}

ObscureNewTabPageUIConfig::~ObscureNewTabPageUIConfig() = default;

bool ObscureNewTabPageUIConfig::IsWebUIEnabled(
    content::BrowserContext* browser_context) {
  Profile* profile = Profile::FromBrowserContext(browser_context);
  // Strict Privacy Isolation: Disable Obscure Launchpad in Incognito and Guest
  // profiles. This ensures standard Chromium Incognito/Guest screens render (TB-05, TB-06).
  return profile && !profile->IsOffTheRecord();
}

std::unique_ptr<content::WebUIController>
ObscureNewTabPageUIConfig::CreateWebUIController(content::WebUI* web_ui,
                                                 const GURL& url) {
  return std::make_unique<ObscureNewTabPageUI>(web_ui);
}

}  // namespace obscure
