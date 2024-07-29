.ONESHELL:
.SHELLFLAGS = -ec

board := star
BUILD_OPENSBI_DIR := $(BUILD_DIR)/$(board)/opensbi
OPENSBI_BIN := $(BUILD_OPENSBI_DIR)/platform/quard_star/firmware/fw_jump.bin

all: $(board)
include rules.mk

# targets
BOOT_IMAGE := $(IMAGES_DIR)/$(board)-fw.img
BOOT_BIN := $(BOARD_DIR)/domain/linux/fw.bin
TRUSTED_BIN := $(BOARD_DIR)/domain/rtos/fw.bin
SBI_DTB := $(BOARD_DIR)/dts/sbi.dtb


$(board): image

DEFAULT_VC := 1366x768
# https://quard-star-tutorial.readthedocs.io/zh-cn/latest/ch7.html
run: qemu $(BOOT_IMAGE)
	$(QEMU) -M $(board) -m 1g -smp 8 -parallel none $(QEMUOPTS) \
		-serial vc:$(DEFAULT_VC) -serial vc:$(DEFAULT_VC) -serial vc:$(DEFAULT_VC) -monitor vc:$(DEFAULT_VC) \
		-drive if=pflash,bus=0,unit=0,format=raw,file=$(BOOT_IMAGE)

# gdb-multiarch -q -n -x boards/star/.gdbinit
gdb: QEMUOPTS := -gdb tcp::26002 -S
gdb: run


## image
image: $(BOOT_IMAGE)
$(BOOT_IMAGE): $(BOOT_BIN) $(TRUSTED_BIN) $(SBI_DTB) $(OPENSBI_BIN) | $(IMAGES_DIR)
	truncate -s 32M $@
	dd of=$@ bs=1k conv=notrunc seek=0 if=$(BOOT_BIN)
	dd of=$@ bs=1k conv=notrunc seek=512 if=$(SBI_DTB)
	dd of=$@ bs=1k conv=notrunc seek=2K if=$(OPENSBI_BIN)
	dd of=$@ bs=1k conv=notrunc seek=4K if=$(TRUSTED_BIN)

$(BOOT_BIN) $(TRUSTED_BIN) &:
	$(MAKE) -C $(BOARD_DIR)/domain

$(SBI_DTB): %.dtb: %.dts
	dtc -I dts -O dtb -o $@ $<

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

clean: clean/image
	git clean -fdx $(BOARD_DIR)

## help
help:
	@
	printf $(help_fmt) "  run"      "run $(board) platform using QEMU"
	printf $(help_fmt) "  gdb"      "start GNU Debugger for $(board) platform"
	printf $(help_fmt) "  opensbi"  "build opensbi"

# 声明伪目录
.PHONY: all run $(board) image clean clean/* help
