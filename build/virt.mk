.ONESHELL:
.SHELLFLAGS = -ec

# build dirs
BUILD_QEMU_DIR := $(BUILD_DIR)/qemu
BUILD_LINUX_DIR := $(BUILD_DIR)/virt/linux
BUILD_UBOOT_DIR := $(BUILD_DIR)/virt/uboot

QEMU_RESULT := $(BUILD_QEMU_DIR)/result
BIN_PREFIX := $(QEMU_RESULT)/bin
QEMU := $(BIN_PREFIX)/qemu-system-riscv64
APK_STATIC := apk.static

# targets
LINUX_IMAGE := $(BUILD_LINUX_DIR)/arch/riscv/boot/Image
CHROOT_DIR := $(BUILD_DIR)/chroot_alpine
ROOTFS_DIR := $(BUILD_DIR)/rootfs
ROOTFS_IMAGE := $(BUILD_DIR)/rootfs.img
BUSYBOX_INSTALL := $(DEPS_DIR)/busybox/_install
UBOOT_BIN := $(BUILD_UBOOT_DIR)/u-boot.bin


all: virt
virt: kernel rootfs modules

## kernel
# https://zhuanlan.zhihu.com/p/258394849
run: qemu kernel rootfs
	$(QEMU) -M virt -m 512M -smp 4 -nographic \
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
# https://github.com/d0u9/Linux-Device-Driver
kernel: $(LINUX_IMAGE)
$(LINUX_IMAGE): KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
$(LINUX_IMAGE):
	mkdir -p $(KBUILD_OUTPUT)
	cp $(PATCHES_DIR)/linux/qemu-riscv64_config $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/linux
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) olddefconfig && $(MAKE)


## rootfs
rootfs: $(ROOTFS_IMAGE)

define fuse-mount
fuse-ext2 -o rw+ $(ROOTFS_IMAGE) $(ROOTFS_DIR)
$(1)
fusermount -u $(ROOTFS_DIR)
endef

define mount-loop
$(SUDO) mount -o loop $(ROOTFS_IMAGE) $(ROOTFS_DIR)
$(1)
$(SUDO) umount $(ROOTFS_DIR)
endef

define create-ext4-rootfs
dd if=/dev/zero of=$(ROOTFS_IMAGE) bs=1M count=$(1)
mkfs.ext4 $(ROOTFS_IMAGE)
endef

ROOT_USER := $(shell test $$(id -u) -eq 0 && echo true)
VALID_SUBUID := $(if $(ROOT_USER),,$(shell test $$(getsubids $$(whoami) | awk '{print $$3}') -eq $$(id -u) && echo true))
VALID_SUBGID := $(if $(ROOT_USER),,$(shell test $$(getsubids -g $$(whoami) | awk '{print $$3}') -eq $$(id -g) && echo true))

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
	)

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
rootfs/alpine/root: SUDO := sudo
rootfs/alpine/root: rootfs/alpine

# rootless method
# 由于 alpine 创建 rootfs 时会生成其他人无权限读写的文件，所以必须把 root id 映射成当前用户的 id
# ```sh
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -u):/g" /etc/subuid
# $ sudo sed -i "s/$(whoami):\([0-9]\+\):/$(whoami):$(id -g):/g" /etc/subgid
# ```
# https://blog.brixit.nl/bootstrapping-alpine-linux-without-root
rootfs/alpine: mirror ?= https://mirror.tuna.tsinghua.edu.cn/alpine
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
	)
	$(SUDO) rm -rf $(CHROOT_DIR)


$(ROOTFS_DIR) $(CHROOT_DIR):
	mkdir -p $@



## build qemu
# https://zhuanlan.zhihu.com/p/258394849
# NOTE 不要让一个文件目标信赖于一个伪目标，否则即使文件存在，也总是执行伪目标。
qemu: $(QEMU)
$(QEMU):
	mkdir -p $(BUILD_QEMU_DIR)
	cd $(BUILD_QEMU_DIR)
	$(DEPS_DIR)/qemu/configure --target-list=riscv64-softmmu,riscv64-linux-user --enable-slirp --prefix=$(QEMU_RESULT)
	$(MAKE) install


## kernel modules (add V=12 for verbose output)
modules: kernel
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

clean/kernel:
	rm -rf $(BUILD_LINUX_DIR)

clean/u-boot:
	rm -rf $(BUILD_UBOOT_DIR)

clean/rootfs:
	rm -rf $(BUILD_DIR)/rootfs*
	cd $(DEPS_DIR)/busybox
	git clean -fdx
	git reset --hard

# distclean
SUB_CLEAN := qemu kernel u-boot rootfs
CLEAN_TARGETS := $(SUB_CLEAN:%=clean/%)
distclean: clean $(CLEAN_TARGETS)


## uboot
# https://zhuanlan.zhihu.com/p/482858701
boot: qemu uboot
	$(QEMU) -M virt -m 512M -nographic -bios $(UBOOT_BIN)

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(UBOOT_BIN):
	mkdir -p $(KBUILD_OUTPUT)
	cd $(DEPS_DIR)/u-boot
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) qemu-riscv64_defconfig && $(MAKE)

# 通过 u-boot 启动 kernel
# https://quard-star-tutorial.readthedocs.io (基于qemu-riscv从0开始构建嵌入式linux系统)
# https://www.jianshu.com/p/f7d5b6ad0710
# https://stdrc.cc/post/2021/02/23/u-boot-qemu-virt
# https://blog.csdn.net/wangyijieonline/article/details/104843769
# https://dingfen.github.io/risc-v/2020/07/23/RISC-V_on_QEMU.html


# 声明伪目录
.PHONY: all run telnet boot uboot qemu kernel rootfs rootfs/* modules distclean clean clean/*
