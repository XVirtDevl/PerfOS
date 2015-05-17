%include "metaprogramming.inc"

GUARDED_INCLUDE CONSOLE_EXPORT_FUNCTIONALITY, "console.inc"

global printf
;IN: esi = string address, further arguments on the stack
printf:
	

global SetBufferedOutputBuffer
; IN: edi = base address, ecx = size
; OUT: eax = zero on success, != zero on error or warning
SetBufferedOutputBuffer:
	cmp dword[ BufferedOutputDesc.length ], 0
	jnz .possible_fault

	push qword 0							; Will be popped by rax => no error


	.update_description:

	mov qword[ BufferedOutputDesc.base_address ], rdi		; Update the buffered output description to the new value
	mov qword[ BufferedOutputDesc.writeTo_address ], rdi
	mov qword[ BufferedOutputDesc.readFrom_address ], rdi
	mov dword[ BufferedOutputDesc.length ], ecx

	push rdx

	mov rdi, rbx

	xor rdx, rdx							; Prepare registers for division
	mov eax, ecx

	mov ebx, dword[ ScreenDimension.x_resolution ]
	add ebx, ebx

	div ebx								; Lines to remember written in eax


	mov dword[ BufferedOutputDesc.remembered_lines ], eax
	
	mov rbx, rdi							; Restore registers
	pop rdx
	pop rax

	ret

	.possible_fault:						; If BufferedOutputDesc already describes a buffer, it could be overwritte or build a substantial memory leak 
		push qword 1
		jmp .update_description

global SetScreenDimensions
; IN: rax = screen base address, bl = x resolution, bh = y resolution, ecx = length
SetScreenDimensions:
	mov qword[ ScreenDimension.base_address ], rax
	mov byte[ ScreenDimension.x_resolution ], bl
	mov byte[ ScreenDimension.y_resolution ], bh
	mov dword[ ScreenDimension.screen_size ], ecx
	shr ecx, 3							; used for clear screen in combination with rep stosq
	mov dword[ ScreenDimension.screen_size_shift8 ], ecx

	push rdx
	mov eax, dword[ BufferedOutputDesc.length ]			; Calculate how many lines will fit into the buffer
	mov ebx, dword[ ScreenDimension.x_resolution ]
	add ebx, ebx							; The doubled x resolution will give the length of a line in bytes
	xor edx, edx
	div ebx
	pop rdx

	mov dword[ BufferedOutputDesc.remembered_lines ], eax
 
	ret

global UpdateScreen
;IN: none OUT: none
UpdateScreen:
	test byte[ BufferedOutputDesc.flags ], CF_BUFFERED_OUTPUT		; Is there a buffered output?
	jz .done								; No? Then everything is on the screen as it should

	test byte[ BufferedOutputDesc.flags ], CF_STAGE_IN_BUFFER_FOR_SCREEN	; Is the buffered output in the right format for the screen?
	jnz .just_memcpy							; yes so it will only need a memcpy


	push rdi								;Save fragil regs
	push rax
	push rsi
	push rcx
	push rbx
	push rdx

	mov ah, byte[ TextAttributes ]						; Load text attributes
	mov rdi, qword[ ScreenDimension.base_address ]
	mov rsi, qword[ BufferedOutputDesc.readFrom_address ]
	mov rcx, qword[ ScreenDimension.screen_size ]

	add rcx, rdi								; Calculate the end of the visible screen

	.printLoop:
		mov al, byte[ rsi ]						; Load one byte from buffer
		add rsi, 1

		cmp al, 0xA
		jz .linebreak							; Do linebreak

		or al, al
		jz .prep_done							; Ok no more to print

		mov word[ rdi ], ax
		add rdi, 2							; Select next cell on the screen

		cmp rcx, rdi							; Already rached the end of the screen?
		jbe .prep_done
		jmp .printLoop							; Continue print loop

	.linebreak:

		mov ebx, dword[ ScreenDimension.x_resolution ]
		mov rax, rdi
		add ebx, ebx							; x resolution * 2 = bytes per line on the screen
		sub rax, qword[ ScreenDimension.base_address ]

		xor edx, edx
		div ebx								; Calculate offset of write pointer to base and divide it by bytes per line

		add rdi, rdx							; In edx the remain of the division resides

		mov ah, byte[ TextAttributes ]					; reload ah cause it got trashed earlier on

		cmp rcx, rdi							; Reached end of the visible screen?
		ja .printLoop


	.prep_done:
		pop rdx								; Restore registers
		pop rbx
		pop rcx
		pop rsi
		pop rax
		pop rdi

		ret

	.just_memcpy:
		; The buffer is already in the right format to get printed directly to the screen, so just perform a memcpy, because the size is a multiple of 8
		; memcpy_size8 can be used
		memcpy_size8 qword[ ScreenDimension.base_address ], qword[ BufferedOutputDesc.readFrom_address ], qword[ ScreenDimension.screen_size ]
	.done:
		ret 

global SetTextAttributes
; IN: ah = Text Attributes
SetTextAttributes:
	push rcx
	mov byte[ TextAttributes ], ah
	mov al, 0x20

%macro PrepareRCX 0							; Function is used repeatedly broadcasts ax to all bits in rcx
	mov cx, ax
	shl rcx, 16
%endmacro

	EnrolledLoop 3, PrepareRCX
	mov cx, ax							; RCX now contains ax broadcasted in rcx
	mov qword[ ScreenClearFixValue ], rcx

	pop rcx
	ret

global SetBufferedOutputFlags
; IN: eax = flags
SetBufferedOutputFlags:
	push rbx							; Save rbx so that only eax is trashed at the end of the function
	mov ebx, dword[ BufferedOutputDesc.flags ]

	xor ebx, eax							; Will check if the flag CF_STAGE_IN_BUFFER_FOR_SCREEN has changed
	test ebx, CF_STAGE_IN_BUFFER_FOR_SCREEN	
	jz .contin							; If not just continue 

	mov rbx, qword[ BufferedOutputDesc.base_address ]		; else reset the write and read pointer of the buffer because the store behavior of the functions will change
	mov qword[ BufferedOutputDesc.writeTo_address ], rbx		; with that changed bit
	mov qword[ BufferedOutputDesc.readFrom_address ], rbx

	.contin:
		pop rbx							; restore rbx
		test eax, CF_BUFFERED_OUTPUT				; If the output should be buffered from now on check if there is a valid base address for the buffer
		jnz .check_base

	.set_flags:
		mov dword[ BufferedOutputDesc.flags ], eax
		xor eax, eax
		ret

	.check_base:
		cmp dword[ BufferedOutputDesc ], 0			; Is there a valid base for buffered output?
		jnz .set_flags						; Yes, continue function

		mov eax, 1			; High possibility of error because the print functions will buffer there output in a not initialised buffer, so abort function
		ret


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DATA SECTION ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ScreenDimension:
	.x_resolution dd 80			; Resolution given in characters
	.y_resolution dd 25
	.screen_size dq 80*25*2			; 2 bytes per char; 1 byte for character and 1 for attributes
	.screen_size_shift8 dq (10)*25*2	; Screen length right shifted by 3
	.base_address dq 0xb8000		; Default output is to the video buffer at address 0xb8000

TextAttributes dd COLOR_PAIR( COLOR_BLACK, COLOR_WHITE )

%define DEF_COL COLOR_PAIR( COLOR_BLACK, COLOR_WHITE )
ScreenClearFixValue dq (DEF_COL<<56)|(0x20<<48)|(DEF_COL<<40)|(0x20<<32)|(DEF_COL<<24)|(0x20<<16)|(DEF_COL<<8)|0x20


BufferedOutputDesc:
	.flags dd CF_NO_BUFFERED_OUTPUT		; No buffered output by default
	.base_address dq 0			; Therefore no output buffer
	.writeTo_address dq 0			; Write cursor address
	.readFrom_address dq 0			; Read pointer used to determinate which content should be sent to the output buffer
	.remembered_lines dd 0
	.length dd 0				; length of the complete buffer
