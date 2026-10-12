# Scripts Directory
**Zorquelz Technologies | Build & QA Tooling**

Utility scripts for building, inspecting, testing, and packaging Obscure.

## Active Scripts
- `check_sandbox.py` — Automated live kernel sandbox inspector. Spawns sandboxed Chromium, discovers child renderer PIDs, and captures `/proc/<pid>/status` (`NoNewPrivs`, `Seccomp`) and `/proc/<pid>/ns/` (User & PID namespace isolation) without requiring `--no-sandbox`.

## Planned Scripts
- `export_patches.sh` — Exports per-commit patch series from the local Chromium branch to `patches/` via `git format-patch`.
- `apply_patches.sh` — Verifies and applies all patch series in `patches/` to a clean Chromium checkout via `git am`.
- `build_obscure.sh` — Invokes Ninja compilation with standard Obscure flags (`out/Stable155`).
