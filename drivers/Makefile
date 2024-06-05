obj-y += hello/
obj-y += chardev/
obj-y += proc/
obj-y += embed/
obj-y += sysfs/
obj-y += threads/
obj-y += tasks/
obj-y += printk/

# embed 目录，在编译 ko 之前必须生成 binary blob，所以需要单独编译
# chardev 和 threads 需要额外编译用户态的程序
EXTRA_DIRS := chardev threads embed
BUILD_EXTRA_DIRS := $(addprefix extra/,$(EXTRA_DIRS))

# build kernel modules
# 不能用 $(PWD) 和 $(src)
build_modules: $(BUILD_EXTRA_DIRS)
	$(MAKE) -C $(KERNEL_PATH) M=$(CURDIR) modules

# build other steps
# 对于每个子目录，定义一个规则来执行其 Makefile
$(BUILD_EXTRA_DIRS):
	$(MAKE) -C $(@:extra/%=%)

# empty recipes
extra/%: ;

# kernel 的 Makefile 没有单独清理 modules 的目标
# 所以直接用 git clean 把 driver 目录多余文件全部清除
clean:
	git clean -fdx

# clean sub dirs
clean/%:
	git clean -fdx $(@:clean/%=%)

.PHONY: build clean clean/* build_modules extra/*
