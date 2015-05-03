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

		cmp al, 0x13
		jz .linebreak

		mov word[edi], ax
		add esi, 1
		add edi, 2
		jmp .print

	.linebreak:
		mov eax, edi
		sub edi, 0xb8000

	.determinate80s:	
		sub edi, 160
		ja .determinate80s
		not edi
		add edi, 1
		add edi, eax
		mov ah, byte[ ScreenAttributes ]

		add esi, 1
		jmp .print
		
	.done:
		mov dword[ ScreenCursor ], edi
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
