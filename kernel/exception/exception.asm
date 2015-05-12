%include "video.inc"


global FatalError
;Stack = error msg
FatalError:
	push r15
	mov r15, qword[ esp + 16 ]
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax
	push r15
	

	mov al, 0x1F
	call setScreenAttributes

	call clearScreen	

	mov esi, TypicalFatalError
	call printf

	call updateScreen	
	jmp $

TypicalFatalError db '      Fatal error cannot proceed! Error: %s',0x13,' rax = %X  rbx = %X',0x13,' rcx = %X  rdx = %X', 0x13, ' rsi = %X  rdi = %X', 0x13
TypicalFatalError2 db '  r8 = %X   r9 = %X',0x13,' r10 = %X  r11 = %X', 0x13, ' r12 = %X  r13 = %X',0x13,' r14 = %X  r15 = %X',0
