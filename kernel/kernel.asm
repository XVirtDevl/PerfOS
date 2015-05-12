%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)
%include "video.inc"
%include "multiboot.inc"
%include "apic.inc"
%include "memory.inc"
%include "processor.inc"

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM
STACK_BASE dd 0x500000
%define GDT_BASE 0x7C00
[BITS 32]
section .text
global _start
_start:
	mov esp, dword[ STACK_BASE ]
	
	cmp ebx, 0x500
	jz .RelocateDone

	mov esi, ebx
	mov edi, MultibootStrucAddr
	mov ecx, 22
	rep movsd
	
	.RelocateDone:	
		mov esi, dword[ MultibootStrucAddr + multiboot.mmap_addr ]
		
		mov dword[ MultibootStrucAddr + multiboot.mmap_addr ], 0x600
		
		or esi, esi
		jz .RemoveMmapDone	

		mov ecx, dword[ MultibootStrucAddr + multiboot.mmap_length ]
		mov edi, 0x600
		rep movsb

	.RemoveMmapDone:

	mov eax, 0x80000001
	cpuid
	and edx, 0x20000000	;Check for the long mode support bit
	test edx, edx
	jz .fatal_error		;No long mode quit the OS
	mov eax, 1		;Check for the PAE-Bit ( Physical Address Extension)
	cpuid
	and edx, 0x40
	test edx, edx
	jz .fatal_error		;If not available quit OS

	xor eax, eax		;Set up new gdt to ensure transparence as well as enable 64 bit segment descriptors

	mov dword[ GDT_BASE + 0 ], eax		; Null Descriptor
	mov dword[ GDT_BASE + 4 ], eax

	mov eax, 0xFFFF
	mov dword[ GDT_BASE + 8 ], eax		; Limit set to max for all 4 Descriptors
	mov dword[ GDT_BASE + 16 ], eax
	mov dword[ GDT_BASE + 24 ], eax
	mov dword[ GDT_BASE + 32 ], eax

	mov eax, 0x00CF9A00	
	mov dword[ GDT_BASE + 12 ], eax		;Code Segment 32-bit offset: 0x8

	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 20 ], eax		;Data Segment 32-Bit offset: 0x10

	mov eax, 0x00AF9A00
	mov dword[ GDT_BASE + 28 ], eax		;Code Segment 64-bit offset: 0x18
	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 36 ], eax		;Data Segment 64-bit offset: 0x20

	lgdt[ gdt_limit ]
	jmp 0x8:_OwnGDT	

	.fatal_error:	
		mov eax, 0x0F200F20
		mov edi, 0xb8000
		mov ecx, 1000
		rep stosd 		;Clear screen with white foreground black background

		mov ah, 0x04
		mov edi, 0xb8000
		mov esi, NoLongModeMsg	;Print error string

		.print:
			mov al, byte[ esi ]
			
			or al, al
			jz .done
			
			mov word[ edi ], ax
			add edi, 2
			add esi, 1
			jmp .print
		.done:
			jmp $
			
		
align 8
	_OwnGDT:
		mov ax, 0x10	;Load new data descriptors
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax
	
		mov eax, cr4
		or eax, 0x20
		mov cr4, eax	; Set PAE-Bit 

		call InitialisePaging
	
		mov ecx, 0xC0000080
		rdmsr
		or eax, 0x100	;Set Long Mode Bit
		wrmsr

		mov eax, cr0	
		or eax, 0x80000000	;Activate Paging
		mov cr0, eax

		jmp 0x18:LongMode

	
InitialisePaging:
		mov edi, BOOTUP_PML4_ADDR
		xor eax, eax
		mov ecx, 0x1000
		rep stosd
		mov edi, 0x300000


		mov eax, 0x30100F
		xor ebx, ebx
	
		mov dword[ edi ], eax
		mov dword[ edi + 4 ], ebx
		
		mov ecx, 4	
		add edi, 0x1000
		push edi
		.MapAll:
			add eax, 0x1000
			mov dword[ edi ], eax
			mov dword[ edi + 4 ], ebx
			add edi, 8

			sub ecx, 1
			jnz .MapAll

		pop edi
		add edi, 0x1000
		mov eax, 0x8B
		mov ecx, 2048
			

		.Map:
			mov dword[ edi ], eax
			mov dword[ edi + 4 ], ebx
			add edi, 8
			add eax, 0x200000
			sub ecx, 1
			jnz .Map

		mov eax, BOOTUP_PML4_ADDR
		mov cr3, eax
		ret				;Identity Mapped First GB

align 8
[BITS 64]
LongMode:
	mov ax, 0x20	;Load 64-bit Data descriptors
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov gs, ax

	mov al, COLOR_PAIR( COLOR_BLACK, COLOR_WHITE )
	call setScreenAttributes

	call clearScreen


	call InitialisePhysMem

	mov rax, 0x1000
	mov rsi, NeedMem
	call AllocMemory

	mov rax, 0x3000
	mov rsi, NeedMem
	call AllocMemory

	call DebugMemoryAllocation
	jmp $

	call InitialiseAPICModule

	mov edi, 0x1000	
	mov eax, gdt_limit
	call setUpMulticoreEnvironment

	mov eax, 0x1000
	call startAllAPs
	jmp $
	

NeedMem db 'Needed Mem',0
gdt_limit dw 40
gdt_base dd GDT_BASE
NoLongModeMsg db 0x13,'Long mode %x isi %d not available the OS can not boot please restart the PC', 0
