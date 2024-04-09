ROOT := $(CURDIR)
BIN_PREFIX := $(CURDIR)/result/bin
QEMU := $(BIN_PREFIX)/qemu-system-riscv64
QEMU_IMG := $(BIN_PREFIX)/qemu-img
APK_STATIC := apk.static

export ARCH := riscv
export CROSS_COMPILE := riscv64-linux-gnu-
export KERNEL_PATH := $(ROOT)/deps/linux

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
kernel: deps/linux/arch/riscv/boot/Image
deps/linux/arch/riscv/boot/Image:
	cp ./patches/linux/config ./deps/linux/.config
	cd ./deps/linux && $(MAKE) olddefconfig && $(MAKE)


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
	cd ./result \
		&& $(QEMU_IMG) create rootfs.img 64m && mkfs.ext4 rootfs.img \
		&& fuse-ext2 -o rw+ rootfs.img rootfs \
		&& rsync -av $(ROOT)/patches/rootfs/ rootfs --exclude='.gitkeep' \
		&& sed -i 's|$${LOGIN}|'"/bin/sh"'|' rootfs/etc/init.d/rcS \
		&& sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' rootfs/etc/init.d/rcS \
		&& cp -r $(ROOT)/deps/busybox/_install/* rootfs \
		&& fusermount -u rootfs

deps/busybox/_install: DIFF_FILES := $(shell find patches/busybox -type f -name '*.diff')
deps/busybox/_install:
	# 找出 patches/busybox/ 目录下所有 diff 文件，并打补丁到 deps/busybox 目录
	$(foreach diff,$(DIFF_FILES),\
		patch -N $(patsubst patches/%.diff,deps/%,$(diff)) $(diff);)
	cp ./patches/busybox/config ./deps/busybox/.config
	cd ./deps/busybox/ && $(MAKE) oldconfig && $(MAKE) install


# requires root privileges
rootfs/alpine: mirror := https://mirror.tuna.tsinghua.edu.cn/alpine
rootfs/alpine: $(QEMU_IMG) result/rootfs
	cd ./result \
		&& $(QEMU_IMG) create rootfs.img 128m && mkfs.ext4 rootfs.img \
		&& sudo mount -o loop rootfs.img rootfs \
		&& sudo $(APK_STATIC) -X $(mirror)/edge/main -X $(mirror)/edge/community -U --allow-untrusted \
			-p rootfs --initdb add apk-tools coreutils busybox-extras binutils musl-utils zsh vim \
			eza bat fd ripgrep hexyl btop fzf fzf-vim fzf-zsh-plugin zsh-syntax-highlighting \
			zsh-autosuggestions zsh-history-substring-search \
		&& sudo rsync -av $(ROOT)/patches/rootfs/ rootfs --exclude='.gitkeep' \
		&& sudo sed -i 's|$${LOGIN}|'"/bin/zsh"'|' rootfs/etc/init.d/rcS \
		&& sudo sed -i 's|$${HOST_PATH}|'"$(ROOT)/drivers"'|' rootfs/etc/init.d/rcS \
		&& sudo sed -i 's|$${MIRROR}|'"$(mirror)"'|' rootfs/etc/apk/repositories \
		&& sudo umount rootfs

result/rootfs:
	mkdir -p result/rootfs

clean/rootfs:
	cd ./result && rm -rf rootfs/ rootfs.img



## build qemu
# https://zhuanlan.zhihu.com/p/258394849
qemu: $(QEMU) $(QEMU_IMG)
# NOTE 不要让一个文件目标信赖于一个伪目标，否则即使文件存在，也总是执行伪目标。
# 当 $(QEMU) 生成时 $(QEMU_IMG) 也一并生成了。
$(QEMU_IMG): $(QEMU)
$(QEMU):
	cd ./deps/qemu && mkdir -p build && cd build \
		&& ../configure --target-list=riscv64-softmmu,riscv64-linux-user --enable-slirp --prefix=$(ROOT)/result \
		&& $(MAKE) install


## kernel modules (add V=12 for verbose output)
modules: kernel
	# build drivers only
	# $(MAKE) -C $(KERNEL_PATH) M=$(PWD)/drivers modules
	# build drivers and user applications
	$(MAKE) -C drivers


## clean
# 清理 drivers 目录
clean:
	$(MAKE) -C drivers clean

DEPS := busybox linux u-boot qemu
CLEAN_DEPDIRS := $(addprefix clean/,$(DEPS))

# make clean/xxx
$(CLEAN_DEPDIRS):
	cd deps/$(@:clean/%=%); git clean -fdx; git reset --hard

# distclean
distclean: $(CLEAN_DEPDIRS)
	git clean -fdx .


## uboot
# https://zhuanlan.zhihu.com/p/482858701
boot: qemu uboot
	$(QEMU) -M virt -m 512M -nographic -bios deps/u-boot/u-boot.bin

uboot: deps/u-boot/u-boot.bin
deps/u-boot/u-boot.bin:
	cd ./deps/u-boot && $(MAKE) qemu-riscv64_defconfig && $(MAKE)

# 通过 u-boot 启动 kernel
# https://quard-star-tutorial.readthedocs.io (基于qemu-riscv从0开始构建嵌入式linux系统)
# https://www.jianshu.com/p/f7d5b6ad0710
# https://stdrc.cc/post/2021/02/23/u-boot-qemu-virt
# https://blog.csdn.net/wangyijieonline/article/details/104843769
# https://dingfen.github.io/risc-v/2020/07/23/RISC-V_on_QEMU.html


# 声明伪目录
.PHONY: all run telnet boot uboot qemu kernel rootfs rootfs/* modules clean distclean clean/*
