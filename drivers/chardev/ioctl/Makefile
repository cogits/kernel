obj-m += ioctl1.o
obj-m := ioctl2.o

ioctl2-objs := ioctl2_main.o ioctl2_fops.o

user: ioctl1-riscv64 ioctl2-riscv64

# userspace cmd for ioctl1.ko
ioctl1-riscv64: user/ioctl1.c
	zig cc --target=riscv64-linux -Os $^ -o $@

# TODO introduce compat_ioctl
# ioctl1-riscv32: user/ioctl1.c
# 	zig cc --target=riscv32-linux -Os $^ -o $@

# userspace cmd for ioctl2.ko
ioctl2-riscv64: user/ioctl2.c
	zig cc --target=riscv64-linux -Os $^ -o $@
