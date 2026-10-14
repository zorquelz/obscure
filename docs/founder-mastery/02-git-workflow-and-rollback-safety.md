# Obscure Founder Mastery: Git Workflow, Patch Architecture & Rollback Safety
**Zorquelz Technologies | Founder Mastery Series — Chapter 2**  
**Audience:** Founder & CEO | **Technical Lead:** Antigravity  
**Goal:** Master Chromium git tree management, patch portability, and bulletproof rollback safety.

---

## 1. Why Git in Chromium is Different

A typical software repository has tens of thousands of lines of code. The Chromium source tree (`src/`) has **over 40 million lines of code**, hundreds of submodules, and a `.git` database weighing over 50 gigabytes.

In an ordinary repository, commands like `git add -A` or `git branch -D` might seem harmless. In Chromium, a reckless `git add -A` can accidentally stage gigabytes of compiler output or CIPD binary dependencies, corrupting your index.

---

## 2. The Four Rollback Tiers of Obscure

Obscure operates under a strict four-tier rollback safety architecture:

```
TIER 1: Git Revert (Cleanest, Non-Destructive)
   git revert <commit-id>
   Creates a new commit that exactly inverts the changes. Preserves full history.

TIER 2: Patch Application Rollback
   git apply --reverse <patch-file>
   Undoes an applied patch without altering Git branch state.

TIER 3: Hard Reset to Immutable Tag (The "Panic Button")
   git reset --hard obscure-baseline-155.0.8059.39
   Instantly returns the working tree and index to the pristine tag.

TIER 4: Git Bundle Work Recovery (Zero Work Loss Guarantee)
   git bundle create backups/obscure_work.bundle obscure-baseline-155.0.8059.39..HEAD
   Packages all unpushed commits into a single portable binary file that can be restored anywhere.
```

---

## 3. Why Line Endings Matter (`*.patch -text`)

When working across Windows (which uses CRLF `\r\n`) and Linux / WSL2 (which uses LF `\n`), patch files can silently get corrupted by automatic Windows line-ending translation.

If a patch file gets CRLF line endings, running `git am` inside WSL2 will fail with:
```
error: patch failed: ...
error: cannot apply binary patch to ...
```
To permanently protect Obscure, we added this rule to `.gitattributes`:
```gitattributes
*.patch -text
```
This forces Git to treat all `.patch` files as **raw binary streams**, guaranteeing that line endings never change across Windows and Linux boundaries.

---

## 4. Disposable Detached Worktrees vs. `git branch -D`

### Why `git branch -D` is Dangerous
In early workflows, verification steps created a throwaway branch and deleted it with `git branch -D throwaway-verify`. If a typo occurs or the active branch is misidentified, `git branch -D` can permanently destroy uncommitted or recently committed work.

### The Modern Obscure Standard: Detached Worktrees
Instead of creating branches, we create disposable, isolated file trees:
```bash
# 1. Create a detached temporary worktree in /tmp
git worktree add --detach /tmp/obscure-verify obscure-baseline-155.0.8059.39

# 2. Test patch application inside the temporary directory
cd /tmp/obscure-verify
git apply --check /tmp/test.patch

# 3. Safely remove the worktree without touching main branches
git worktree remove /tmp/obscure-verify
```
This guarantees **zero branch collision** and **zero risk of deleting real work**.
