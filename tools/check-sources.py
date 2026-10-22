#!/usr/bin/env python3
"""Verify a synced TWRP checkout against the source lock, without modifying it."""
import json
import subprocess
import sys
from pathlib import Path

def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit("usage: check-sources.py SOURCE_ROOT [twrp|ofox]")
    checkout = Path(sys.argv[1]).resolve()
    tree = Path(__file__).resolve().parents[1]
    flavor = sys.argv[2] if len(sys.argv) == 3 else "twrp"
    if flavor not in ("twrp", "ofox"):
        raise SystemExit("Unknown flavor")
    lock = "sources.lock.json" if flavor == "twrp" else "ofox-sources.lock.json"
    records = json.loads((tree / "manifests" / lock).read_text())
    failures = []
    for record in records:
        project = checkout / record["path"]
        if not (project / ".git").exists():
            failures.append(record["path"] + ": missing checkout")
            continue
        head = subprocess.check_output(["git", "-C", str(project), "rev-parse", "HEAD"], text=True).strip()
        if head != record["commit"]:
            failures.append(record["path"] + ": wrong HEAD " + head)
        dirty = subprocess.check_output(["git", "-C", str(project), "status", "--porcelain", "--untracked-files=no"], text=True)
        if dirty:
            failures.append(record["path"] + ": tracked modifications")
    if failures:
        raise SystemExit("\n".join(failures))
    print("PASS:", len(records), "source revisions and tracked files")

if __name__ == "__main__":
    main()
