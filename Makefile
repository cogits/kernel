.ONESHELL:
.SHELLFLAGS = -ec

ROOT := $(CURDIR)
BIN_PREFIX := $(ROOT)/result/bin
QEMU := $(BIN_PREFIX)/qemu-system-riscv64
QEMU_IMG := $(BIN_PREFIX)/qemu-img
APK_STATIC := apk.static

# build dirs
BUILD_DIR := $(ROOT)/result/build
BUILD_LINUX_DIR := $(BUILD_DIR)/qemu/linux
BUILD_LINUX_D1_DIR := $(BUILD_DIR)/d1/linux
BUILD_UBOOT_DIR := $(BUILD_DIR)/qemu/uboot
BUILD_UBOOT_D1_DIR := $(BUILD_DIR)/d1/uboot
BUILD_OPENSBI_DIR := $(BUILD_DIR)/d1/opensbi

export ARCH := riscv
export CROSS_COMPILE := riscv64-linux-gnu-

all: kernel rootfs modules

## kernel
# https://zhuanlan.zhihu.com/p/258394849
run: qemu kernel rootfs
	$(QEMU) -M virt -m 512M -smp 4 -nographic \
		-kernel deps/linux/arch/riscv/boot/Image \
		-drive file=result/rootfs.img,format=raw,id=hd0 \
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
kernel: $(BUILD_LINUX_DIR)/arch/riscv/boot/Image
$(BUILD_LINUX_DIR)/arch/riscv/boot/Image: KBUILD_OUTPUT := $(BUILD_LINUX_DIR)
$(BUILD_LINUX_DIR)/arch/riscv/boot/Image:
	mkdir -p $(KBUILD_OUTPUT)
	cp ./patches/linux/qemu-riscv64_config $(KBUILD_OUTPUT)/.config
	cd ./deps/linux
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) olddefconfig && $(MAKE)


## rootfs
rootfs: rootfs/busybox


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
rootfs/busybox: result/rootfs.img
result/rootfs.img: $(QEMU_IMG) deps/busybox/_install result/rootfs
	cd ./result
	$(QEMU_IMG) create rootfs.img 64m && mkfs.ext4 rootfs.img
	fuse-ext2 -o rw+ rootfs.img rootfs
	rsync -av $(ROOT)/patches/rootfs/ rootfs --exclude='.gitkeep'
	sed -i 's|$${LOGIN}|'"/bin/sh"'|' rootfs/etc/init.d/rcS
	sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' rootfs/etc/init.d/rcS
	cp -r $(ROOT)/deps/busybox/_install/* rootfs
	fusermount -u rootfs

deps/busybox/_install: DIFF_FILES := $(shell find patches/busybox -type f -name '*.diff')
deps/busybox/_install:
	# 找出 patches/busybox/ 目录下所有 diff 文件，并打补丁到 deps/busybox 目录
	$(foreach diff,$(DIFF_FILES),\
		patch -N $(patsubst patches/%.diff,deps/%,$(diff)) $(diff);)
	cp ./patches/busybox/config ./deps/busybox/.config
	cd ./deps/busybox
	$(MAKE) oldconfig
	$(MAKE) install


# requires root privileges
rootfs/alpine: mirror := https://mirror.tuna.tsinghua.edu.cn/alpine
rootfs/alpine: $(QEMU_IMG) result/rootfs
	cd ./result
	$(QEMU_IMG) create rootfs.img 128m && mkfs.ext4 rootfs.img
	sudo mount -o loop rootfs.img rootfs
	sudo $(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted \
		-p rootfs --initdb add apk-tools coreutils busybox-extras binutils musl-utils zsh vim \
		eza bat fd ripgrep hexyl btop fzf fzf-vim fzf-zsh-plugin zsh-syntax-highlighting \
		zsh-autosuggestions zsh-history-substring-search
	sudo rsync -av $(ROOT)/patches/rootfs/ rootfs --exclude='.gitkeep'
	sudo sed -i 's|$${LOGIN}|'"/bin/zsh"'|' rootfs/etc/init.d/rcS
	sudo sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' rootfs/etc/init.d/rcS
	sudo sed -i 's|$${MIRROR}|'"$(mirror)"'|' rootfs/etc/apk/repositories
	sudo umount rootfs

result/rootfs:
	mkdir -p result/rootfs

clean/rootfs:
	cd ./result
	rm -rf rootfs/ rootfs.img



## build qemu
# https://zhuanlan.zhihu.com/p/258394849
qemu: $(QEMU) $(QEMU_IMG)
# NOTE 不要让一个文件目标信赖于一个伪目标，否则即使文件存在，也总是执行伪目标。
# 当 $(QEMU) 生成时 $(QEMU_IMG) 也一并生成了。
$(QEMU_IMG): $(QEMU)
$(QEMU):
	mkdir -p ./deps/qemu/build
	cd ./deps/qemu/build
	../configure --target-list=riscv64-softmmu,riscv64-linux-user --enable-slirp --prefix=$(ROOT)/result
	$(MAKE) install


## kernel modules (add V=12 for verbose output)
modules: kernel
	# build drivers only
	# $(MAKE) -C $(BUILD_LINUX_DIR) M=$(PWD)/drivers modules
	# build drivers and user applications
	$(MAKE) -C drivers KERNEL_PATH=$(BUILD_LINUX_DIR)


## clean
# 清理 drivers 目录
clean:
	$(MAKE) -C drivers clean

# make clean/xxx
# 显式规则： $(CLEAN_DEPDIRS)
# 隐式规则（要小心，即使目录不存在也会匹配）：
clean/%:
	cd deps/$(@:clean/%=%)
	git clean -fdx
	git reset --hard
# 覆盖隐式规则
clean/result:
	rm -rf result/

# distclean
# `%` 不能单独用在右边的依赖名称中，所以必须定义变量
DEPS := $(wildcard deps/*)
CLEAN_DEPDIRS := $(DEPS:deps/%=clean/%)
distclean: $(CLEAN_DEPDIRS)
	git clean -fdx .


## uboot
# https://zhuanlan.zhihu.com/p/482858701
boot: qemu uboot
	$(QEMU) -M virt -m 512M -nographic -bios $(BUILD_UBOOT_DIR)/u-boot.bin

uboot: $(BUILD_UBOOT_DIR)/u-boot.bin
$(BUILD_UBOOT_DIR)/u-boot.bin: KBUILD_OUTPUT := $(BUILD_UBOOT_DIR)
$(BUILD_UBOOT_DIR)/u-boot.bin:
	mkdir -p $(KBUILD_OUTPUT)
	cd ./deps/u-boot
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) qemu-riscv64_defconfig && $(MAKE)

# 通过 u-boot 启动 kernel
# https://quard-star-tutorial.readthedocs.io (基于qemu-riscv从0开始构建嵌入式linux系统)
# https://www.jianshu.com/p/f7d5b6ad0710
# https://stdrc.cc/post/2021/02/23/u-boot-qemu-virt
# https://blog.csdn.net/wangyijieonline/article/details/104843769
# https://dingfen.github.io/risc-v/2020/07/23/RISC-V_on_QEMU.html


### d1
d1: d1/opensbi d1/uboot d1/kernel d1/rtl8723ds

## opensbi
d1/opensbi: $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin
$(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin:
	mkdir -p $(BUILD_OPENSBI_DIR)
	cd ./deps/opensbi
	$(MAKE) O=$(BUILD_OPENSBI_DIR) PLATFORM=generic PLATFORM_RISCV_XLEN=64

d1/uboot: $(BUILD_UBOOT_D1_DIR)/u-boot-sunxi-with-spl.bin
$(BUILD_UBOOT_D1_DIR)/u-boot-sunxi-with-spl.bin: KBUILD_OUTPUT := $(BUILD_UBOOT_D1_DIR)
$(BUILD_UBOOT_D1_DIR)/u-boot-sunxi-with-spl.bin: $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin
	mkdir -p $(KBUILD_OUTPUT)
	cd ./deps/uboot-d1
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) nezha_defconfig && $(MAKE) OPENSBI=$<

d1/kernel: $(BUILD_LINUX_D1_DIR)/arch/riscv/boot/Image
$(BUILD_LINUX_D1_DIR)/arch/riscv/boot/Image: KBUILD_OUTPUT := $(BUILD_LINUX_D1_DIR)
$(BUILD_LINUX_D1_DIR)/arch/riscv/boot/Image:
	mkdir -p $(KBUILD_OUTPUT)
	cp ./patches/linux/lichee_rv_dock_config $(KBUILD_OUTPUT)/.config
	cd ./deps/linux
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) olddefconfig
	$(MAKE)

d1/rtl8723ds: deps/rtl8723ds/8723ds.ko
deps/rtl8723ds/8723ds.ko: $(BUILD_LINUX_D1_DIR)/arch/riscv/boot/Image
	cd ./deps/rtl8723ds
	$(MAKE) KSRC=$(BUILD_LINUX_D1_DIR) modules


# 声明伪目录
.PHONY: all run telnet boot uboot qemu kernel rootfs rootfs/* modules d1 d1/* distclean clean clean/*
