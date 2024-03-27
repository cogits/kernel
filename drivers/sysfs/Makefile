obj-m += hello-sysfs.o

PWD := $(CURDIR)

all:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) clean
