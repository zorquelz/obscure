// Copyright 2026 Zorquelz Technologies. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_H_
#define CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_H_

#include <string>

#include "content/public/browser/web_ui_controller.h"
#include "content/public/browser/web_ui_data_source.h"

namespace content {
class WebUI;
}  // namespace content

namespace obscure {

// WebUIController for Obscure Launchpad.
// Manages the lifecycle of chrome://new-tab-page and configures
// the in-memory WebUIDataSource and Content Security Policy.
class ObscureNewTabPageUI : public content::WebUIController {
 public:
  explicit ObscureNewTabPageUI(content::WebUI* web_ui);
  ~ObscureNewTabPageUI() override;

  ObscureNewTabPageUI(const ObscureNewTabPageUI&) = delete;
  ObscureNewTabPageUI& operator=(const ObscureNewTabPageUI&) = delete;

 private:
  // Request filter callbacks to serve in-memory HTML, CSS, and JS
  // without modifying external .pak packaging files (HK-04).
  static bool ShouldHandleRequest(const std::string& path);
  static void HandleRequest(const std::string& path,
                           content::WebUIDataSource::GotDataCallback callback);
};

}  // namespace obscure

#endif  // CHROME_BROWSER_OBSCURE_UI_WEBUI_OBSCURE_NEW_TAB_PAGE_UI_H_
