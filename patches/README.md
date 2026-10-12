# Patches Directory
**Zorquelz Technologies | Upstream Patch Series**

This directory stores per-commit `.patch` files generated via `git format-patch` against the pinned baseline tag `obscure-baseline-155.0.8059.39` (`3ff7ac5a9224be9156d7f8703a06e22890aafd34`).

## Conventions
- Patches are generated per-commit using:
  `git format-patch obscure-baseline-155.0.8059.39..HEAD -o /mnt/f/Zorquelz/Obscure/patches/`
- Each patch retains author metadata, commit timestamps, and atomic commit messages:
  - `0001-scaffold-isolated-obscure-browser-module.patch`
  - `0002-register-obscure-webui-configs-and-hooks.patch`
- Verification command on fresh checkout:
  `git apply --check patches/*.patch`
- Application command:
  `git am --signoff patches/*.patch`
- Clean rollback command:
  `git am --abort` or `git reset --hard obscure-baseline-155.0.8059.39`
