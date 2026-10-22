#!/usr/bin/env bash
# Run from a synced, dedicated Linux recovery source root.
set -eo pipefail
if [[ $(uname -s) != Linux ]]; then
    echo "A Linux Android build host is required." >&2
    exit 1
fi
if [[ ! -f build/envsetup.sh || ! -d .repo ]]; then
    echo "Run from the recovery source checkout root." >&2
    exit 1
fi
if pgrep -f '[s]oong_ui|[n]inja' >/dev/null; then
    echo "Another Android build is running; refusing concurrent build." >&2
    exit 1
fi
piano_flavor=${1:-twrp}
[[ "$piano_flavor" = twrp || "$piano_flavor" = ofox ]] || exit 2
piano_tree=device/xiaomi/piano
python3 "$piano_tree/tools/check-sources.py" "$PWD" "$piano_flavor"
[[ -f "$piano_tree/security/recovery_avb.pem" ]] || {
    echo "Missing private recovery AVB key; see docs/BUILDING.md." >&2
    exit 1
}
mkdir -p recovery-build-logs
repo manifest -r -o recovery-build-logs/sources.xml
# Capture the local device tree separately, including uncommitted source files.
python3 - <<'HASH'
import hashlib, json
from pathlib import Path
root = Path("device/xiaomi/piano")
records = {}
for path in sorted(root.rglob("*")):
    parts = path.relative_to(root).parts
    if path.is_file() and not any(x in parts for x in (".git", "security", "__pycache__")):
        records[str(path.relative_to(root))] = hashlib.sha256(path.read_bytes()).hexdigest()
Path("recovery-build-logs/device-files.json").write_text(json.dumps(records, indent=2) + "\n")
HASH
export PIANO_RECOVERY_FLAVOR="$piano_flavor"
source build/envsetup.sh
lunch "${piano_flavor}_piano-bp2a-eng"
m recoveryimage -j"${PIANO_BUILD_JOBS:-2}" 2>&1 | tee recovery-build-logs/build.log
python3 "$piano_tree/tools/check-image.py" out/target/product/piano/recovery.img | tee recovery-build-logs/image-check.log
python3 external/avb/avbtool.py verify_image --image out/target/product/piano/recovery.img --key "$piano_tree/security/recovery_avb.pem" | tee recovery-build-logs/avb-check.log
