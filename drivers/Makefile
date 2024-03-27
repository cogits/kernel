# another way of building external kernel module directory
# note the last `/`, it's necessary.
obj-y += hello/

DIRS := \
	chardev \
	proc \
	sysfs \
	embed \
	threads

BUILD_SUBDIRS := $(addprefix build_,$(DIRS))
CLEAN_SUBDIRS := $(addprefix clean_,$(DIRS))

all: $(BUILD_SUBDIRS)

# 对于每个子目录，定义一个规则来执行其 Makefile
$(BUILD_SUBDIRS):
	$(MAKE) -C $(@:build_%=%)

$(CLEAN_SUBDIRS):
	$(MAKE) -C $(@:clean_%=%) clean

clean: $(CLEAN_SUBDIRS)
	# unfortunately, these's no way of cleaning the directory automatically
	git clean -fdx hello
