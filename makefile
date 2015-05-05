nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/
g++ -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/ckernel.o ./kernel/kernel.cpp -I./kernel/include
g++ -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/cvideo.o ./kernel/video/video.cpp -I./kernel/include
ld -m elf_x86_64 -T ./kernel/link.ld -o ./kernel.bin ./bin/kernel.elf
rm ./bin/cvideo.o
rm ./bin/kernel.elf
rm ./bin/ckernel.o
