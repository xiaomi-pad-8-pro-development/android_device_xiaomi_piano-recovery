#!/system/bin/sh
#
# Give the recovery's own secure stack and touch services a view of the
# ramdisk /vendor and /odm that the recovery can never mount over.
#
# The recovery mounts the installed vendor and odm over /vendor and /odm to
# read their properties and load modules, and kills whatever uses them before
# it unmounts. Services run from there were killed, restarted by init from the
# installed partitions, and kept them busy, so the recovery failed out with
# "problem with fstab". Run them from /twrplib instead: a private tmpfs whose
# binds keep pointing at the ramdisk whatever is mounted over /vendor and /odm.

LIB=/twrplib

mkdir -p "${LIB}"
mount -t tmpfs -o mode=0755 tmpfs "${LIB}" || exit 1
# init mounts / shared; a mount over /vendor must not reach these binds.
mount -o rprivate none "${LIB}" || exit 1

# TWRP's /odm/bin and /odm/etc point into a /vendor/odm that does not exist.
for d in bin etc; do
    [ -L "/odm/${d}" ] && rm "/odm/${d}" && mkdir "/odm/${d}"
done

for p in vendor odm; do
    mkdir -p "${LIB}/${p}"
    mount -o bind "/${p}" "${LIB}/${p}" || exit 1
    mount -o private none "${LIB}/${p}"
done

# Prebuilt files in the recovery ramdisk can lose their executable bit.
chmod 0755 "${LIB}"/vendor/bin/* "${LIB}"/vendor/bin/hw/* "${LIB}"/odm/bin/hw/* 2>/dev/null
exit 0
