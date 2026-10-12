#!/bin/bash
set -e
cd ~/Obscure/chromium/src
LOG="/mnt/f/Zorquelz/Obscure/docs/evidence/logs/tb10_revert_test.log"
PATCH_FILE="/tmp/0001-test-tracer-bullet-hook.patch"

mkdir -p /mnt/f/Zorquelz/Obscure/docs/evidence/logs

exec > "$LOG" 2>&1

echo "=== TB-10: THROWAWAY-BRANCH PATCH APPLICATION & REVERSAL TEST ==="
echo "Timestamp (UTC): $(date -u)"
echo "Target Baseline Tag: obscure-baseline-155.0.8059.39"

# 1. Generate a test patch against baseline
git am --abort 2>/dev/null || true
git checkout obscure-stable-155
git branch -D tb10-patch-generator 2>/dev/null || true
git branch -D tb10-disposable-verify 2>/dev/null || true

git checkout -b tb10-patch-generator obscure-baseline-155.0.8059.39
mkdir -p chrome/browser/obscure
echo "// Obscure TB-10 Smoke Hook" > chrome/browser/obscure/tb10_hook.h
git add chrome/browser/obscure/tb10_hook.h
GIT_AUTHOR_NAME="Antigravity Implementation Lead" \
GIT_AUTHOR_EMAIL="dev@zorquelz.com" \
GIT_COMMITTER_NAME="Antigravity Implementation Lead" \
GIT_COMMITTER_EMAIL="dev@zorquelz.com" \
git commit -m "feat(obscure): test hook for TB-10 revert validation"
git format-patch -1 HEAD -o /tmp/
mv /tmp/0001-feat-obscure-test-hook-for-TB-10-revert-validation.patch "$PATCH_FILE"
echo "Generated test patch: $PATCH_FILE"

# Return to clean baseline
git checkout obscure-stable-155
git branch -D tb10-patch-generator

# 2. Enter isolated throwaway verification environment
git checkout -b tb10-disposable-verify obscure-baseline-155.0.8059.39
BASELINE_COMMIT=$(git rev-parse HEAD)
echo "--- Initial Baseline State ---"
echo "BASELINE_COMMIT_ID: $BASELINE_COMMIT"
git status --short

# 3. Dry-run verify patch application
echo "--- Step 1: Dry-Run Patch Verification ---"
git apply --check "$PATCH_FILE"
echo "git apply --check EXIT_CODE: $?"

# 4. Apply patch series via git am
echo "--- Step 2: Apply Patch Series via git am ---"
GIT_COMMITTER_NAME="Antigravity Implementation Lead" \
GIT_COMMITTER_EMAIL="dev@zorquelz.com" \
git am --signoff "$PATCH_FILE"
echo "git am EXIT_CODE: $?"
APPLIED_COMMIT=$(git rev-parse HEAD)
echo "APPLIED_COMMIT_ID: $APPLIED_COMMIT"
git log -1 --oneline

# 5. Execute safe reversal back to pristine baseline
echo "--- Step 3: Execute Reversal / Rollback to Baseline Tag ---"
git reset --hard obscure-baseline-155.0.8059.39
echo "git reset --hard EXIT_CODE: $?"
RESTORED_COMMIT=$(git rev-parse HEAD)
echo "RESTORED_COMMIT_ID: $RESTORED_COMMIT"

# 6. Verification comparison
if [ "$RESTORED_COMMIT" = "$BASELINE_COMMIT" ]; then
  echo "VERIFICATION RESULT: PASS (100% Exact Restoration to Baseline Tag)"
else
  echo "VERIFICATION RESULT: FAIL (Commit Mismatch)"
  exit 1
fi

# 7. Safe cleanup without leaving orphan branches
echo "--- Step 4: Cleanup Disposable Environment ---"
git checkout obscure-stable-155
git branch -D tb10-disposable-verify
rm -f "$PATCH_FILE"

echo "Active Branch: $(git branch --show-current)"
echo "Active HEAD: $(git rev-parse HEAD)"
git status --short
echo "=== TB-10 TEST COMPLETE: PASS (EXECUTED & VERIFIED) ==="
