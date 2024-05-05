CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy

fw.bin: fw.elf
	$(OBJCOPY) -O binary -S $< $@

fw.elf: startup.o boot.lds
	$(CC) -nostartfiles -T./boot.lds -Wl,-Map=lowlevel_fw.map -Wl,--gc-sections $< -o $@

%.o: %.s
	$(CC) -x assembler-with-cpp -c $< -o $@
