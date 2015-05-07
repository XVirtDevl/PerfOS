nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/
nasm -f bin -o ./bin/bootloader.bin ./boot/mbr.asm -i ./boot/
g++ -m64 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/ckernel.o ./kernel/kernel.cpp -I./kernel/include
g++ -m64 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/cvideo.o ./kernel/video/video.cpp -I./kernel/include
g++ -m64 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wall -Wextra -pedantic-errors -c -o ./bin/cmemory.o ./kernel/memory/memory.cpp -I./kernel/include
rm ./bin/kernel.bin
ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/kernel.elf ./bin/ckernel.o ./bin/cvideo.o ./bin/cmemory.o
cat ./bin/kernel.bin >> ./bin/bootloader.bin
./appender ./bin/bootloader.bin ./bin/bootloader.bin
rm ./bin/cvideo.o
rm ./bin/kernel.elf
rm ./bin/ckernel.o
rm ./bin/cmemory.o
