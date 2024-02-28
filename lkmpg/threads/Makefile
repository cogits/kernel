obj-m += sleep.o

PWD := $(CURDIR)

all: cat_nonblock
	make -C $(KERNEL_PATH) M=$(PWD) modules

clean:
	make -C $(KERNEL_PATH) M=$(PWD) clean

# userspace
cat_nonblock: user/cat_nonblock.c
	zig cc --target=riscv64-linux -Os $^ -o $@
