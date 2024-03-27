obj-m += chardev.o
obj-m += ioctltest.o
obj-m += ioctl.o

PWD := $(CURDIR)

all: user_ioctl
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) clean


# userspace cmd for ioctl.ko
user_ioctl: user/ioctl.c
	zig cc --target=riscv64-linux -Os $^ -o $@
