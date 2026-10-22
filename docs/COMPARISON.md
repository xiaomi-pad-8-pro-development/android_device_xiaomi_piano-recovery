# Existing tree comparison — 2026-10-22

Compared local clean seventeen snapshots:

- TWRP: `863c8b908f50f9bb6b1c54b98c75a094f661b3a3`
- OrangeFox: `bd9cb4e8c4777cc2a027a24472c96f622c6c0b54`

This is source evidence, not a diagnosis proving why either recovery is unstable.

| Area | TWRP | OrangeFox | Fresh baseline |
|---|---|---|---|
| Image | v4, kernel-less, legacy LZ4, 100 MiB | Same | Retained |
| Board/storage | sun; same super geometry and fstab | Same | Geometry retained; diagnostic fstab only |
| Display | Landscape HDPI | Portrait theme centered in 1202-pixel column, X offset 999 | Separate profiles |
| Secure binaries | Installs under /vendor/bin and /vendor/bin/hw | Installs under /piano/bin with corresponding init/policy changes | None |
| Crypto | FBE/metadata flags, mounted installed vendor runtime, custom hooks | Same broad design; different recovery framework patches | Disabled by omission |
| Kernel | Active boot-slot kernel; no kernel packaged | Same plus dummy kernel-header Makefile | Active-slot design; no dummy source |
| Boot control | QTI recovery service package | Same | Deferred |
| Touch | Packaged H3 modules, firmware and THP runtime | Shared assets | Deferred until matching kernel ABI is established |
| Charging | ADSP and batterysecret from installed runtime | Similar init integration | Deferred, not claimed functional |
| OTA | Recovery preservation and snapshot/unmap patches | Additional auto-reflash flag and many framework patches | Deferred |
| Build policy | ALLOW_MISSING_DEPENDENCIES, unchecked stock ELFs, prune hook | Same | No broad dependency bypass or prune hook |
| Fox-only | — | Torch paths, Aroma exclusion, theme/maintainer, Magisk-other-slot script | Aroma exclusion/maintainer only |

## Concrete maintenance problems

- BoardConfig.mk contains an older asserted 29 MB ceiling and later notes
  acknowledging larger booting images. The image audit separately calls the
  true ceiling unmeasured. The new checker enforces geometry and partition
  arithmetic only; it does not turn historical sizes into boot guarantees.
- device.mk and init.recovery.qcom.rc still describe a minimal image while
  actually including a large secure runtime. A clean baseline removes that
  discrepancy.
- OrangeFox docs/BUILDING.md still initializes the TWRP manifest. Its separate
  manifests/orangefox-r12.xml replaces many projects and intentionally retains
  TWRP vold/core/update_engine according to historical comments. This is a
  mixed source stack, not evidence of a clean supported OrangeFox baseline.
- The old TWRP patch loop covers only bootable/recovery, system/vold and
  system/security although hardware/qcom/bootctrl and vendor/twrp patches also
  exist. Source preparation is not fully expressed by that command.
- Old touch modules are explicitly H3. A ramdisk-only recovery inherits the
  active kernel: those binaries cannot be presumed compatible with ALXP or
  experimental 6.18 kernels. Do not use recovery UI failure as a kernel verdict
  without logs and matching module evidence.
- Shared fstab exposes userdata/metadata and raw partitions; shared runtime
  launches multiple firmware-dependent services. These increase the number of
  moving parts before basic repeated-boot stability has been established.

## File inventory

Shared files with differing content:

- `Android.mk`
- `BoardConfig.mk`
- `CHANGELOG.md`
- `README.md`
- `docs/BUILDING.md`
- `docs/INSTALLATION.md`
- `patches/README.md`
- `recovery/root/init.recovery.qcom.rc`
- `recovery/root/system/bin/twrp-pre-unmap`
- `sepolicy/vendor/file_contexts`
- `tools/piano16-elf-closure-audit.py`

Only in TWRP:

- `patches/bootable_recovery/0005-partition-display-names.patch`
- `patches/bootable_recovery/0006-release-super-before-unmap.patch`
- `patches/bootable_recovery/0007-format-data-on-android-factory-reset.patch`
- `patches/vendor_twrp/0001-export-crypto-flags-to-soong.patch`

Only in OrangeFox:

- `kernel-headers/Makefile`
- `manifests/orangefox-r12.xml`
- `manifests/piano.xml`
- `patches/ofox_bootable_recovery/0001-use-recovery-servicemanager.patch`
- `patches/ofox_bootable_recovery/0002-wait-for-piano-secure-stack.patch`
- `patches/ofox_bootable_recovery/0003-build-fixes.patch`
- `patches/ofox_bootable_recovery/0004-follow-android-time-zone.patch`
- `patches/ofox_bootable_recovery/0005-mtp-after-decrypt-and-pre-decrypt-hook.patch`
- `patches/ofox_bootable_recovery/0006-ors-sideload-no-double-install.patch`
- `patches/ofox_bootable_recovery/0007-persist-clock-and-submount-unmount.patch`
- `patches/ofox_bootable_recovery/0008-screen-offsets.patch`
- `patches/ofox_bootable_recovery/0009-default-dark-theme-no-gestures.patch`
- `patches/ofox_bootable_recovery/0010-fix-recovery-checksums-for-reflash.patch`
- `patches/ofox_bootable_recovery/0011-gui-action-fixes.patch`
- `patches/ofox_bootable_recovery/0012-partition-display-names.patch`
- `patches/ofox_bootable_recovery/0013-log-maintainer.patch`
- `patches/ofox_bootable_recovery/0014-hyperos-rom-label.patch`
- `patches/ofox_bootable_recovery/0015-release-super-before-unmap.patch`
- `patches/ofox_bootable_recovery/0016-format-data-on-android-factory-reset.patch`
- `patches/ofox_system_core/0001-libsnapshot-export-update-engine-headers.patch`
- `recovery/root/system/bin/fox_magisk_other_slot.sh`
- `theme/maintainer.png`
- `tools/apply-ofox-patches.sh`
- `vendorsetup.sh`
