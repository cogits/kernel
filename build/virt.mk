.ONESHELL:
.SHELLFLAGS = -ec

all: virt
board := virt
include rules.mk

# targets
ROOTFS_IMAGE := $(IMAGES_DIR)/rootfs.img
UBOOT_BIN := $(BUILD_UBOOT_DIR)/u-boot.bin


virt: kernel drivers image

## kernel
# https://zhuanlan.zhihu.com/p/258394849
run: qemu opensbi kernel image
	$(QEMU) -M virt -m 512M -smp 4 -nographic \
		-bios $(OPENSBI_BIN) \
		-kernel $(LINUX_IMAGE) \
		-drive file=$(ROOTFS_IMAGE),format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-netdev user,id=host_net0,hostfwd=tcp::7023-:23 \
		-device e1000,mac=52:54:00:12:34:50,netdev=host_net0 \
		-append "root=/dev/vda rw console=ttyS0"

## telnet
# https://github.com/d0u9/Linux-Device-Driver/blob/master/02_getting_start_with_driver_development/05_telnet_server.md
telnet:
	telnet localhost 7023

## build kernel
$(LINUX_IMAGE): LINUX_CONF := qemu-riscv64_config


## images [rootfs=<busybox|alpine>]
image: $(ROOTFS_IMAGE)


# NOTE
# 文件目标依赖于伪目标，即使文件存在，也总是执行伪目标。
# 所以需要手动判断文件是否存在，不存在时再动态地创建规则。
ifeq ($(wildcard $(ROOTFS_IMAGE)),)
ifeq ($(rootfs),alpine)
$(ROOTFS_IMAGE): image/alpine
else
$(ROOTFS_IMAGE): image/busybox
endif
endif


define fuse-mount
  fuse2fs $(ROOTFS_IMAGE) $(MOUNT_POINT) -o fakeroot
  $(1)
  chown -R root:root $(MOUNT_POINT)
  fusermount -u $(MOUNT_POINT)
endef

define mount-loop
  $(SUDO) mount -o loop $(ROOTFS_IMAGE) $(MOUNT_POINT)
  $(1)
  $(SUDO) chown -R root $(MOUNT_POINT)
  $(SUDO) umount $(MOUNT_POINT)
endef

define create-ext4-rootfs
  truncate -s $(1)M $(ROOTFS_IMAGE)
  mkfs.ext4 $(ROOTFS_IMAGE)
endef

## image/busybox
# https://zhuanlan.zhihu.com/p/258394849
# https://wiki.debian.org/ManipulatingISOs#Loopmount_an_ISO_Without_Administrative_Privileges
# https://manpages.debian.org/bookworm/fuseext2/fuseext2.1.en.html
#
## NFS support
# https://github.com/d0u9/Linux-Device-Driver/blob/master/02_getting_start_with_driver_development/04_nfs_support.md
# ```sh
# sudo apt install nfs-kernel-server
# sudo echo '${宿主机共享目录}      127.0.0.1(insecure,rw,sync,no_root_squash)' >> /etc/exports
# ```
image/busybox: $(BUSYBOX_DIR) | $(IMAGES_DIR) $(MOUNT_POINT)
	cd $(IMAGES_DIR)
	$(call create-ext4-rootfs,64)

	$(call $(if $(ROOT_USER),mount-loop,$(if $(SUDO),mount-loop,fuse-mount)),
		$(SUDO) rsync -a $(BUSYBOX_DIR)/ $(MOUNT_POINT)
		test -d $(BUILD_OUT_DIR)/lib/modules && \
			$(SUDO) rsync -av $(BUILD_OUT_DIR)/lib/modules $(MOUNT_POINT)/lib --exclude='build'
	)


# rootless method
# https://blog.brixit.nl/bootstrapping-alpine-linux-without-root
image/alpine: alpine_extra_pkgs += binutils musl-utils
image/alpine: $(ALPINE_DIR) | $(IMAGES_DIR) $(MOUNT_POINT)
	cd $(IMAGES_DIR)
	$(call create-ext4-rootfs,128)

	$(call $(if $(ROOT_USER),mount-loop,$(if $(SUDO),mount-loop,fuse-mount)),
		$(SUDO) rsync -a $(ALPINE_DIR)/ $(MOUNT_POINT)
		test -d $(BUILD_OUT_DIR)/lib/modules && \
			$(SUDO) rsync -av $(BUILD_OUT_DIR)/lib/modules $(MOUNT_POINT)/lib --exclude='build'
	)


## clean
clean/image:
	rm -fv $(ROOTFS_IMAGE)

# distclean
distclean: clean clean/image
	rm -rf virt/


## uboot
# https://zhuanlan.zhihu.com/p/482858701
boot: qemu uboot
	$(QEMU) -M virt -m 512M -nographic -bios $(UBOOT_BIN)

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): export KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(UBOOT_BIN): | $(BUILD_UBOOT_DIR)
	cd $(DEPS_DIR)/u-boot
	$(MAKE) qemu-riscv64_defconfig && $(MAKE)

# 通过 u-boot 启动 kernel
# https://www.jianshu.com/p/f7d5b6ad0710
# https://stdrc.cc/post/2021/02/23/u-boot-qemu-virt
# https://blog.csdn.net/wangyijieonline/article/details/104843769


## 创建目录
$(BUILD_UBOOT_DIR):
	mkdir -p $@


# 声明伪目录
.PHONY: all run telnet boot uboot qemu kernel image image/* drivers distclean clean clean/*
