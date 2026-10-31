#!/usr/bin/env bash
# Sync a recovery source on a GitHub runner.
#
# usage: ci-sync.sh <manifest-url> <branch>
#
# The clang and rust prebuilts hold every toolchain version and do not fit on
# a hosted runner together with the rest of the tree. Leave them out of the
# repo sync and fetch only the versions the build uses, as sparse checkouts.
set -euo pipefail
repo init -u "$1" -b "$2" --depth=1
# A rerun must read the full manifest, not the one with our removals.
rm -f .repo/local_manifests/ci-remove.xml
repo manifest -o /tmp/full.xml

big="prebuilts/clang/host/linux-x86 prebuilts/rust"
# OrangeFox points these at GitLab repositories that no longer exist; the
# recovery does not use them.
case "$1" in *OrangeFox*) big="$big external/libvpx external/libwebm" ;; esac
# twrp-16.0 replaced the classic TWRP UI with GUI2 ("YARP") on 2026-10-24;
# stay on the last classic commit unless PIANO_YARP=1 asks for GUI2.
pin=
case "$1" in *TWRP-Test*) [ -n "${PIANO_YARP:-}" ] || pin=0315dbb53c47a0532546b7056f6af71b4dc0ddab ;; esac
mkdir -p .repo/local_manifests
{
    echo '<manifest>'
    for p in $big; do echo "  <remove-project path=\"$p\" />"; done
    [ -n "$pin" ] && echo "  <extend-project name=\"android_bootable_recovery\" revision=\"$pin\" />"
    # foxcli master needs libfox_protocol_types, which no fox_16.0 project
    # provides yet (2026-10-31); stay on the last commit before it.
    case "$1" in *OrangeFox*) echo "  <extend-project name=\"external/foxcli\" revision=\"288f5579550ebd0d5e6325c1844a65bd3fb42d8c\" />" ;; esac
    echo '</manifest>'
} > .repo/local_manifests/ci-remove.xml
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags ||
    repo sync -c -j2 --force-sync --no-clone-bundle --no-tags

# URL and revision of a project in the full manifest.
project() {
    python3 - "$1" <<'PY'
import sys, xml.etree.ElementTree as ET
m = ET.parse("/tmp/full.xml").getroot()
remotes = {r.get("name"): r.get("fetch") for r in m.iter("remote")}
default = m.find("default")
for p in m.iter("project"):
    if p.get("path", p.get("name")) == sys.argv[1]:
        remote = p.get("remote") or default.get("remote")
        fetch = remotes[remote].rstrip("/")
        if fetch.startswith(".."):
            fetch = "https://android.googlesource.com"
        print(f"{fetch}/{p.get('name')} {p.get('revision') or default.get('revision')}")
PY
}

sparse() {
    path=$1; shift
    read -r url rev < <(project "$path")
    git clone --filter=blob:none --no-checkout --depth=1 --no-tags "$url" "$path"
    git -C "$path" fetch --depth=1 --filter=blob:none origin "$rev"
    git -C "$path" sparse-checkout set "$@"
    git -C "$path" checkout -q FETCH_HEAD
}

clang=$(sed -n 's/.*ClangDefaultVersion *= *"\(clang-r[0-9a-z]*\)".*/\1/p' build/soong/cc/config/global.go)
bindgen=$(sed -n 's/.*bindgenClangVersion *= *"\(clang-r[0-9a-z]*\)".*/\1/p' build/soong/rust/bindgen.go)
rust=$(sed -n 's/.*RustDefaultVersion *= *"\([0-9.]*\)".*/\1/p' build/soong/rust/config/global.go)
echo "clang $clang $bindgen, rust $rust"
[ -n "$clang" ] && [ -n "$rust" ] || { echo "toolchain versions not found" >&2; exit 1; }
sparse prebuilts/clang/host/linux-x86 "$clang" $bindgen clang-stable soong
sparse prebuilts/rust linux-x86/"$rust" bootstrap soong

"$(dirname "$0")/apply-patches.sh"
