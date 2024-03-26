ROOT := $(CURDIR)
BIN_PREFIX := result/bin
QEMU := $(BIN_PREFIX)/qemu-system-riscv64
QEMU_IMG := $(BIN_PREFIX)/qemu-img

export ARCH := riscv
export CROSS_COMPILE := riscv64-linux-gnu-
export KERNEL_PATH := $(ROOT)/deps/linux

all: kernel rootfs modules

## kernel
# https://zhuanlan.zhihu.com/p/258394849
run: qemu kernel rootfs
	$(QEMU) -M virt -m 512M -smp 4 -nographic \
		-kernel deps/linux/arch/riscv/boot/Image \
		-drive file=deps/busybox/rootfs.img,format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-netdev user,id=host_net0,hostfwd=tcp::7023-:23 \
		-device e1000,mac=52:54:00:12:34:50,netdev=host_net0 \
		-netdev user,id=host_net1 \
		-device e1000,mac=52:54:00:12:34:56,netdev=host_net1 \
		-append "root=/dev/vda rw console=ttyS0"

# https://github.com/d0u9/Linux-Device-Driver
kernel: deps/linux/arch/riscv/boot/Image
deps/linux/arch/riscv/boot/Image:
	cp ./patches/linux/config ./deps/linux/.config
	cd ./deps/linux && $(MAKE) olddefconfig && $(MAKE)


## rootfs/busybox
# https://zhuanlan.zhihu.com/p/258394849
# https://wiki.debian.org/ManipulatingISOs#Loopmount_an_ISO_Without_Administrative_Privileges
# https://manpages.debian.org/bookworm/fuseext2/fuseext2.1.en.html
#
## NFS support
# https://github.com/d0u9/Linux-Device-Driver/blob/master/02_getting_start_with_driver_development/04_nfs_support.md
# ```sh
# sudo apt install nfs-kernel-server
# sudo echo '$宿主机共享目录        127.0.0.1(insecure,rw,sync,no_root_squash)' >> /etc/exports
# ```
rootfs: deps/busybox/rootfs.img
deps/busybox/rootfs.img: qemu deps/busybox/_install
	cd ./deps/busybox && $(QEMU_IMG) create rootfs.img 64m && mkfs.ext4 rootfs.img \
		&& mkdir -p rootfs && fuse-ext2 -o rw+ rootfs.img rootfs \
		&& rsync -av $(ROOT)/patches/busybox/rootfs/ rootfs --exclude='.gitkeep' \
		&& sed -i 's|$${HOST_PATH}|'"$(ROOT)"'|' rootfs/etc/init.d/rcS \
		&& cp -r ./_install/* rootfs && fusermount -u rootfs

deps/busybox/_install: DIFF_FILES := $(shell find patches/busybox -type f -name '*.diff' | grep -v "^patches/busybox/rootfs")
deps/busybox/_install:
	# 找出 patches/busybox/*~*rootfs(/) 目录下所有 diff 文件，并打补丁到 deps/busybox 目录
	$(foreach diff,$(DIFF_FILES),\
		patch -N $(patsubst patches/%.diff,deps/%,$(diff)) $(diff);)
	cp ./patches/busybox/config ./deps/busybox/.config
	cd ./deps/busybox/ && $(MAKE) oldconfig && $(MAKE) install

qemu: $(QEMU)
$(QEMU):
	cd ./deps/qemu && mkdir -p build && cd build \
		&& ../configure --target-list=riscv64-softmmu,riscv64-linux-user --prefix=$(ROOT)/result \
		&& $(MAKE) install

## telnet
# https://github.com/d0u9/Linux-Device-Driver/blob/master/02_getting_start_with_driver_development/05_telnet_server.md
telnet:
	telnet localhost 7023


## modules (add V=12 for verbose output)
# there's two ways of building external modules
modules: kernel
	# for lkmpg/hello
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD)/lkmpg modules
	# for others
	$(MAKE) -C lkmpg

# NOTE $(SUBDIR) 不能是局部变量
DEPS := busybox linux u-boot qemu
SUBDIR := $(patsubst %,deps/%,$(DEPS)) lkmpg
## clean
clean:
# distclean
ifeq ($(dir),)
	$(foreach dir,$(DEPS),\
		cd $(CURDIR)/deps/$(dir); git clean -fdx .; git reset --hard;)
	git clean -fdx .
else
# 清理子目录
# make clean dir=xxx
ifeq (,$(findstring $(dir),$(SUBDIR)))
	$(error $(dir) not exist in $(SUBDIR))
endif
ifneq (,$(filter deps/$(dir),$(SUBDIR)))
	cd deps/$(dir) && git clean -fdx . && git reset --hard
else
	$(MAKE) -C lkmpg clean
endif
endif


## uboot
# https://zhuanlan.zhihu.com/p/482858701
boot: qemu uboot
	$(QEMU) -M virt -m 512M -nographic -bios deps/u-boot/u-boot.bin

uboot: deps/u-boot/u-boot.bin
deps/u-boot/u-boot.bin:
	cd ./deps/u-boot && $(MAKE) qemu-riscv64_defconfig && $(MAKE)


.PHONY: all run telnet boot uboot kernel rootfs modules clean

# 通过 u-boot 启动 kernel
# https://quard-star-tutorial.readthedocs.io (基于qemu-riscv从0开始构建嵌入式linux系统)
# https://www.jianshu.com/p/f7d5b6ad0710
# https://stdrc.cc/post/2021/02/23/u-boot-qemu-virt
# https://blog.csdn.net/wangyijieonline/article/details/104843769
# https://dingfen.github.io/risc-v/2020/07/23/RISC-V_on_QEMU.html
