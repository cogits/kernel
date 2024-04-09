obj-m += chardev.o
obj-m += ioctltest.o
obj-m += ioctl/
obj-m += scull/

# 需要额外编译用户态的程序的目录
EXTRA_DIRS := ioctl
BUILD_EXTRA_DIRS := $(addprefix user/,$(EXTRA_DIRS))

extra: $(BUILD_EXTRA_DIRS)

# 对于每个子目录，定义一个规则来执行其 Makefile
$(BUILD_EXTRA_DIRS):
	$(MAKE) -C $(@:user/%=%)


.PHONY: extra user/*
