# Reproducible TWRP source setup

Primary firmware target: HyperOS 4 / Android 17. Recovery engine: pinned
TWRP-Test twrp-16.0. See COMPATIBILITY.md. OrangeFox uses its own pinned fox_16.0 manifest (414 projects);
its first full build is pending.

Use a fresh dedicated Linux source directory with enough storage for checkout
and build. Do not sync into a ROM checkout or run alongside an active ROM build.
Clone this private repository on branch seventeen at device/xiaomi/piano
before the build. GitHub Actions installs the exact checked-out workflow revision.

```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git \
  -b 6f074703a0ab31f22518b1a94331b358190237ba
mkdir -p .repo/local_manifests
# After installing this device repository at device/xiaomi/piano:
cp device/xiaomi/piano/manifests/twrp-pins.xml .repo/local_manifests/piano-twrp-pins.xml
repo sync -j4 --fail-fast --no-clone-bundle --no-tags
python3 device/xiaomi/piano/tools/check-sources.py "$PWD"
```

The overlay pins all 393 effective upstream projects; the standalone
manifests/twrp-locked.xml records the equivalent flattened source manifest.
The original three upstream XML files and their hashes are preserved for audit.
Do not use `repo sync -c` with arbitrary SHA pins unless that repo version can
fetch them correctly. No source patches are currently required by this tree;
a successful full build is still pending and may reveal missing dependencies.

Provide a private RSA-4096 key at
`device/xiaomi/piano/security/recovery_avb.pem`. For a new development key:

```bash
mkdir -p device/xiaomi/piano/security
(umask 077; test ! -e device/xiaomi/piano/security/recovery_avb.pem &&
 openssl genrsa -out device/xiaomi/piano/security/recovery_avb.pem 4096)
bash device/xiaomi/piano/tools/build-twrp.sh
```

Do not overwrite an existing signing key. Keys are ignored by Git. The wrapper
checks source revisions, records manifest/device hashes, builds with two jobs by
default, checks image geometry and verifies the AVB signature. It performs no
flash, device, slot or installation operations. Logs: recovery-build-logs/.
A development signature does not establish that a locked bootloader trusts it.

To intentionally refresh upstream pins, review the upstream manifest snapshot,
then run `python3 tools/lock-sources.py` from the device repository. The tool also regenerates
twrp-pins.xml and baseline.json; review them before accepting that refresh.
Do not regenerate pins automatically during a build.

## GitHub Actions

Run the Piano recovery workflow on seventeen. Choose both, twrp or ofox.
Each recovery gets an isolated Ubuntu 24.04 job, pinned upstream source and
an ephemeral development signing key. Private keys are never uploaded.
Successful jobs upload recovery.img and its SHA-256 checksum; failed jobs
upload available sync/build logs. These are bring-up artifacts, not releases.
Hosted-runner disk, RAM and six-hour limits may prevent the first build;
the job logs are authoritative. OrangeFox uses its own upstream source stack,
not the old mixed TWRP/OrangeFox overlay. No hardware support is implied.
