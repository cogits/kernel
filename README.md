dependencies:

- gcc-riscv64-linux-gnu
- nfs-kernel-server
- fuse-ext2
- rsync
- zig cc

for compiling qemu
- libglib2.0-dev
- libslirp-dev

clone:

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
