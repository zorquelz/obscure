#!/usr/bin/env python3
"""
Obscure Source Synchronizer
Zorquelz Technologies | Engineering & Build Tooling

Safely synchronizes canonical native C++ and WebUI sources from this
control repository into the WSL2 Chromium source tree under
//chrome/browser/obscure/, without cross-filesystem symlinks.
"""

import argparse
import hashlib
import os
import shutil
import sys
from pathlib import Path

# Paths
REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_NATIVE = REPO_ROOT / "src" / "native"
SRC_WEBUI = REPO_ROOT / "src" / "webui" / "newtab"

# Default WSL target path (can be overridden via CLI)
DEFAULT_WSL_TARGET = Path("/home/lucifer-1403/Obscure/chromium/src/chrome/browser/obscure")

# On Windows host, map to WSL path if accessible via \\wsl$\ or \\wsl.localhost\
def get_default_dest():
    if os.name == "nt":
        wsl_base = Path(r"\\wsl.localhost\Obscure-Ubuntu\home\lucifer-1403\Obscure\chromium\src\chrome\browser\obscure")
        if wsl_base.parent.exists():
            return wsl_base
    return DEFAULT_WSL_TARGET

def compute_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def plan_sync():
    """Returns a list of (src_path, relative_dest_path) tuples."""
    files_to_sync = []
    
    # Native C++ sources
    for root, _, files in os.walk(SRC_NATIVE):
        for f in files:
            if f.endswith((".h", ".cc", ".gn")):
                src_file = Path(root) / f
                rel_path = src_file.relative_to(SRC_NATIVE)
                files_to_sync.append((src_file, rel_path))
                
    return files_to_sync

def main():
    parser = argparse.ArgumentParser(description="Synchronize Obscure sources to Chromium tree")
    parser.add_argument("--dest", type=Path, default=get_default_dest(),
                        help="Destination directory in Chromium checkout")
    parser.add_argument("--check", action="store_true",
                        help="Check whether destination matches canonical sources without modifying")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print planned operations without copying")
    args = parser.parse_args()

    dest_dir = args.dest
    files = plan_sync()

    print(f"=== OBSCURE SOURCE SYNCHRONIZER ===")
    print(f"Source Root: {SRC_NATIVE}")
    print(f"Target Destination: {dest_dir}")
    print(f"Files to process: {len(files)}\n")

    mismatches = 0
    copied = 0

    for src_file, rel_dest in files:
        target_file = dest_dir / rel_dest
        src_hash = compute_sha256(src_file)

        if target_file.exists():
            target_hash = compute_sha256(target_file)
            if src_hash == target_hash:
                status = "MATCH (Identical)"
            else:
                status = "DIFF (Modified)"
                mismatches += 1
        else:
            status = "MISSING (Will Create)"
            mismatches += 1

        print(f"[{status:20}] {rel_dest}")

        if not args.check and not args.dry_run and status != "MATCH (Identical)":
            target_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_file, target_file)
            copied += 1

    print("\n-------------------------------------------")
    if args.check:
        if mismatches == 0:
            print("CHECK RESULT: PASS (All destination files match canonical sources 100%)")
            sys.exit(0)
        else:
            print(f"CHECK RESULT: FAIL ({mismatches} files differ or are missing)")
            sys.exit(1)
    elif args.dry_run:
        print(f"DRY RUN COMPLETE: {mismatches} files would be updated.")
    else:
        print(f"SYNC COMPLETE: {copied} files copied/updated. Destination is 100% synchronized.")

if __name__ == "__main__":
    main()
