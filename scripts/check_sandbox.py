import subprocess
import time
import os
import glob
import sys

def main():
    chrome_bin = "/home/lucifer-1403/Obscure/chromium/src/out/Stable155/chrome"
    if not os.path.exists(chrome_bin):
        print(f"Error: {chrome_bin} does not exist", file=sys.stderr)
        sys.exit(1)

    print("Launching Chromium Stable 155 with sandbox enabled...")
    proc = subprocess.Popen([
        chrome_bin,
        "--headless=new",
        "--remote-debugging-port=9222",
        "https://example.com"
    ])

    time.sleep(3)
    browser_pid = proc.pid
    print(f"Browser PID: {browser_pid}")

    renderers = []
    for p in glob.glob("/proc/[0-9]*/cmdline"):
        try:
            with open(p, "rb") as f:
                cmd = f.read().decode("utf-8", errors="ignore")
                if "--type=renderer" in cmd:
                    pid = p.split("/")[2]
                    renderers.append(pid)
        except Exception:
            pass

    print(f"Renderer PIDs found: {renderers}")

    for r_pid in renderers:
        print(f"\n=== RENDERER PID {r_pid} STATUS ===")
        os.system(f"grep -E '^(Name|Seccomp|NoNewPrivs|Pid|PPid)' /proc/{r_pid}/status")
        print("\n=== USER & PID NAMESPACES ===")
        os.system(f"echo -n 'Browser  user ns: ' && readlink /proc/{browser_pid}/ns/user")
        os.system(f"echo -n 'Renderer user ns: ' && readlink /proc/{r_pid}/ns/user")
        os.system(f"echo -n 'Browser  pid  ns: ' && readlink /proc/{browser_pid}/ns/pid")
        os.system(f"echo -n 'Renderer pid  ns: ' && readlink /proc/{r_pid}/ns/pid")

    proc.terminate()
    try:
        proc.wait(timeout=2)
    except Exception:
        proc.kill()

if __name__ == "__main__":
    main()
