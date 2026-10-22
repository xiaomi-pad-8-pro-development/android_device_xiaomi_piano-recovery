#!/usr/bin/env python3
"""Sync on ephemeral CI runners, leaving enough disk to preserve diagnostics."""
import json
import os
import shutil
import signal
import subprocess
import time
from pathlib import Path

GIB = 1024 ** 3

def main():
    samples = []
    process = subprocess.Popen(
        ["repo", "sync", "-j2", "--fail-fast", "--no-clone-bundle", "--no-tags"],
        start_new_session=True)
    low_disk = False
    try:
        while True:
            usage = shutil.disk_usage(".")
            sample = {"time": time.time(), "free_bytes": usage.free, "total_bytes": usage.total}
            samples.append(sample)
            Path("sync-storage.json").write_text(json.dumps(samples, indent=2) + "\n")
            print(f"CI disk: {usage.free / GIB:.1f} GiB free of {usage.total / GIB:.1f} GiB", flush=True)
            if process.poll() is not None:
                break
            if usage.free < 3 * GIB:
                low_disk = True
                print("Stopping sync below 3 GiB free to preserve runner logs. More storage is required.", flush=True)
                break
            time.sleep(10)
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
    raise SystemExit(1 if low_disk else process.returncode)

if __name__ == "__main__":
    main()
