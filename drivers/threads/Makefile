obj-m += sleep.o

all: user
user: cat_nonblock

cat_nonblock: user/cat_nonblock.c
	zig cc --target=riscv64-linux -Os $^ -o $@
