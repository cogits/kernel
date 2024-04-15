.ONESHELL:
.SHELLFLAGS = -ec

# build dirs
BUILD_LINUX_D1_DIR := $(BUILD_DIR)/d1/linux
BUILD_UBOOT_D1_DIR := $(BUILD_DIR)/d1/uboot
BUILD_OPENSBI_DIR := $(BUILD_DIR)/d1/opensbi

# targets
OPENSBI_BIN := $(BUILD_OPENSBI_DIR)/platform/generic/firmware/fw_dynamic.bin
UBOOT_BIN := $(BUILD_UBOOT_D1_DIR)/u-boot-sunxi-with-spl.bin
LINUX_IMAGE := $(BUILD_LINUX_D1_DIR)/arch/riscv/boot/Image
RTL8723DS_KO := $(DEPS_DIR)/rtl8723ds/8723ds.ko

### d1
all: d1
d1: opensbi uboot kernel rtl8723ds

## opensbi
opensbi: $(OPENSBI_BIN)
$(OPENSBI_BIN):
	mkdir -p $(BUILD_OPENSBI_DIR)
	cd $(DEPS_DIR)/opensbi
	$(MAKE) O=$(BUILD_OPENSBI_DIR) PLATFORM=generic PLATFORM_RISCV_XLEN=64

uboot: $(UBOOT_BIN)
$(UBOOT_BIN): KBUILD_OUTPUT := $(BUILD_UBOOT_D1_DIR)
$(UBOOT_BIN): $(OPENSBI_BIN)
	mkdir -p $(KBUILD_OUTPUT)
	cd $(DEPS_DIR)/uboot-d1
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) nezha_defconfig
	$(MAKE) OPENSBI=$<

kernel: $(LINUX_IMAGE)
$(LINUX_IMAGE): KBUILD_OUTPUT := $(BUILD_LINUX_D1_DIR)
$(LINUX_IMAGE):
	mkdir -p $(KBUILD_OUTPUT)
	cp $(PATCHES_DIR)/linux/lichee_rv_dock_config $(KBUILD_OUTPUT)/.config
	cd $(DEPS_DIR)/linux
	export KBUILD_OUTPUT=$(KBUILD_OUTPUT)
	$(MAKE) olddefconfig
	$(MAKE)

rtl8723ds: $(RTL8723DS_KO)
$(RTL8723DS_KO): $(LINUX_IMAGE)
	cd $(DEPS_DIR)/rtl8723ds
	$(MAKE) KSRC=$(BUILD_LINUX_D1_DIR) modules


clean/kernel:
	rm -rf $(BUILD_LINUX_D1_DIR)
clean/uboot:
	rm -rf $(BUILD_UBOOT_D1_DIR)
clean/opensbi:
	rm -rf $(BUILD_OPENSBI_DIR)
clean/ko:
	cd $(DEPS_DIR)/rtl8723ds
	git clean -fdx
	git reset --hard

# distclean
# `%` 不能单独用在右边的依赖名称中，所以必须定义变量
SUB_CLEAN := kernel uboot ko
CLEAN_TARGETS := $(SUB_CLEAN:%=clean/%)
distclean: $(CLEAN_TARGETS)


# 声明伪目录
.PHONY: all boot uboot qemu kernel rootfs rootfs/* modules d1 d1/* distclean clean clean/*
