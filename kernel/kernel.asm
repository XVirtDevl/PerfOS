%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM

%define GDT_BASE 0
gdt_limit dw 40
gdt_base dd GDT_BASE


extern LongMode
section .text
global _start
_start:
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
	mov dword[ GDT_BASE + 0 ], eax
	mov dword[ GDT_BASE + 4 ], eax

	mov eax, 0xFFFF
	mov dword[ GDT_BASE + 8 ], eax
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
		mov esi, NoLongModeMsg

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
		mov ax, 0x10
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax
		
		mov eax, cr4
		or eax, 0x40
		mov cr4, eax	; Set PAE-Bit 

		call InitialisePaging
	
		mov ecx, 0xC0000080
		rdmsr
		or eax, 0x100	;Set Long Mode Bit
		wrmsr

		mov eax, cr0	
		or eax, 0x80000000	;Activate Paging
		mov cr0, eax
		
		jmp 0x18:0x200000

InitialisePaging:
		mov edi, 0x300000
		mov eax, 0x301013
		xor ebx, ebx
	
		mov dword[ edi ], eax
		mov dword[ edi + 4 ], ebx
		
		add edi, 0x1000
		add eax, 0x1000
		mov dword[ edi ], eax
		mov dword[ edi + 4 ], ebx

		add edi, 0x1000
		mov eax, 0x93
		mov ecx, 512

		.Map:
			mov dword[ edi ], eax
			mov dword[ edi + 4 ], ebx
			add eax, 0x200000
			sub ecx, 1
			jnz .Map

		mov eax, 0x300000
		mov cr3, eax
		ret				;Identity Mapped First GB

NoLongModeMsg db 'Long mode is not available the OS can not boot please restart the PC', 0
