# 配置

## fuse 挂载

fuse 挂载有时写数据太慢，需要耐心等待。


## opensbi 启动 kernel

qemu 指定 `-bios` 参数。实际上不指定时，默认也是 `opensbi`。

参考 [QEMU 'virt' 平台下通过 OpenSBI + U-Boot 引导 RISCV64 Linux Kernel](https://gitee.com/tinylab/riscv-linux/blob/master/articles/20220823-boot-riscv-linux-kernel-with-uboot-on-qemu-virt-machine.md)。



# 问题

## qemu 内 ping 不通

user mode networking 模式下不支持 ICMP，其他流量是通的。

参考 [Using the user mode network stack](https://www.qemu.org/docs/master/system/devices/net.html#using-the-user-mode-network-stack)。
