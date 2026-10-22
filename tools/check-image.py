#!/usr/bin/env python3
"""Read-only structural recovery header check, not boot or AVB validation."""
import hashlib
import struct
import sys
from pathlib import Path

def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: check-image.py recovery.img")
    data = Path(sys.argv[1]).read_bytes()
    if len(data) < 4096 or data[:8] != b"ANDROID!":
        raise SystemExit("FAIL: truncated header or invalid magic")
    kernel, ramdisk = struct.unpack_from("<II", data, 8)
    version = struct.unpack_from("<I", data, 40)[0]
    header_size = struct.unpack_from("<I", data, 20)[0]
    if version != 4 or kernel != 0 or header_size != 1584:
        raise SystemExit("FAIL: expected v4, 1584-byte header and no kernel")
    if not ramdisk or 4096 + ramdisk > len(data):
        raise SystemExit("FAIL: absent or truncated ramdisk")
    if data[4096:4100] != bytes.fromhex("02214c18"):
        raise SystemExit("FAIL: expected legacy LZ4")
    if len(data) > 104857600:
        raise SystemExit("FAIL: exceeds recovery partition")
    print("PASS: structural checks only; hardware and AVB remain unverified")
    print("ramdisk_bytes=", ramdisk)
    print("sha256=", hashlib.sha256(data).hexdigest())

if __name__ == "__main__":
    main()
