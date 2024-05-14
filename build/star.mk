.ONESHELL:
.SHELLFLAGS = -ec

board := star
BUILD_OPENSBI_DIR := $(BUILD_DIR)/$(board)/opensbi
OPENSBI_BIN := $(BUILD_OPENSBI_DIR)/platform/quard_star/firmware/fw_jump.bin

all: $(board)
include rules.mk

# targets
BOOT_IMAGE := $(IMAGES_DIR)/$(board)-fw.img
BOOT_BIN := $(BOARD_DIR)/boot/fw.bin


$(board): image

# https://quard-star-tutorial.readthedocs.io/zh-cn/latest/ch4.html
run: qemu $(BOOT_IMAGE)
	$(QEMU) -M $(board) -m 32m -smp 1 -nographic \
		-drive if=pflash,bus=0,unit=0,format=raw,file=$(BOOT_IMAGE)

image: $(BOOT_IMAGE)
$(BOOT_IMAGE): $(BOOT_BIN) | $(IMAGES_DIR)
	truncate -s 32M $@
	dd of=$@ bs=1k conv=notrunc seek=0 if=$<

$(BOOT_BIN):
	$(MAKE) -C $(BOARD_DIR)/boot

## opensbi
OPENSBI_QUARD_STAR_DIR := $(DEPS_DIR)/opensbi/platform/quard_star
$(OPENSBI_BIN): | $(OPENSBI_QUARD_STAR_DIR)
$(OPENSBI_BIN): export PLATFORM := quard_star

$(OPENSBI_QUARD_STAR_DIR):
	test -d $(OPENSBI_QUARD_STAR_DIR) && exit
	$(call git-apply,opensbi)


## clean
clean/image:
	rm -fv $(BOOT_IMAGE)

# distclean
distclean: clean/image
	git clean -fdx $(BOARD_DIR)


# 声明伪目录
.PHONY: all run $(board) image distclean clean/*
