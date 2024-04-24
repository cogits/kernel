.ONESHELL:
.SHELLFLAGS = -ec

all: virt
board := virt
include build/targets.mk

BUILD_QEMU_DIR := $(BUILD_DIR)/$(board)/qemu
QEMU := $(BUILD_OUT_DIR)/bin/qemu-system-riscv64

# targets
CHROOT_DIR := $(BUILD_DIR)/chroot_alpine
ROOTFS_DIR := $(BUILD_DIR)/rootfs
ROOTFS_IMAGE := $(BUILD_DIR)/rootfs.img
BUSYBOX_INSTALL := $(DEPS_DIR)/busybox/_install
UBOOT_BIN := $(BUILD_UBOOT_DIR)/u-boot.bin


virt: qemu kernel busybox modules

## kernel
# https://zhuanlan.zhihu.com/p/258394849
run: qemu kernel rootfs opensbi
	$(QEMU) -M virt -m 512M -smp 4 -nographic \
		-bios $(OPENSBI_BIN) \
		-kernel $(LINUX_IMAGE) \
		-drive file=$(ROOTFS_IMAGE),format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-netdev user,id=host_net0,hostfwd=tcp::7023-:23 \
		-device e1000,mac=52:54:00:12:34:50,netdev=host_net0 \
		-netdev user,id=host_net1 \
		-device e1000,mac=52:54:00:12:34:56,netdev=host_net1 \
		-append "root=/dev/vda rw console=ttyS0"

## telnet
# https://github.com/d0u9/Linux-Device-Driver/blob/master/02_getting_start_with_driver_development/05_telnet_server.md
telnet:
	telnet localhost 7023

## build kernel
kernel: LINUX_CONF := qemu-riscv64_config


## rootfs
rootfs: $(ROOTFS_IMAGE)

VALID_SUBUID := $(if $(ROOT_USER),,$(shell test $$(getsubids $$(whoami) | awk '{print $$3}') -eq $$(id -u) && echo true))
VALID_SUBGID := $(if $(ROOT_USER),,$(shell test $$(getsubids -g $$(whoami) | awk '{print $$3}') -eq $$(id -g) && echo true))
ALLOW_OTHER := $(shell grep '^ *user_allow_other' /etc/fuse.conf)

# 'user_allow_other' should be set in /etc/fuse.conf
define fuse-mount
  mount_opt='rw+,allow_other,uid=0,gid=0'
  $(if $(ALLOW_OTHER),,
    mount_opt='rw+'
  )
  fuse-ext2 -o $${mount_opt} $(ROOTFS_IMAGE) $(ROOTFS_DIR)
  $(1)
  fusermount -u $(ROOTFS_DIR)
endef

define mount-loop
  $(SUDO) mount -o loop $(ROOTFS_IMAGE) $(ROOTFS_DIR)
  $(1)
  $(SUDO) umount $(ROOTFS_DIR)
endef

define create-ext4-rootfs
  truncate -s $(1)M $(ROOTFS_IMAGE)
  mkfs.ext4 $(ROOTFS_IMAGE)
endef

## rootfs/busybox
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
rootfs/busybox: $(ROOTFS_IMAGE)
$(ROOTFS_IMAGE): $(BUSYBOX_INSTALL) $(ROOTFS_DIR)
	cd $(BUILD_DIR)
	$(call create-ext4-rootfs,64)

	$(call fuse-mount,
		rsync -av $(PATCHES_DIR)/rootfs/ rootfs --exclude='.gitkeep'
		sed -i 's|$${LOGIN}|'"/bin/sh"'|' rootfs/etc/init.d/rcS
		sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' rootfs/etc/init.d/rcS
		cp -r $(BUSYBOX_INSTALL)/* rootfs
		test -d $(BUILD_OUT_DIR)/lib/modules && rsync -av $(BUILD_OUT_DIR)/lib/modules rootfs/lib --exclude='build'
	)

busybox: $(BUSYBOX_INSTALL)
$(BUSYBOX_INSTALL): DIFF_FILES := $(shell find $(PATCHES_DIR)/busybox -type f -name '*.diff')
$(BUSYBOX_INSTALL):
	# 找出 patches/busybox/ 目录下所有 diff 文件，并打补丁到 deps/busybox 目录
	$(foreach diff,$(DIFF_FILES),
		patch -N $(patsubst $(PATCHES_DIR)/%.diff,$(DEPS_DIR)/%,$(diff)) $(diff)
	)
	cp $(PATCHES_DIR)/busybox/config $(DEPS_DIR)/busybox/.config
	cd $(DEPS_DIR)/busybox
	$(MAKE) oldconfig
	$(MAKE) install


# requires root privileges
rootfs/alpine/root: SUDO := $(if $(ROOT_USER),,sudo)
rootfs/alpine/root: rootfs/alpine

# rootless method
# 由于 alpine 创建 rootfs 时会生成其他人无权限读写的文件，所以必须把 root id 映射成当前用户的 id
# ```sh
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -u):/g" /etc/subuid
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -g):/g" /etc/subgid
# ```
# https://blog.brixit.nl/bootstrapping-alpine-linux-without-root
rootfs/alpine: mirror ?= $(ALPINE_MIRROR)
rootfs/alpine: $(ROOTFS_DIR) $(CHROOT_DIR)
	cd $(BUILD_DIR)
	$(call create-ext4-rootfs,128)

	$(if $(ROOT_USER),,$(if $(SUDO),,
		$(if $(VALID_SUBUID),,$(error subordinate user ID must be equal to UID, see subuid))
		$(if $(VALID_SUBGID),,$(error subordinate group ID must be equal to GID, see subgid))
		map_users=$$(getsubids $$(whoami) | awk '{printf "%s,0,%s\n", $$3, $$4}')
		map_groups=$$(getsubids -g $$(whoami) | awk '{printf "%s,0,%s\n", $$3, $$4}')
		unshare_cmd="unshare --map-users=$${map_users} --map-groups=$${map_groups} --setuid 0 --setgid 0 --wd $(CHROOT_DIR)"
	))

	cd $(CHROOT_DIR)
	$(if $(ROOT_USER),,$(if $(SUDO),$(SUDO),$${unshare_cmd})) \
		$(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted -p . --initdb add \
		apk-tools coreutils busybox-extras binutils musl-utils zsh vim eza bat fd ripgrep hexyl btop fzf \
		fzf-vim fzf-zsh-plugin zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search

	$(call $(if $(ROOT_USER),mount-loop,$(if $(SUDO),mount-loop,fuse-mount)),
		$(SUDO) rsync -a $(CHROOT_DIR)/ $(ROOTFS_DIR)
		$(SUDO) rsync -av $(PATCHES_DIR)/rootfs/ $(ROOTFS_DIR) --exclude='.gitkeep'
		$(SUDO) sed -i 's|$${LOGIN}|'"/bin/zsh"'|' $(ROOTFS_DIR)/etc/init.d/rcS
		$(SUDO) sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' $(ROOTFS_DIR)/etc/init.d/rcS
		$(SUDO) sed -i 's|$${MIRROR}|'"$(mirror)"'|' $(ROOTFS_DIR)/etc/apk/repositories
		test -d $(BUILD_OUT_DIR)/lib/modules && $(SUDO) rsync -av $(BUILD_OUT_DIR)/lib/modules $(ROOTFS_DIR)/lib --exclude='build'
	)
	$(if $(SUDO),$(SUDO) rm -rf $(CHROOT_DIR),)


## build qemu
# https://zhuanlan.zhihu.com/p/258394849
# NOTE 不要让一个文件目标信赖于一个伪目标，否则即使文件存在，也总是执行伪目标。
qemu: $(QEMU)
$(QEMU):
	mkdir -p $(BUILD_QEMU_DIR)
	cd $(BUILD_QEMU_DIR)
	$(DEPS_DIR)/qemu/configure --target-list=riscv64-softmmu,riscv64-linux-user --enable-slirp --prefix=$(BUILD_OUT_DIR)
	$(MAKE) install


## kernel modules (add V=12 for verbose output)
modules: $(LINUX_IMAGE)
	# build drivers only
	# $(MAKE) -C $(BUILD_LINUX_DIR) M=$(ROOT)/drivers modules
	# build drivers and user applications
	$(MAKE) -C $(ROOT)/drivers KERNEL_PATH=$(BUILD_LINUX_DIR)


## clean
# 清理 drivers 目录
clean:
	$(MAKE) -C $(ROOT)/drivers clean

clean/qemu:
	rm -rf $(BUILD_QEMU_DIR)

clean/rootfs:
	rm -rf $(BUILD_DIR)/rootfs*

# distclean
distclean: clean clean/rootfs
	rm -rf $(BUILD_DIR)/virt
	rm -rf $(CHROOT_DIR)


## uboot
# https://zhuanlan.zhihu.com/p/482858701
boot: qemu uboot
	$(QEMU) -M virt -m 512M -nographic -bios $(UBOOT_BIN)

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): export KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(UBOOT_BIN): $(BUILD_UBOOT_DIR)
	cd $(DEPS_DIR)/u-boot
	$(MAKE) qemu-riscv64_defconfig && $(MAKE)

# 通过 u-boot 启动 kernel
# https://quard-star-tutorial.readthedocs.io (基于qemu-riscv从0开始构建嵌入式linux系统)
# https://www.jianshu.com/p/f7d5b6ad0710
# https://stdrc.cc/post/2021/02/23/u-boot-qemu-virt
# https://blog.csdn.net/wangyijieonline/article/details/104843769
# https://dingfen.github.io/risc-v/2020/07/23/RISC-V_on_QEMU.html


## 创建目录
# NOTE 以目录作为依赖，有时候目录有可能被`更新`，导致 target 再次执行。比如 BUILD_QEMU_DIR
$(ROOTFS_DIR) $(CHROOT_DIR) $(BUILD_UBOOT_DIR):
	mkdir -p $@


# 声明伪目录
.PHONY: all run telnet boot uboot qemu kernel rootfs rootfs/* modules distclean clean clean/*
