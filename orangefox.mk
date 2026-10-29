#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# OrangeFox has no landscape theme: center the portrait one on the panel.
TW_THEME := portrait_hdpi
TW_X_OFFSET := 999
TW_W_OFFSET := -1998

OF_AB_DEVICE_WITH_RECOVERY_PARTITION := 1
OF_FL_PATH1 := /sys/class/leds/led:torch_0
OF_FL_PATH2 := /sys/class/leds/led:switch_2
OF_MAINTAINER := ALXP
OF_USE_GREEN_LED := 0
# AromaFM is a 32-bit ARM binary; SM8750 runs 64-bit code only.
FOX_DELETE_AROMAFM := 1
