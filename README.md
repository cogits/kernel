# kernel

Building linux kernel and drivers using qemu-system-riscv64.

## Dependencies

for compiling kernel, busybox and drivers:
- gcc-riscv64-linux-gnu
- flex/bison/bc (building kernel)
- nfs-kernel-server
- fuse-ext2
- rsync
- zig cc

for compiling qemu:
- libglib2.0-dev
- libslirp-dev
- libfdt-dev
- meson
- ninja
- python3-venv (Python's ensurepip module)

for making alpine rootfs (optional):
- qemu-user-static (binfmt support)
- apk.static (riscv64)
- unshare/newuidmap (uidmap)

## Clone

```sh
$ git clone git@github.com:snoire/kernel.git
$ cd kernel/deps
$ rm -rf *
$ git clone --depth=1 -b v6.7 git@github.com:torvalds/linux.git
$ git clone --depth=1 -b 1_36_1 git://git.busybox.net/busybox
$ git clone --depth=1 -b v2024.01 git@github.com:u-boot/u-boot.git
$ git clone --depth=1 -b v8.2.2 git@github.com:qemu/qemu.git
$ git clone --depth=1 -b v1.4 git@github.com:riscv-software-src/opensbi.git
$ git clone --depth=1 -b d1-2022-10-31 git@github.com:smaeul/u-boot.git uboot-d1
$ git clone --depth=1 git@github.com:lwfinger/rtl8723ds.git
$ git submodule update --init
```

## References

- [在 QEMU 上运行 RISC-V 64 位版本的 Linux](https://zhuanlan.zhihu.com/p/258394849)
- [Advanced examples of Linux Device Drivers](https://github.com/d0u9/Linux-Device-Driver)
- [The Linux Kernel Module Programming Guide](https://github.com/sysprog21/lkmpg)
- [基于qemu-riscv从0开始构建嵌入式linux系统](https://quard-star-tutorial.readthedocs.io)
- [QEMU: Network emulation](https://www.qemu.org/docs/master/system/devices/net.html#using-the-user-mode-network-stack)
- [RISC-V Archlinux D1 LicheeRV image builder](https://github.com/sehraf/d1-riscv-arch-image-builder)
- [build debian from sources for lichee rv](https://andreas.welcomes-you.com/boot-sw-debian-risc-v-lichee-rv)
- [opensbi 编译与运行](https://zhuanlan.zhihu.com/p/659025580)
- [Bootstrapping Alpine Linux without root](https://blog.brixit.nl/bootstrapping-alpine-linux-without-root)
