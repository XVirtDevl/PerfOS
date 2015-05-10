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

%define LOCAL_APIC_ID 0x20
%define LOCAL_APIC_VERSION 0x30
%define LOCAL_APIC_TPR 0x80
%define LOCAL_APIC_APR 0x90
%define LOCAL_APIC_PPR 0xA0
%define LOCAL_APIC_EOI 0xB0
%define LOCAL_APIC_LOGICALDST 0xD0
%define LOCAL_APIC_DSTFORMAT 0xE0
%define LOCAL_APIC_SPURIOUSVEC 0xF0
%define LOCAL_APIC_ERRORSTATUS 0x230
%define LOCAL_APIC_ICRLOW 0x300
%define LOCAL_APIC_ICRHIGH 0x310
%define LOCAL_APIC_LVTTIMER 0x320
%define LOCAL_APIC_LVTTHERMALSENSOR 0x330
%define LOCAL_APIC_PERFORMANCEMONIT 0x340
%define LOCAL_APIC_LINT0 0x350
%define LOCAL_APIC_LINT1 0x360
%define LOCAL_APIC_LVTERROR 0x370
%define LOCAL_APIC_INITIALCOUNT 0x380
%define LOCAL_APIC_CURRENTCOUNT 0x390
%define LOCAL_APIC_DIVIDECONFIG 0x3E0


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
; eax = start vector
startAllAPs:
	push rbx
	push rcx
	push rdx
	push rax
	mov eax, 1
	cpuid

	test edx, (1<<9)
	jz .noAPIC

	shr eax, 8
	and al, 0xF

	cmp al, 5
	js .noAPIC

	mov ecx, 0x1B
	rdmsr
	and ax, 0xF000
	mov dword[ APIC_BASE ], eax

	mov ebx, 0xC4500
	mov dword[ eax + LOCAL_APIC_ICRLOW ], ebx
	mov ebx, 0xFF000000
	mov dword[ eax + LOCAL_APIC_ICRHIGH ], ebx

	push rax
	mov ebx, 100
	.check:
		in al, 0x92
		sub ebx, 1
		jnz .check

	pop rax
	mov ebx, 0xC4600
	mov dword[ eax + LOCAL_APIC_ICRLOW ], ebx
	mov ecx, 0xFF000000
	mov dword[ eax + LOCAL_APIC_ICRHIGH ], ecx

	push rax

	in al, 0x92
	in al, 0x92
	in al, 0x92
	in al, 0x92
	
	pop rax
	pop rbx
	or ebx, 0xC4600

	mov dword[ eax + LOCAL_APIC_ICRLOW ], ebx
	mov dword[ eax + LOCAL_APIC_ICRHIGH ], ecx


	push qword 0

	.noAPIC:
		pop rax
		pop rdx
		pop rcx
		pop rbx
		ret
	

APIC_BASE dd 0

IDT_LIMIT dw (256*16)-1
IDT_Base dq 0
