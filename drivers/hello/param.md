# module parameters

Several parameters that a driver needs to know can change from system to system.
These can vary from the device number to use to numerous aspects of how the
driver should operate.

This example shows how our kernel module get parameters from user at load time
by insmod or modprobe.

## Usage

Run:

```sh
insmod param.ko
```

Running `dmesg | tail -10`, you can find something like this:

```
[ 1141.505799] parameters test module is loaded
[ 1141.508953] #0 Hello, Mom
```

It is right that we defautly set to print **hello, Mom** only one time. Next we
unload this module and pass parameters to it when loading.

```sh
# unload the module
rmmod param

# re-load the module and passing parameters to it
insmod param.ko whom=dady howmany=3
```

This time, the message is changed:

```log
[ 1322.364784] parameters test module is loaded
[ 1322.366768] #0 Hello, dady
[ 1322.367999] #1 Hello, dady
[ 1322.369154] #2 Hello, dady
```

We can view and change the parameters:

```sh
$ cat /sys/module/param/parameters/whom
dady
$ cat /sys/module/param/parameters/whom
3
$ echo xx > /sys/module/param/parameters/whom
Permission denied
$ echo 9 > /sys/module/param/parameters/howmany
```

---

### ¶ The end

