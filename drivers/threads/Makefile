obj-m += sleep.o
obj-m += completion/

user: cat_nonblock

cat_nonblock: user/cat_nonblock.c
	$(CROSS_COMPILE)gcc -static -Os $^ -o $@


.PHONY: user
