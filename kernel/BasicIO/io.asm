global _printString
_printString:
	push edi
	push eax
	mov edi, dword[ScreenCursor]
	mov ah, byte[ScreenAttributes]

	.print:
		mov al, byte[esi]
		or al, al
		jz .done

		mov word[edi], ax
		add esi, 1
		add edi, 2
		jmp .print

	.done:
		pop eax
		pop edi
		ret

global _clrScreen
_clrScreen:
	push edi
	push eax
	push ecx
	mov ah, byte[ScreenAttributes]
	mov al, 0x20
	mov edi, 0xb8000
	mov cx, ax
	shl eax, 16
	mov ax, cx
	mov ecx, 1024
	rep stosd
	pop ecx
	pop eax
	pop edi
	ret 

global _setColor
_setColor:
	mov byte[ScreenAttributes], al
	ret

ScreenCursor dd 0xb8000
ScreenAttributes db 0x0F
