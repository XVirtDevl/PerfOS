org 0x7C00
[BITS 16]
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax

mov sp, 0x9000



times 510-($-$$) hlt
db 0x55
db 0xAA

