#!/usr/bin/env python3
"""Copy the files listed in recovery-files.txt out of stock firmware dumps.

usage: extract-files.py <hyperos4-dump> <hyperos3-dump>

Each dump is an unpacked firmware (vendor/, odm/, ...). Common files and the
[hos4] section come from the HyperOS 4 dump, the [hos3] section from the
HyperOS 3 dump. The previous recovery/root/{vendor,odm,variant} trees are
replaced, so the result matches the list exactly.
"""
import hashlib
import shutil
import sys
from pathlib import Path

tree = Path(__file__).resolve().parent.parent
root = tree / "recovery" / "root"
dumps = {"hos4": Path(sys.argv[1]), "hos3": Path(sys.argv[2])}

for d in ("vendor", "odm", "variant"):
    shutil.rmtree(root / d, ignore_errors=True)

section = None
records = []
for line in (tree / "recovery-files.txt").read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("["):
        section = line.strip("[]")
        continue
    src = dumps[section or "hos4"] / line
    dst = root / ("variant/" + section if section else "") / line
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
    if "/bin/" in line:
        dst.chmod(0o755)
    digest = hashlib.sha1(src.read_bytes()).hexdigest()
    records.append(f"{digest}  {dst.relative_to(tree)}")

# Fixups. Recovery has no first-stage firmware mount of its own, so point
# ueventd at the modem image (mounted by init.recovery.qcom.rc), the stock
# vendor firmware and the touch firmware under /odm.
ueventd = root / "vendor/etc/ueventd.rc"
ueventd.write_text(ueventd.read_text().replace(
    "# firmware_directories /vendor/firmware_mnt/image/ /vendor/modem_firmware/image/",
    "firmware_directories /vendor/firmware_mnt/image/ /vendor/firmware/ /odm/firmware/"))

(tree / "recovery-files.sha1").write_text("\n".join(records) + "\n")
print(f"{len(records)} files")
