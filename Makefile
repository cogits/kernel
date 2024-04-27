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

# global variables
export ROOT_USER := $(shell test $$(id -u) -eq 0 && echo true)
export ALPINE_MIRROR := https://mirror.tuna.tsinghua.edu.cn/alpine

# args (recursive evaluated)
arg1 = $(word 1,$(subst /, ,$@))
arg2 = $(word 2,$(subst /, ,$@))
arg3 = $(word 3,$(subst /, ,$@))

# platforms
platforms := virt d1


all: $(platforms)

## platform specific rules
# qemu `virt` generic virtual platform
run telnet boot rootfs:
	$(MAKE) -C $(BUILD_DIR) -f virt.mk $@
rootfs/%:
	$(MAKE) -C $(BUILD_DIR) -f virt.mk $@

# lichee rv dock platform
image:
	$(MAKE) -C $(BUILD_DIR) -f d1.mk $@

## platform general rules
# <virt|d1>
$(platforms):
	$(MAKE) -C $(BUILD_DIR) -f $@.mk

# <virt|d1>/*
%:
	$(if $(filter $(arg1),$(platforms)),# make $@,$(error expect <virt|d1>/*, found $@))
	$(MAKE) -C $(BUILD_DIR) -f $(arg1).mk $(subst $(arg1)/,,$@)


## clean rules
# distclean
# `%` 不能单独用在右边的依赖名称中，所以必须定义变量
DEPS := $(wildcard deps/*)
CLEAN_DEPDIRS := $(DEPS:deps/%=clean/%)
distclean: $(CLEAN_DEPDIRS)
	git clean -fdx .

# clean/<dep>
$(CLEAN_DEPDIRS):
	cd deps/$(@:clean/%=%)
	git clean -fdx
	git reset --hard

# clean/<virt|d1>
$(addprefix clean/,$(platforms)):
	$(MAKE) -C $(BUILD_DIR) -f $(@:clean/%=%).mk distclean

# clean/<virt|d1>/*
clean/%:
	$(if $(filter $(arg2),$(platforms)),# clean $(arg2) $(arg3),$(error expect clean/<virt|d1>/*, found $@))
	$(MAKE) -C $(BUILD_DIR) -f $(arg2).mk clean/$(arg3)


## update rules
# update/<virt|d1>/*
update/%: clean/%
	$(MAKE) $(@:update/%=%)


# 声明伪目录
.PHONY: all virt virt/* run telnet d1 d1/* clean/* distclean update/*
