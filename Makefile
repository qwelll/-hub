ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = roothide
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VolumeHUDExpanded
VolumeHUDExpanded_FILES = Tweak.mm
VolumeHUDExpanded_CFLAGS = -fobjc-arc
VolumeHUDExpanded_FRAMEWORKS = UIKit Foundation
VolumeHUDExpanded_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
