#!/system/bin/sh
#
# Prepare the secure stack for the ROM installed in the active slot.
#
# One recovery image serves HyperOS 3 (Android 16), HyperOS 4 (Android 17)
# and the AOSP ROMs built on either firmware:
#
# - Weaver, ssgtzd, batterysecret and a few of their libraries differ between
#   the two firmware generations. Both sets are in /variant; the one matching
#   the installed odm is copied over the common files.
# - KeyMint binds key blobs to the OS version and patch levels it is started
#   with, and refuses or upgrades blobs when they differ from the installed
#   ROM. Read the real values from the installed system and vendor before
#   KeyMint starts. If they cannot be read, the build-time values stay; they
#   are deliberately old, so a mismatch fails to decrypt instead of upgrading
#   the ROM's keys.

LOG_TAG=piano-setup
SLOT=$(getprop ro.boot.slot_suffix)
MNT=/tmp/piano

log_msg() {
    echo "I:${LOG_TAG}: $1" >> /tmp/recovery.log
    echo "${LOG_TAG}: $1" > /dev/kmsg
}

# First match only: build.prop may repeat a key and init keeps the first.
read_prop() {
    grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-
}

mount_ro() {
    dev=/dev/block/mapper/$1${SLOT}
    mkdir -p "${MNT}/$1"
    i=0
    while [ ! -e "${dev}" ] && [ "${i}" -lt 10 ]; do
        sleep 1
        i=$((i + 1))
    done
    # Stock firmware ships erofs; some custom ROMs use ext4.
    mount -t erofs -o ro "${dev}" "${MNT}/$1" 2>/dev/null ||
        mount -t ext4 -o ro "${dev}" "${MNT}/$1" 2>/dev/null ||
        log_msg "cannot mount ${dev}"
}

set_prop() {
    if [ -z "$2" ]; then
        log_msg "$1 not found in the installed ROM, keeping $(getprop "$1")"
        return
    fi
    resetprop "$1" "$2"
    log_msg "$1=$2"
}

# Start a service and wait for init to report it running. A start can be
# refused while TWRP briefly mounts over /vendor, so retry it.
start_service() {
    i=0
    while [ "${i}" -lt 30 ]; do
        [ "$(getprop "init.svc.$1")" = running ] && return 0
        setprop ctl.start "$1"
        sleep 1
        i=$((i + 1))
    done
    log_msg "$1 did not start"
    return 1
}

mount_ro vendor
mount_ro odm
mount_ro system

# Both generations report the same vendor SDK, so tell them apart by the
# Weaver library that only the HyperOS 3 odm ships. Custom ROMs carry the
# stock odm of the firmware they are built on.
if [ -f "${MNT}/odm/lib64/libmi_weaver.so" ]; then
    variant=hos3
else
    variant=hos4
fi
log_msg "using the ${variant} secure stack"
# init cannot mount persist under the recovery policy; qseecomd needs it.
grep -q " /mnt/vendor/persist " /proc/mounts ||
    mount -t ext4 -o noatime,nosuid,nodev /dev/block/bootdevice/by-name/persist /mnt/vendor/persist

# OrangeFox briefly mounts the installed vendor and odm over /vendor and /odm
# to read their properties; files put there in the meantime vanish when it
# unmounts.
i=0
while grep -qE " /(vendor|odm) " /proc/mounts && [ "${i}" -lt 30 ]; do
    sleep 1
    i=$((i + 1))
done
# TWRP's /odm/bin and /odm/etc point into a /vendor/odm that does not exist.
for d in bin etc; do
    [ -L /odm/${d} ] && rm /odm/${d} && mkdir /odm/${d}
done
cp -a /variant/${variant}/. /
# Prebuilt files in the recovery ramdisk can lose their executable bit.
chmod 0755 /vendor/bin/* /vendor/bin/hw/* /odm/bin/hw/*

set_prop ro.build.version.release \
    "$(read_prop "${MNT}/system/system/build.prop" ro.build.version.release)"
set_prop ro.build.version.security_patch \
    "$(read_prop "${MNT}/system/system/build.prop" ro.build.version.security_patch)"
set_prop ro.vendor.build.security_patch \
    "$(read_prop "${MNT}/vendor/build.prop" ro.vendor.build.security_patch)"

umount "${MNT}/system" 2>/dev/null
umount "${MNT}/odm" 2>/dev/null
umount "${MNT}/vendor" 2>/dev/null

# Charging and the battery readout need the ADSP. The kernel cannot read
# its firmware in place (the modem image is 0440 system), so copy it to
# /lib/firmware, which the kernel always searches.
for f in /firmware/image/adsp*; do
    [ -f "${f}" ] || continue
    cp "${f}" /lib/firmware/ && chmod 0644 "/lib/firmware/${f##*/}"
done
if [ -e /sys/kernel/boot_adsp/boot ]; then
    echo 1 > /sys/kernel/boot_adsp/boot
else
    for r in /sys/class/remoteproc/remoteproc*; do
        [ "$(cat "${r}/name")" = 3000000.remoteproc-adsp ] || continue
        [ "$(cat "${r}/state")" = running ] || echo start > "${r}/state"
    done
fi

# KeyMint first: metadata decryption needs only KeyMint, and TWRP gives it a
# limited wait.
start_service vendor.keymint-qti
start_service vendor.gatekeeper_default
start_service odm.weaver
start_service vendor.ssgtzd
start_service vendor.batterysecret
setprop piano.setup.done 1
