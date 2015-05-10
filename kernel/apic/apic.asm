%define PRESENT_FLAG 0x80
%define DPL_RING3 0x60
%define DPL_RING2 0x40
%define DPL_RING1 0x20
%define DPL_RING0 0
%define IDT_GATE_64BIT 0xE
%define IDT_TRAP_GATE_64BIT 0x7
%define PIC_MASTER_CMD 0x20
%define PIC_MASTER_DATA 0x21
%define PIC_MASTER_IMR 0x21
%define PIC_SLAVE_CMD 0xA0
%define PIC_SLAVE_DATA 0xA1
%define PIC_SLAVE_IMR 0xA1

struc idt_entry
	.offset resw 1
	.code_sel resw 1
	.unused resb 1
	.type resb 1
	.offset_hi resb 6
	.reserved resd 1
endstruc


global setIDTGate
;rdi = address; rcx = int number
setIDTGate:
	push rsi
	mov esi, dword[ IDT_Base ]

	shl ecx, 4
	add esi, ecx

	mov word[ esi + idt_entry.offset ], di
	shr rdi, 16

	mov word[ esi + idt_entry.code_sel ], cs
	mov byte[ esi + idt_entry.unused ], 0
	mov byte[ esi + idt_entry.type ], (PRESENT_FLAG | DPL_RING0 | IDT_GATE_64BIT )
	mov dword[ esi + idt_entry.offset_hi ], edi
	
	pop rsi
	ret
	
global setIDTBase
;rdi new base of the idt
setIDTBase:
	mov qword[ IDT_Base ], rdi
	push rax
	push rcx
	xor rax, rax
	mov ecx, 512
	rep stosq
	pop rcx
	pop rax
	ret

global loadNewIDT
loadNewIDT:
	lidt[IDT_LIMIT]
	ret	

global picRemapIRQ
picRemapIRQ:
	mov al, 0x11
	out PIC_MASTER_CMD, al
	out PIC_SLAVE_CMD, al

	mov al, 0x20
	out PIC_MASTER_DATA, al
	add al, 8
	out PIC_SLAVE_DATA, al


	mov al, 0x4
	out PIC_MASTER_DATA, al
	mov al, 2
	out PIC_SLAVE_DATA, al

	mov al, 0x01
	out PIC_MASTER_DATA, al
	out PIC_SLAVE_DATA, al

	xor al, al
	out PIC_MASTER_DATA, al
	out PIC_SLAVE_DATA, al
	ret
	

global picMapInterrupts
;ax = mask
picMapInterrupts:
	out PIC_MASTER_IMR, al
	shr ax, 8
	out PIC_SLAVE_IMR, al	

	ret

global startAllAPs
startAllAPs:
	

IDT_LIMIT dw (256*16)-1
IDT_Base dq 0
