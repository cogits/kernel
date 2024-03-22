obj-m += sleep.o

PWD := $(CURDIR)

all: cat_nonblock
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) clean

# userspace
cat_nonblock: user/cat_nonblock.c
	zig cc --target=riscv64-linux -Os $^ -o $@
