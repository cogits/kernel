.ONESHELL:
.SHELLFLAGS = -ec

# path definitions
BOARD_DIR := $(ROOT)/boards/$(board)

# build dirs
BUILD_OUT_DIR := $(BUILD_DIR)/$(board)/out
BUILD_UBOOT_DIR := $(BUILD_DIR)/$(board)/uboot
BUILD_LINUX_DIR := $(BUILD_DIR)/$(board)/linux
BUILD_OPENSBI_DIR ?= $(BUILD_DIR)/common/opensbi
BUILD_BUSYBOX_DIR := $(BUILD_DIR)/common/busybox
BUILD_QEMU_DIR := $(BUILD_DIR)/common/qemu

# targets
ROOTFS_DIR := $(BUILD_DIR)/rootfs
BUSYBOX_DIR := $(ROOTFS_DIR)/busybox
ALPINE_DIR := $(ROOTFS_DIR)/alpine

IMAGES_DIR := $(BUILD_DIR)/images
MOUNT_POINT := $(IMAGES_DIR)/mnt

QEMU := $(BUILD_QEMU_DIR)/qemu-system-riscv64
LINUX_IMAGE := $(BUILD_LINUX_DIR)/arch/riscv/boot/Image
OPENSBI_BIN ?= $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin

APK_STATIC := apk.static

# 控制 modules 安装路径
export INSTALL_MOD_PATH := $(BUILD_OUT_DIR)
export KERNELRELEASE ?= 6.7.0

# args (recursive evaluated)
arg1 = $(word 1,$(subst /, ,$@))
arg2 = $(word 2,$(subst /, ,$@))

## macros
# changes to DEPS_DIR/$(1) and applies patches from PATCHES_DIR/$(1)
define git-apply
  cd $(DEPS_DIR)/$(1)
  for patch in $(PATCHES_DIR)/$(1)/*.patch; do
    git apply $${patch}
  done
endef


## build qemu
# https://zhuanlan.zhihu.com/p/258394849
qemu: $(QEMU)
$(QEMU): | $(BUILD_QEMU_DIR)
	# $(call git-apply,qemu)
	cd $(BUILD_QEMU_DIR)
	$(DEPS_DIR)/qemu/configure --target-list=riscv64-softmmu --enable-slirp
	$(MAKE)

## opensbi
opensbi: $(OPENSBI_BIN)
$(OPENSBI_BIN): export PLATFORM ?= generic
$(OPENSBI_BIN): export PLATFORM_RISCV_XLEN ?= 64
$(OPENSBI_BIN): | $(BUILD_OPENSBI_DIR)
	cd $(DEPS_DIR)/opensbi
	$(MAKE) O=$(BUILD_OPENSBI_DIR)

## build kernel
# https://github.com/d0u9/Linux-Device-Driver
kernel: $(LINUX_IMAGE)
$(LINUX_IMAGE): export KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
$(LINUX_IMAGE): | $(BUILD_LINUX_DIR) $(INSTALL_MOD_PATH)
	cp -u $(PATCHES_DIR)/linux/$(LINUX_CONF) $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/linux
	$(MAKE) olddefconfig
	$(MAKE)
	$(MAKE) modules_install

# kernel: make nconfig
kernel/config: export KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
kernel/config: | $(BUILD_LINUX_DIR)
kernel/config:
	cp -u $(PATCHES_DIR)/linux/$(LINUX_CONF) $(KBUILD_OUTPUT)/.config
	$(MAKE) -C $(DEPS_DIR)/linux nconfig
	cp -u $(KBUILD_OUTPUT)/.config $(PATCHES_DIR)/linux/$(LINUX_CONF)

## build drivers (add V=12 for verbose output)
drivers: $(LINUX_IMAGE)
	$(MAKE) -C ../drivers KERNEL_PATH=$(BUILD_LINUX_DIR)

# drivers/*
SUB_DRIVERS := $(wildcard ../drivers/*/)
SUB_DRIVERS := $(SUB_DRIVERS:../%/=%)
$(SUB_DRIVERS): $(LINUX_IMAGE)
	$(MAKE) -C ../drivers extra/$(arg2) KERNEL_PATH=$(BUILD_LINUX_DIR)
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(ROOT)/$@ modules


## build busybox
busybox: $(BUSYBOX_DIR)
$(BUSYBOX_DIR): export KBUILD_OUTPUT := $(BUILD_BUSYBOX_DIR)
$(BUSYBOX_DIR): | $(BUILD_BUSYBOX_DIR)
	cd $(DEPS_DIR)/busybox
	cp $(PATCHES_DIR)/busybox/config $(KBUILD_OUTPUT)/.config

	$(MAKE) oldconfig
	$(MAKE) CONFIG_PREFIX=$@ install

	# patches/rootfs
	rsync -av $(PATCHES_DIR)/rootfs/ $@ --exclude='.gitkeep'
	sed -i 's|$${LOGIN}|'"/bin/sh"'|' $@/etc/init.d/rcS $@/etc/inittab
	sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $@/etc/fstab
	cp /etc/localtime $@/etc


## create alpine rootfs
# 由于 alpine 创建 rootfs 时会生成其他人无权限读写的文件，所以必须把 root id 映射成当前用户的 id
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -u):/g" /etc/subuid
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -g):/g" /etc/subgid
alpine: $(ALPINE_DIR)
$(ALPINE_DIR): mirror ?= $(ALPINE_MIRROR)
$(ALPINE_DIR):
	$(if $(ROOT_USER),,$(if $(SUDO),,
		$(if $(shell test $$(getsubids $$(whoami) | awk '{print $$3}') -eq $$(id -u) && echo true),,
			$(error subordinate user ID must be equal to UID, see subuid))
		$(if $(shell test $$(getsubids -g $$(whoami) | awk '{print $$3}') -eq $$(id -g) && echo true),,
			$(error subordinate group ID must be equal to GID, see subgid))
		map_users=$$(getsubids $$(whoami) | awk '{printf "%s,0,%s\n", $$3, $$4}')
		map_groups=$$(getsubids -g $$(whoami) | awk '{printf "%s,0,%s\n", $$3, $$4}')
		unshare="unshare --map-users=$${map_users} --map-groups=$${map_groups} --setuid 0 --setgid 0 --wd $@"
	))

	mkdir -p $@
	cd $@
	$(if $(ROOT_USER),,$(if $(SUDO),$(SUDO),$${unshare})) \
		$(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted -p . --initdb add \
		apk-tools $(alpine_extra_pkgs) coreutils busybox-extras zsh vim eza fd ripgrep hexyl wpa_supplicant btop \
		fzf fzf-vim fzf-zsh-plugin zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search

	# patches/rootfs
	$(SUDO) rsync -av $(PATCHES_DIR)/rootfs/ $@ --exclude='.gitkeep'
	$(SUDO) sed -i 's|$${LOGIN}|'"/bin/zsh"'|' $@/etc/init.d/rcS $@/etc/inittab
	$(SUDO) sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $@/etc/fstab
	$(SUDO) sed -i 's|$${MIRROR}|'"$(mirror)"'|' $@/etc/apk/repositories
	$(SUDO) cp /etc/localtime $@/etc


# clean
clean/qemu:
	$(MAKE) -C .. clean/$(@:clean/%=deps/%)
	rm -rf $(BUILD_QEMU_DIR)
clean/uboot:
	rm -rf $(BUILD_UBOOT_DIR)
clean/opensbi:
	$(MAKE) -C .. clean/$(@:clean/%=deps/%)
	rm -rf $(BUILD_OPENSBI_DIR)
clean/kernel:
	rm -rf $(BUILD_LINUX_DIR)
	rm -rf $(INSTALL_MOD_PATH)/lib/modules

clean/drivers:
	$(MAKE) -C ../drivers clean
$(addprefix clean/,$(SUB_DRIVERS)):
	$(MAKE) -C ../drivers clean/$(@:clean/$(arg2)/%=%)

clean/busybox:
	$(MAKE) -C .. clean/$(@:clean/%=deps/%)
	rm -rf $(BUILD_BUSYBOX_DIR) $(BUSYBOX_DIR)
clean/alpine:
	$(SUDO) rm -rf $(ALPINE_DIR)


## 创建目录
# NOTE 以目录作为依赖，有时候目录有可能被`更新`，导致 target 再次执行。
# 所以必须使用 [order-only-prerequisites](https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html)。
$(BUILD_QEMU_DIR) $(BUILD_LINUX_DIR) $(INSTALL_MOD_PATH) $(BUILD_OPENSBI_DIR) $(BUILD_BUSYBOX_DIR) $(IMAGES_DIR) $(MOUNT_POINT):
	mkdir -p $@


# 声明伪目录
.PHONY: opensbi kernel busybox alpine clean/* drivers drivers/*
