obj-m += hello-1.o
obj-m += hello-2.o
obj-m += hello-3.o
obj-m += hello-4.o
obj-m += hello-5.o
obj-m += startstop.o
startstop-objs := start.o stop.o

PWD := $(CURDIR)

all:
	make -C $(KERNEL_PATH) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- M=$(PWD) modules

clean:
	make -C $(KERNEL_PATH) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- M=$(PWD) clean
