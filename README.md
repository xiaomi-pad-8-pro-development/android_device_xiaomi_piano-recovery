# Recovery for the Xiaomi Pad 8 Pro (piano)

TWRP and OrangeFox device tree for the Xiaomi Pad 8 Pro (SM8750, `sun`).
One image works with HyperOS 3 (Android 16), HyperOS 4 (Android 17) and AOSP
ROMs built on either firmware.

## How it stays compatible

- **Kernel modules:** touch, ADSP and charger modules are loaded from the
  installed `vendor_dlkm`, so they always match the ROM's kernel.
- **Decryption:** at boot, `piano-setup.sh` reads the OS version and the
  system and vendor security patch levels from the installed ROM before
  KeyMint starts. No rebuild is needed after a firmware update.
- **Secure stack:** Weaver, `ssgtzd` and `batterysecret` differ between
  HyperOS 3 and 4. Both sets are in `recovery/root/variant/`. The set that
  matches the installed `odm` is used.

## Build

The recovery builds on GitHub Actions: run **Build recovery** and choose
TWRP, OrangeFox or both. Tick *Publish a GitHub release* to publish the
images.

To build locally, in a TWRP source synced from
`https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git` (`twrp-16.0`)
or an OrangeFox source from `https://gitlab.com/OrangeFox/Manifest.git`
(`fox_16.0`):

```
git clone https://github.com/xiaomi-pad-8-pro-development/android_device_xiaomi_piano-recovery -b seventeen device/xiaomi/piano
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export PIANO_FOX=1          # OrangeFox only
lunch twrp_piano-bp2a-eng
m recoveryimage
```

## Install

```
fastboot flash recovery_a recovery.img
fastboot flash recovery_b recovery.img
fastboot reboot recovery
```

## Where the files come from

Everything in `recovery/root/vendor`, `recovery/root/odm` and
`recovery/root/variant` is extracted from stock firmware with
`tools/extract-files.py`, following `recovery-files.txt`:

- HyperOS 4 China `OS4.0.5.0.XPYCNXM`: common files and `variant/hos4`
- HyperOS 3 China `OS3.0.307.0.WPYCNXM`: `variant/hos3`

`recovery-files.sha1` records the hash of every extracted file.
