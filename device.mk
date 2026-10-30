#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/xiaomi/piano

$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_SHIPPING_API_LEVEL := 35
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# Ramdisk-only recovery: no kernel to check against the VINTF requirements.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
