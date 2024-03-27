obj-m += hello-1.o
obj-m += hello-2.o
obj-m += hello-3.o
obj-m += hello-4.o
obj-m += hello-5.o
obj-m += param.o

obj-m += startstop.o
startstop-objs := start.o stop.o

# two modules
obj-m += start2.o
obj-m += stop2.o

# specify flags
# for all files
ccflags-y := -std=gnu99

# for single file
CFLAGS_param.o := -DDEBUG
