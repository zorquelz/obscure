// Copyright 2026 Zorquelz Technologies. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "chrome/browser/obscure/ui/webui/obscure_new_tab_page_ui.h"

#include <string_view>
#include <utility>

#include "base/functional/bind.h"
#include "base/memory/ref_counted_memory.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/common/webui_url_constants.h"
#include "content/public/browser/browser_context.h"
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
