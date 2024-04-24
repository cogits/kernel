.ONESHELL:
.SHELLFLAGS = -ec

# 控制 modules 安装路径
export INSTALL_MOD_PATH := $(BUILD_OUT_DIR)
export KERNELRELEASE ?= 6.7.0

## build kernel
# https://github.com/d0u9/Linux-Device-Driver
kernel: $(LINUX_IMAGE)
$(LINUX_IMAGE): export KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
$(LINUX_IMAGE):
	mkdir -p $(KBUILD_OUTPUT) $(INSTALL_MOD_PATH)
	cp $(PATCHES_DIR)/linux/$(LINUX_CONF) $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/linux
	$(MAKE) olddefconfig
	$(MAKE)
	$(MAKE) modules_install

# clean
clean/kernel:
	rm -rf $(BUILD_LINUX_DIR)
	rm -rf $(INSTALL_MOD_PATH)/lib/modules
clean/uboot:
	rm -rf $(BUILD_UBOOT_DIR)
