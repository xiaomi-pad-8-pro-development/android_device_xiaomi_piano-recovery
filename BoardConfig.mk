#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/piano

# Minimal manifest
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Platform
PRODUCT_PLATFORM := sun
TARGET_BOARD_PLATFORM := sun
TARGET_BOOTLOADER_BOARD_NAME := sun
TARGET_NO_BOOTLOADER := true

# Kernel: ramdisk-only recovery, the active slot's boot supplies the kernel.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_NO_KERNEL_OVERRIDE := true
# gzip and zstd ramdisks do not boot on this bootloader.
BOARD_RAMDISK_USE_LZ4 := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# Verified boot. The bootloader is unlocked, so the AOSP test key is enough.
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Partitions
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_SUPER_PARTITION_SIZE := 13958643712
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 13948157952
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vendor \
    vendor_dlkm
BOARD_USES_METADATA_PARTITION := true
TARGET_COPY_OUT_VENDOR := vendor
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_ROOT_EXTRA_FOLDERS := firmware persist

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# Crypto. The OS version and patch levels are read from the installed ROM at
# boot (piano-setup.sh). These are only the fallback and are deliberately
# old: KeyMint then refuses a mismatch instead of upgrading the ROM's keys.
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
PLATFORM_VERSION := 16
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2025-01-01
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Touch, ADSP and charger modules come from the installed vendor_dlkm, so the
# recovery matches whichever kernel the ROM ships.
TW_LOAD_VENDOR_MODULES := "xiaomi_touch.ko nt36532_touch.ko adsp_loader_dlkm.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

# Display and input
TW_THEME := landscape_hdpi
TW_FRAMERATE := 60
TW_BRIGHTNESS_PATH := /sys/class/backlight/panel0-backlight/brightness
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 2048
RECOVERY_TOUCHSCREEN_SWAP_XY := true
RECOVERY_TOUCHSCREEN_FLIP_Y := true
TW_NO_HAPTICS := true
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := en

# Battery: TWRP reads the fuel gauge from sysfs.
TW_USE_LEGACY_BATTERY_SERVICES := true

# Tools
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_FASTBOOTD := true
TW_ENABLE_ALL_PARTITION_TOOLS := true
TW_USE_DMCTL := true
TW_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true

# Misc
RECOVERY_SDCARD_ON_DATA := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_EXCLUDE_APEX := true
TW_SKIP_ADDITIONAL_FSTAB := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ksu,/data/adb/ap
# Release numbers, one per recovery. Raise the one you release.
ifeq ($(PIANO_FOX),1)
FOX_MAINTAINER_PATCH_VERSION := 1
FOX_VARIANT := ALXP
TW_DEVICE_VERSION := $(FOX_MAINTAINER_PATCH_VERSION)(ALXP)
else ifeq ($(PIANO_YARP),1)
TW_DEVICE_VERSION := 0(ALXP)
else
TW_DEVICE_VERSION := 3(ALXP)
endif

# OrangeFox: the CI sets PIANO_FOX=1 when building in an OrangeFox source.
ifeq ($(PIANO_FOX),1)
include $(DEVICE_PATH)/orangefox.mk
endif
