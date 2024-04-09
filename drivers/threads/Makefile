obj-m += sleep.o
obj-m += completion/

user: cat_nonblock

cat_nonblock: user/cat_nonblock.c
	zig cc --target=riscv64-linux -Os $^ -o $@


.PHONY: user
