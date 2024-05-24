## 板子通过宿主机连网

宿主机有两个接口，一个作外网，一个作内网，开启路由功能：

```sh
$ sudo sysctl net.ipv4.ip_forward=1
$ sudo iptables -t nat -A POSTROUTING -s <内网网段> -o <外网接口> -j MASQUERADE
```



## 板子直接通过 WiFi 连网

```sh
$ modprobe 8723ds
$ ip link set wlan0 up
$ wpa_passphrase 'ExampleWifiSSID' 'ExampleWifiPassword' > /etc/wpa_supplicant/wpa_supplicant.conf
$ wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
$ udhcpc -i wlan0
```

参考 [alpine Wi-Fi](https://wiki.alpinelinux.org/wiki/Wi-Fi)。



## 通过 nfs 挂载宿主机目录

宿主机安装 `nfs-kernel-server` 服务端，再修改 `/etc/exports`：

```sh
宿主机目录     *(ro,insecure,all_squash)
```

所有设备都可以只读挂载指定的目录。更多挂载选项可参考 [man 5 exports](https://www.man7.org/linux/man-pages/man5/exports.5.html) `EXAMPLE` 一节。



## apk 无法更新

```sh
$ apk --allow-untrusted update
D01C53A13F000000:error:0A000086:SSL routines:tls_post_process_server_certificate:certificate verify failed:ssl/statem/statem_clnt.c:2091:
```

原因是时间不对，用 `date` 修改当前时间：

```sh
$ date -s '2024-04-22 16:21:42'
```

