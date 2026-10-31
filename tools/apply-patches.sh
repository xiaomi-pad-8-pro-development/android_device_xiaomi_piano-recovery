#!/usr/bin/env bash
# Apply the recovery source fixes from the top of a recovery source.
#
# patches/<project path>/*.patch apply to every build; patches-yarp/ only
# to YARP (PIANO_YARP=1), whose GUI2 code classic TWRP does not have.
# Patches that are already applied are skipped, so a rerun is harmless.
set -eo pipefail
tree=$(cd "$(dirname "$0")/.." && pwd)
dirs="$tree/patches"
[ -n "${PIANO_YARP:-}" ] && dirs="$dirs $tree/patches-yarp"
for patches in $dirs; do
    find "$patches" -name '*.patch' | sort | while read -r f; do
        p=$(dirname "${f#"$patches"/}")
        git -C "$p" apply --reverse --check "$f" 2>/dev/null && continue
        git -C "$p" apply "$f" || { echo "cannot apply ${f#"$tree"/}" >&2; exit 1; }
    done
done
