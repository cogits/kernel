obj-m += chardev.o
obj-m += ioctltest.o
obj-m += ioctl.o
obj-m += scull/

PWD := $(CURDIR)

all: ioctl-riscv64
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) clean


# userspace cmd for ioctl.ko
ioctl-riscv64: user/ioctl.c
	zig cc --target=riscv64-linux -Os $^ -o $@

# TODO introduce compat_ioctl
# ioctl-riscv32: user/ioctl.c
# 	zig cc --target=riscv32-linux -Os $^ -o $@
