nasm -f elf32 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/
g++ -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/ckernel.o ./kernel/kernel.cpp -I./kernel/include
g++ -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/cvideo.o ./kernel/video/video.cpp -I./kernel/include
ld -m elf_i386 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/kernel.elf ./bin/ckernel.o ./bin/cvideo.o
rm ./bin/cvideo.o
rm ./bin/kernel.elf
rm ./bin/ckernel.o
