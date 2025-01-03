.ONESHELL:
.SHELLFLAGS = -ec

board := dock
all: $(board)
include rules.mk

SUDO := $(if $(ROOT_USER),,sudo)
mirror ?= $(ALPINE_MIRROR)

# targets
UBOOT_BIN := $(BUILD_UBOOT_DIR)/u-boot-sunxi-with-spl.bin
RTL8723DS_KO := $(BUILD_OUT_DIR)/lib/modules/$(KERNELRELEASE)/updates/8723ds.ko
SYSTEM_IMAGE := $(IMAGES_DIR)/dock-sd.img
ROOTFS_DOCK_DIR := $(ROOTFS_DIR)/$(board)


$(board): image

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): export KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(UBOOT_BIN): $(OPENSBI_BIN) | $(BUILD_UBOOT_DIR)
	cd $(DEPS_DIR)/uboot-d1
	$(MAKE) lichee_rv_dock_defconfig
	$(MAKE) OPENSBI=$<

## build kernel
$(LINUX_IMAGE) kernel/config: LINUX_CONF := lichee_rv_dock_config


modules: $(RTL8723DS_KO)

rtl8723ds: $(RTL8723DS_KO)
$(RTL8723DS_KO): export CONFIG_RTL8723DS := m
$(RTL8723DS_KO): $(LINUX_IMAGE)
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(DEPS_DIR)/rtl8723ds modules
	$(MAKE) -C $(BUILD_LINUX_DIR) M=$(DEPS_DIR)/rtl8723ds modules_install


# image
image: $(SYSTEM_IMAGE)
$(SYSTEM_IMAGE): alpine_extra_pkgs += tcpdump ethtool lftp
$(SYSTEM_IMAGE): $(UBOOT_BIN) $(LINUX_IMAGE) $(RTL8723DS_KO) $(ALPINE_DIR) $(ROOTFS_DOCK_DIR) | $(IMAGES_DIR) $(MOUNT_POINT)
	cd $(IMAGES_DIR)
	# Create a suitable empty file
	truncate -s 256M $(SYSTEM_IMAGE)
	# Write partition table on it
	parted -s -a optimal -- $(SYSTEM_IMAGE) mklabel gpt
	parted -s -a optimal -- $(SYSTEM_IMAGE) mkpart primary ext2 10MiB 60MiB
	parted -s -a optimal -- $(SYSTEM_IMAGE) mkpart primary ext4 60MiB 100%

	DEVICES=$$($(SUDO) losetup -f -P --show $(SYSTEM_IMAGE));
	# Write bootloader
	$(SUDO) dd if=$(UBOOT_BIN) of="$${DEVICES}" bs=8192 seek=16

	# Creating filesystem
	$(SUDO) mkfs.ext2 -F -L boot $${DEVICES}p1
	$(SUDO) mkfs.ext4 -F -L root $${DEVICES}p2
	# mount
	$(SUDO) mount $${DEVICES}p2 $(MOUNT_POINT)
	$(SUDO) mkdir $(MOUNT_POINT)/boot
	$(SUDO) mount $${DEVICES}p1 $(MOUNT_POINT)/boot

	# Copying rootfs
	$(SUDO) rsync -a $(ALPINE_DIR)/ $(MOUNT_POINT)
	$(SUDO) rsync -a $(ROOTFS_DOCK_DIR)/ $(MOUNT_POINT)

	# install kernel and modules
	$(SUDO) cp $(LINUX_IMAGE) $(MOUNT_POINT)/boot
	$(SUDO) mkdir -p $(MOUNT_POINT)/lib
	$(SUDO) rsync -av $(BUILD_OUT_DIR)/lib/modules $(MOUNT_POINT)/lib --exclude='build'

	# umount
	$(SUDO) umount -l $(MOUNT_POINT)
	# clean up
	$(SUDO) losetup -d $${DEVICES};

$(ROOTFS_DOCK_DIR):
	mkdir -p $@
	# patches/rootfs
	rsync -av $(BOARD_DIR)/rootfs/ $@ --exclude='.gitkeep'
	sed -i 's|$${LOGIN}|'"/bin/zsh"'|' $@/etc/init.d/rcS
	sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $@/etc/init.d/rcS
	cp /etc/resolv.conf $@/etc


# apk/<add|del|...>
# param1: root=<root mount point>
# param2: args=[args...]
apk/%:
	$(if $(root),,$(error sd card root partition mount point should be specified, e.g. root=/media/user/root))
	$(SUDO) $(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted -p $(root) \
		$(@:apk/%=%) $(args)

# param: dev=<device>
flash/uboot: $(UBOOT_BIN)
	$(if $(dev), \
		$(if $(filter $(dev),sda nvme0n1),$(error Primary disk '/dev/$(dev)' is not allowed.),),
		$(error Please specify an external storage device. e.g. dev=sdb)
	)
	$(SUDO) dd if=$(UBOOT_BIN) of=/dev/$(dev) bs=8192 seek=16


# clean
clean/ko:
	cd $(DEPS_DIR)/rtl8723ds
	git clean -fdx
	git reset --hard

clean/image:
	rm -fv $(SYSTEM_IMAGE)

clean: clean/ko clean/image clean/alpine
	rm -rf $(board) $(ROOTFS_DOCK_DIR) $(MOUNT_POINT)


## 创建目录
$(BUILD_UBOOT_DIR):
	mkdir -p $@

## help
help:
	@
	printf $(help_fmt) "  uboot"            "build U-Boot"
	printf $(help_fmt) "  kernel"           "build linux kernel"
	printf $(help_fmt) "  kernel/config"    "configure linux kernel"
	printf $(help_fmt) "  modules"          "build kernel modules"
	printf $(help_fmt) "  apk/<cmd>"        "run APK command to manage alpine packages"
	printf $(help_fmt) "  flash/uboot"      "burn U-Boot onto the SD card"

# 声明伪目录
.PHONY: all $(board) uboot kernel modules rtl8723ds image apk/% flash/uboot clean clean/* help
