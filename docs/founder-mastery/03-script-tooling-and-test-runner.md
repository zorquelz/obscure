# Founder Mastery: Script Tooling & Test Runner Mechanics
**Zorquelz Technologies | Founder Mastery Curriculum — Chapter 3**  
**Audience:** Founder & CEO | **Technical Lead:** Antigravity  
**Companion Artifact:** [`Obscure_Founder_Mastery_Handbook.pdf`](file:///f:/Zorquelz/Obscure/docs/founder-mastery/Obscure_Founder_Mastery_Handbook.pdf)

---

## 1. Deep Dive: `scripts/test_tb10_patch_revert.sh`

The script [`test_tb10_patch_revert.sh`](file:///f:/Zorquelz/Obscure/scripts/test_tb10_patch_revert.sh) is our automated empirical proof for acceptance condition **TB-10**. 

### Step-by-Step Breakdown

```
[ Step 1: Isolation ]       Creates temporary branch tb10-patch-generator from baseline tag.
          |
[ Step 2: Synthetic Patch ] Commits test hook in chrome/browser/obscure/ and formats patch.
          |
[ Step 3: Dry-Run Check ]   Runs 'git apply --check' to verify patch applies without conflict.
          |
[ Step 4: Apply Commit ]    Applies commit via 'git am --signoff' and records APPLIED_COMMIT.
          |
[ Step 5: Hard Revert ]     Executes 'git reset --hard obscure-baseline-155.0.8059.39'.
          |
[ Step 6: Verification ]    Compares RESTORED_COMMIT == BASELINE_COMMIT. (PASS on 100% match).
```

### Why Each Flag Matters
* **`set -e`**: Terminates the script immediately if any command returns a non-zero exit code. Prevents hidden failures.
* **`git apply --check`**: Dry-run tests patch validity without modifying the working tree.
* **`git am --signoff`**: Applies the patch as a real Git commit while appending audit provenance.
* **`git reset --hard <tag>`**: Instantly returns index and working tree to the immutable tag.

---

## 2. Deep Dive: `scripts/check_sandbox.py`

The script [`check_sandbox.py`](file:///f:/Zorquelz/Obscure/scripts/check_sandbox.py) validates that Chromium's multi-process sandbox is actively protecting the operating system without ever needing dangerous `--no-sandbox` flags.

### What It Inspects Under `/proc`

| Kernel Field | Target Value | Real-World Physical Meaning |
| :--- | :---: | :--- |
| **`/proc/<pid>/status` $\rightarrow$ `Seccomp`** | **`2`** | Confirms Secure Computing Mode 2 (filtering mode). The Linux kernel intercepts every syscall and kills the process if an unauthorized syscall is attempted. |
| **`/proc/<pid>/status` $\rightarrow$ `NoNewPrivs`** | **`1`** | Confirms that neither the process nor any of its children can ever escalate root privileges (e.g. executing setuid root binaries like `sudo`). |
| **`/proc/<pid>/ns/user`** | Unique Inode | Confirms that the renderer runs in an isolated user namespace separate from the browser process. |
| **`/proc/<pid>/ns/pid`** | Unique Inode | Confirms that the renderer lives in an isolated PID namespace and cannot see or signal host OS processes. |
