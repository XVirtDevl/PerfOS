%include "metaprogramming.inc"

GUARDED_INCLUDE CONSOLE_EXPORT_FUNCTIONALITY, "console.inc"


global ClearScreen
; IN: none; OUT: none
ClearScreen:
	push rdi						; Save registers
	push rax
	push rcx


	mov rdi, qword[ ScreenDimension.base_address ]
	mov rcx, qword[ ScreenDimension.screen_size_shift8 ]	; Clear only the screen not the buffer
	mov rax, qword[ ScreenClearFixValue ]
	mov qword[ ScreenDimension.writeTo_address ], rdi	; reset write ptr to the screen

	rep stosq


	pop rcx							; Restore registers
	pop rax
	pop rdi

	ret

global ConvertNumberToHexStr32
ConvertNumberToHexStr32:
;IN: eax = number, rdi = destBuffer
	push rcx					; Save rcx
	mov ecx, 32					; Just 32-bits precision
	add rdi, 10					; 11 Bytes are needed
	jmp ConvertNumberToHexStr64.startConv		; Start the conversion

global ConvertNumberToHexStr32
;IN: rax = number, rdi = destBuffer
ConvertNumberToHexStr64:
	push rcx
	mov ecx, 64		; 64 Bit precision
	add rdi, 18		; 19 bytes are needed

	.startConv:		; Entry point for the 32-bit version of this function, just needs to tweak the precision inc ecx and set up the stack properly
	mov byte[ rdi ], 0	; zero terminating string
	sub rdi, 1


	.prLoop:
		push rax	; Save rax for the next round
		and al, 0x0F	; zero out everything except the lower 4 bits

		cmp al, 0xA	; If al is greater than 9 then it will become a letter
		jns .hexTime

		add al, 48	; Else add 48 to get the letter in ascii

	.push:
		mov byte[ rdi ], al		; Write the calculated ascii key to the buffer
		sub rdi, 1			; Go down in the buffer by one
		pop rax				; Restore the number before the modify
		shr rax, 4			; Select the next 4 bits

		sub ecx, 4			; Processed 4 bits in one loop so subract the precision by 4
		jnz .prLoop			; If the desired precision is reached end the loop

		pop rcx

		sub rdi, 1			; rdi is alraedy pointing at a free cell so it needs only a subtract of one to point to two free cells
		mov word[ rdi ], '0x'		; Add Preceeding 0x
		ret

	.hexTime:
		add al, 55	; Add 55 to get the character in ascii so 10 => A 11 => B and so on
		jmp .push



global printf
;IN: esi = string address, further arguments on the stack
printf:
	mov rbp, rsp							; Arguments have postiv ofssets arg1 = qword[ ebp + 8 ]
	test byte[ BufferedOutputDesc.flags ], CF_BUFFERED_OUTPUT	; Is there a buffer to write to?
	jnz .prepare_output_stage					; Yes then write to the buffer instead of writing to the screen 

	push rdi							; Save original rdi
	mov rdi, qword[ ScreenDimension.base_address ]
	push rcx							; Save original rcx
	mov rcx, qword[ ScreenDimension.screen_size ]
	push rdi							; Save the base address of the screen on the stack at address [ebp-24]
	push rax							; Save other register
	push rdx
	xor edx, edx

	add rcx, rdi							; Calculate the end of the screen address

	push rbx


	mov rdi, qword[ ScreenDimension.writeTo_address ]		; Load the actual write pointer in rdi

	mov ah, byte[ TextAttributes ]					; Load the text attributes

	.printLoop:
		mov al, byte[ rsi ]					; Grab one byte from the string
		add rsi, 1

		or al, al
		jz .done						; If it is zero then we're done

		cmp al, CONSOLE_NEWLINE_CHAR
		jz .newline

		cmp al, CONSOLE_NEWCOLOR_CHAR				; The byte preceedig the CONSOLE_NEWCOLOR_CHAR will define the new color
		jz .selectNewColor

		cmp al, '%'
		jz .printFormatted

		mov word[ rdi ], ax					; If it is none of the above print it on the screen 
		add rdi, 2

		cmp rcx, rdi						; Already at the end of the screen?
		ja .printLoop
		jmp .overflow

	.printFormatted:
		mov al, byte[ rsi ]					; Load the character following the '%'
		add rsi, 1
		add edx, 8

		cmp al, 'X'						; If it is a big X print the number as hexadecimal 64 bit string
		jz .ConvertNumberToHexStr

		cmp al, 's'						; Print a string which address is on the stack
		jz .printSubStr

		jmp .printLoop

	.printSubStr:
		push rsi						; Save rsi on the stack
		mov rsi, qword[ rbp + rdx ]				; Load the substr address

		call .prNumber						; Print the string, nevermind newline or color change

		pop rsi							; restore rsi
		jmp .printLoop						; continue the normal print loop

	.ConvertNumberToHexStr:
		sub rsp, 24						; Make some place for the number
		mov rax, rdi						; Save old rdi
		mov rdi, rsp						; Destination buffer will be on the stack


		push rsi						; Save registers; Remember rdi will not change but rsp will !!
		push rax						; Save old rdi on the stack cause rax = old rdi
		mov rax, qword[ rbp + rdx ]				; Load the properly argument from the stack
		call ConvertNumberToHexStr64				; Convert the number in rax to a string
		mov rsi, rdi						; Load the string address in rsi
		pop rdi							; restore the write ptr
		mov ah, byte[ TextAttributes ]				; restore the text attributes

		call .prNumber						; will just print the number, does not remember linebreak and things like that
		pop rsi							; restore original rsi
		add rsp, 24						; Don't use the stack space anymore
		jmp .printLoop						; Continue print loop

	.prNumber:
		mov al, byte[ rsi ]					; Grab one byte from the converted number
		add rsi, 1

		or al, al
		jz .retToCallee						; If it is zero then the whole number has been printed

		mov word[ rdi ], ax					; Print the number character with the related attributes
		add rdi, 2
		jmp .prNumber

	.retToCallee:
		ret							; Return to the callee

	.newline:
		mov rax, rdi
		sub rax, qword[ ebp - 24 ]				; Calculate the offset of rdi in the screen
		mov ebx, dword[ ScreenDimension.x_resolution ]
		add ebx, ebx						; Calculate x resolution *2 to get the bytes per line in ebx

		push rdx
		add rdi, rbx
		xor edx, edx						; Clear just before the division
		div ebx

		sub rdi, rdx						; rdi + Bytes per line - remain of division = new line address
		pop rdx							; Restore rdx

		mov ah, byte[ TextAttributes ]				; Restore attributes in ah

		cmp rcx, rdi						; Check if rdi got out of screen bounds due to this calculation
		ja .printLoop

	.selectNewColor:						; The byte preceeding the triggering character specifies the new color
		mov ah, byte[ rsi ]					; Load the new attributes
		add rsi, 1

		or ah, ah						; If ah is there it is probably an errror quit the function to avoid riskes
		jz .done						; because if ah is zero nothing can be seen on the screen and it is also the string terminating
									; character, so the probability of a misstype is very high

		call SetTextAttributes					; Set the new attributes

		jmp .printLoop

	;TODO: Handle overflow
	; Should handle the case when rdi got out of the screen bounds could be called with two setups!
	; Setup 1: rdi is writing directly to the screen therefore it is important to either scroll the screen or stop printing
	; Setup 2: rdi is writing to the buffer, so rdi reached the end of the buffer, this means rdi should start to recycle the whole buffer 
	.overflow:
		jmp $


	.done:
		test byte[ BufferedOutputDesc.flags ], CF_BUFFERED_OUTPUT	; If there is a buffered output then there is no need to update the writeTo_ptr of the screen
		jnz .update_writeToBuf

		mov qword[ ScreenDimension.writeTo_address ], rdi		; Store the offset in the screen will only be used if rdi points directly to the screen
										; but doesnt make any harm if rdi points to a buffer 
		jmp .restore_regs

	.update_writeToBuf:
		mov qword[ BufferedOutputDesc.writeTo_address ], rdi		; Update the buffer writeTo address

	.restore_regs:
		pop rdx
		pop rbx
		pop rax
		pop rdi								; Pop screen base address
		pop rcx
		pop rdi								; Pop "real" rdi
		ret

	.prepare_output_stage:
		push rdi							;Create the same stack hirachy as for the normal function
		push rcx
		mov rdi, qword[ BufferedOutputDesc.base_address ]
		push rdi							; Push the base address of the buffer for new line calculations
		mov rcx, qword[ BufferedOutputDesc.length ]
		add rcx, rdi							; Calculate the end of the buffer
		mov rdi, qword[ BufferedOutputDesc.writeTo_address ]		; Load the writeTo address at which the writing will be starting
		mov ah, byte[ TextAttributes ]					; Load the current screen attributes
		push rax
		push rbx
		push rdx

		test byte[ BufferedOutputDesc.flags ], CF_STAGE_IN_BUFFER_FOR_SCREEN	; If the buffer should have the same format as the screen, then the screen print loop can be used!
		jnz .printLoop

	;TODO: Write a printer loop if the format of the buffer is not the same as the screen
		jmp $

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

	mov dword[ BufferedOutputDesc.remembered_lines ], eax		; Store the calculated nuber of lines
 
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

		cmp al, CONSOLE_NEWLINE_CHAR
		jz .linebreak							; Do linebreak

		cmp al, CONSOLE_NEWCOLOR_CHAR
		jz .selectNewColor

		or al, al
		jz .prep_done							; Ok no more to print

		mov word[ rdi ], ax
		add rdi, 2							; Select next cell on the screen

		cmp rcx, rdi							; Already rached the end of the screen?
		jbe .prep_done
		jmp .printLoop							; Continue print loop

	.selectNewColor:
		mov ah, byte[ rsi ]						; Grab the new attributes from rsi
		add rsi, 1

		or ah, ah							; If ah is zero then probably there went something wrong with new new attributes
		jz .prep_done							; it if far more probable that the zero is the terminating character of the string instead of
										; the new black background with black foreground text arttributes

		call SetTextAttributes						; Commit changes to the module

		jmp .printLoop

	.linebreak:

		mov ebx, dword[ ScreenDimension.x_resolution ]
		mov rax, rdi
		add ebx, ebx							; x resolution * 2 = bytes per line on the screen
		sub rax, qword[ ScreenDimension.base_address ]

		xor edx, edx
		add rdi, rbx
		div ebx								; Calculate offset of write pointer to base and divide it by bytes per line

		sub rdi, rdx							; In edx the remain of the division resides

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
	.writeTo_address dq 0xb8000		; Store the position of the write pointer, only used if no buffer is specified

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
