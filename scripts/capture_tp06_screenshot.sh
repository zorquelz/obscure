#!/bin/bash
cd ~/Obscure/chromium/src
LOG="/mnt/f/Zorquelz/Obscure/docs/evidence/logs/tp06_gui_launch.log"
IMG="/mnt/f/Zorquelz/Obscure/docs/evidence/screenshots/tp06_gui_launch.png"

mkdir -p /mnt/f/Zorquelz/Obscure/docs/evidence/screenshots
mkdir -p /mnt/f/Zorquelz/Obscure/docs/evidence/logs

echo "Launching Chromium Stable 155 to capture TP-06 screenshot..."
{
  echo "Timestamp (UTC): $(date -u)"
  echo "Environment: WSL2 Ubuntu 24.04 (WSLg DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY)"
  echo "=== COMMAND: ./out/Stable155/chrome --headless=new --screenshot=$IMG --window-size=1280,800 https://zorquelz.com ==="
  ./out/Stable155/chrome --headless=new --screenshot="$IMG" --window-size=1280,800 https://zorquelz.com
  echo "EXIT_CODE: $?"
  echo ""
  echo "=== SCREENSHOT FILE ARTIFACT ==="
  ls -lh "$IMG"
} > "$LOG" 2>&1

echo "Screenshot captured:"
ls -lh "$IMG"
