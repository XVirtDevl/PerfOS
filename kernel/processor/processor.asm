%include "multiboot.inc"
%include "apic.inc"
%include "memory.inc"

%define GLOBAL_STARTUP_VECTOR 0x1000

global setUpAllCores
; rax = gdtr address
setUpAllCores:
	mov dword[ MultibootStrucAddr + multiboot.gdtr_addr ], eax
	push rsi
	push rcx

	mov edi, GLOBAL_STARTUP_VECTOR	
	mov esi, _load
	mov ecx, _loadend - _load 
	rep movsb
	
	mov eax, GLOBAL_STARTUP_VECTOR
	call startAllAPs

	pop rcx
	pop rsi

	ret

global setEstimatedProcessorCount
setEstimatedProcessorCount:
	mov dword[ EstimatedProcessorCount ], eax
	ret
global getEstimatedProcessorCount
getEstimatedProcessorCount:
	mov eax, dword[ EstimatedProcessorCount ]
	ret

global GetCoreCount
GetCoreCount:
	mov eax, dword[ ApplicationProcessorCount ]
	add eax, 1
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

	add dword[ ApplicationProcessorCount ], 1	

	mov byte[ InitialisationMutex ], 0
	
	hlt 
	jmp $

InitialisationMutex db 0
ApplicationProcessorCount dd 0
EstimatedProcessorCount dd 0
;;The whole 16-bit code will be relocated to a 4KB boundary so that the APs will start at that address
[BITS 16]
_load:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
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
