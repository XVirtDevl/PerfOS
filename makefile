nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/
nasm -f bin -o ./bin/bootloader.bin ./boot/mbr.asm -i ./kernel/include/
nasm -f elf64 -o ./bin/console.elf ./kernel/console/console.asm -i ./kernel/include/
nasm -f elf64 -o ./bin/driver_list.elf ./kernel/data/StdDriverList.asm -i ./kernel/include/
ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/kernel.elf ./bin/console.elf ./bin/driver_list.elf
cat ./bin/kernel.bin >> ./bin/bootloader.bin
./appender ./bin/bootloader.bin ./bin/bootloader.bin
rm ./bin/console.elf
rm ./bin/kernel.elf
rm ./bin/driver_list.elf

