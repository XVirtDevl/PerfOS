%include "multiboot.inc"
%include "exception.inc"
%include "video.inc"

%define FIRST_USABLE_ADDR 0x800

struc PhysMemMapEntry
	.length resq 1
	.nextSelector resq 1
	.lastSelector resq 1
	.usage resq 1
endstruc
%define ENTRY_HEADER_SIZE 32

struc E820Entry
	.BaseAddress resq 1
	.Length resq 1
	.Type resd 1
endstruc

global InitialisePhysMem
;Trashes rsi, rdi, rcx, rax, rbx
InitialisePhysMem:
	mov esi, dword[ MultibootStrucAddr + multiboot.mmap_addr ]
	
	or esi, esi
	jnz .parseMemMap


	.NoMemMap:
		push qword ErrNoMemmap
		call FatalError
		jmp $

	.parseMemMap:
		mov ecx, dword[ MultibootStrucAddr + multiboot.mmap_length ]
		
		or ecx, ecx
		jz .NoMemMap
		
		push qword 0

	.Overwrite:
		mov eax,  dword[ esi + E820Entry.Type ]
		
		cmp eax, 1
		jnz .selectNextEntry

		mov rax, qword[ esi + E820Entry.BaseAddress ]
		mov rbx, qword[ esi + E820Entry.Length ]
		
		
		or rax, rax
		jz .zeroSelector

	.BuildSelector:	
		sub rbx, ENTRY_HEADER_SIZE
		mov qword[ rax + PhysMemMapEntry.length ], rbx	
		mov qword[ rax + PhysMemMapEntry.usage ], 0
	
		cmp dword[ FirstHead ], 0
		jz .MakeFirstHead

		pop rbx
		mov qword[ rax + PhysMemMapEntry.lastSelector ], rbx
		mov qword[ rax + PhysMemMapEntry.nextSelector ], 0	

		push rax
		or rbx, rbx
		jz .selectNextEntry

		mov qword[ rbx + PhysMemMapEntry.nextSelector ], rax
	.selectNextEntry:

		add esi, 20
		sub ecx, 20
		jnz .Overwrite	
		
		pop rax
		ret
	.zeroSelector:
		mov rax, FIRST_USABLE_ADDR
		sub rbx, FIRST_USABLE_ADDR
		jmp .BuildSelector
	.MakeFirstHead:
		mov qword[ FirstHead ], rax
		add rbx, ENTRY_HEADER_SIZE
		jmp .BuildSelector

global AllocMemory
;rax = size, rsi = usage( muste be != 0 )
AllocMemory:	
	push rsi	

	mov rdi, qword[ FirstHead ]
	or rdi, rdi
	jz .fatal_no_mem

	add rax, ENTRY_HEADER_SIZE


	.SearchMemLoop:
		cmp qword[ rdi + PhysMemMapEntry.usage ], 0 
		jnz .selectNextEntry

		cmp rax, qword[ rdi + PhysMemMapEntry.length ]
		js .bigEnough
		je .perfectHit

	.selectNextEntry:
		mov rdi, qword[ rdi + PhysMemMapEntry.nextSelector ]
		
		or rdi, rdi
		jz .fatal_no_mem
		jmp .SearchMemLoop	

	.fatal_no_mem:
		push qword ErrNoMoreMem
		call FatalError
		jmp $
	
	.perfectHit:
		pop rsi
		mov qword[ rdi + PhysMemMapEntry.usage ], rsi
		ret
	

	.bigEnough:
		mov rsi, rdi
		mov rbx, qword[ rdi + PhysMemMapEntry.length ]
		sub rbx, rax
		add rsi, ENTRY_HEADER_SIZE
		mov qword[ rdi + PhysMemMapEntry.length ], rbx
		add rsi, rbx
		
		;rdi = old header length = new length rsi = new header
		sub rax, ENTRY_HEADER_SIZE
		mov qword[ rsi + PhysMemMapEntry.length ], rax
		pop rbx
		mov qword[ rsi + PhysMemMapEntry.usage ], rbx
		mov qword[ rsi + PhysMemMapEntry.lastSelector ], rdi
		mov rbx, qword[ rdi + PhysMemMapEntry.nextSelector ]
		mov qword[ rsi + PhysMemMapEntry.nextSelector ], rbx
		mov qword[ rbx + PhysMemMapEntry.lastSelector ], rsi
		mov qword[ rdi + PhysMemMapEntry.nextSelector ], rsi
		add rsi, ENTRY_HEADER_SIZE	

		ret
		

	
global DebugMemoryAllocation
DebugMemoryAllocation:
	push rdi
	push rsi
	push rax
	push rbx
	push rcx

	mov rdi, qword[ FirstHead ]
	
	or rdi, rdi
	jz AllocMemory.fatal_no_mem
	
	mov esi, DebugHead
	call printf
	
	xor rbx, rbx
	xor rcx, rcx
	.printLoop:
		add rbx, qword[ rdi + PhysMemMapEntry.length ]
		add rbx, ENTRY_HEADER_SIZE
		add rcx, ENTRY_HEADER_SIZE
		
		cmp qword[ rdi + PhysMemMapEntry.usage ], 0
		jz .selectNext
	
		add rcx, qword[ rdi + PhysMemMapEntry.length ]

		mov rax, rdi
		push qword[ rdi + PhysMemMapEntry.usage ]
		add rax, ENTRY_HEADER_SIZE
		push qword[ rdi + PhysMemMapEntry.length ]
		push rax
		mov esi, DebugMsg
		call printf
		add esp, 24

	.selectNext:
		mov rdi, qword[ rdi + PhysMemMapEntry.nextSelector ]
		or rdi, rdi
		jnz .printLoop

		push rcx
		sub rbx, rcx
		push rbx
		mov esi, DebugEnd
		call printf
		add esp, 16

		call updateScreen
	
		pop rcx	
		pop rbx
		pop rax
		pop rsi
		pop rdi
		ret


global BlockMemory
;rdi = address, rcx = size
BlockMemory:
	
		
	
DebugHead db ' Base address       | Length             | Usage',0x13,0
DebugMsg db 0x13,' %X | %X | %s',0
DebugEnd db 0x13,' Free memory: %X used memory: %X',0
FirstHead dq 0
ErrNoMemmap db 'Module: pmemory.elf Error: The OS cannot determinate the amount of RAM usable!',0
ErrNoMoreMem db 'Module: pmemory.elf Error: No more memory left to satisfy the desire',0
