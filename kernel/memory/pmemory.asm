%include "multiboot.inc"
%include "exception.inc"
%include "console.inc"

debug_msg db 'Still alive arg  = %d', 0x13, 0
%macro DEBUG 1
	VPrintf debug_msg, %1
	call UpdateScreen
%endmacro

%define FIRST_USABLE_ADDR 0x2000

struc PhysMemMapEntry
	.length resq 1
	.nextSelector resq 1
	.lastSelector resq 1
	.usage resq 1
endstruc
%define ENTRY_HEADER_SIZE 32

struc E820Entry
	.entry_len resd 1
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
		jmp $
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
			
		mov eax, dword[ esi + E820Entry.entry_len ]
		add eax, 4
		add esi, eax
		sub ecx, eax
		ja .Overwrite	
		
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

align 8
MUTEX_MEM_MANAGER dd 0


LockMutex:
	push rax
	mov al, 1
	
	.again:
		xchg al, byte[ MUTEX_MEM_MANAGER ]
		test al, al
		jnz .again
	pop rax
	ret

UnlockMutex:
	mov byte[ MUTEX_MEM_MANAGER ], 0
	ret


global AllocMemoryAligned
; rax = size, rcx = Mask forbidden bits, rsi = usage
AllocMemoryAligned:
	push qword UnlockMutex
	push rdx
	push rcx

	mov rdx, rcx		; if ecx = 0xFFF then edx = 0xFFF1000
	not rdx

	push rsi		; ecx = 0xFFF f. e. will create a page at boundary 0x1000
	jmp AllocMemory.alignedEnter

global AllocMemory
;rax = size, rsi = usage( muste be != 0 )
AllocMemory:
	push qword UnlockMutex	
	push rdx
	push rcx
	push rsi	
	xor ecx, ecx	; Boundary = 0 means no forbidden bits means no Boundary
	
	.alignedEnter:

	call LockMutex
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
		pop rcx
		pop rdx
		mov qword[ rdi + PhysMemMapEntry.usage ], rsi
		mov rsi, rdi
		add rsi, ENTRY_HEADER_SIZE
		ret
	
	.CutUpperMem:
		sub rax, ENTRY_HEADER_SIZE
		add rsi, rax
		mov qword[ rdi + PhysMemMapEntry.length ], rax
		pop rdx
		mov qword[ rdi + PhysMemMapEntry.usage ], rdx

		sub rbx, rax
		sub rbx, ENTRY_HEADER_SIZE
		mov qword[ rsi + PhysMemMapEntry.length ], rbx
		mov rdx, rsi
		mov qword[ rsi + PhysMemMapEntry.usage ], 0
		xchg rdx, qword[ rdi + PhysMemMapEntry.nextSelector ]
		mov qword[ rsi + PhysMemMapEntry.lastSelector ], rdi
		mov qword[ rsi + PhysMemMapEntry.nextSelector ], rdx

		add rsi, ENTRY_HEADER_SIZE
		pop rcx
		pop rdx
		ret

	.bigEnough:
		mov rbx, qword[ rdi + PhysMemMapEntry.length ]
		
		or rcx, rcx
		jz .dontmind

		mov rsi, rdi
		add rsi, ENTRY_HEADER_SIZE
		test rsi, rcx
		jz .CutUpperMem

		add rsi, rcx
		add rsi, 1
		and rsi, rdx	; rsi = address on boundary above rdi

		sub rsi, rdi	; rsi = difference between that address and rdi
		sub rsi, ENTRY_HEADER_SIZE	; rsi = offset in rdis mem
		push rax
		add rax, rsi  ; rax = size + HEADER_ENTRY_SIZE + offset in rdi

		sub rbx, rax
		pop rax
		js .selectNextEntry

		; rbx = remaining length
		mov rdx, rbx

		mov qword[ rdi + PhysMemMapEntry.length ], rsi
		mov rbx, qword[ rdi + PhysMemMapEntry.nextSelector ]
	
		add rsi, rdi	; rsi = address of header
		mov qword[ rsi + PhysMemMapEntry.nextSelector ], rbx
		
		pop rbx
		mov qword[ rsi + PhysMemMapEntry.lastSelector ], rdi
		mov qword[ rsi + PhysMemMapEntry.usage ], rbx
		mov qword[ rdi + PhysMemMapEntry.nextSelector ], rsi
		sub rax, ENTRY_HEADER_SIZE
		mov qword[ rsi + PhysMemMapEntry.length ], rax
		
		cmp rdx, 256
		jns .NewHead

		add qword[ rsi + PhysMemMapEntry.length ], rax
		
		pop rcx
		pop rdx
		add rsi, ENTRY_HEADER_SIZE
		ret
		
		.NewHead:
			mov rdi, rsi
			add rdi, rax
			add rdi, ENTRY_HEADER_SIZE
			
			mov qword[ rdi + PhysMemMapEntry.length ], rdx
			mov qword[ rdi + PhysMemMapEntry.usage ], 0
			mov rdx, rdi
			mov qword[ rdi + PhysMemMapEntry.lastSelector ], rsi
			xchg rdx, qword[ rsi + PhysMemMapEntry.nextSelector ]
			mov qword[ rdi + PhysMemMapEntry.nextSelector ], rdx
	
			add rsi, ENTRY_HEADER_SIZE
			pop rcx
			pop rdx
			ret
	
		

	.dontmind:
		sub rbx, rax ; rax = size + HEADER_ENTRY_SIZE  => 
		cmp rbx, 256
		js .perfectHit

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

		or rbx, rbx
		jz .NoNeedToEnter
		mov qword[ rbx + PhysMemMapEntry.lastSelector ], rsi
	
	.NoNeedToEnter:
		mov qword[ rdi + PhysMemMapEntry.nextSelector ], rsi
		add rsi, ENTRY_HEADER_SIZE	
		pop rcx
		pop rdx
		ret	
		
;00 | 20	| 100 | 120
;rsi = 00
;rsi = 20 + (100 - 20-20)
;rsi = 20 + 60 = 80

global PrintAllHeads
PrintAllHeads:
	push qword UnlockMutex
	push rsi
	push rdi
	call LockMutex
	mov rdi, qword[ FirstHead ]	

	or rdi, rdi
	jz AllocMemory.fatal_no_mem

	
	mov esi, DebugHead
	call printf

	.looped:
		mov rsi, qword[ rdi + PhysMemMapEntry.usage ]
		or rsi, rsi
		jnz .PushRSI

		mov rsi, FreeMemoryMsg
	.PushRSI:
		push rsi
		push qword[ rdi + PhysMemMapEntry.length ]
		push rdi
		mov esi, DebugMsg
		call printf
		add esp, 24

	.selectNext:
		mov rdi, qword[ rdi + PhysMemMapEntry.nextSelector ]
		or rdi, rdi
		jnz .looped

		call UpdateScreen

		pop rdi
		pop rsi
		ret
		
	
global DebugMemoryAllocation
DebugMemoryAllocation:
	push qword UnlockMutex
	push rdi
	push rsi
	push rax
	push rbx
	push rcx
	call LockMutex

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

		call UpdateScreen

		pop rcx
		pop rbx
		pop rax
		pop rsi
		pop rdi
		ret


global FreeMemory
;rax = address
FreeMemory:
	push qword UnlockMutex
	push rsi
	push rdi
	push rbx

	sub rax, ENTRY_HEADER_SIZE
	
	call LockMutex
	mov rdi, qword[ rax + PhysMemMapEntry.nextSelector ]
	mov rsi, qword[ rax + PhysMemMapEntry.lastSelector ]

	cmp qword[ rax + PhysMemMapEntry.usage ], 0
	jz .fatal_overwrite

	or rdi, rdi
	jz .testLower

	cmp rax, rdi
	jns .fatal_overwrite

	cmp qword[ rdi + PhysMemMapEntry.usage ], 0
	jz .MergeUpper

	.testLower:
		or rsi, rsi
		jz .MergeNone
	
		cmp rsi, rax
		jns .fatal_overwrite

		cmp qword[ rsi + PhysMemMapEntry.usage ], 0
		jz .MergeOnlyLower	

	.MergeNone:
		mov qword[ rax + PhysMemMapEntry.usage ], 0	
		pop rbx
		pop rdi
		pop rsi
		ret

	.MergeOnlyLower:
		mov rbx, rax
		sub rbx, qword[ rsi + PhysMemMapEntry.length ]
		sub rbx, ENTRY_HEADER_SIZE

		cmp rbx, rsi
		jnz .MergeNone

		jmp .MergeLower	

	.MergeOnlyUpper:
		mov rbx, rax
		add rbx, qword[ rax + PhysMemMapEntry.length ]
		add rbx, ENTRY_HEADER_SIZE
		
		cmp rbx, rdi
		jnz .MergeNone

		mov rbx, qword[ rdi + PhysMemMapEntry.length ]
		mov rsi, qword[ rdi + PhysMemMapEntry.nextSelector ]
		add rbx, ENTRY_HEADER_SIZE
		mov qword[ rax + PhysMemMapEntry.nextSelector ], rsi
		add qword[ rax + PhysMemMapEntry.length ], rbx

		jmp .MergeNone
		

	.MergeUpper:
		or rsi, rsi
		jz .MergeOnlyUpper
		
		cmp qword[ rsi + PhysMemMapEntry.usage ], 0
		jnz .MergeOnlyUpper

	.MergeBoth:
		mov rbx, rax
		sub rbx, qword[ rsi + PhysMemMapEntry.length ]
		sub rbx, ENTRY_HEADER_SIZE

		cmp rbx, rsi
		jnz .MergeOnlyUpper

	.MergeLower:
		mov rbx, qword[ rax + PhysMemMapEntry.length ]
		add rbx, ENTRY_HEADER_SIZE
		mov qword[ rsi + PhysMemMapEntry.nextSelector ], rdi
		add qword[ rsi + PhysMemMapEntry.length ], rbx
		
		or rdi, rdi
		jz .NoBackward
		
		mov qword[ rdi + PhysMemMapEntry.lastSelector ], rsi
		
	.NoBackward:
		mov rbx, rsi
		mov rax, rsi
		add rbx, qword[ rsi + PhysMemMapEntry.length ]

		cmp rbx, rdi
		jnz .MergeNone

		mov rbx, qword[ rdi + PhysMemMapEntry.length ]
		mov rdi, qword[ rdi + PhysMemMapEntry.nextSelector ]
		add rbx, ENTRY_HEADER_SIZE
		add qword[ rsi + PhysMemMapEntry.length ], rbx
		add qword[ rsi + PhysMemMapEntry.nextSelector ], rdi
		jmp .MergeNone
		
	.fatal_overwrite:
		push qword ErrMemMapEntryOverride
		call FatalError
		jmp $
		

global BlockMemory
;rdi = address, rcx = size
BlockMemory:
	push qword UnlockMutex
	push rsi
	push rax
	push rbx
	call LockMutex
	mov rsi, qword[ FirstHead ]
	
	or rsi, rsi
	jz .fatal_no_mem

	.BlockLooped:
		cmp qword[ rsi + PhysMemMapEntry.usage ], 0
		jz .CheckBounds
	
	.selectNextEntry:
		mov rsi, qword[ rsi + PhysMemMapEntry.nextSelector ]
		
		or rsi, rsi
		jnz .BlockLooped
	.done:
		pop rbx
		pop rax	
		pop rsi
		ret
	.fatal_no_mem:	
		push qword ErrNoMoreMem
		call FatalError
		jmp $

	.CheckBounds:
		cmp rdi, rsi
		jbe .CheckBoundEnd

		mov rax, rsi
		add rax, qword[ rsi + PhysMemMapEntry.length ]

		cmp rdi, rax
		jns .selectNextEntry

		;rdi is in the area [rsi - rsi + length]
		mov rbx, rdi
		add rbx, rcx
		add rbx, ENTRY_HEADER_SIZE + 256

		cmp rax, rbx
		js .GreaterThan	
				
		
		mov rbx, rdi
		sub rbx, rsi
		sub rbx, ENTRY_HEADER_SIZE
		mov qword[ rsi + PhysMemMapEntry.length ], rbx
		
		 

		
		add rdi, rcx
		sub rax, rdi
		sub rax, ENTRY_HEADER_SIZE


		mov qword[ rdi + PhysMemMapEntry.length ], rax
		mov qword[ rdi + PhysMemMapEntry.usage ], 0
		mov qword[ rdi + PhysMemMapEntry.lastSelector ], rsi

		mov rax, rdi
		xchg rax, qword[ rsi + PhysMemMapEntry.nextSelector ]
		
		mov qword[ rdi + PhysMemMapEntry.nextSelector ], rax
		
		or rax, rax
		jz .NoSetNeed
		
		mov qword[ rax + PhysMemMapEntry.lastSelector ], rdi
	
	.NoSetNeed:
		jmp .done		

	;2 Things are clear now: 1. rdi € [ rsi; rsi+length[ 2. rdi+rcx > rsi+length
	.GreaterThan:
		mov rax, rdi
		sub rax, rsi
		sub rax, ENTRY_HEADER_SIZE


		mov rdi, rsi
		add rdi, qword[ rsi + PhysMemMapEntry.length ]
		sub rbx, rdi
		sub rcx, rbx

		mov qword[ rsi + PhysMemMapEntry.length ], rax
		jmp .selectNextEntry
		

	.CheckBoundEnd:
		mov rax, rdi
		add rax, rcx

		cmp rax, rsi
		js .selectNextEntry
		je .done

		sub rax, rsi
		add rax, ENTRY_HEADER_SIZE + 256
		cmp rax, qword[ rsi + PhysMemMapEntry.length ]
		je .DeleteEntry
		ja .DeleteEntryAndSelectNext

		sub rax, 256
		sub rax, ENTRY_HEADER_SIZE
		
		sub qword[ rsi + PhysMemMapEntry.length ], rax

		push rcx
		mov rdi, rsi
		mov rcx, 4
		add rdi, rax
		rep movsq
		pop rcx

		sub rdi, ENTRY_HEADER_SIZE
	
		mov rsi, qword[ rdi + PhysMemMapEntry.nextSelector ]
		mov rax, qword[ rdi + PhysMemMapEntry.lastSelector ]

		or rsi, rsi
		jz .NoNextSelector
		mov qword[ rsi + PhysMemMapEntry.lastSelector ], rdi
		
	.NoNextSelector:
		or rax, rax
		jz .NewHeadLeader

		mov qword[ rax + PhysMemMapEntry.nextSelector ], rdi

		jmp .done
	
	.NewHeadLeader:
		mov qword[ FirstHead ], rdi
		jmp .done
	
	
	.DeleteEntryAndSelectNext:
		mov rax, rsi
		add rax, qword[ rsi + PhysMemMapEntry.length ]
		sub rax, rdi 

		sub rcx, rax

		add rax, rdi
		
		push rax
		mov rax, qword[ rsi + PhysMemMapEntry.nextSelector ]
		mov rsi, qword[ rsi + PhysMemMapEntry.lastSelector ]

		or rax, rax
		jz .NoNextSelAnd
		mov qword[ rax + PhysMemMapEntry.lastSelector ], rsi
		
		.NoNextSelAnd:
			or rsi, rsi
			jz .workout

			mov qword[ rsi + PhysMemMapEntry.nextSelector ], rax
			jmp .workoutDone
	
		.workout:
			mov qword[ FirstHead ], rax
		.workoutDone:
			pop rdi

			or rax, rax
			jz .done
		
			mov rsi, rax
			jmp .BlockLooped
			

	
	.DeleteEntry:
		mov rax, qword[ rsi + PhysMemMapEntry.nextSelector ]
		mov rsi, qword[ rsi + PhysMemMapEntry.lastSelector ]

		or rax, rax
		jz .NoNextSel
	
		mov qword[ rax + PhysMemMapEntry.lastSelector ], rsi
		
		.NoNextSel:
			or rsi, rsi
			jz .NewHead

			mov qword[ rsi + PhysMemMapEntry.nextSelector ], rax
			
			jmp .done
		.NewHead:
			mov qword[ FirstHead ], rax

			jmp .done
	

		
		
	
FreeMemoryMsg db 'Free memory',0
DebugHead db 0xA,'Used memory table ver 0.1.0',0xA,' Base address       | Length             | Usage',0
DebugMsg db 0xA,' %X | %X | %s',0
DebugEnd db 0xA,' Free memory: %X used memory: %X',0
FirstHead dq 0
ErrMemMapEntryOverride db 'Module: pmemory.elf Error: The memory description block is corrupted!',0
ErrNoMemmap db 'Module: pmemory.elf Error: The OS cannot determinate the amount of RAM usable!',0
ErrNoMoreMem db 'Module: pmemory.elf Error: No more memory left to satisfy the desire',0
