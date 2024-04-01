# kernel

Building linux kernel and drivers using qemu-system-riscv64.

## Dependencies

for compiling kernel, busybox and drivers:
- gcc-riscv64-linux-gnu
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

for making alpine rootfs (optional):
- qemu-user-static (binfmt support)
- apk.static (riscv64)

## Clone

```sh
$ git clone git@github.com:snoire/kernel.git
$ cd kernel/deps
$ rm -rf *
$ git clone --depth=1 -b v6.7 git@github.com:torvalds/linux.git
$ git clone --depth=1 -b 1_36_1 git://git.busybox.net/busybox
$ git clone --depth=1 -b v2024.01 git@github.com:u-boot/u-boot.git
$ git clone --depth=1 -b v8.2.2 git@github.com:qemu/qemu.git
$ git submodule update --init
```

## References

- [在 QEMU 上运行 RISC-V 64 位版本的 Linux](https://zhuanlan.zhihu.com/p/258394849)
- [Advanced examples of Linux Device Drivers](https://github.com/d0u9/Linux-Device-Driver)
- [The Linux Kernel Module Programming Guide](https://github.com/sysprog21/lkmpg)
- [基于qemu-riscv从0开始构建嵌入式linux系统](https://quard-star-tutorial.readthedocs.io)
- [QEMU: Network emulation](https://www.qemu.org/docs/master/system/devices/net.html#using-the-user-mode-network-stack)
