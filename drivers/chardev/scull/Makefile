ccflags-y := -std=gnu99 -DENABLE_DEBUG
scull-objs := main.o fops.o
obj-m := scull.o

CFLAGS_main.o := -DDEBUG
CFLAGS_fops.o := -DDEBUG

.PHONY: clean
clean:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) clean
