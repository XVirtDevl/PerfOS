global printf
;rsi = string address, parameters on the stack
printf:
	mov rbp, rsp
	push rdi
	push rax
	push rcx

	mov ecx, 8

	mov edi, dword[WriteBuffer]
	mov ah, byte[ScreenAttributes]
	mov edx, dword[ PageBase ]

	.printStr:
		mov al, byte[ esi ]	
		add esi, 1

		or al, al
		jz .done

		cmp al, 0x13
		jz .newLine

		cmp al, '%'
		jz .formatOutput

		mov word[ edi ], ax
		add edi, 2
		jmp .printStr

	.newLine:
		mov eax, edi
		sub eax, ScreenBuffer
		push rdx
		push rbx

		xor edx, edx
		mov ebx, 160
		div ebx
		mov eax, 160
		sub eax, edx
		add edi, eax
		
		pop rbx
		pop rdx

		mov ah, byte[ ScreenAttributes ]
		jmp .printStr


		

	.formatOutput:
		mov al, byte[ esi ]
		add esi, 1
		
		cmp al, 'd'
		jz .printInt
		
		cmp al, 'x'
		jz .printHex

		cmp al, 'X'
		jz .printBigHex

		cmp al, 's'
		jz .printSubStr

	.selectNextParam:
		add ecx, 8
		jmp .printStr

	.printSubStr:
		push rsi
		mov esi, dword[ ebp + ecx ]
		
		.prLoop:
			mov al, byte[ esi ]
			add esi, 1

			or al, al
			jz .prLoopDone
	
			mov word[ edi  ], ax
			add edi, 2
			jmp .prLoop
		.prLoopDone:
			pop rsi
			jmp .selectNextParam

	.printInt:
		push rbx
		push rdx	
		push rdi

		mov rax, qword[ ebp + ecx ]
		mov ebx, 10
		xor edx, edx
		mov edi, DecimalBuffer+24

		.outpt:
			div rbx

			
			add dl, 48
			mov byte[ edi ], dl

			xor edx, edx
			sub edi, 1

			or eax, eax
			jnz .outpt
			add edi, 1
		
		mov ebx, edi
		mov ah, byte[ ScreenAttributes ]
		pop rdi
		
		.printIt:
			mov al, byte[ ebx ]
			add ebx, 1

			mov word[ edi ], ax
			add edi, 2
					 
			cmp ebx, DecimalBuffer+25
			jne .printIt
		pop rdx
		pop rbx
		jmp .selectNextParam
	.printBigHex:
		mov rax, qword[ ebp + ecx ]
		push rcx
		mov cl, 60	
		jmp .starthex	

	.printHex:
		mov rax, qword[ ebp + ecx ]
		push rcx
		mov cl, 28

	.starthex:	
		push rdx
		
		mov dh, byte[ ScreenAttributes ]
		mov dl, '0'
		mov word[ edi ], dx
		add edi, 2
		mov dl, 'x'
		mov word[ edi ], dx
		add edi, 2

		mov rdx, rax

		.printH:
			shr rax, cl
			and al, 0xF
			
			cmp al, 0xA
			jae .addH

			add al, 48

		.outputHN:	
			mov ah, byte[ ScreenAttributes ]
			mov word[ edi ], ax
			add edi, 2
		
			mov rax, rdx
			sub cl, 4
			jns .printH

			pop rdx
			pop rcx
			mov ah, byte[ ScreenAttributes ]
			jmp .selectNextParam
		.addH:
			add al, 55
			jmp .outputHN
	
	.done:		
		mov dword[ WriteBuffer ], edi
		pop rcx
		pop rax
		pop rdi	
		ret




global updateScreen
updateScreen:
	push rdi
	push rcx
	push rsi
		
	mov esi, dword[ PageBase ]
	mov ecx, 500
	mov edi, 0xb8000
	rep movsq

	pop rsi
	pop rcx
	pop rdi
	ret

	
	
global setScreenAttributes
;al = new ScreenAttributes
setScreenAttributes:
	push rcx
	mov byte[ScreenAttributes], al
	mov ch, al
	mov cl, 0x20
	mov ax, cx
	shl rax, 16
	mov ax, cx
	shl rax, 16
	mov ax, cx
	shl rax, 16
	mov ax, cx
	mov qword[ ScreenDefaultChar ], rax
	pop rcx
	ret
	

global clearScreen
clearScreen:
	push rax
	push rcx
	push rdi

	mov edi, dword[ PageBase ]
	mov eax, dword[ WriteBuffer ]
	cmp edi, eax
	ja .notInside

	add edi, 4000
	cmp edi, eax
	js .notInside

	sub edi, 4000
	mov rax, qword[ ScreenDefaultChar ]
	mov ecx, 25*20
	rep stosq
	
	sub edi, 4000
	mov dword[ WriteBuffer ], edi

	.notInside: 
		mov edi, dword[ ScreenPointer ]
		mov rax, qword[ ScreenDefaultChar ]
		mov ecx, 25*20
		rep stosq

	pop rdi
	pop rcx
	pop rax
	ret

global scrollScreen
;eax scroll count
scrollScreen:
	push rdi


	test al, 0x80
	jz .downScroll
	
	mov edi, dword[ PageBase ]

	and al, 0x7F

	or al, al
	jz .done
	
	.NewPageBase:
		sub edi, 160

		sub al, 1	
		jnz .NewPageBase	
	
	cmp edi, ScreenBuffer
	jns .done

	mov edi, ScreenBuffer
	jmp .done

	.downScroll:
		or al, al
		jz .done

		mov edi, dword[ PageBase ]
	.NewPageBaseDown:
		add edi, 160
		sub al, 1
		jnz .NewPageBaseDown

	.done:
		mov dword[ PageBase ], edi
		pop rdi
		ret

global endl
endl:
	push rax
	mov eax, dword[ WriteBuffer ]
	push rdx
	push rbx
	sub eax, ScreenBuffer

	xor edx, edx
	mov ebx, 160
	div ebx
	mov eax, 160
	sub eax, edx
	add edi, eax
		
	pop rbx
	pop rdx
	pop rax
	
	ret
		

ScreenPointer dd 0xb8000
WriteBuffer dd ScreenBuffer
PageBase dd ScreenBuffer
ScreenAttributes dd 0x0F
ScreenDefaultChar dq 0x0F200F200F200F20

section .bss

DecimalBuffer resb 32
ScreenBuffer resb 4096*100
