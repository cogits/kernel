.ONESHELL:
.SHELLFLAGS = -ec

# path definitions
export ROOT := $(CURDIR)
export DEPS_DIR := $(ROOT)/deps
export BUILD_DIR := $(ROOT)/build
export PATCHES_DIR := $(ROOT)/patches

# cross build environments
export ARCH := riscv
export CROSS_COMPILE := riscv64-linux-gnu-

# global variables
export ROOT_USER := $(shell test $$(id -u) -eq 0 && echo true)
export ALPINE_MIRROR := https://mirror.tuna.tsinghua.edu.cn/alpine

# args (recursive evaluated)
arg1 = $(word 1,$(subst /, ,$@))
arg2 = $(word 2,$(subst /, ,$@))

# platforms
platforms := virt star dock
CLEAN_PLATFORMS := $(addprefix clean/,$(platforms))


all: $(platforms)

# <platforms>
virt star: qemu
virt dock: opensbi
$(platforms):
	$(MAKE) -C build -f $@.mk

# <platforms>/*
$(addsuffix /%,$(platforms)):
	$(MAKE) -C build -f $(arg1).mk $(@:$(arg1)/%=%)


## clean rules
# distclean
# `%` 不能单独用在右边的依赖名称中，所以必须定义变量
DEPS := $(wildcard deps/*)
CLEAN_DEPDIRS := $(addprefix clean/,$(DEPS))
distclean: $(CLEAN_DEPDIRS) $(CLEAN_PLATFORMS)
	git clean -fdx .

# clean/deps/<dep>
$(CLEAN_DEPDIRS):
	cd $(@:clean/%=%)
	git clean -fdx
	git reset --hard

# clean/<platforms>
$(CLEAN_PLATFORMS):
	$(MAKE) -C build -f $(@:clean/%=%).mk distclean

# clean/<platforms>/*
$(addsuffix /%,$(CLEAN_PLATFORMS)):
	$(MAKE) -C build -f $(arg2).mk clean/$(@:clean/$(arg2)/%=%)


## update rules
update/%:
	$(MAKE) clean/$(@:update/%=%)
	$(MAKE) $(@:update/%=%)

## execute commands using sudo
sudo/%: export SUDO := $(if $(ROOT_USER),,sudo)
sudo/%:
	$(MAKE) $(@:sudo/%=%)


## platform independent rules
COMMON_RULES := qemu opensbi busybox
CLEAN_COMMON_RULES := $(addprefix clean/,$(COMMON_RULES))

$(COMMON_RULES) $(CLEAN_COMMON_RULES):
	$(MAKE) -C build -f rules.mk $@


# 声明伪目录
.PHONY: all $(platforms) virt/* star/* dock/* distclean clean/* update/* sudo/*
