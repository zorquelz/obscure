#!/bin/bash
SRC_DIR="$HOME/Obscure/chromium/src"
LOG_DIR="/mnt/f/Zorquelz/Obscure/docs/evidence/logs"

mkdir -p "$LOG_DIR"
cd "$SRC_DIR"

echo "Capturing raw evidence logs into $LOG_DIR..."

# 1. git_checkout_status.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: git status --short --branch ==="
  git status --short --branch
  echo ""
  echo "=== COMMAND: git rev-parse HEAD ==="
  git rev-parse HEAD
  echo ""
  echo "=== COMMAND: git rev-parse 155.0.8059.39^{commit} ==="
  git rev-parse 155.0.8059.39^{commit}
  echo ""
  echo "=== COMMAND: git describe --tags --exact-match HEAD ==="
  git describe --tags --exact-match HEAD
  echo ""
  echo "=== COMMAND: git tag -l '*obscure*' ==="
  git tag -l '*obscure*'
  echo ""
  echo "=== COMMAND: cat chrome/VERSION ==="
  cat chrome/VERSION
} > "$LOG_DIR/git_checkout_status.log" 2>&1
echo "Saved git_checkout_status.log"

# 2. build_args_and_ninja.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: cat out/Stable155/args.gn ==="
  cat out/Stable155/args.gn
  echo ""
  echo "=== COMMAND: ./buildtools/linux64/gn args out/Stable155 --list --short (Key Variables) ==="
  ./buildtools/linux64/gn args out/Stable155 --list --short | grep -E '^(is_debug|is_component_build|symbol_level|dcheck_always_on|use_siso|use_sysroot) '
  echo ""
  echo "=== COMMAND: ls -lh out/Stable155/chrome ==="
  ls -lh out/Stable155/chrome
  echo ""
  echo "=== COMMAND: ./out/Stable155/chrome --version ==="
  ./out/Stable155/chrome --version
} > "$LOG_DIR/build_args_and_ninja.log" 2>&1
echo "Saved build_args_and_ninja.log"

# 3. binary_size_and_ldd.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: ls -lh out/Stable155/chrome out/Obscure/chrome ==="
  ls -lh out/Stable155/chrome out/Obscure/chrome
  echo ""
  echo "=== COMMAND: size out/Stable155/chrome out/Obscure/chrome ==="
  size out/Stable155/chrome out/Obscure/chrome
  echo ""
  echo "=== COMMAND: ldd out/Stable155/chrome | wc -l ==="
  ldd out/Stable155/chrome | wc -l
  echo ""
  echo "=== COMMAND: ldd out/Obscure/chrome | wc -l ==="
  ldd out/Obscure/chrome | wc -l
  echo ""
  echo "=== COMMAND: ldd out/Stable155/chrome (sample) ==="
  ldd out/Stable155/chrome | head -n 15
  echo ""
  echo "=== COMMAND: ldd out/Obscure/chrome (sample) ==="
  ldd out/Obscure/chrome | head -n 15
} > "$LOG_DIR/binary_size_and_ldd.log" 2>&1
echo "Saved binary_size_and_ldd.log"

# 4. out_obscure_history.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: ls -l --time-style=full-iso out/Obscure/ ==="
  ls -l --time-style=full-iso out/Obscure/
  echo ""
  echo "=== COMMAND: cat out/Obscure/args.gn ==="
  cat out/Obscure/args.gn
  echo ""
  echo "=== COMMAND: ./out/Obscure/chrome --version ==="
  ./out/Obscure/chrome --version
} > "$LOG_DIR/out_obscure_history.log" 2>&1
echo "Saved out_obscure_history.log"

# 5. non_component_release155.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: cat out/Release155/args.gn ==="
  cat out/Release155/args.gn
  echo ""
  echo "=== COMMAND: ./buildtools/linux64/gn gen out/Release155 ==="
  ./buildtools/linux64/gn gen out/Release155
  echo ""
  echo "=== COMMAND: ninja -C out/Release155 components/version_info ==="
  ninja -C out/Release155 components/version_info
  echo ""
  echo "=== COMMAND: ls -lh out/Release155/obj/base/version_info/libversion_info.a ==="
  ls -lh out/Release155/obj/base/version_info/libversion_info.a
  echo ""
  echo "=== COMMAND: ls -lh out/Release155/obj/components/version_info/version_info_with_user_agent/ ==="
  ls -lh out/Release155/obj/components/version_info/version_info_with_user_agent/
} > "$LOG_DIR/non_component_release155.log" 2>&1
echo "Saved non_component_release155.log"

# 6. dependency_provenance.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: git status --short ==="
  git status --short
  echo ""
  echo "=== COMMAND: python3 tools/rust/update_rust.py --print-revision installed ==="
  python3 tools/rust/update_rust.py --print-revision installed
  echo ""
  echo "=== COMMAND: python3 tools/rust/update_rust.py --print-revision rust ==="
  python3 tools/rust/update_rust.py --print-revision rust
  echo ""
  echo "=== COMMAND: git log -1 --stat ==="
  git log -1 --stat
} > "$LOG_DIR/dependency_provenance.log" 2>&1
echo "Saved dependency_provenance.log"

# 7. headless_dom_dump.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: ./out/Stable155/chrome --headless=new --dump-dom https://example.com ==="
  ./out/Stable155/chrome --headless=new --dump-dom https://example.com
  echo "EXIT_CODE: $?"
} > "$LOG_DIR/headless_dom_dump.log" 2>&1
echo "Saved headless_dom_dump.log"

# 8. sandbox_proc_status.log
{
  echo "Timestamp (UTC): $(date -u)"
  echo "=== COMMAND: python3 /mnt/f/Zorquelz/Obscure/scripts/check_sandbox.py ==="
  python3 /mnt/f/Zorquelz/Obscure/scripts/check_sandbox.py
} > "$LOG_DIR/sandbox_proc_status.log" 2>&1
echo "Saved sandbox_proc_status.log"

echo "ALL_LOGS_CAPTURED_SUCCESSFULLY"
