# kernel

Building linux kernel and drivers for different platforms:
- [qemu riscv64 virt](https://www.qemu.org/docs/master/system/riscv/virt.html)
- [quard star board](https://quard-star-tutorial.readthedocs.io)
- [lichee rv dock](https://linux-sunxi.org/Sipeed_Lichee_RV)

## Dependencies

for compiling kernel, busybox and drivers:
- [gcc-riscv64-linux-gnu](https://packages.debian.org/sid/gcc-riscv64-linux-gnu)
- flex, bison, bc (building kernel)
- swig (building uboot-d1)
- device-tree-compiler (building quard star)

for compiling qemu:
- [python3-venv](https://packages.debian.org/sid/python3-venv) (Python's ensurepip module)
- libglib2.0-dev
- libslirp-dev (networking support)
- libfdt-dev
- meson, ninja

for making busybox rootfs:
- [nfs-kernel-server](https://packages.debian.org/sid/nfs-kernel-server)
- fuse/fuse3, [fuse2fs](https://packages.debian.org/sid/fuse2fs) (user-level mount of ext2/3/4 file systems)
- rsync (copying files)

for making alpine rootfs (optional):
- [qemu-user-static (binfmt support)](https://packages.debian.org/sid/qemu-user-static)
- [apk.static (riscv64)](https://pkgs.alpinelinux.org/package/edge/main/riscv64/apk-tools-static)
- unshare, [newuidmap](https://packages.debian.org/sid/uidmap)

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
$ git clone --depth=1 -b d1-wip git@github.com:smaeul/u-boot.git uboot-d1
$ git clone --depth=1 git@github.com:lwfinger/rtl8723ds.git
$ git submodule update --init
```

## References

- [在 QEMU 上运行 RISC-V 64 位版本的 Linux](https://zhuanlan.zhihu.com/p/258394849)
- [Advanced examples of Linux Device Drivers](https://github.com/d0u9/Linux-Device-Driver)
- [The Linux Kernel Module Programming Guide](https://github.com/sysprog21/lkmpg)
- [QEMU: Network emulation](https://www.qemu.org/docs/master/system/devices/net.html#using-the-user-mode-network-stack)
- [Bootstrapping Alpine Linux without root](https://blog.brixit.nl/bootstrapping-alpine-linux-without-root)
- [在全志D1上启动操作系统](https://blog.hutao.tech/posts/boot-os-from-d1)
- [RISC-V Archlinux D1 LicheeRV image builder](https://github.com/sehraf/d1-riscv-arch-image-builder)
- [build debian from sources for lichee rv](https://andreas.welcomes-you.com/boot-sw-debian-risc-v-lichee-rv)
- [opensbi 编译与运行](https://zhuanlan.zhihu.com/p/659025580)
