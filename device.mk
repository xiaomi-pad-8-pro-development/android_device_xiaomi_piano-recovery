DEVICE_PATH := device/xiaomi/piano
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)
# recovery/root is installed by the recovery staging recipe.
