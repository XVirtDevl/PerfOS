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

;eax = Value to convert, edi = destination string to put the letters in
global _inttostr
_inttostr:
	push edx
	push ebx
	push edi

	mov ebx, 10
	xor edx, edx
	.StartConvert:
		div ebx
		add dl, 48
		mov byte[ edi ], dl
		add edi, 1
		xor edx, edx
		
		or eax, eax
		jnz .StartConvert

		mov byte[ edi ], 0
		mov ebx, edi
		sub ebx, 1
		pop edi
	.Switch:
		mov dl, byte[ebx]
		xchg byte[edi], dl
		mov byte[ebx],dl
		sub ebx, 1
		add edi, 1
		cmp ebx, edi
		ja .Switch

		pop ebx
		pop edx
		ret

;edi = destination string address, eax = value
global _inttostrhex
Cond dw 48
_inttostrhex:
	push ecx
	mov word[edi], '0x'
	add edi, 2

	mov cl, 28

	.outputLoop:
		push eax
		shr eax, cl
		mov bx, 55
		and al, 0xF

		cmp al, 10
		cmovb bx, word[Cond]

		add ax, bx
		

	
	.check:
		mov byte[ edi ], al
		add edi, 1
		pop eax
		sub cl, 4
		jns .outputLoop
		mov byte[ edi ], 0		
		
		pop ecx
		ret


		
ScreenCursor dd 0xb8000
ScreenAttributes db 0x0F
