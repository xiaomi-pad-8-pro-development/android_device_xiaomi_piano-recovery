# Recovery for the Xiaomi Pad 8 Pro (piano)

Fresh recovery bring-up tree for SM8750 (sun), targeting the Android 17
installed firmware (HyperOS 4 China OS4.0.0.44.XPYCNXM). Install at `device/xiaomi/piano` in a dedicated recovery
source checkout. TWRP and OrangeFox have separate products and share board setup.

This is an unbuilt baseline, not a replacement ready to flash. No boot,
touch, USB, charging or decryption success is claimed. See docs/COMPARISON.md
for the old-tree comparison and docs/BRINGUP.md for build and acceptance steps.

Board geometry comes from the existing piano recovery trees. Two retained
runtime files and their exact origins are recorded in provenance.json.
No old secure-service stack, touch binaries/modules, source patches, OTA hooks,
prune hooks or partition-changing scripts are included.

Source setup: [BUILDING](docs/BUILDING.md). Target and secondary Android 16
compatibility: [COMPATIBILITY](docs/COMPATIBILITY.md). All runtime tests remain pending.

GitHub Actions: run **Piano recovery** with `both`, `twrp` or `ofox`.
Builds use separate pinned upstream manifests and publish development artifacts.
