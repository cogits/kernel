obj-y += hello/
obj-y += chardev/
obj-y += proc/
obj-y += sysfs/
obj-y += threads/

# embed 目录，在编译 ko 之前必须生成 binary blob，所以需要单独编译
# chardev 和 threads 需要额外编译用户态的程序
EXTRA_DIRS := chardev threads embed
BUILD_EXTRA_DIRS := $(addprefix drv/,$(EXTRA_DIRS))

build: build_modules $(BUILD_EXTRA_DIRS)

# kernel 的 Makefile 没有单独清理 modules 的目标
# 所以直接用 git clean 把 driver 目录多余文件全部清除
clean:
	git clean -fdx

# build kernel modules
# 不能用 $(PWD) 和 $(src)
build_modules:
	$(MAKE) -C $(KERNEL_PATH) M=$(CURDIR) modules

# build other steps
# 对于每个子目录，定义一个规则来执行其 Makefile
$(BUILD_EXTRA_DIRS):
	$(MAKE) -C $(@:drv/%=%)
