import os
import subprocess
import re

src_dir = os.path.expanduser("~/Obscure/chromium/src")

modules = [
    ("V8", "v8"),
    ("Skia", "third_party/skia"),
    ("ANGLE", "third_party/angle"),
    ("WebRTC", "third_party/webrtc"),
    ("BoringSSL", "third_party/boringssl/src"),
    ("DevTools Frontend", "third_party/devtools-frontend/src")
]

print("=== S1-1: SUBMODULE REVISION AUDIT (ACTUAL VS PINNED DEPS) ===")
deps_path = os.path.join(src_dir, "DEPS")
with open(deps_path, "r", encoding="utf-8", errors="ignore") as f:
    deps_content = f.read()

for name, path in modules:
    full_path = os.path.join(src_dir, path)
    actual_rev = "N/A"
    if os.path.isdir(full_path):
        try:
            actual_rev = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=full_path, text=True
            ).strip()
        except Exception as e:
            actual_rev = f"Error: {e}"
    else:
        actual_rev = "Directory not found"

    # Search in DEPS
    # Typically in DEPS: 'src/v8': Var('chromium_git') + '/v8/v8.git' + '@' + 'revision'
    # or 'v8_revision': '...'
    pinned_rev = "Not found in DEPS regex"
    
    # Try finding git revision pattern in DEPS
    patterns = [
        rf"'{name.lower().replace(' ', '_')}_revision':\s*'([a-f0-9]+)'",
        rf"'{path.split('/')[-1]}_revision':\s*'([a-f0-9]+)'",
        rf"'devtools_frontend_revision':\s*'([a-f0-9]+)'",
        rf"webrtc.*?@' \+ '([a-f0-9]+)'",
        rf"'{path}':.*?@([a-f0-9]+)'",
        rf"'src/{path}':.*?@([a-f0-9]+)'",
    ]
    if name == "WebRTC":
        m_webrtc = re.search(r"webrtc.*?@' \+ '([a-f0-9]+)'", deps_content)
        if m_webrtc:
            pinned_rev = m_webrtc.group(1)
    else:
        for p in patterns:
            m = re.search(p, deps_content, re.IGNORECASE | re.DOTALL)
            if m:
                pinned_rev = m.group(1)
                break

    match_status = "MATCH" if actual_rev == pinned_rev else "MISMATCH / DIFF"
    print(f"Submodule: {name}")
    print(f"  Path: {path}")
    print(f"  Actual Revision: {actual_rev}")
    print(f"  Pinned in DEPS:  {pinned_rev}")
    print(f"  Status:          {match_status}\n")
