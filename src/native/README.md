# Obscure Native C++ Shim Sources

This directory contains Obscure-specific C++ classes designed to be symlinked or copied into `//chrome/browser/obscure/` inside the Chromium source tree.

## Planned Components
- `obscure_workspace_service.h/.cc` — Manages reading, writing, and manipulating workspace JSON state.
- `obscure_webui_controller.h/.cc` — Connects Chromium's IPC/Mojo to Obscure WebUI frontends.
