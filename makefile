nasm -f elf32 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/
nasm -f elf32 -o ./bin/io.elf ./kernel/BasicIO/io.asm -i ./kernel/include/
ld -m elf_i386 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/kernel.elf ./bin/io.elf
rm ./bin/kernel.elf
rm ./bin/io.elf
