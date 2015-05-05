extern main
section longmode
LongMode:
	mov ax, 0x20
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov gs, ax

	push rbx
	call main
	jmp $
