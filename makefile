nasm -f elf32 -o ./bin/kernel.elf ./kernel/kernel.asm
ld -m i386 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/kernel.elf
rm ./bin/kernel.elf
