.ONESHELL:
.SHELLFLAGS = -ec

all: d1
board := d1
include build/rules.mk

SUDO := $(if $(ROOT_USER),,sudo)
mirror ?= $(ALPINE_MIRROR)

# targets
UBOOT_BIN := $(BUILD_UBOOT_DIR)/u-boot-sunxi-with-spl.bin
RTL8723DS_KO := $(BUILD_OUT_DIR)/lib/modules/$(KERNELRELEASE)/updates/8723ds.ko
SYSTEM_IMAGE := $(BUILD_DIR)/d1_full.img
MOUNTPOINT := $(BUILD_DIR)/chroot_alpine


d1: uboot kernel modules

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): export KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(UBOOT_BIN): $(OPENSBI_BIN) | $(BUILD_UBOOT_DIR)
	cd $(DEPS_DIR)/uboot-d1
	$(MAKE) nezha_defconfig
	$(MAKE) OPENSBI=$<

kernel: LINUX_CONF := lichee_rv_dock_config

modules: $(RTL8723DS_KO)

rtl8723ds: $(RTL8723DS_KO)
$(RTL8723DS_KO): export CONFIG_RTL8723DS := m
$(RTL8723DS_KO): $(LINUX_IMAGE)
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(DEPS_DIR)/rtl8723ds modules
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(DEPS_DIR)/rtl8723ds modules_install


# image
image: $(SYSTEM_IMAGE)
$(SYSTEM_IMAGE): PERCENT := %
$(SYSTEM_IMAGE): $(UBOOT_BIN) $(LINUX_IMAGE) $(RTL8723DS_KO) | $(MOUNTPOINT)
	cd $(BUILD_DIR)
	# Create a suitable empty file
	dd if=/dev/zero of=$(SYSTEM_IMAGE) bs=1M count=256
	# Write partition table on it
	parted -s -a optimal -- $(SYSTEM_IMAGE) mklabel gpt
	parted -s -a optimal -- $(SYSTEM_IMAGE) mkpart primary ext2 10MiB 60MiB
	parted -s -a optimal -- $(SYSTEM_IMAGE) mkpart primary ext4 60MiB 100$(PERCENT)
	# Write rootfs, kernel and boot config
	DEVICES=$$($(SUDO) losetup -f -P --show $(SYSTEM_IMAGE));
	# Write bootloader
	$(SUDO) dd if=$(UBOOT_BIN) of="$${DEVICES}" bs=8192 seek=16
	# Creating filesystem
	$(SUDO) mkfs.ext2 -F -L boot $${DEVICES}p1
	$(SUDO) mkfs.ext4 -F -L root $${DEVICES}p2
	# mount
	$(SUDO) mount $${DEVICES}p2 $(MOUNTPOINT)
	$(SUDO) mkdir $(MOUNTPOINT)/boot
	$(SUDO) mount $${DEVICES}p1 $(MOUNTPOINT)/boot
	# Writing rootfs and kernel
	cd $(MOUNTPOINT)
	$(SUDO) $(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted -p . --initdb add \
		apk-tools coreutils busybox-extras binutils musl-utils zsh vim eza bat fd ripgrep hexyl btop fzf \
		fzf-vim fzf-zsh-plugin zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search \
		tcpdump ethtool wpa_supplicant lftp

	$(SUDO) rsync -av $(PATCHES_DIR)/rootfs/ $(MOUNTPOINT) --exclude='.gitkeep'
	$(SUDO) rsync -av $(PATCHES_DIR)/d1/rootfs/ $(MOUNTPOINT) --exclude='.gitkeep'
	$(SUDO) cp /etc/resolv.conf $(MOUNTPOINT)/etc
	$(SUDO) sed -i 's|$${LOGIN}|'"/bin/zsh"'|' $(MOUNTPOINT)/etc/init.d/rcS
	$(SUDO) sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $(MOUNTPOINT)/etc/init.d/rcS
	$(SUDO) sed -i 's|$${MIRROR}|'"$(mirror)"'|' $(MOUNTPOINT)/etc/apk/repositories

	# install kernel and modules
	$(SUDO) cp $(LINUX_IMAGE) $(MOUNTPOINT)/boot
	$(SUDO) mkdir -p $(MOUNTPOINT)/lib
	$(SUDO) rsync -av $(BUILD_OUT_DIR)/lib/modules $(MOUNTPOINT)/lib --exclude='build'

	# umount
	$(SUDO) umount -l $(MOUNTPOINT)
	# clean up
	$(SUDO) losetup -d $${DEVICES};


# apk/<add|del|...>
# param1: root=<root mount point>
# param2: args=[args...]
apk/%:
	$(if $(root),,$(error sd card root partition mountpoint should be specified, e.g. root=/media/user/root))
	$(SUDO) $(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted -p $(root) \
		$(@:apk/%=%) $(args)

# clean
clean/ko:
	cd $(DEPS_DIR)/rtl8723ds
	git clean -fdx
	git reset --hard

clean/image:
	rm -fv $(SYSTEM_IMAGE)

distclean: clean/ko clean/image
	rm -rf $(BUILD_DIR)/d1
	rm -rf $(MOUNTPOINT)


## 创建目录
$(BUILD_UBOOT_DIR) $(MOUNTPOINT):
	mkdir -p $@


# 声明伪目录
.PHONY: all boot uboot qemu kernel rootfs rootfs/* modules d1 d1/* distclean clean clean/*
