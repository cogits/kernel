.ONESHELL:
.SHELLFLAGS = -ec

board := star
all: $(board)
include rules.mk

# targets
BOOT_IMAGE := $(IMAGES_DIR)/$(board)-fw.img
BOOT_BIN := $(BOARD_DIR)/boot/fw.bin


$(board): qemu image

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


## clean
clean/image:
	rm -fv $(BOOT_IMAGE)

# distclean
distclean: clean/image
	git clean -fdx $(BOARD_DIR)


# 声明伪目录
.PHONY: all run $(board) image distclean clean/*
