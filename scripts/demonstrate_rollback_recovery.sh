#!/bin/bash
set -e
cd ~/Obscure/chromium/src
LOG="/mnt/f/Zorquelz/Obscure/docs/evidence/logs/rollback_recovery_demonstration.log"
mkdir -p /mnt/f/Zorquelz/Obscure/backups
mkdir -p /mnt/f/Zorquelz/Obscure/docs/evidence/logs

exec > "$LOG" 2>&1

echo "=== S1-6: OBSCURE WORK BACKUP, ROLLBACK & RESTORATION DEMONSTRATION ==="
echo "Timestamp (UTC): $(date -u)"
echo "Starting on active branch: $(git branch --show-current)"
echo "Baseline tag: obscure-baseline-155.0.8059.39"

# Ensure starting on obscure-stable-155
git checkout obscure-stable-155
git branch -D test-recovery-demo 2>/dev/null || true
git branch -D backup-obscure-recovery-demo 2>/dev/null || true

# 1. Create temporary verification branch from immutable baseline
git checkout -b test-recovery-demo obscure-baseline-155.0.8059.39
BASELINE_COMMIT=$(git rev-parse HEAD)
echo "Baseline Commit ID: $BASELINE_COMMIT"

# 2. Simulate actual Obscure work (creating custom module file)
mkdir -p chrome/browser/obscure
echo "// Copyright 2026 Zorquelz Technologies. All rights reserved." > chrome/browser/obscure/recovery_demo.h
echo "class ObscureRecoveryDemo {};" >> chrome/browser/obscure/recovery_demo.h

# 3. Explicit selective staging (NEVER blindly staging with git add -A)
echo "--- Selective Staging (Explicit Path) ---"
git status --short
git add chrome/browser/obscure/recovery_demo.h
GIT_AUTHOR_NAME="Antigravity Implementation Lead" \
GIT_AUTHOR_EMAIL="dev@zorquelz.com" \
GIT_COMMITTER_NAME="Antigravity Implementation Lead" \
GIT_COMMITTER_EMAIL="dev@zorquelz.com" \
git commit -m "feat(obscure): simulated custom obscure work for recovery demo"
BEFORE_COMMIT=$(git rev-parse HEAD)
echo "BEFORE_COMMIT_ID (Work Committed): $BEFORE_COMMIT"

# 4. Create explicit backup bundle and backup branch
git bundle create /mnt/f/Zorquelz/Obscure/backups/obscure_recovery_demo.bundle obscure-baseline-155.0.8059.39..HEAD
git bundle verify /mnt/f/Zorquelz/Obscure/backups/obscure_recovery_demo.bundle
git branch backup-obscure-recovery-demo
echo "Backup Created: bundle /mnt/f/Zorquelz/Obscure/backups/obscure_recovery_demo.bundle and branch backup-obscure-recovery-demo"

# 5. Execute rollback to pristine baseline
echo "--- Executing Rollback to Baseline ---"
git reset --hard obscure-baseline-155.0.8059.39
ROLLBACK_COMMIT=$(git rev-parse HEAD)
echo "ROLLBACK_COMMIT_ID (Restored to baseline): $ROLLBACK_COMMIT"
if [ "$ROLLBACK_COMMIT" = "$BASELINE_COMMIT" ]; then
  echo "Rollback Status: SUCCESS (Cleanly at baseline)"
else
  echo "Rollback Status: FAILED"
  exit 1
fi

# 6. Execute full restoration from backup
echo "--- Executing Restoration from Backup ---"
git reset --hard backup-obscure-recovery-demo
AFTER_COMMIT=$(git rev-parse HEAD)
echo "AFTER_COMMIT_ID (Restored from backup): $AFTER_COMMIT"

# 7. Verification comparison
if [ "$BEFORE_COMMIT" = "$AFTER_COMMIT" ]; then
  echo "RECOVERY RESULT: 100% EXACT RESTORATION (BEFORE_COMMIT == AFTER_COMMIT)"
else
  echo "RECOVERY RESULT: FAILED MISMATCH"
  exit 1
fi

# 8. Clean return to obscure-stable-155
echo "--- Cleanup of Verification Artifacts ---"
git checkout obscure-stable-155
git branch -D test-recovery-demo backup-obscure-recovery-demo
echo "Active Branch: $(git branch --show-current)"
echo "Active HEAD: $(git rev-parse HEAD)"
git status --short
echo "=== DEMONSTRATION COMPLETE: ALL SAFEGUARDS VERIFIED ==="
