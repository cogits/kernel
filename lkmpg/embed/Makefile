obj-m += embed_art.o
embed_art-objs := embed.o art.o

PWD := $(CURDIR)

all: art.o_shipped
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_PATH) M=$(PWD) clean

art.o_shipped: art.txt
	$(CROSS_COMPILE)ld -r -b binary -o $@ $<


# https://codeplea.com/embedding-files-in-c-programs#Linking_the_Blob_in_Directly
# https://www.kernel.org/doc/html/latest/kbuild/modules.html#binary-blobs
