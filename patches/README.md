# Patches Directory

This directory stores unified `.patch` / `.diff` files generated against upstream Chromium.

## Conventions
- Patches must be named sequentially with clear intent:
  - `0001-add-obscure-branding-constants.patch`
  - `0002-register-obscure-webui-datasource.patch`
- Every patch must be testable via `git apply --check <patch_file>`.
- Revert command for any applied patch:
  `git apply -R <patch_file>`
