# Compatibility contract

The maintained target is piano, SM8750/sun, HyperOS 4 China
OS4.0.0.44.XPYCNXM, Android 17. The repository branch is seventeen.
There is no separate Android 16 product or maintenance branch.

Android 16 installed-ROM support is secondary compatibility, currently
untested. It must not require switching the default firmware blobs or weakening
Android 17 validation. Detect installed-ROM requirements before starting secure
services; never assume that changing an OS-version property supplies compatibility.

The recovery build engine currently comes from TWRP-Test twrp-16.0. The selected
manifest has no twrp-17 branch as checked on 2026-10-22. This is an Android 17
device target using Android 16 recovery sources, not an Android 17 source rebase.
The upstream manifest itself selects Android 17 ublksrv; all projects are pinned
individually in manifests/sources.lock.json. No compatibility patches are yet
implemented or validated.

Bring up and test HyperOS 4 first. Secure-service binaries, firmware, libraries
and kernel modules must have recorded source hashes and matching dependencies.
If Android 16 later requires different HALs or configuration, introduce a small,
explicit runtime compatibility path only after tests demonstrate the need.
Do not inherit the old HOS3/HOS4 daemon switching without validating it again.

| Capability | Android 17 / HyperOS 4 | Android 16 |
|---|---|---|
| Recovery source build | Pending | Same image, not a separate build |
| Boot / ADB / display | Pending | Pending secondary test |
| Touch / charging | Not integrated | Not integrated |
| Metadata and credential decryption | Not integrated | Not integrated |
| Backup / restore / OTA / slot operations | Not enabled or validated | Not enabled or validated |

A successful build does not mark runtime cells passed. Record image hashes,
installed firmware and kernel tuple, logs, and repeatability for each result.
