set confirm off
set architecture riscv:rv64
target remote 127.0.0.1:26002

set disassemble-next-line auto
set riscv use-compressed-breakpoints yes
set print pretty on

file ./build/star/opensbi/platform/quard_star/firmware/fw_jump.elf
layout split

# display/z $a0
# display/z $a1
# display/z $a2

# b *0x20000000
# b *0x80000000
# b sbi_init

c
