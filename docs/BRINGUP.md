# Bring-up

The primary target is HyperOS 4 / Android 17. Android 16 is secondary installed-ROM
compatibility, not a separate product. Follow [BUILDING](BUILDING.md) for the
pinned source checkout and build wrapper, and [COMPATIBILITY](COMPATIBILITY.md)
for the target contract. The recovery engine remains TWRP-Test twrp-16.0.

No full build has run. On 2026-10-22 the inspected Linux builder was running an
EvolutionX build and had 59 GB free; it was left undisturbed. Source lock,
configuration and host checks do not prove lunch or recoveryimage succeeds.

Acceptance stages (pending; no device execution performed):

- Establish ramdisk boot, ADB reconnect and useful recovery/kernel logs first.
  Record exact active boot/vendor_boot/dtbo/module tuple and image hashes.
- Verify panel orientation, brightness and touch. The old tree packaged H3
  touch modules and a userspace THP stack; they are deliberately absent here.
  Touch will require matching active-kernel modules plus complete firmware and
  userspace dependencies unless the active vendor ramdisk already supplies it.
- Verify charging separately. Old ADSP/batterysecret setup is absent; do not
  infer normal charging from a visible battery percentage.
- Repeat cold/warm recovery boots, USB reconnects and recovery exits before
  enabling filesystem writes. Preserve logs for every failure.
- Only then add metadata/FBE, stock secure HALs and policy as a separate change
  with matching firmware provenance and credential/non-mutation tests.
- Add OTA/snapshot/slot operations last, with a separate test matrix.

The diagnostic fstab only describes EROFS logical filesystems. Ext4 ROM support,
userdata/metadata, flashing, backup, fastbootd and OTA installation are outside
this baseline. Menu presence from upstream does not prove these operations work.
No blanket permissive policy, automatic mount/format of data, or auto-reflash
hooks are added. Recovery-only SELinux denials must be logged and reviewed.
