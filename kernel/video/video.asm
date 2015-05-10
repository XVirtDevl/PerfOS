struc RefreshCommand
	.BaseAddress resd 1
	.Length resd 1
endstruc

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
		sub edi, ScreenBuffer

		.calcNewLine:
			sub edi, 160
			ja .calcNewLine

			not edi
			add eax, 1
			add edi, eax
			mov ah, byte[ ScreenAttributes ]
			mov dword[ WriteBuffer ], edi
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
	mov byte[ScreenAttributes], al
	ret
	

global clearScreen
clearScreen:
	push rax
	push rcx

	xor rax, rax
	mov ch, byte[ ScreenAttributes ]
	mov cl, 0x20
	mov ax, cx
	shl ax, 16
	push rdi
	mov ax, cx
	shl ax, 16
	mov edi, ScreenBuffer
	mov ax, cx
	shl ax, 16
	mov ax, cx

	mov ecx, 25*20
	rep stosq

	pop rdi
	pop rcx
	pop rax
	mov dword[ ScreenPointer ], 0xb8000
	ret

global resetWritePtr
resetWritePtr:
	mov dword[ ScreenPointer ], 0xb8000
	ret

ScreenPointer dd 0xb8000
WriteBuffer dd ScreenBuffer
PageBase dd ScreenBuffer
ScreenAttributes db 0x0F
CommandBufferLength dd 0

section .bss

CommandBuffer resq 100
DecimalBuffer resb 32
ScreenBuffer resb 4096*100