%include "meta/metaprogramming.inc"

GUARDED_INCLUDE CONSOLE_EXPORT_FUNCTIONALITY, "console.inc"	; Include the file "console.inc". But exclude the ifdef CONSOLE_EXPORT_FUNCTIONALITY Block

global Console@64_PolymorphicList
Console@64_PolymorphicList:			; The following functions depend heavily on the used flags in BufferedOutputDesc
	.scroll_screen dq ScrollScreen 		; so they will become polymorphic to ease the acces and debug of these functions
	.update_screen dq UpdateScreen
	.printf dq printf


global ClearScreen	; Declared global as it does not depend that heavily on the flags in BufferedOutputDecsc
; IN: none; OUT: none
ClearScreen:
	push rdi						; Save registers
	push rax
	push rcx


	mov rdi, qword[ ScreenDimension.base_address ]
	mov rcx, qword[ ScreenDimension.screen_size_shift8 ]	; Clear only the screen not the buffer
	mov rax, qword[ ScreenClearFixValue ]
	mov qword[ ScreenDimension.writeTo_address ], rdi	; reset write ptr to the screen

	memset NUSED,NUSED,NUSED,PH_LOAD_NO_REGS|PH_SAVE_NO_REGS|PH_SHR_8


	pop rcx							; Restore registers
	pop rax
	pop rdi

	ret

; eax = scroll amount
ScrollScreen:
	cmp eax, dword[ ScreenDimension.y_resolution ]			; If the screen should be more scrolled then there are lines, then clear the screen
	jns ClearScreen							; Because there is nothing on the stack now, ClearScreen can use the same return address as this function

	push rbx							; Save reg

	mov ebx, dword[ ScreenDimension.bytes_per_line ]


	push rcx
	push rsi
	push rdi

	mov rsi, qword[ ScreenDimension.base_address ]
	mov ecx, dword[ ScreenDimension.screen_size ]
	mov rdi, rsi

	mul ebx

	add rsi, rax
	sub rcx, rax

	memcpy NUSED,NUSED,NUSED, PH_SAVE_NO_REGS | PH_LOAD_NO_REGS|PH_DIVIDABLE_4

	mov qword[ ScreenDimension.writeTo_address ], rdi

	mov ecx, eax
	mov rax, qword[ ScreenClearFixValue ]

	memset NUSED,NUSED,NUSED, PH_SAVE_NO_REGS|PH_LOAD_NO_REGS|PH_DIVIDABLE_4

	pop rdi
	pop rsi
	pop rcx
	pop rbx

	ret

;eax = scroll amount can be scrolled up
ScrollBufferBase:
	push rcx
	push rdi
	test eax, 0x80000000
	jnz .scrolling_up

	xor ecx, ecx

	.backup:
		cmp eax, dword[ BufferedOutputDesc.remembered_lines ]
		jns .clear_buffer

		push rbx

		mov ebx, dword[ ScreenDimension.bytes_per_line ]

		xor edx, edx
		mul ebx

		pop rbx

		or ecx, ecx
		jnz .scroll_up


		mov rdi, qword[ BufferedOutputDesc.base_address ]
		mov rcx, qword[ BufferedOutputDesc.readFrom_address ]
		add rdi, qword[ BufferedOutputDesc.length ]
		add rcx, rax

		cmp rcx, rdi
		js .endfunc

		sub rcx, rdi
		add rcx, qword[ BufferedOutputDesc.base_address ]
		jmp .endfunc

	.scroll_up:
		mov rcx, qword[ BufferedOutputDesc.readFrom_address ]
		sub rcx, rax

		cmp rcx, qword[ BufferedOutputDesc.base_address ]
		jns .endfunc

	.flip_over:
		add rcx, qword[ BufferedOutputDesc.length ]

		jmp .endfunc

	.clear_buffer:
		mov rdi, qword[ BufferedOutputDesc.base_address ]
		memset NUSED, qword[ ScreenClearFixValue ], qword[ ScreenDimension.screen_size_shift8 ],  PH_LOAD_RAX | PH_LOAD_RCX | PH_SHR_8 | PH_SAVE_ALL
		mov rcx, rdi
		mov qword[ BufferedOutputDesc.writeTo_address ], rdi

	.endfunc:
		mov qword[ BufferedOutputDesc.readFrom_address ], rcx
		pop rdi
		pop rcx
		ret

	.scrolling_up:
		not eax
		mov ecx, 1
		add eax, 1
		jmp .backup



global ConvertNumberToDecStr64
ConvertNumberToDecStr64:
;IN: rax = number, rdi = destBuffer( at least 27 Byte available )
	push rbx
	push rdx		; Save registers

	add rdi, 26		; Start at the end of the string. If every bit in a 64-bit register is set the decimal number is at least 25 bytes long
	mov ebx, 10		; Divide by 10

	mov byte[ rdi ], 0	; Zero terminate the string

	.prLoop:
		xor edx, edx	; edx must the zero for the division
		div rbx
		sub rdi, 1	; rdi started at the end of the string, therefor is must decrease while the loop is running
		add dl, 48	; To the rest added 48 gives the number in ascii code
		mov byte[ rdi ], dl

		or eax, eax
		jnz .prLoop

		pop rdx		; Restore registers
		pop rbx
		ret

global ConvertNumberToHexStr32
;IN: eax = number, rdi = destBuffer
ConvertNumberToHexStr32:
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
		add rsi, 1						; already increase rsi, to ensure the string parsing is going forward even if an error occured
		add edx, 8						; Select the next parameter which will match the paramter needed by %x

		cmp al, 'X'						; If it is a big X print the number as hexadecimal 64 bit string
		jz .ConvertNumberToHexStr

		cmp al, 's'						; Print a string which address is on the stack
		jz .printSubStr

		cmp al, 'd'
		jz .printDecStr						; The big and small d are the same, because every paramter is 64-bits large
									; because of the layout of the 64-bit stack
		cmp al, 'D'
		jz .printDecStr

		jmp .printLoop

	.printDecStr:
		sub rsp, 30						; Reserve 30 Bytes on the stack
		mov rax, qword[ rbp + rdx ]				; Load the next parameter on the stack
		mov rbx, rdi						; Save rdi in rbx
		mov rdi, rsp


		call ConvertNumberToDecStr64

		push rsi
		mov rsi, rdi						; Load the address of the converted number in to rsi

		mov ah, byte[ TextAttributes ]				; Reload text attributes

		mov rdi, rbx						; restore rdi

		call .prNumber

		pop rsi							; Restore rsi and after that!! Release the mem on the stack
		add rsp, 30
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
		mov ebx, dword[ ScreenDimension.bytes_per_line ]

		push rdx
		add rdi, rbx
		xor edx, edx						; Clear just before the division
		div ebx

		sub rdi, rdx						; rdi + Bytes per line - remain of division = new line address
		pop rdx							; Restore rdx

		mov ah, byte[ TextAttributes ]				; Restore attributes in ah

		cmp rcx, rdi						; Check if rdi got out of screen bounds due to this calculation
		ja .printLoop
		jmp .overflow

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
		test byte[ BufferedOutputDesc.flags ], CF_BUFFERED_OUTPUT		; If there is a buffer
		jnz .handleBufferedOverflow


		push rsi
		push rcx

		mov ebx, dword[ ScreenDimension.bytes_per_line ]

		mov ecx, dword[ ScreenDimension.screen_size ]
		mov rsi, qword[ ScreenDimension.base_address ]
		sub ecx, ebx
		mov rdi, rsi
		shr ecx, 3
		add rsi, rbx


		rep movsq

		mov ecx, ebx
		push rdi
		push rax
		shr ecx, 3
		mov rax, qword[ ScreenClearFixValue ]
		rep stosq
		pop rax
		pop rdi

		pop rcx
		pop rsi
		jmp .printLoop

	.handleBufferedOverflow:
		mov rdi, qword[ BufferedOutputDesc.base_address ]	; Just start all over again
		push rdi
		push rcx
		push rax
		mov ecx, dword[ ScreenDimension.screen_size_shift8 ]
		mov rax, qword[ ScreenClearFixValue ]
		rep stosq
		pop rax
		pop rcx
		pop rdi
		jmp .printLoop

	.done:
		test byte[ BufferedOutputDesc.flags ], CF_BUFFERED_OUTPUT	; If there is a buffered output then there is no need to update the writeTo_ptr of the screen
		jnz .update_writeToBuf

		mov qword[ ScreenDimension.writeTo_address ], rdi		; Store the offset in the screen will only be used if rdi points directly to the screen
										; but doesnt make any harm if rdi points to a buffer 
		jmp .restore_regs

	.update_writeToBuf:
		mov qword[ BufferedOutputDesc.writeTo_address ], rdi		; Update the buffer writeTo address

		cmp dword[ AutoscrollBehave ], 0
		jnz .restore_regs

		mov rax, rdi
		mov ebx, dword[ ScreenDimension.bytes_per_line ]
		sub rax, qword[ BufferedOutputDesc.base_address ]

		add rdi, rbx

		xor edx, edx

		div ebx

		sub rdi, rdx

		cmp rdi, rcx
		jns .QuitClear

		push rdi

		mov rax, qword[ ScreenClearFixValue ]
		mov ecx, ebx
		shr ecx, 3

		rep stosq

		pop rdi

	.QuitClear:

		cmp rdi, qword[ BufferedOutputDesc.readFrom_address ]
		js .rare_flipovercase

		sub rdi, qword[ BufferedOutputDesc.readFrom_address ]

		sub rdi, qword[ ScreenDimension.screen_size ]
		js .restore_regs

		add qword[ BufferedOutputDesc.readFrom_address ], rdi
		jmp .restore_regs

	.rare_flipovercase:
		sub rdi, qword[ BufferedOutputDesc.base_address ]

		sub rdi, qword[ ScreenDimension.screen_size ]
		js .double_flip

		add rdi, qword[ BufferedOutputDesc.base_address ]

		mov qword[ BufferedOutputDesc.readFrom_address ], rdi
		jmp .restore_regs

	.double_flip:
		add rdi, qword[ BufferedOutputDesc.base_address ]
		add rdi, qword[ BufferedOutputDesc.length ]

		mov qword[ BufferedOutputDesc.readFrom_address ], rdi

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
		jmp .printLoop

global SetAutoscroll
;IN: eax = 0 => on 1 => off
SetAutoscroll:
	mov dword[ AutoscrollBehave ], eax
	ret

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
	mov dword[ BufferedOutputDesc.real_length ], ecx

	push rdx

	mov rdi, rbx

	xor rdx, rdx							; Prepare registers for division
	mov eax, ecx

	mov ebx, dword[ ScreenDimension.bytes_per_line ]

	div ebx								; Lines to remember written in eax


	mov dword[ BufferedOutputDesc.remembered_lines ], eax

	xor edx, edx
	mul ebx
	mov dword[ BufferedOutputDesc.length ], eax

	
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
	xor bh, bh
	shl bx, 1
	mov word[ ScreenDimension.bytes_per_line ], bx

	mov dword[ ScreenDimension.screen_size ], ecx
	shr ecx, 3							; used for clear screen in combination with rep stosq
	mov dword[ ScreenDimension.screen_size_shift8 ], ecx

	push rdx
	mov eax, dword[ BufferedOutputDesc.real_length ]			; Calculate how many lines will fit into the buffer
	mov ebx, dword[ ScreenDimension.bytes_per_line ]
	xor edx, edx
	div ebx
	pop rdx

	mov dword[ BufferedOutputDesc.remembered_lines ], eax		; Store the calculated nuber of lines

	xor edx, edx
	mul ebx
	mov dword[ BufferedOutputDesc.length ], eax			; Store the next multiple of the line length in length
 
	ret


;IN: none OUT:none
UpdateScreen:
	ret

;IN: none OUT: none
UpdateBufferedScreen:
	; The buffer is already in the right format to get printed directly to the screen, so just perform a memcpy, because the size is a multiple of 8
	; memcpy_size8 can be used
	; There could be several problems: It is possible that the readfrom address needs to wrap around if the screen is divided
	push rsi
	push rdi
	mov rsi, qword[ BufferedOutputDesc.readFrom_address ]
	mov rdi, qword[ BufferedOutputDesc.base_address ]
	add rsi, qword[ ScreenDimension.screen_size ]			; rsi = Buffer read from address + screen size
	add rdi, qword[ BufferedOutputDesc.length ]			; rdi = Buffer base address + buffer length

	cmp rdi, rsi							; If Buffer base address + buffer length is smaller than Buffer read address + screen size
	js .several_memcpy						; Then it needs several memcpys

	pop rdi								; If not restore registers and perform single memcpy
	pop rsi
	memcpy qword[ ScreenDimension.base_address ], qword[ BufferedOutputDesc.readFrom_address ], qword[ ScreenDimension.screen_size ]

	ret

	.several_memcpy:

		sub rdi, qword[ BufferedOutputDesc.readFrom_address ]		; Calculate the length of the readRom address to the buffer end : this length is the first memcpy length
		mov rax, qword[ ScreenDimension.base_address ]			; Get the screen base address in rax
		push rax
		push rbx
		push rcx

		mov rcx, rdi							; Get the first memcpy size in rcx
		add rax, rdi							; Calculate the offset for the nexxt memcpy


		memcpy qword[ ScreenDimension.base_address ], qword[ BufferedOutputDesc.readFrom_address ], rcx, PH_LOAD_RDI | PH_LOAD_RSI | PH_SAVE_RCX

		mov ebx, dword[ ScreenDimension.screen_size ]			; Get the screen size in ebx
		sub ebx, ecx							; Subtract from the screen size the actually copied bytes and therefore get the
										; new number of bytes to copy in rbx

		mov ecx, ebx							; Move the bytes to copy in rcx

		memcpy rax, qword[ BufferedOutputDesc.base_address ], rcx, PH_LOAD_RDI | PH_LOAD_RSI | PH_SAVE_NO_REGS	; Perform second memcpy
		pop rcx								; Restore registers
		pop rbx
		pop rax
		pop rdi
		pop rsi
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
	test eax, CF_BUFFERED_OUTPUT
	jnz .handle_buffered_output

	mov qword[ Console@64_PolymorphicList.scroll_screen ], ScrollScreen
	mov qword[ Console@64_PolymorphicList.printf ], printf
	mov qword[ Console@64_PolymorphicList.update_screen ], UpdateScreen

	.done_prepare:
		mov dword[ BufferedOutputDesc.flags ], eax
		ret

	.handle_buffered_output:
		cmp qword[ BufferedOutputDesc.base_address ], 0
		jz .err_no_base

		test eax, CF_STAGE_IN_BUFFER_FOR_SCREEN
		jz .special_buffered_output

		mov qword[ Console@64_PolymorphicList.scroll_screen ], ScrollBufferBase
		mov qword[ Console@64_PolymorphicList.printf ], printf
		mov qword[ Console@64_PolymorphicList.update_screen ], UpdateBufferedScreen

		jmp .done_prepare


	.special_buffered_output:
		mov qword[ Console@64_PolymorphicList.scroll_screen ], ScrollScreen
		mov qword[ Console@64_PolymorphicList.printf ], ScrollScreen
		mov qword[ Console@64_PolymorphicList.update_screen ], ScrollScreen

		jmp .done_prepare

	.err_no_base:
		mov eax, 1
		ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DATA SECTION ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ScreenDimension:
	.x_resolution dd 80			; Resolution given in characters
	.y_resolution dd 25
	.screen_size dq 80*25*2			; 2 bytes per char; 1 byte for character and 1 for attributes
	.screen_size_shift8 dq (10)*25*2	; Screen length right shifted by 3
	.base_address dq 0xb8000		; Default output is to the video buffer at address 0xb8000
	.writeTo_address dq 0xb8000		; Store the position of the write pointer, only used if no buffer is specified
	.bytes_per_line dq 80*2		; Store bytes per line

TextAttributes dd COLOR_PAIR( COLOR_BLACK, COLOR_WHITE )
AutoscrollBehave dd 0				; Autoscroll is off by default

%define DEF_COL COLOR_PAIR( COLOR_BLACK, COLOR_WHITE )
ScreenClearFixValue dq (DEF_COL<<56)|(0x20<<48)|(DEF_COL<<40)|(0x20<<32)|(DEF_COL<<24)|(0x20<<16)|(DEF_COL<<8)|0x20


BufferedOutputDesc:
	.flags dd CF_NO_BUFFERED_OUTPUT		; No buffered output by default
	.base_address dq 0			; Therefore no output buffer
	.writeTo_address dq 0			; Write cursor address
	.readFrom_address dq 0			; Read pointer used to determinate which content should be sent to the output buffer
	.remembered_lines dd 0
	.length dq 0				; length of the complete buffer, stored in a multiple of the current bytes per line
	.real_length dq 0			; Store the real length of the buffer
