.ONESHELL:
.SHELLFLAGS = -ec

# build dirs
BUILD_OUT_DIR := $(BUILD_DIR)/$(board)/out
BUILD_UBOOT_DIR := $(BUILD_DIR)/$(board)/uboot
BUILD_LINUX_DIR := $(BUILD_DIR)/$(board)/linux
BUILD_OPENSBI_DIR := $(BUILD_DIR)/opensbi

# targets
OPENSBI_BIN := $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin
LINUX_IMAGE := $(BUILD_LINUX_DIR)/arch/riscv/boot/Image

APK_STATIC := apk.static

# 控制 modules 安装路径
export INSTALL_MOD_PATH := $(BUILD_OUT_DIR)
export KERNELRELEASE ?= 6.7.0


## opensbi
opensbi: $(OPENSBI_BIN)
$(OPENSBI_BIN): | $(BUILD_OPENSBI_DIR)
	cd $(DEPS_DIR)/opensbi
	$(MAKE) O=$(BUILD_OPENSBI_DIR) PLATFORM=generic PLATFORM_RISCV_XLEN=64

## build kernel
# https://github.com/d0u9/Linux-Device-Driver
kernel: $(LINUX_IMAGE)
$(LINUX_IMAGE): export KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
$(LINUX_IMAGE): | $(BUILD_LINUX_DIR) $(INSTALL_MOD_PATH)
	cp $(PATCHES_DIR)/linux/$(LINUX_CONF) $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/linux
	$(MAKE) olddefconfig
	$(MAKE)
	$(MAKE) modules_install

## 创建目录
# NOTE 以目录作为依赖，有时候目录有可能被`更新`，导致 target 再次执行。
# 所以必须使用 [order-only-prerequisites](https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html)。
$(BUILD_LINUX_DIR) $(INSTALL_MOD_PATH) $(BUILD_OPENSBI_DIR):
	mkdir -p $@

# clean
clean/kernel:
	rm -rf $(BUILD_LINUX_DIR)
	rm -rf $(INSTALL_MOD_PATH)/lib/modules
clean/uboot:
	rm -rf $(BUILD_UBOOT_DIR)
clean/opensbi:
	rm -rf $(BUILD_OPENSBI_DIR)
