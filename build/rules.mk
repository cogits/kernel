.ONESHELL:
.SHELLFLAGS = -ec

# build dirs
BUILD_OUT_DIR := $(BUILD_DIR)/$(board)/out
BUILD_UBOOT_DIR := $(BUILD_DIR)/$(board)/uboot
BUILD_LINUX_DIR := $(BUILD_DIR)/$(board)/linux
BUILD_OPENSBI_DIR := $(BUILD_DIR)/common/opensbi
BUILD_BUSYBOX_DIR := $(BUILD_DIR)/common/busybox

# targets
ROOTFS_DIR := $(BUILD_DIR)/rootfs
BUSYBOX_DIR := $(ROOTFS_DIR)/busybox
ALPINE_DIR := $(ROOTFS_DIR)/alpine

IMAGES_DIR := $(BUILD_DIR)/images
MOUNT_POINT := $(IMAGES_DIR)/mnt

OPENSBI_BIN := $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin
LINUX_IMAGE := $(BUILD_LINUX_DIR)/arch/riscv/boot/Image


APK_STATIC := apk.static
VALID_SUBUID := $(if $(ROOT_USER),,$(shell test $$(getsubids $$(whoami) | awk '{print $$3}') -eq $$(id -u) && echo true))
VALID_SUBGID := $(if $(ROOT_USER),,$(shell test $$(getsubids -g $$(whoami) | awk '{print $$3}') -eq $$(id -g) && echo true))

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

## build busybox
busybox: $(BUSYBOX_DIR)
$(BUSYBOX_DIR): DIFF_FILES := $(shell find $(PATCHES_DIR)/busybox -type f -name '*.diff')
$(BUSYBOX_DIR): export KBUILD_OUTPUT := $(BUILD_BUSYBOX_DIR)
$(BUSYBOX_DIR): | $(BUILD_BUSYBOX_DIR)
$(BUSYBOX_DIR):
	# 找出 patches/busybox/ 目录下所有 diff 文件，并打补丁到 deps/busybox 目录
	$(foreach diff,$(DIFF_FILES),
		patch -N $(patsubst $(PATCHES_DIR)/%.diff,$(DEPS_DIR)/%,$(diff)) $(diff)
	)
	cp $(PATCHES_DIR)/busybox/config $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/busybox
	$(MAKE) oldconfig
	$(MAKE) CONFIG_PREFIX=$(BUSYBOX_DIR) install

	# patch/rootfs
	rsync -av $(PATCHES_DIR)/rootfs/ $(BUSYBOX_DIR) --exclude='.gitkeep'
	sed -i 's|$${LOGIN}|'"/bin/sh"'|' $(BUSYBOX_DIR)/etc/init.d/rcS
	sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $(BUSYBOX_DIR)/etc/init.d/rcS


## create alpine rootfs
# 由于 alpine 创建 rootfs 时会生成其他人无权限读写的文件，所以必须把 root id 映射成当前用户的 id
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -u):/g" /etc/subuid
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -g):/g" /etc/subgid
alpine: $(ALPINE_DIR)
$(ALPINE_DIR): mirror ?= $(ALPINE_MIRROR)
$(ALPINE_DIR):
	$(if $(ROOT_USER),,$(if $(SUDO),,
		$(if $(VALID_SUBUID),,$(error subordinate user ID must be equal to UID, see subuid))
		$(if $(VALID_SUBGID),,$(error subordinate group ID must be equal to GID, see subgid))
		map_users=$$(getsubids $$(whoami) | awk '{printf "%s,0,%s\n", $$3, $$4}')
		map_groups=$$(getsubids -g $$(whoami) | awk '{printf "%s,0,%s\n", $$3, $$4}')
		unshare="unshare --map-users=$${map_users} --map-groups=$${map_groups} --setuid 0 --setgid 0 --wd $(ALPINE_DIR)"
	))

	mkdir -p $(ALPINE_DIR)
	cd $(ALPINE_DIR)
	$(if $(ROOT_USER),,$(if $(SUDO),$(SUDO),$${unshare})) \
		$(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted -p . --initdb add \
		apk-tools $(alpine_extra_pkgs) coreutils busybox-extras zsh vim eza bat fd ripgrep hexyl wpa_supplicant \
		btop fzf fzf-vim fzf-zsh-plugin zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search

	# patches/rootfs
	rsync -av $(PATCHES_DIR)/rootfs/ $(ALPINE_DIR) --exclude='.gitkeep'
	sed -i 's|$${LOGIN}|'"/bin/zsh"'|' $(ALPINE_DIR)/etc/init.d/rcS
	sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $(ALPINE_DIR)/etc/init.d/rcS
	sed -i 's|$${MIRROR}|'"$(mirror)"'|' $(ALPINE_DIR)/etc/apk/repositories


## 创建目录
# NOTE 以目录作为依赖，有时候目录有可能被`更新`，导致 target 再次执行。
# 所以必须使用 [order-only-prerequisites](https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html)。
$(BUILD_LINUX_DIR) $(INSTALL_MOD_PATH) $(BUILD_OPENSBI_DIR) $(BUILD_BUSYBOX_DIR) $(IMAGES_DIR) $(MOUNT_POINT):
	mkdir -p $@

# clean
clean/kernel:
	rm -rf $(BUILD_LINUX_DIR)
	rm -rf $(INSTALL_MOD_PATH)/lib/modules
clean/uboot:
	rm -rf $(BUILD_UBOOT_DIR)
clean/opensbi:
	rm -rf $(BUILD_OPENSBI_DIR)
clean/busybox:
	$(MAKE) -C $(ROOT) $@
	rm -rf $(BUILD_BUSYBOX_DIR) $(BUSYBOX_DIR)

# 声明伪目录
.PHONY: opensbi kernel busybox alpine clean/*
