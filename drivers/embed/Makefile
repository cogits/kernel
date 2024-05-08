obj-m += embed_art.o
embed_art-objs := embed.o art.o

blob: art.o_shipped

art.o_shipped: art.txt
	$(CROSS_COMPILE)ld -r -b binary -o $@ $<


# https://codeplea.com/embedding-files-in-c-programs#Linking_the_Blob_in_Directly
# https://www.kernel.org/doc/html/latest/kbuild/modules.html#binary-blobs
