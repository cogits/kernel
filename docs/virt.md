# 配置

## fuse 允许更改文件 id

fuse mount 时允许更改文件 id，需要设置：

```sh
$ cat /etc/fuse.conf
user_allow_other
```

参考 [fuse-ext2](https://github.com/alperakcan/fuse-ext2)。



# 问题

## qemu 内 ping 不通

user mode networking 模式下不支持 ICMP，其他流量是通的。

参考 [Using the user mode network stack](https://www.qemu.org/docs/master/system/devices/net.html#using-the-user-mode-network-stack)。

