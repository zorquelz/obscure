# Obscure Native C++ Shim Sources
**Zorquelz Technologies | Engineering & Implementation**

## Architecture & Source Organization

This directory contains the canonical Obscure-specific C++ classes and GN definitions designed to build inside the Chromium source tree under `//chrome/browser/obscure/`.

### Source Synchronization Mechanism (No Symlinks)
Cross-filesystem symlinks between the Windows host (NTFS) and the WSL2 Linux environment (`~/Obscure/chromium/src`) are strictly avoided due to filesystem boundary issues, Git index corruptions, and Ninja dependency tracking risks.

Instead, the source flow is managed deterministically:
1. **Canonical Source Storage:** Canonical source files are maintained under `src/native/` in this Obscure control repository.
2. **Chromium Tree Placement:** Files are synchronized into `chrome/browser/obscure/` inside the Chromium checkout via `scripts/sync_sources.py` or applied as clean Git commits on the `obscure-stable-155` branch.
3. **Review & Audit Pipeline:** Changes in the Chromium tree are exported using `git format-patch` into `patches/` for independent QA review by Claude.

---

## Planned Native Components

| Component File | Role / Responsibility | Enclosing Namespace |
|---|---|---|
| `BUILD.gn` | Declares `source_set("obscure")` and `test("unit_tests")` additions | N/A |
| `obscure_workspace_service.h/.cc` | Core workspace state management, JSON serialization, 10 MB file cap, off-UI-thread debounced writes, and `.bak` recovery | `obscure::` |
| `obscure_workspace_service_factory.h/.cc` | KeyedService factory attaching service to Profile lifecycle via `PreProfileInit()`; returns `nullptr` in Incognito/Guest | `obscure::` |
| `ui/webui/obscure_new_tab_page_ui.h/.cc` | WebUI controller serving Launchpad assets and binding Mojo IPC | `obscure::` |
| `ui/webui/obscure_new_tab_page_ui_config.h/.cc` | `WebUIConfig` implementation registered on `chrome::kChromeUINewTabPageHost` | `obscure::` |
| `mojom/obscure_spaces.mojom` | Strongly typed Mojo IPC interface definition connecting WebUI renderer to browser process | `obscure::mojom` |
| `obscure_workspace_service_unittest.cc` | Comprehensive unit tests for serialization, corruption recovery, and scheme validation | `obscure::` |
