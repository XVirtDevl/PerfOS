%include "multiboot.inc"

struc cpu_state
	.workScheduleAddr resd 1
	.workScheduleSize resd 1
endstruc

global setUpMulticoreEnvironment
; rax = gdtr address, rdi = load address 4KB aligned
setUpMulticoreEnvironment:
	mov dword[ MultibootStrucAddr + multiboot.gdtr_addr ], eax
	push rsi
	push rcx
	mov esi, _load
	mov ecx, _loadend - _load 
	rep movsb
	pop rcx
	pop rsi

	ret

_APEntryPoint:
	mov ax, 0x20
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax
	
	mov al, 1
	.try_again:
		xchg byte[ InitialisationMutex ], al
		or al, al
		jnz .try_again

	


	jmp $

InitialisationMutex db 0
ApplicationProcessorCount dd 0
;;The whole 16-bit code will be relocated to a 4KB boundary so that the APs will start at that address
[BITS 16]
_load:
	mov eax, dword[ MultibootStrucAddr + multiboot.gdtr_addr ]
	cli
	lgdt[ eax ]

	mov eax, cr0
	or eax, 1
	mov cr0, eax
	
	jmp dword 0x8:_protMode
_loadend:

[BITS 32]
	_protMode:
		mov ax, 0x10
		mov ds, ax
		mov es, ax
		mov ss, ax
		mov fs, ax
		mov gs, ax

		mov eax, cr4
		or eax, 0x20
		mov cr4, eax	; Set PAE-Bit 

		mov eax, 0x300000
		mov cr3, eax
	
		mov ecx, 0xC0000080
		rdmsr
		or eax, 0x100	;Set Long Mode Bit
		wrmsr

		mov eax, cr0	
		or eax, 0x80000000	;Activate Paging
		mov cr0, eax
		
		jmp 0x18:_APEntryPoint

section .bss
	cpu_state_buffer resb 256*4
