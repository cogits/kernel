# args (recursive evaluated)
arg1 = $(word 1,$(subst /, ,$@))

CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

all: linux/fw.bin rtos/fw.bin linux/fw.lst rtos/fw.lst

%.bin: %.elf
	$(OBJCOPY) -O binary -S $< $@

%.lst: %.elf
	$(OBJDUMP) --source --demangle --disassemble --reloc --wide $< > $@

%/fw.elf: %/startup.o %/boot.lds
	$(CC) -nostartfiles -T$(arg1)/boot.lds -Wl,-Map=$(arg1)/fw.map -Wl,--gc-sections $< -o $@

%.o: %.s
	$(CC) -x assembler-with-cpp -c $< -o $@
