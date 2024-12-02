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

# format string for help target
help_fmt_width := 20
export help_fmt_name := "  %-$(help_fmt_width)s\n"
export help_fmt      := "  %-$(help_fmt_width)s- %s\n"
export help_fmt_mark := "* %-$(help_fmt_width)s- %s\n"

# args (recursive evaluated)
arg1 = $(word 1,$(subst /, ,$@))
arg2 = $(word 2,$(subst /, ,$@))

# platforms
platforms := virt star dock
CLEAN_PLATFORMS := $(addprefix clean/,$(platforms))
HELP_PLATFORMS := $(addprefix help/,$(platforms))


all: $(platforms)

# <platform>
virt star: qemu
virt dock: opensbi
$(platforms):
	$(MAKE) -C build -f $@.mk

# <platform>/*
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

# clean/<platform>
$(CLEAN_PLATFORMS):
	$(MAKE) -C build -f $(@:clean/%=%).mk clean

# clean/<platform>/*
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

## help
help $(HELP_PLATFORMS): MAKEFLAGS += --no-print-directory
help:
	@
	echo "Top-level targets:"
	printf $(help_fmt) "all"                "build all targets marked with [*]"
	printf $(help_fmt) "distclean"          "clean all build output"
	printf $(help_fmt) "clean/<step>"       "clean specific build artifacts"
	printf $(help_fmt) "update/<step>"      "clean and then build specific step"
	printf $(help_fmt) "sudo/<step>"        "run build step with superuser privileges"
	echo ""
	$(foreach t,$(COMMON_RULES),
		printf $(help_fmt) "$(t)"           "build $(t:clean/%=%)"
	)
	echo ""

	printf $(help_fmt) "clean/deps/<dep>"   "clean build dependencies for:"
	$(foreach d,$(DEPS),
		printf $(help_fmt_name)  "  $(d:deps/%=%)"
	)
	echo ""

	printf $(help_fmt) "help"               "display this help message"
	printf $(help_fmt) "help/<board>"       "show help for specific board"
	$(foreach board,$(platforms),
		printf $(help_fmt_name)  "  $(board)"
	)
	echo ""

	echo "Platform targets:"
	$(foreach board,$(platforms),
		$(MAKE) help/$(board)
	)

# help/<platform>
$(HELP_PLATFORMS):
	@
	# common targets
	printf $(help_fmt_mark) "$(arg2)"       "build $(arg2) platform"
	printf $(help_fmt) "$(arg2)/<step>"     "build specific step for $(arg2) platform"
	printf $(help_fmt) "  clean"            "clean $(arg2) build artifacts"
	printf $(help_fmt) "  image"            "build $(arg2) image"

	# specific targets
	$(MAKE) -C build -f $(arg2).mk help
	echo ""


# 声明伪目录
.PHONY: all $(platforms) virt/* star/* dock/* distclean clean/* update/* sudo/* help help/*
