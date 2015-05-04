nasm -f elf32 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/
g++ -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/ckernel.o ./kernel/kernel.cpp
ld -m elf_i386 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/kernel.elf ./bin/ckernel.o
rm ./bin/kernel.elf
rm ./bin/ckernel.o
