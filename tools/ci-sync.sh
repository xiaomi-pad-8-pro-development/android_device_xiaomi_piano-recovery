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
repo manifest -o /tmp/full.xml

big="prebuilts/clang/host/linux-x86 prebuilts/rust"
mkdir -p .repo/local_manifests
{
    echo '<manifest>'
    for p in $big; do echo "  <remove-project path=\"$p\" />"; done
    echo '</manifest>'
} > .repo/local_manifests/ci-remove.xml
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

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
rust=$(sed -n 's/.*RustDefaultVersion *= *"\([0-9.]*\)".*/\1/p' build/soong/rust/config/global.go)
echo "clang $clang, rust $rust"
[ -n "$clang" ] && [ -n "$rust" ] || { echo "toolchain versions not found" >&2; exit 1; }
sparse prebuilts/clang/host/linux-x86 "$clang" clang-stable soong
sparse prebuilts/rust linux-x86/"$rust" bootstrap
