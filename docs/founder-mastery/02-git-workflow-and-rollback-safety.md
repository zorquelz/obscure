# Founder Mastery: Git Workflow & Rollback Fortress
**Zorquelz Technologies | Founder Mastery Curriculum — Chapter 2**  
**Audience:** Founder & CEO | **Technical Lead:** Antigravity  
**Companion Artifact:** [`Obscure_Founder_Mastery_Handbook.pdf`](file:///f:/Zorquelz/Obscure/docs/founder-mastery/Obscure_Founder_Mastery_Handbook.pdf)

---

## 1. The Reality of Chromium's Git Scale

Chromium's source tree is not a normal software project:
* Contains **over 40 million lines of code**.
* Hundreds of synchronized third-party submodules (V8, Skia, ANGLE, Dawn, WebRTC).
* A `.git` repository size exceeding **50 gigabytes**.

In an ordinary small repository, commands like `git add -A` or `git branch -D` are common. In Chromium, a blind `git add -A` can accidentally stage gigabytes of Ninja build output or CIPD distribution binaries, corrupting the repository index.

---

## 2. The 4-Tier Rollback Fortress

To guarantee that Obscure work can never be lost, our workflow operates under a structured four-tier recovery model:

| Rollback Tier | Command / Action | Mechanism | Risk Level |
| :--- | :--- | :--- | :---: |
| **Tier 1: Non-Destructive Inversion** | `git revert <commit>` | Creates a new commit that exactly inverts changes while keeping full commit history intact. | **Zero Risk** |
| **Tier 2: Patch Reversal** | `git apply --reverse <patch>` | Reverses an applied patch series without altering branch heads. | **Zero Risk** |
| **Tier 3: Tagged Hard Reset** | `git reset --hard <tag>` | Restores working tree and index to an immutable baseline tag (e.g. `obscure-baseline-155.0.8059.39`). | **Safe (When Tagged)** |
| **Tier 4: Portable Git Bundles** | `git bundle create backups/...` | Packages commits into a portable binary `.bundle` archive that can be restored byte-for-byte even after a hard reset. | **Work Loss Fortress** |

---

## 3. Line-Ending Physics: Why `*.patch -text` is Mandatory

* **The Problem:** Windows uses CRLF (`\r\n`) line endings, while Linux and WSL2 use LF (`\n`). If a developer views or saves a `.patch` file on Windows, editors or Git configurations can silently rewrite LF to CRLF.
* **The Failure:** When `git am` runs inside Linux/WSL2 on a CRLF patch, it fails immediately with corrupt patch errors.
* **The Obscure Solution:** We enforce `*.patch -text` in `.gitattributes`. This forces Git to treat all `.patch` files as **raw binary streams**, ensuring byte-exact line-ending preservation across Windows and Linux boundaries.

---

## 4. Detached Worktrees vs. Dangerous Branch Deletions

In legacy workflows, temporary verification was done by creating a branch and deleting it with `git branch -D throwaway-verify`. If a typo occurred, real commits could be destroyed.

### The Modern Obscure Standard: Detached Worktrees
Instead of creating branches, we create disposable filesystem checkouts:
```bash
# 1. Create a detached temporary worktree in /tmp
git worktree add --detach /tmp/obscure-verify obscure-baseline-155.0.8059.39

# 2. Test patch application inside the temporary directory
cd /tmp/obscure-verify
git apply --check /tmp/test.patch

# 3. Remove the worktree safely without touching any branch heads
git worktree remove /tmp/obscure-verify
```
This guarantees **zero branch collision** and **zero risk to active work**.
