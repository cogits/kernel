.ONESHELL:
.SHELLFLAGS = -ec

# path definitions
export ROOT := $(CURDIR)
export DEPS_DIR := $(ROOT)/deps
export PATCHES_DIR := $(ROOT)/patches
export BUILD_DIR := $(ROOT)/build

# cross build environments
export ARCH := riscv
export CROSS_COMPILE := riscv64-linux-gnu-

# Makefiles
VIRT_MK := $(BUILD_DIR)/virt.mk
D1_MK := $(BUILD_DIR)/d1.mk


all: virt

# qemu `virt` generic virtual platform
virt run telnet boot rootfs:
	$(MAKE) -f $(VIRT_MK) $@
rootfs/%:
	$(MAKE) -f $(VIRT_MK) $@
virt/%:
	$(MAKE) -f $(VIRT_MK) $(@:virt/%=%)

# lichee rv dock platform
d1:
	$(MAKE) -f $(D1_MK)
d1/%:
	$(MAKE) -f $(D1_MK) $(@:d1/%=%)

# clean/xxx
clean/%:
	cd deps/$(@:clean/%=%)
	git clean -fdx
	git reset --hard

# distclean
# `%` 不能单独用在右边的依赖名称中，所以必须定义变量
DEPS := $(wildcard deps/*)
CLEAN_DEPDIRS := $(DEPS:deps/%=clean/%)
distclean: $(CLEAN_DEPDIRS)
	git clean -fdx .


# 声明伪目录
.PHONY: all virt virt/* run telnet d1 d1/* clean/* distclean
