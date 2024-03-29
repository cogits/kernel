obj-m += chardev.o
obj-m += ioctltest.o
obj-m += ioctl.o
obj-m += scull/

all: user
user: ioctl-riscv64

# userspace cmd for ioctl.ko
ioctl-riscv64: user/ioctl.c
	zig cc --target=riscv64-linux -Os $^ -o $@

# TODO introduce compat_ioctl
# ioctl-riscv32: user/ioctl.c
# 	zig cc --target=riscv32-linux -Os $^ -o $@
