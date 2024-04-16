.ONESHELL:
.SHELLFLAGS = -ec

APK_STATIC := apk.static
mirror ?= https://mirror.tuna.tsinghua.edu.cn/alpine

# build dirs
BUILD_LINUX_DIR := $(BUILD_DIR)/d1/linux
BUILD_UBOOT_DIR := $(BUILD_DIR)/d1/uboot
BUILD_OPENSBI_DIR := $(BUILD_DIR)/d1/opensbi
BUILD_OUT_DIR := $(BUILD_DIR)/d1/out

# 控制 modules 安装路径
export INSTALL_MOD_PATH := $(BUILD_OUT_DIR)
export KERNELRELEASE ?= 6.7.0

# targets
OPENSBI_BIN := $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin
UBOOT_BIN := $(BUILD_UBOOT_DIR)/u-boot-sunxi-with-spl.bin
LINUX_IMAGE := $(BUILD_LINUX_DIR)/arch/riscv/boot/Image
RTL8723DS_KO := $(BUILD_OUT_DIR)/lib/modules/$(KERNELRELEASE)/updates/8723ds.ko
SYSTEM_IMAGE := $(BUILD_DIR)/d1_full.img
MOUNTPOINT := $(BUILD_DIR)/chroot_alpine

### d1
all: d1
d1: uboot kernel rtl8723ds

## opensbi
opensbi: $(OPENSBI_BIN)
$(OPENSBI_BIN): $(BUILD_OPENSBI_DIR)
	cd $(DEPS_DIR)/opensbi
	$(MAKE) O=$(BUILD_OPENSBI_DIR) PLATFORM=generic PLATFORM_RISCV_XLEN=64

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): export KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(UBOOT_BIN): $(OPENSBI_BIN) $(BUILD_UBOOT_DIR)
	cd $(DEPS_DIR)/uboot-d1
	$(MAKE) nezha_defconfig
	$(MAKE) OPENSBI=$<

kernel: $(LINUX_IMAGE)
$(LINUX_IMAGE): export KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
$(LINUX_IMAGE):
	mkdir -p $(KBUILD_OUTPUT) $(BUILD_OUT_DIR)
	cp $(PATCHES_DIR)/linux/lichee_rv_dock_config $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/linux
	$(MAKE) olddefconfig
	$(MAKE)
	$(MAKE) modules_install

rtl8723ds: $(RTL8723DS_KO)
$(RTL8723DS_KO): export CONFIG_RTL8723DS := m
$(RTL8723DS_KO): $(LINUX_IMAGE)
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(DEPS_DIR)/rtl8723ds modules
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(DEPS_DIR)/rtl8723ds modules_install


# image
image: $(SYSTEM_IMAGE)
$(SYSTEM_IMAGE): SUDO := sudo
$(SYSTEM_IMAGE): PERCENT := %
$(SYSTEM_IMAGE): $(MOUNTPOINT) $(UBOOT_BIN) $(LINUX_IMAGE)
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
		tcpdump ethtool

	$(SUDO) rsync -av $(PATCHES_DIR)/rootfs/ $(MOUNTPOINT) --exclude='.gitkeep'
	$(SUDO) rsync -av $(PATCHES_DIR)/d1/rootfs/ $(MOUNTPOINT) --exclude='.gitkeep'
	$(SUDO) cp /etc/resolv.conf $(MOUNTPOINT)/etc
	$(SUDO) sed -i 's|$${LOGIN}|'"/bin/zsh"'|' $(MOUNTPOINT)/etc/init.d/rcS
	$(SUDO) sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $(MOUNTPOINT)/etc/init.d/rcS
	$(SUDO) sed -i 's|$${MIRROR}|'"$(mirror)"'|' $(MOUNTPOINT)/etc/apk/repositories

	# install kernel and modules
	$(SUDO) cp $(LINUX_IMAGE) $(MOUNTPOINT)/boot
	$(SUDO) mkdir -p $(MOUNTPOINT)/lib
	$(SUDO) rsync -av $(BUILD_OUT_DIR)/lib/modules $(MOUNTPOINT)/lib

	# umount
	$(SUDO) umount -l $(MOUNTPOINT)
	# clean up
	$(SUDO) losetup -d $${DEVICES};

# clean
clean/kernel:
	rm -rf $(BUILD_LINUX_DIR)
	rm -rf $(BUILD_OUT_DIR)
clean/uboot:
	rm -rf $(BUILD_UBOOT_DIR)
clean/opensbi:
	rm -rf $(BUILD_OPENSBI_DIR)
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
# NOTE 以目录作为依赖，有时候目录有可能被`更新`，导致 target 再次执行。比如 BUILD_LINUX_DIR
$(BUILD_OPENSBI_DIR) $(BUILD_UBOOT_DIR) $(BUILD_OUT_DIR) $(MOUNTPOINT):
	mkdir -p $@


# 声明伪目录
.PHONY: all boot uboot qemu kernel rootfs rootfs/* modules d1 d1/* distclean clean clean/*
